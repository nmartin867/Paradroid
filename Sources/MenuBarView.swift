import SwiftUI

struct MenuBarView: View {
    @StateObject private var deviceManager = DeviceManager()
    @State private var settings = ScrcpySettings.load()
    @State private var showSettings = false
    @State private var selectedDevice: AndroidDevice?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ScrcpyConnect")
                    .font(.headline)
                Spacer()
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: showSettings ? "xmark.circle" : "gearshape")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help(showSettings ? "Back to devices" : "Settings")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            if showSettings {
                SettingsPanel(settings: $settings)
            } else {
                DeviceListPanel(
                    deviceManager: deviceManager,
                    settings: settings,
                    selectedDevice: $selectedDevice
                )
            }
        }
        .frame(width: 380)
        .onAppear {
            deviceManager.startAutoRefresh(interval: 3.0)
        }
        .onDisappear {
            deviceManager.stopAutoRefresh()
        }
        .onChange(of: settings) { _, newVal in
            newVal.save()
        }
    }
}

// MARK: - Device List

struct DeviceListPanel: View {
    @ObservedObject var deviceManager: DeviceManager
    let settings: ScrcpySettings
    @Binding var selectedDevice: AndroidDevice?

    var body: some View {
        VStack(spacing: 0) {
            if deviceManager.devices.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No Android devices found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Connect a device via USB or enable\nWireless Debugging on your device")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(deviceManager.devices) { device in
                            DeviceRow(
                                device: device,
                                isSelected: selectedDevice == device,
                                onConnect: {
                                    selectedDevice = device
                                    deviceManager.launchScrcpy(device: device, settings: settings)
                                },
                                onShowPackages: {
                                    PackageWindowController.showPackages(for: device)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
            }

            Divider()

            // Footer
            HStack {
                Circle()
                    .fill(deviceManager.isScanning ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)
                Text("\(deviceManager.devices.count) device\(deviceManager.devices.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") {
                    deviceManager.scan()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct DeviceRow: View {
    let device: AndroidDevice
    let isSelected: Bool
    let onConnect: () -> Void
    let onShowPackages: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: device.id.contains(":") ? "wifi" : "cable.connector")
                .font(.system(size: 18))
                .foregroundStyle(device.isConnectable ? .primary : .tertiary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.model.isEmpty ? device.id : device.model)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(device.id)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    StatusBadge(status: device.status)
                }
            }

            Spacer()

            Button(action: onShowPackages) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 11))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!device.isConnectable)
            .help("View installed packages")

            Button(action: onConnect) {
                Image(systemName: "play.fill")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .controlSize(.small)
            .disabled(!device.isConnectable)
            .help(device.isConnectable ? "Connect with scrcpy" : "Device is \(device.status)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
        )
    }
}

struct StatusBadge: View {
    let status: String

    var color: Color {
        switch status {
        case "device": return .green
        case "offline": return .red
        case "unauthorized": return .orange
        default: return .gray
        }
    }

    var body: some View {
        Text(status)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                Capsule().fill(color.opacity(0.15))
            )
    }
}
