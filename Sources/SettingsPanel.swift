import SwiftUI

struct SettingsPanel: View {
    @Binding var settings: ScrcpySettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Video
                SettingsSection(title: "Video") {
                    SettingsRow(label: "Max resolution") {
                        Picker("", selection: $settings.maxSize) {
                            Text("Original").tag(0)
                            Text("2560").tag(2560)
                            Text("1920").tag(1920)
                            Text("1280").tag(1280)
                            Text("1024").tag(1024)
                            Text("800").tag(800)
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }

                    SettingsRow(label: "Max FPS") {
                        Picker("", selection: $settings.maxFps) {
                            Text("Unlimited").tag(0)
                            Text("120").tag(120)
                            Text("60").tag(60)
                            Text("30").tag(30)
                            Text("15").tag(15)
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }

                    SettingsRow(label: "Video bitrate") {
                        Picker("", selection: $settings.videoBitrate) {
                            Text("2 Mbps").tag(2)
                            Text("4 Mbps").tag(4)
                            Text("8 Mbps").tag(8)
                            Text("16 Mbps").tag(16)
                            Text("32 Mbps").tag(32)
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }

                    SettingsRow(label: "Codec") {
                        Picker("", selection: $settings.videoCodec) {
                            Text("H.264").tag("h264")
                            Text("H.265").tag("h265")
                            Text("AV1").tag("av1")
                        }
                        .labelsHidden()
                        .frame(width: 110)
                    }

                    SettingsRow(label: "Crop") {
                        TextField("w:h:x:y", text: $settings.crop)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                    }
                }

                // Window
                SettingsSection(title: "Window") {
                    Toggle("Always on top", isOn: $settings.alwaysOnTop)
                    Toggle("Start fullscreen", isOn: $settings.fullscreen)

                    SettingsRow(label: "Window title") {
                        TextField("Auto", text: $settings.windowTitle)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                    }
                }

                // Device
                SettingsSection(title: "Device") {
                    Toggle("Turn screen off", isOn: $settings.turnScreenOff)
                    Toggle("Stay awake", isOn: $settings.stayAwake)
                    Toggle("No audio", isOn: $settings.noAudio)
                }

                // Paths
                SettingsSection(title: "Paths") {
                    SettingsRow(label: "scrcpy") {
                        TextField("/opt/homebrew/bin/scrcpy", text: $settings.scrcpyPath)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11, design: .monospaced))
                    }
                }

                // Reset
                HStack {
                    Spacer()
                    Button("Reset to Defaults") {
                        settings = ScrcpySettings()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Reusable components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 6) {
                content
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
            )
        }
    }
}

struct SettingsRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
            Spacer()
            content
        }
    }
}
