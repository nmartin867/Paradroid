import Foundation

struct ScrcpySettings: Codable, Equatable {
    var maxSize: Int = 0          // 0 = no limit
    var maxFps: Int = 0           // 0 = no limit
    var videoBitrate: Int = 8     // Mbps
    var turnScreenOff: Bool = false
    var stayAwake: Bool = false
    var alwaysOnTop: Bool = false
    var fullscreen: Bool = false
    var noAudio: Bool = false
    var crop: String = ""         // e.g. "1224:1440:0:0"
    var windowTitle: String = ""
    var videoCodec: String = "h264"
    var scrcpyPath: String = "/opt/homebrew/bin/scrcpy"

    private static let storageKey = "ScrcpyConnectSettings"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func load() -> ScrcpySettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(ScrcpySettings.self, from: data)
        else {
            return ScrcpySettings()
        }
        return settings
    }
}
