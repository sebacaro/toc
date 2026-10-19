import SwiftUI

@MainActor
struct GeneralPreferencesView: View {
    @AppStorage(UserDefaultsKeys.launchAtLogin) private var launchAtLogin = false
    @AppStorage(UserDefaultsKeys.snappingEnabled) private var snappingEnabled = true
    @AppStorage(UserDefaultsKeys.snapEdgeThreshold) private var edgeThreshold = 8.0
    @AppStorage(UserDefaultsKeys.excludedApplications) private var excludedApplications = ""
    @State private var accessibilityGranted = AccessibilityPermission.isTrusted
    @ObservedObject private var windowManager = WindowManager.shared

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        if !LaunchOnLogin.setEnabled(newValue) {
                            launchAtLogin = !newValue
                        }
                    }
                    .onAppear { launchAtLogin = LaunchOnLogin.isEnabled }

                Toggle("Enable drag-to-edge snapping", isOn: $snappingEnabled)
                    .onChange(of: snappingEnabled) { _, newValue in
                        if newValue {
                            SnapManager.shared.start()
                        } else {
                            SnapManager.shared.stop()
                        }
                    }

                HStack {
                    Text("Edge sensitivity")
                    Slider(value: edgeSensitivity, in: 1...40, step: 1)
                        .accessibilityLabel("Edge sensitivity in screen points")
                    Text("\(Int(WindowPreferences.normalizedEdgeThreshold(CGFloat(edgeThreshold)))) pt")
                        .monospacedDigit()
                        .frame(width: 42, alignment: .trailing)
                }
                .disabled(!snappingEnabled)
                Text("Higher sensitivity activates the preview farther from an edge.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Excluded applications") {
                TextEditor(text: $excludedApplications)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 60)
                    .accessibilityLabel("Excluded application bundle identifiers")
                Text("One bundle identifier per line, for example com.apple.Safari. Exclusions apply to shortcuts and dragging.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Accessibility") {
                HStack {
                    Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(accessibilityGranted ? .green : .red)
                    Text(accessibilityGranted ? "Accessibility permission granted" : "Accessibility permission required")
                }
                if !accessibilityGranted {
                    Button("Grant Access") {
                        AccessibilityPermission.promptForAccess()
                        AccessibilityPermission.openSettings()
                    }
                    Text("Enable the installed copy of Toc. Drag snapping resumes automatically when access is granted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let status = windowManager.lastStatus {
                    Text(status)
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .task {
            while !Task.isCancelled {
                accessibilityGranted = AccessibilityPermission.isTrusted
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
    }

    private var edgeSensitivity: Binding<Double> {
        Binding(
            get: { Double(WindowPreferences.normalizedEdgeThreshold(CGFloat(edgeThreshold))) },
            set: { edgeThreshold = Double(WindowPreferences.normalizedEdgeThreshold(CGFloat($0))) }
        )
    }
}
