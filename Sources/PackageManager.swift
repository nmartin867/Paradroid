import Foundation
import Combine

struct InstalledPackage: Identifiable, Equatable {
    let id: String            // full package name, e.g. "com.spotify.music"
    let isSystemPackage: Bool
}

enum PackageFilter: String, CaseIterable {
    case thirdParty = "Third-Party"
    case all = "All"
    case system = "System"
}

class PackageManager: ObservableObject {
    @Published var packages: [InstalledPackage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var uninstallingPackage: String?

    let device: AndroidDevice
    private let adbPath: String

    init(device: AndroidDevice) {
        self.device = device
        let candidates = [
            "/opt/homebrew/bin/adb",
            "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/adb",
            "/usr/local/bin/adb"
        ]
        self.adbPath = candidates.first { FileManager.default.isExecutableFile(atPath: $0) } ?? "adb"
    }

    func fetchPackages(filter: PackageFilter) {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let allOutput = self.shell("\(self.adbPath) -s \(self.device.id) shell pm list packages")
            let thirdPartyOutput = self.shell("\(self.adbPath) -s \(self.device.id) shell pm list packages -3")

            let allPackages = self.parsePackageList(allOutput)
            let thirdPartySet = Set(self.parsePackageList(thirdPartyOutput))

            let results: [InstalledPackage]
            switch filter {
            case .all:
                results = allPackages.map { name in
                    InstalledPackage(id: name, isSystemPackage: !thirdPartySet.contains(name))
                }
            case .thirdParty:
                results = thirdPartySet.sorted().map { name in
                    InstalledPackage(id: name, isSystemPackage: false)
                }
            case .system:
                results = allPackages
                    .filter { !thirdPartySet.contains($0) }
                    .map { name in InstalledPackage(id: name, isSystemPackage: true) }
            }

            DispatchQueue.main.async {
                self.packages = results.sorted { $0.id < $1.id }
                self.isLoading = false
            }
        }
    }

    func uninstallPackage(_ package: InstalledPackage) {
        uninstallingPackage = package.id
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let command: String
            if package.isSystemPackage {
                command = "\(self.adbPath) -s \(self.device.id) shell pm uninstall --user 0 \(package.id)"
            } else {
                command = "\(self.adbPath) -s \(self.device.id) uninstall \(package.id)"
            }

            let output = self.shell(command).trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async {
                self.uninstallingPackage = nil
                if output.contains("Success") {
                    self.packages.removeAll { $0.id == package.id }
                } else {
                    self.errorMessage = "Failed to uninstall \(package.id): \(output)"
                }
            }
        }
    }

    private func parsePackageList(_ output: String) -> [String] {
        output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("package:") }
            .map { String($0.dropFirst(8)) }
    }

    private func shell(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
