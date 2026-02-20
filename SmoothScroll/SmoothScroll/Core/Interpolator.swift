import Foundation

enum EasingType: String, CaseIterable, Identifiable {
    case linear = "Linear"
    case easeOutQuad = "Ease Out (Light)"
    case easeOutCubic = "Ease Out (Medium)"
    case easeInOutQuad = "Ease In/Out"

    var id: String { rawValue }
}

struct Interpolator {
    /// Linear interpolation: calculates step from current toward target
    func lerp(current: Double, target: Double, factor: Double) -> Double {
        return (target - current) * factor
    }

    /// Ease-out quadratic: decelerating to zero velocity (lighter)
    func easeOutQuad(_ t: Double) -> Double {
        return t * (2 - t)
    }

    /// Ease-out cubic: decelerating to zero velocity (medium)
    func easeOutCubic(_ t: Double) -> Double {
        let t1 = t - 1
        return t1 * t1 * t1 + 1
    }

    /// Ease-in-out quadratic: smooth start and end
    func easeInOutQuad(_ t: Double) -> Double {
        if t < 0.5 {
            return 2 * t * t
        }
        return -1 + (4 - 2 * t) * t
    }

    /// Apply easing based on type
    func apply(value: Double, easing: EasingType, normalizedProgress: Double) -> Double {
        let clampedProgress = max(0, min(1, normalizedProgress))
        let easedFactor: Double

        switch easing {
        case .linear:
            easedFactor = clampedProgress
        case .easeOutQuad:
            easedFactor = easeOutQuad(clampedProgress)
        case .easeOutCubic:
            easedFactor = easeOutCubic(clampedProgress)
        case .easeInOutQuad:
            easedFactor = easeInOutQuad(clampedProgress)
        }

        return value * easedFactor
    }
}
