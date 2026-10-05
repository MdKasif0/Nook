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
        // Light travels down-left towards back-left wall so foreground floor remains brightly sunlit
        let sun = DirectionalLight()
        sun.light.color = .init(red: 1.0, green: 0.94, blue: 0.84, alpha: 1.0)
        sun.light.intensity = 2800
        sun.shadow = DirectionalLightComponent.Shadow(
            shadowProjection: .automatic(maximumDistance: 8.0),
            depthBias: 0.0015
        )
        sun.position = [2.6, 3.4, 0.8]
        sun.look(at: [-0.30, 0.35, -0.40], from: sun.position, relativeTo: nil)
        sun.name = "sun_directional_light"
        root.addChild(sun)
        self.sunLight = sun
        
        // 2. Open Front Key/Fill Light (Streaming into the open-front dollhouse from camera angle)
        let ambient = DirectionalLight()
        ambient.light.color = .init(red: 1.0, green: 0.97, blue: 0.92, alpha: 1.0)
        ambient.light.intensity = 2400
        ambient.position = [2.2, 2.8, 2.8]
        ambient.look(at: [-0.10, 0.50, -0.10], from: ambient.position, relativeTo: nil)
        ambient.name = "ambient_fill_light"
        root.addChild(ambient)
        self.ambientLight = ambient
        
        // 3. Bounce Fill Light (Warm golden under-bounce from wooden floor)
        let bounce = DirectionalLight()
        bounce.light.color = .init(red: 1.0, green: 0.88, blue: 0.72, alpha: 1.0)
        bounce.light.intensity = 950
        bounce.position = [0, -1.0, 0]
        bounce.look(at: [0, 1.0, 0], from: bounce.position, relativeTo: nil)
        bounce.name = "floor_bounce_light"
        root.addChild(bounce)
        self.bounceFillLight = bounce
        
        // 4. Window Glow Illumination (Golden aura around curtains and bed)
        let windowGlow = PointLight()
        windowGlow.light.color = .init(red: 1.0, green: 0.92, blue: 0.78, alpha: 1.0)
        windowGlow.light.intensity = 1800
        windowGlow.light.attenuationRadius = 2.5
        windowGlow.position = [0.55, 1.25, -1.05]
        windowGlow.name = "window_glow_light"
        root.addChild(windowGlow)
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
