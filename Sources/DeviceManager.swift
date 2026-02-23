import Foundation
import Combine

struct AndroidDevice: Identifiable, Equatable, Hashable {
    let id: String        // serial number
    let status: String    // device, offline, unauthorized, etc.
    let model: String     // ro.product.model
    let name: String      // ro.product.device

    var displayName: String {
        if !model.isEmpty {
            return "\(model) (\(id))"
        }
        return id
    }

    var isConnectable: Bool {
        status == "device"
    }
}

class DeviceManager: ObservableObject {
    @Published var devices: [AndroidDevice] = []
    @Published var isScanning: Bool = false

    private var timer: Timer?
    private let adbPath: String

    init() {
        // Resolve adb path: check common locations
        let candidates = [
            "/opt/homebrew/bin/adb",
            "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/adb",
            "/usr/local/bin/adb"
        ]
        self.adbPath = candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
            ?? "adb"
    }

    func startAutoRefresh(interval: TimeInterval = 3.0) {
        stopAutoRefresh()
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.scan()
        }
    }

    func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }

    func scan() {
        isScanning = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let devices = self.fetchDevices()
            DispatchQueue.main.async {
                self.devices = devices
                self.isScanning = false
            }
        }
    }

    private func fetchDevices() -> [AndroidDevice] {
        let output = shell("\(adbPath) devices -l")
        var results: [AndroidDevice] = []

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("List of"),
                  !trimmed.hasPrefix("*") else { continue }

            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard parts.count >= 2 else { continue }

            let serial = parts[0]
            let status = parts[1]

            var model = ""
            var deviceName = ""
            for part in parts.dropFirst(2) {
                if part.hasPrefix("model:") {
                    model = String(part.dropFirst(6))
                } else if part.hasPrefix("device:") {
                    deviceName = String(part.dropFirst(7))
                }
            }

            results.append(AndroidDevice(
                id: serial,
                status: status,
                model: model,
                name: deviceName
            ))
        }
        return results
    }

    func launchScrcpy(device: AndroidDevice, settings: ScrcpySettings) {
        let scrcpyPath = settings.scrcpyPath.isEmpty ? "/opt/homebrew/bin/scrcpy" : settings.scrcpyPath

        var args = ["--serial", device.id]

        if settings.maxSize > 0 {
            args += ["--max-size", "\(settings.maxSize)"]
        }
        if settings.maxFps > 0 {
            args += ["--max-fps", "\(settings.maxFps)"]
        }
        if settings.videoBitrate > 0 {
            args += ["--video-bit-rate", "\(settings.videoBitrate)M"]
        }
        if settings.turnScreenOff {
            args += ["--turn-screen-off"]
        }
        if settings.stayAwake {
            args += ["--stay-awake"]
        }
        if settings.alwaysOnTop {
            args += ["--always-on-top"]
        }
        if settings.fullscreen {
            args += ["--fullscreen"]
        }
        if settings.noAudio {
            args += ["--no-audio"]
        }
        if !settings.crop.isEmpty {
            args += ["--crop", settings.crop]
        }
        if !settings.windowTitle.isEmpty {
            args += ["--window-title", settings.windowTitle]
        } else {
            args += ["--window-title", device.displayName]
        }
        if !settings.videoCodec.isEmpty && settings.videoCodec != "h264" {
            args += ["--video-codec", settings.videoCodec]
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: scrcpyPath)
            process.arguments = args
            // Inherit PATH so scrcpy can find adb
            var env = ProcessInfo.processInfo.environment
            let adbDir = (self.adbPath as NSString).deletingLastPathComponent
            if let existingPath = env["PATH"] {
                env["PATH"] = "\(adbDir):/opt/homebrew/bin:\(existingPath)"
            }
            process.environment = env

            do {
                try process.run()
            } catch {
                print("Failed to launch scrcpy: \(error)")
            }
        }
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
