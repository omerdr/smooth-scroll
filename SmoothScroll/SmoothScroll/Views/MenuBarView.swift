import SwiftUI

struct MenuBarView: View {
    @StateObject private var permissionService = PermissionService.shared

    @AppStorage("isEnabled") private var isEnabled = true
    @AppStorage("sensitivity") private var sensitivity = 1.0
    @AppStorage("smoothness") private var smoothness = 0.85
    @AppStorage("momentumEnabled") private var momentumEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("SmoothScroll")
                    .font(.headline)
                Spacer()
                if !permissionService.hasAccessibilityPermission {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .help("Accessibility permission required")
                }
            }

            Divider()

            // Permission warning if needed
            if !permissionService.hasAccessibilityPermission {
                permissionWarningView
                Divider()
            }

            // Enable Toggle
            Toggle("Enabled", isOn: $isEnabled)
                .toggleStyle(.switch)
                .disabled(!permissionService.hasAccessibilityPermission)
                .onChange(of: isEnabled) { newValue in
                    toggleScrollInterceptor(enabled: newValue)
                }

            Divider()

            // Speed Slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Scroll Speed")
                    .font(.subheadline)
                HStack {
                    Text("Slower")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $sensitivity, in: 0.1...3.0, step: 0.1)
                        .onChange(of: sensitivity) { _ in
                            updateSettings()
                        }
                    Text("Faster")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(!isEnabled || !permissionService.hasAccessibilityPermission)

            // Smoothness Slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Smoothness")
                    .font(.subheadline)
                HStack {
                    Text("Responsive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $smoothness, in: 0.5...0.95, step: 0.05)
                        .onChange(of: smoothness) { _ in
                            updateSettings()
                        }
                    Text("Smooth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(!isEnabled || !permissionService.hasAccessibilityPermission)

            // Momentum Toggle
            Toggle("Momentum (inertia)", isOn: $momentumEnabled)
                .toggleStyle(.checkbox)
                .onChange(of: momentumEnabled) { _ in
                    updateSettings()
                }
                .disabled(!isEnabled || !permissionService.hasAccessibilityPermission)

            Divider()

            // Quit
            Button("Quit SmoothScroll") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            // Apply initial settings
            if permissionService.hasAccessibilityPermission && isEnabled {
                toggleScrollInterceptor(enabled: true)
            }
        }
    }

    private var permissionWarningView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessibility Permission Required")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.orange)

            Text("SmoothScroll needs accessibility access to intercept scroll events.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Open System Settings") {
                permissionService.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private func toggleScrollInterceptor(enabled: Bool) {
        if enabled {
            do {
                try ScrollInterceptor.shared.start()
                updateSettings()
            } catch {
                print("Failed to start ScrollInterceptor: \(error)")
                isEnabled = false
            }
        } else {
            ScrollInterceptor.shared.stop()
        }
    }

    private func updateSettings() {
        ScrollInterceptor.shared.updateSettings(
            sensitivity: sensitivity,
            smoothness: smoothness,
            momentumEnabled: momentumEnabled
        )
    }
}

#Preview {
    MenuBarView()
}
