import RealityKit
import AppKit

/// Manages all physical lights and environmental illumination for the Nook room:
/// - Directional window sunlight entering diagonally from the right window
/// - Soft ambient fill eliminating harsh contact shadows
/// - Bounce warmth simulator
/// - Time-of-day transitions (Morning, Afternoon, Sunset, Cozy Night)
@MainActor
final class RoomLightingSystem {
    
    let rootEntity: Entity
    
    private(set) var sunLight: DirectionalLight
    private(set) var ambientLight: DirectionalLight
    private(set) var bounceFillLight: DirectionalLight
    
    init(root: Entity) {
        self.rootEntity = root
        
        // 1. Primary Directional Sunlight (Streaming through the right window)
        // Positioned pointing from (+X, +Y, +Z) diagonally down towards (-X, -Y, -Z)
        let sun = DirectionalLight()
        sun.light.color = .init(red: 1.0, green: 0.94, blue: 0.86, alpha: 1.0)
        sun.light.intensity = 2600
        sun.shadow = DirectionalLightComponent.Shadow(
            shadowProjection: .automatic(maximumDistance: 8.0),
            depthBias: 0.0015
        )
        // Window sun orientation: Angled down from the right wall window
        sun.orientation = simd_quatf(angle: -Float.pi * 0.32, axis: [1, 0, 0]) * simd_quatf(angle: Float.pi * 0.42, axis: [0, 1, 0])
        sun.name = "sun_directional_light"
        root.addChild(sun)
        self.sunLight = sun
        
        // 2. Ambient Fill Light (Soft warm cream, prevents pitch black shadows)
        let ambient = DirectionalLight()
        ambient.light.color = .init(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
        ambient.light.intensity = 850
        // Opposite angle to fill shadow sides gently
        ambient.orientation = simd_quatf(angle: Float.pi * 0.28, axis: [1, 0, 0]) * simd_quatf(angle: -Float.pi * 0.35, axis: [0, 1, 0])
        ambient.name = "ambient_fill_light"
        root.addChild(ambient)
        self.ambientLight = ambient
        
        // 3. Bounce Fill Light (Warm golden under-bounce from wooden floor)
        let bounce = DirectionalLight()
        bounce.light.color = .init(red: 1.0, green: 0.88, blue: 0.72, alpha: 1.0)
        bounce.light.intensity = 450
        bounce.orientation = simd_quatf(angle: Float.pi * 0.45, axis: [1, 0, 0])
        bounce.name = "floor_bounce_light"
        root.addChild(bounce)
        self.bounceFillLight = bounce
    }
    
    /// Updates illumination according to the current RoomTimeOfDay
    func applyTimeOfDay(_ timeOfDay: RoomTimeOfDay) {
        switch timeOfDay {
        case .morning:
            sunLight.light.color = .init(red: 1.0, green: 0.94, blue: 0.86, alpha: 1.0)
            sunLight.light.intensity = 2400
            ambientLight.light.color = .init(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
            ambientLight.light.intensity = 800
            bounceFillLight.light.intensity = 400
            
        case .afternoon:
            sunLight.light.color = .init(red: 1.0, green: 0.98, blue: 0.93, alpha: 1.0)
            sunLight.light.intensity = 2700
            ambientLight.light.color = .init(red: 0.96, green: 0.95, blue: 0.92, alpha: 1.0)
            ambientLight.light.intensity = 900
            bounceFillLight.light.intensity = 450
            
        case .sunset:
            // Warm golden hour
            sunLight.light.color = .init(red: 1.0, green: 0.76, blue: 0.52, alpha: 1.0)
            sunLight.light.intensity = 2200
            ambientLight.light.color = .init(red: 0.98, green: 0.88, blue: 0.78, alpha: 1.0)
            ambientLight.light.intensity = 750
            bounceFillLight.light.intensity = 550
            
        case .night:
            // Strictly warm amber interior lighting — NO blue
            sunLight.light.color = .init(red: 0.96, green: 0.82, blue: 0.64, alpha: 1.0)
            sunLight.light.intensity = 350
            ambientLight.light.color = .init(red: 0.75, green: 0.62, blue: 0.48, alpha: 1.0)
            ambientLight.light.intensity = 450
            bounceFillLight.light.intensity = 300
        }
    }
}
