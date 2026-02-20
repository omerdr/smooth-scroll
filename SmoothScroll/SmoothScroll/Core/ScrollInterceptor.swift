import Cocoa
import CoreGraphics

enum ScrollInterceptorError: Error {
    case eventTapCreationFailed
    case runLoopSourceCreationFailed
    case notTrusted
}

final class ScrollInterceptor {
    static let shared = ScrollInterceptor()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var isEnabled = false

    private let animator = ScrollAnimator()
    private(set) lazy var processor = ScrollProcessor(animator: animator)

    // Event mask for scroll wheel events
    private let scrollEventMask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)

    private init() {}

    func start() throws {
        guard !isEnabled else { return }

        // Check accessibility permission first
        guard AXIsProcessTrusted() else {
            throw ScrollInterceptorError.notTrusted
        }

        // Create event tap at HID level, head insert for early interception
        // Using UnsafeMutableRawPointer to pass self to the C callback
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,           // Intercept at HID level (before system processes)
            place: .headInsertEventTap,     // Insert at the head of the event queue
            options: .defaultTap,           // Active tap (can modify/suppress events)
            eventsOfInterest: scrollEventMask,
            callback: scrollEventCallback,
            userInfo: userInfo
        )

        guard let eventTap = eventTap else {
            throw ScrollInterceptorError.eventTapCreationFailed
        }

        // Create run loop source from the event tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        guard let runLoopSource = runLoopSource else {
            self.eventTap = nil
            throw ScrollInterceptorError.runLoopSourceCreationFailed
        }

        // Add to the main run loop
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)

        // Enable the tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        isEnabled = true

        print("ScrollInterceptor started successfully")
    }

    func stop() {
        guard isEnabled, let eventTap = eventTap else { return }

        // Disable the tap
        CGEvent.tapEnable(tap: eventTap, enable: false)

        // Remove from run loop
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        self.eventTap = nil
        self.runLoopSource = nil
        isEnabled = false

        print("ScrollInterceptor stopped")
    }

    /// Handle event tap being disabled by timeout (can happen if callback takes too long)
    fileprivate func handleTapDisabled() {
        guard let eventTap = eventTap else { return }
        // Re-enable the tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("ScrollInterceptor: Re-enabled tap after timeout")
    }

    /// Process a scroll event
    fileprivate func processScrollEvent(_ event: CGEvent) -> CGEvent? {
        return processor.processEvent(event: event)
    }

    /// Update settings
    func updateSettings(sensitivity: Double, smoothness: Double, momentumEnabled: Bool) {
        processor.updateSettings(
            sensitivity: sensitivity,
            smoothness: smoothness,
            momentumEnabled: momentumEnabled
        )
    }
}

// C-style callback function required by CGEvent API
private func scrollEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let interceptor = Unmanaged<ScrollInterceptor>.fromOpaque(userInfo).takeUnretainedValue()

    // Handle special event types
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
        // Event tap was disabled, re-enable it
        interceptor.handleTapDisabled()
        return Unmanaged.passUnretained(event)

    case .scrollWheel:
        // Process the scroll event
        if let processedEvent = interceptor.processScrollEvent(event) {
            return Unmanaged.passUnretained(processedEvent)
        } else {
            // Return nil to suppress the event
            return nil
        }

    default:
        // Pass through other events unchanged
        return Unmanaged.passUnretained(event)
    }
}
