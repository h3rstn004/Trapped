import RealityKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

enum RoomBuilder {
    static let roomWidth: Float = 10
    static let roomLength: Float = 10
    static let roomHeight: Float = 3
    static let wallThickness: Float = 0.2

    static func makeRoom() -> Entity {
        let room = Entity()
        room.name = "DarkRoom"

        // This disables image-based/environment lighting for the room and all descendants.
        room.components.set(
            EnvironmentLightingConfigurationComponent(environmentLightingWeight: 0)
        )

        #if os(macOS)
        let roomColor = NSColor(white: 0.22, alpha: 1)
        #else
        let roomColor = UIColor(white: 0.22, alpha: 1)
        #endif

        let material = SimpleMaterial(color: roomColor, isMetallic: false)

        let floor = makeBox(
            size: [roomWidth, wallThickness, roomLength],
            position: [0, -wallThickness / 2, 0],
            material: material,
            name: "Floor"
        )

        let ceiling = makeBox(
            size: [roomWidth, wallThickness, roomLength],
            position: [0, roomHeight + wallThickness / 2, 0],
            material: material,
            name: "Ceiling"
        )

        let northWall = makeBox(
            size: [roomWidth, roomHeight, wallThickness],
            position: [0, roomHeight / 2, -roomLength / 2],
            material: material,
            name: "NorthWall"
        )

        let southWall = makeBox(
            size: [roomWidth, roomHeight, wallThickness],
            position: [0, roomHeight / 2, roomLength / 2],
            material: material,
            name: "SouthWall"
        )

        let westWall = makeBox(
            size: [wallThickness, roomHeight, roomLength],
            position: [-roomWidth / 2, roomHeight / 2, 0],
            material: material,
            name: "WestWall"
        )

        let eastWall = makeBox(
            size: [wallThickness, roomHeight, roomLength],
            position: [roomWidth / 2, roomHeight / 2, 0],
            material: material,
            name: "EastWall"
        )

        room.addChild(floor)
        room.addChild(ceiling)
        room.addChild(northWall)
        room.addChild(southWall)
        room.addChild(westWall)
        room.addChild(eastWall)

        return room
    }

    private static func makeBox(
        size: SIMD3<Float>,
        position: SIMD3<Float>,
        material: SimpleMaterial,
        name: String
    ) -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generateBox(size: size),
            materials: [material]
        )
        entity.name = name
        entity.position = position
        return entity
    }
}
