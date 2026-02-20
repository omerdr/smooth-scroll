import CoreGraphics
import Foundation

final class ScrollProcessor {
    private let animator: ScrollAnimator

    init(animator: ScrollAnimator) {
        self.animator = animator
    }

    /// Process a scroll event and return the event to pass through, or nil to suppress it
    func processEvent(event: CGEvent) -> CGEvent? {
        // Check if this is a continuous event (trackpad) vs discrete (mouse wheel)
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0

        // Skip trackpad events - they already have smooth scrolling
        if isContinuous {
            return event
        }

        // Extract raw scroll deltas (discrete notch values: +1/-1 per notch)
        let deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
        let deltaX = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)

        // Skip if no actual scroll
        if deltaY == 0 && deltaX == 0 {
            return event
        }

        // At HID level, Shift+Scroll arrives as a vertical event (axis1) — the
        // axis swap to horizontal happens later at the AppKit layer. Detect the
        // Shift modifier here and reroute the delta to the horizontal axis so
        // the animated synthetic event is posted as horizontal, not vertical.
        let isShiftDown = event.flags.contains(.maskShift)
        let effectiveDeltaY: Int64 = isShiftDown ? 0 : deltaY
        let effectiveDeltaX: Int64 = isShiftDown ? deltaY : deltaX

        // Feed to animator for smooth interpolation
        animator.addScrollImpulse(
            deltaY: effectiveDeltaY,
            deltaX: effectiveDeltaX
        )

        // Suppress original event (return nil)
        return nil
    }

    /// Update animator settings
    func updateSettings(sensitivity: Double, smoothness: Double, momentumEnabled: Bool) {
        animator.sensitivity = sensitivity
        animator.smoothness = smoothness
        animator.momentumEnabled = momentumEnabled
    }
}
