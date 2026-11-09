import Foundation
import RealityKit

@MainActor
final class PlayerController {
    let player: Entity
    let camera: PerspectiveCamera
    let flashlight: FlashlightController

    private let input: InputController
    private let movementSpeed: Float = 2.5
    private let lookSensitivity: Float = 0.003
    private let eyeHeight: Float = 1.7

    private var yaw: Float = 0
    private var pitch: Float = 0

    init(input: InputController) {
        self.input = input
        player = Entity()
        player.name = "Player"
        player.position = [0, 0, 0]

        camera = PerspectiveCamera()
        camera.name = "FirstPersonCamera"
        camera.position = [0, eyeHeight, 0]

        flashlight = FlashlightController()

        player.addChild(camera)
        camera.addChild(flashlight.entity)
    }

    func update(deltaTime: TimeInterval) {
        let look = input.consumeLookDelta()

        yaw -= look.x * lookSensitivity
        pitch -= look.y * lookSensitivity
        pitch = max(-1.35, min(1.35, pitch))

        player.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        camera.orientation = simd_quatf(angle: pitch, axis: [1, 0, 0])

        let movement = input.movement
        guard simd_length(movement) > 0.01 else { return }

        // Movement is relative to the player's horizontal facing direction.
        let forward = SIMD3<Float>(-sin(yaw), 0, -cos(yaw))
        let right = SIMD3<Float>(cos(yaw), 0, -sin(yaw))
        let direction = forward * movement.y + right * movement.x
        let distance = movementSpeed * Float(deltaTime)

        var nextPosition = player.position + direction * distance

        // Keep the player's body inside the room, leaving space from the walls.
        let halfWidth = RoomBuilder.roomWidth / 2 - 0.45
        let halfLength = RoomBuilder.roomLength / 2 - 0.45
        nextPosition.x = max(-halfWidth, min(halfWidth, nextPosition.x))
        nextPosition.z = max(-halfLength, min(halfLength, nextPosition.z))
        nextPosition.y = 0

        player.position = nextPosition
    }
}
