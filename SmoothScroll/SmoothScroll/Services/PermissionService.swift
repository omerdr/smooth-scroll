import Cocoa
import ApplicationServices
import Combine

final class PermissionService: ObservableObject {
    static let shared = PermissionService()

    @Published private(set) var hasAccessibilityPermission: Bool = false

    private var permissionCheckTimer: Timer?

    private init() {
        hasAccessibilityPermission = checkPermission()
        startMonitoring()
    }

    @discardableResult
    func checkPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = trusted
        }
        return trusted
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func startMonitoring() {
        // Poll for permission changes since there's no reliable notification
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
    }

    deinit {
        permissionCheckTimer?.invalidate()
    }
}
