import Foundation
import RealityKit

/// Shared input values used by both keyboard and iPhone controls.
@MainActor
final class InputController {
    var movement: SIMD2<Float> = .zero
    var lookDelta: SIMD2<Float> = .zero

    func setMovement(_ value: SIMD2<Float>) {
        movement = SIMD2(
            max(-1, min(1, value.x)),
            max(-1, min(1, value.y))
        )
    }

    func addLookDelta(_ value: SIMD2<Float>) {
        lookDelta += value
    }

    func consumeLookDelta() -> SIMD2<Float> {
        let value = lookDelta
        lookDelta = .zero
        return value
    }
}
