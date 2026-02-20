import Cocoa
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check accessibility permission on launch
        let permissionService = PermissionService.shared

        if !permissionService.checkPermission() {
            // Request permission (shows system dialog)
            permissionService.requestPermission()
        }

        // Monitor for permission changes and auto-start when granted
        permissionService.$hasAccessibilityPermission
            .removeDuplicates()
            .sink { [weak self] hasPermission in
                self?.handlePermissionChange(hasPermission: hasPermission)
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up: stop the interceptor
        ScrollInterceptor.shared.stop()
    }

    private func handlePermissionChange(hasPermission: Bool) {
        let isEnabled = UserDefaults.standard.bool(forKey: "isEnabled")

        if hasPermission && isEnabled {
            // Start interceptor if permission granted and user has it enabled
            do {
                try ScrollInterceptor.shared.start()
                applyStoredSettings()
            } catch {
                print("Failed to start ScrollInterceptor: \(error)")
            }
        } else if !hasPermission {
            // Stop interceptor if permission revoked
            ScrollInterceptor.shared.stop()
        }
    }

    private func applyStoredSettings() {
        let defaults = UserDefaults.standard
        let sensitivity = defaults.double(forKey: "sensitivity")
        let smoothness = defaults.double(forKey: "smoothness")
        let momentumEnabled = defaults.bool(forKey: "momentumEnabled")

        // Use defaults if not set
        let finalSensitivity = sensitivity > 0 ? sensitivity : 1.0
        let finalSmoothness = smoothness > 0 ? smoothness : 0.85

        ScrollInterceptor.shared.updateSettings(
            sensitivity: finalSensitivity,
            smoothness: finalSmoothness,
            momentumEnabled: momentumEnabled
        )
    }
}
