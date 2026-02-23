import SwiftUI
import AppKit

// MARK: - Window Controller

class PackageWindowController {
    private static var openWindows: [String: NSWindow] = [:]

    static func showPackages(for device: AndroidDevice) {
        if let existing = openWindows[device.id], existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let packageManager = PackageManager(device: device)
        let contentView = PackageListView(packageManager: packageManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Packages — \(device.displayName)"
        window.contentViewController = NSHostingController(rootView: contentView)
        window.center()
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 400, height: 350)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        openWindows[device.id] = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { notification in
            guard let closingWindow = notification.object as? NSWindow else { return }
            openWindows = openWindows.filter { $0.value !== closingWindow }
        }
    }
}

// MARK: - Package List View

struct PackageListView: View {
    @ObservedObject var packageManager: PackageManager
    @State private var searchText = ""
    @State private var filter: PackageFilter = .thirdParty
    @State private var packageToUninstall: InstalledPackage?

    private var filteredPackages: [InstalledPackage] {
        if searchText.isEmpty { return packageManager.packages }
        return packageManager.packages.filter {
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search packages...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))

                Picker("Filter", selection: $filter) {
                    ForEach(PackageFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(12)

            Divider()

            // Count + Refresh
            HStack {
                Text("\(filteredPackages.count) packages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if packageManager.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Refresh") {
                    packageManager.fetchPackages(filter: filter)
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .disabled(packageManager.isLoading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // Package list
            if packageManager.isLoading && packageManager.packages.isEmpty {
                Spacer()
                ProgressView("Loading packages...")
                Spacer()
            } else if filteredPackages.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "No packages found" : "No matching packages")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredPackages) { pkg in
                            PackageRow(
                                package: pkg,
                                isUninstalling: packageManager.uninstallingPackage == pkg.id,
                                onUninstall: { packageToUninstall = pkg }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }

            Divider()

            // Status footer
            HStack(spacing: 6) {
                if let error = packageManager.errorMessage {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else if let name = packageManager.uninstallingPackage {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Uninstalling \(name)...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Ready")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(minWidth: 400, minHeight: 350)
        .onAppear {
            packageManager.fetchPackages(filter: filter)
        }
        .onChange(of: filter) { _, newFilter in
            packageManager.fetchPackages(filter: newFilter)
        }
        .alert(
            "Uninstall Package",
            isPresented: Binding(
                get: { packageToUninstall != nil },
                set: { if !$0 { packageToUninstall = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { packageToUninstall = nil }
            Button("Uninstall", role: .destructive) {
                if let pkg = packageToUninstall {
                    packageManager.uninstallPackage(pkg)
                }
                packageToUninstall = nil
            }
        } message: {
            if let pkg = packageToUninstall {
                Text("Are you sure you want to uninstall \(pkg.id)?" + (pkg.isSystemPackage ? " This is a system package and will only be removed for the current user." : ""))
            }
        }
    }
}

// MARK: - Package Row

struct PackageRow: View {
    let package: InstalledPackage
    let isUninstalling: Bool
    let onUninstall: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: package.isSystemPackage ? "gearshape.fill" : "shippingbox.fill")
                .font(.system(size: 14))
                .foregroundStyle(package.isSystemPackage ? .orange : .blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(package.id)
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
                if package.isSystemPackage {
                    Text("System")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(.orange.opacity(0.15)))
                }
            }

            Spacer()

            if isUninstalling {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(action: onUninstall) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Uninstall \(package.id)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
        )
    }
}
