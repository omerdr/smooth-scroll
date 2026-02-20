import CoreVideo
import CoreGraphics
import Foundation

final class ScrollAnimator {
    private var displayLink: CVDisplayLink?
    private var isRunning = false

    // Animation state
    private var currentY: Double = 0
    private var currentX: Double = 0
    private var targetY: Double = 0
    private var targetX: Double = 0

    // Velocity for momentum
    private var velocityY: Double = 0
    private var velocityX: Double = 0
    private var lastScrollTime: CFAbsoluteTime = 0

    // Settings (will be updated from SettingsService)
    var sensitivity: Double = 1.0
    var smoothness: Double = 0.85
    var momentumEnabled: Bool = true
    var baseScrollAmount: Double = 50.0

    // Momentum settings
    private let momentumDecay: Double = 0.95
    private let momentumThreshold: Double = 0.5
    private let scrollPauseThreshold: TimeInterval = 0.1  // 100ms

    // Dead zone - stop animating when delta is negligible
    private let deadZone: Double = 0.1


    // Thread safety
    private let lock = NSLock()

    init() {
        setupDisplayLink()
    }

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let displayLink = link else {
            print("Failed to create CVDisplayLink")
            return
        }

        self.displayLink = displayLink

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
            guard let userInfo = userInfo else { return kCVReturnError }
            let animator = Unmanaged<ScrollAnimator>.fromOpaque(userInfo).takeUnretainedValue()
            animator.tick()
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(
            displayLink,
            callback,
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    func addScrollImpulse(deltaY: Int64, deltaX: Int64) {
        lock.lock()
        defer { lock.unlock() }

        // Calculate target scroll amount based on sensitivity
        let impulseY = Double(deltaY) * sensitivity * baseScrollAmount
        let impulseX = Double(deltaX) * sensitivity * baseScrollAmount

        // Accumulate target values
        targetY += impulseY
        targetX += impulseX

        // Update velocity for momentum
        velocityY = impulseY
        velocityX = impulseX
        lastScrollTime = CFAbsoluteTimeGetCurrent()

        // Start animation if not running
        if !isRunning {
            start()
        }
    }

    private func tick() {
        lock.lock()

        let now = CFAbsoluteTimeGetCurrent()
        let timeSinceScroll = now - lastScrollTime
        let inMomentumPhase = timeSinceScroll > scrollPauseThreshold

        var frameY: Double = 0
        var frameX: Double = 0

        if inMomentumPhase && momentumEnabled {
            // Momentum phase: apply decaying velocity
            velocityY *= momentumDecay
            velocityX *= momentumDecay

            frameY = velocityY
            frameX = velocityX

            // Update targets to match momentum
            targetY = currentY + velocityY
            targetX = currentX + velocityX
        } else {
            // Active scrolling: interpolate toward target
            let factor = 1.0 - smoothness
            frameY = (targetY - currentY) * factor
            frameX = (targetX - currentX) * factor
        }

        // Update current position
        currentY += frameY
        currentX += frameX

        let magnitude = sqrt(frameY * frameY + frameX * frameX)
        let remainingY = abs(targetY - currentY)
        let remainingX = abs(targetX - currentX)
        let velocityMagnitude = sqrt(velocityY * velocityY + velocityX * velocityX)

        // Check if animation should stop
        let shouldStop: Bool
        if inMomentumPhase && momentumEnabled {
            shouldStop = velocityMagnitude < momentumThreshold
        } else {
            shouldStop = remainingY < deadZone && remainingX < deadZone && magnitude < deadZone
        }

        lock.unlock()

        // Post scroll event if above dead zone
        if magnitude > deadZone {
            postScrollEvent(deltaY: frameY, deltaX: frameX)
        }

        if shouldStop {
            resetState()
            stop()
        }
    }

    private func postScrollEvent(deltaY: Double, deltaX: Double) {
        // Create a scroll wheel event
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(deltaY.rounded()),
            wheel2: Int32(deltaX.rounded()),
            wheel3: 0
        ) else {
            return
        }

        // Set as continuous scroll (smooth)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)

        // Set point delta values for pixel-precise scrolling
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: deltaY)
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: deltaX)

        // Post the event at session level (not HID level) to avoid interfering with mouse movement
        event.post(tap: .cgSessionEventTap)
    }

    private func resetState() {
        lock.lock()
        defer { lock.unlock() }

        currentY = 0
        currentX = 0
        targetY = 0
        targetX = 0
        velocityY = 0
        velocityX = 0
    }

    private func start() {
        guard let displayLink = displayLink, !isRunning else { return }
        CVDisplayLinkStart(displayLink)
        isRunning = true
    }

    private func stop() {
        guard let displayLink = displayLink, isRunning else { return }
        CVDisplayLinkStop(displayLink)
        isRunning = false
    }

    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}
