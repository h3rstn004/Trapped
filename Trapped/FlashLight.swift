import RealityKit

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

@MainActor
final class FlashlightController {
    let entity: Entity
    private(set) var isOn = false

    init() {
        entity = Entity()
        entity.name = "PlayerFlashlight"

        #if os(macOS)
        let flashlightColor = NSColor.white
        #else
        let flashlightColor = UIColor.white
        #endif

        let spotlight = SpotLightComponent(
            color: flashlightColor,
            intensity: 450,
            innerAngleInDegrees: 16,
            outerAngleInDegrees: 30,
            attenuationRadius: 14
        )

        entity.components.set(spotlight)
        entity.components.set(SpotLightComponent.Shadow())
        entity.isEnabled = false
    }

    func setOn(_ enabled: Bool) {
        isOn = enabled
        entity.isEnabled = enabled
    }

    func toggle() {
        setOn(!isOn)
    }
}
