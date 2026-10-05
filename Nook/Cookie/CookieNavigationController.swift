import Foundation
import RealityKit
import simd

/// A physical bounding box for navigation queries and obstacle avoidance.
public struct NavBox: Sendable {
    public let minX: Float
    public let maxX: Float
    public let minZ: Float
    public let maxZ: Float
    
    public init(minX: Float, maxX: Float, minZ: Float, maxZ: Float) {
        self.minX = minX
        self.maxX = maxX
        self.minZ = minZ
        self.maxZ = maxZ
    }
    
    public func contains(x: Float, z: Float) -> Bool {
        x >= minX && x <= maxX && z >= minZ && z <= maxZ
    }
    
    public func clamp(x: Float, z: Float) -> (Float, Float) {
        let cx = min(max(x, minX), maxX)
        let cz = min(max(z, minZ), maxZ)
        return (cx, cz)
    }
}

/// The discrete physical zones inside Nook's miniature room diorama where Cookie can walk or perch.
public enum RoomNavZone: String, CaseIterable, Sendable {
    case daybed = "Daybed"
    case desk = "Desk"
    case upperFloor = "Upper Floor"
    case lowerFloor = "Sunken Lounge"
    case ottoman = "Record Bench"
    case windowLedge = "Window Sill"
    
    public var surfaceY: Float {
        switch self {
        case .daybed:      return 0.605
        case .desk:        return 0.880
        case .upperFloor:  return 0.160
        case .lowerFloor:  return 0.020
        case .ottoman:     return 0.380
        case .windowLedge: return 0.850
        }
    }
    
    public var bounds: NavBox {
        switch self {
        case .daybed:
            // Daybed mattress surface (comfortably away from walls/headboard)
            return NavBox(minX: -0.10, maxX: 0.78, minZ: -0.90, maxZ: -0.45)
        case .desk:
            // Desk tabletop surface (excluding monitor/laptop rear footprint)
            return NavBox(minX: -0.92, maxX: -0.52, minZ: -0.55, maxZ: 0.20)
        case .upperFloor:
            // Main room floor platform (excluding desk chair & walls)
            return NavBox(minX: -0.42, maxX: 0.45, minZ: -0.35, maxZ: 0.18)
        case .lowerFloor:
            // Sunken lounge floor platform (excluding pouf & table)
            return NavBox(minX: -0.85, maxX: 0.85, minZ: 0.24, maxZ: 0.82)
        case .ottoman:
            // Audio lounge record bench
            return NavBox(minX: 0.58, maxX: 0.82, minZ: -0.38, maxZ: 0.05)
        case .windowLedge:
            // Warm window sill ledge
            return NavBox(minX: 0.22, maxX: 0.68, minZ: -1.01, maxZ: -0.96)
        }
    }
    
    /// Default comfortable lounging point inside this zone
    public var defaultSpot: SIMD3<Float> {
        switch self {
        case .daybed:      return SIMD3<Float>(0.48, 0.605, -0.66)
        case .desk:        return SIMD3<Float>(-0.70, 0.880, -0.15)
        case .upperFloor:  return SIMD3<Float>(0.08, 0.160, -0.10)
        case .lowerFloor:  return SIMD3<Float>(-0.25, 0.020, 0.55)
        case .ottoman:     return SIMD3<Float>(0.68, 0.380, -0.18)
        case .windowLedge: return SIMD3<Float>(0.45, 0.850, -0.98)
        }
    }
}

/// Navigation abstraction determining valid surfaces, avoiding walls/furniture obstacles,
/// and executing smooth, physically constrained locomotion.
@MainActor
public final class CookieNavigationController {
    
    public weak var entity: CookieRealityEntity?
    public private(set) var currentZone: RoomNavZone = .daybed
    public private(set) var isNavigating: Bool = false
    
    // Physical Room Obstacles (No-walk zones within otherwise open areas)
    private static let monitorObstacle = NavBox(minX: -0.88, maxX: -0.50, minZ: -0.92, maxZ: -0.60)
    private static let deskChairObstacle = NavBox(minX: -0.48, maxX: -0.18, minZ: -0.32, maxZ: 0.05)
    private static let bouclePoufObstacle = NavBox(minX: 0.08, maxX: 0.34, minZ: 0.52, maxZ: 0.78)
    private static let skateboardObstacle = NavBox(minX: -0.18, maxX: 0.12, minZ: 0.24, maxZ: 0.54)
    
    // Room Boundary Clamps
    public static let minRoomX: Float = -1.02
    public static let maxRoomX: Float = 1.02
    public static let minRoomZ: Float = -1.02
    public static let maxRoomZ: Float = 0.88
    
    public init(entity: CookieRealityEntity? = nil) {
        self.entity = entity
    }
    
    // MARK: - Zone & Surface Detection
    
    /// Determines the navigation zone matching any 3D point in the room.
    public static func zone(for position: SIMD3<Float>) -> RoomNavZone {
        let x = position.x
        let y = position.y
        let z = position.z
        
        // 1. Desk tabletop (elevation > 0.75m on left)
        if x <= -0.50 && z <= 0.25 && y >= 0.70 {
            return .desk
        }
        
        // 2. Window sill (elevation > 0.75m at back window)
        if x >= 0.18 && x <= 0.72 && z <= -0.90 && y >= 0.75 {
            return .windowLedge
        }
        
        // 3. Daybed surface (elevation > 0.45m at back-right)
        if x >= -0.15 && z <= -0.35 && y >= 0.45 {
            return .daybed
        }
        
        // 4. Ottoman record bench (elevation > 0.25m at mid-right)
        if x >= 0.52 && z >= -0.42 && z <= 0.10 && y >= 0.25 {
            return .ottoman
        }
        
        // 5. Lower Sunken Lounge (foreground floor)
        if z >= 0.20 {
            return .lowerFloor
        }
        
        // 6. Upper Main Floor
        return .upperFloor
    }
    
    /// Computes the exact physical resting surface height Y at any (x, z) coordinate.
    public static func surfaceHeight(at x: Float, z: Float) -> Float {
        // Tabletop / elevated surfaces take precedence
        if x <= -0.52 && z <= 0.22 && z >= -0.92 {
            return RoomNavZone.desk.surfaceY
        }
        if x >= -0.12 && z <= -0.42 && z >= -0.95 {
            return RoomNavZone.daybed.surfaceY
        }
        if x >= 0.55 && z >= -0.40 && z <= 0.08 {
            return RoomNavZone.ottoman.surfaceY
        }
        if x >= 0.20 && x <= 0.70 && z <= -0.95 {
            return RoomNavZone.windowLedge.surfaceY
        }
        if z >= 0.20 {
            return RoomNavZone.lowerFloor.surfaceY
        }
        return RoomNavZone.upperFloor.surfaceY
    }
    
    /// Checks if a position collides with any physical furniture obstacles.
    public static func isObstacle(x: Float, z: Float) -> Bool {
        if monitorObstacle.contains(x: x, z: z) { return true }
        if deskChairObstacle.contains(x: x, z: z) { return true }
        if bouclePoufObstacle.contains(x: x, z: z) { return true }
        if skateboardObstacle.contains(x: x, z: z) { return true }
        return false
    }
    
    /// Clamps an arbitrary position into a safe, valid walkable coordinate on a specified surface.
    public static func clampToWalkable(_ target: SIMD3<Float>, zone: RoomNavZone? = nil) -> SIMD3<Float> {
        let resolvedZone = zone ?? Self.zone(for: target)
        let bounds = resolvedZone.bounds
        var (clampedX, clampedZ) = bounds.clamp(x: target.x, z: target.z)
        
        // Hard room boundary limits
        clampedX = min(max(clampedX, minRoomX), maxRoomX)
        clampedZ = min(max(clampedZ, minRoomZ), maxRoomZ)
        
        // Steer clear of localized obstacles
        if isObstacle(x: clampedX, z: clampedZ) {
            // Nudge toward zone center
            let center = resolvedZone.defaultSpot
            clampedX = (clampedX * 0.4) + (center.x * 0.6)
            clampedZ = (clampedZ * 0.4) + (center.z * 0.6)
        }
        
        return SIMD3<Float>(clampedX, resolvedZone.surfaceY, clampedZ)
    }
    
    // MARK: - Autonomous Navigation
    
    /// Smoothly navigates Cookie to a designated room coordinate.
    /// Handles obstacle avoidance, walking animations, and parabolic ballistic jumps between elevation changes.
    @discardableResult
    public func navigateTo(destination rawDest: SIMD3<Float>) async -> Bool {
        guard !isNavigating, let entity = self.entity else { return false }
        isNavigating = true
        defer { isNavigating = false }
        
        let targetZone = Self.zone(for: rawDest)
        let safeDest = Self.clampToWalkable(rawDest, zone: targetZone)
        let currentPos = entity.position
        let currentZone = Self.zone(for: currentPos)
        self.currentZone = currentZone
        
        // 1. Same surface navigation (Smooth walking waddle)
        if currentZone == targetZone {
            return await walkSegment(from: currentPos, to: safeDest)
        }
        
        // 2. Inter-surface navigation (Requires approach walk -> jump -> arrival walk)
        // Find intermediate approach edge
        let approachEdge: SIMD3<Float>
        let landingSpot: SIMD3<Float>
        
        switch (currentZone, targetZone) {
        case (.daybed, .upperFloor):
            approachEdge = SIMD3<Float>(0.05, RoomNavZone.daybed.surfaceY, -0.55)
            landingSpot = SIMD3<Float>(0.05, RoomNavZone.upperFloor.surfaceY, -0.42)
            
        case (.upperFloor, .daybed):
            approachEdge = SIMD3<Float>(0.05, RoomNavZone.upperFloor.surfaceY, -0.42)
            landingSpot = SIMD3<Float>(0.05, RoomNavZone.daybed.surfaceY, -0.55)
            
        case (.upperFloor, .desk):
            approachEdge = SIMD3<Float>(-0.45, RoomNavZone.upperFloor.surfaceY, -0.15)
            landingSpot = SIMD3<Float>(-0.58, RoomNavZone.desk.surfaceY, -0.15)
            
        case (.desk, .upperFloor):
            approachEdge = SIMD3<Float>(-0.58, RoomNavZone.desk.surfaceY, -0.15)
            landingSpot = SIMD3<Float>(-0.45, RoomNavZone.upperFloor.surfaceY, -0.15)
            
        case (.upperFloor, .lowerFloor):
            approachEdge = SIMD3<Float>(currentPos.x, RoomNavZone.upperFloor.surfaceY, 0.18)
            landingSpot = SIMD3<Float>(currentPos.x, RoomNavZone.lowerFloor.surfaceY, 0.25)
            
        case (.lowerFloor, .upperFloor):
            approachEdge = SIMD3<Float>(currentPos.x, RoomNavZone.lowerFloor.surfaceY, 0.25)
            landingSpot = SIMD3<Float>(currentPos.x, RoomNavZone.upperFloor.surfaceY, 0.18)
            
        default:
            // Route through upper floor platform as central hub
            let hubSpot = RoomNavZone.upperFloor.defaultSpot
            let success1 = await walkSegment(from: currentPos, to: hubSpot)
            if !success1 { return false }
            return await navigateTo(destination: safeDest)
        }
        
        // Step A: Walk to departure edge
        let reachedEdge = await walkSegment(from: currentPos, to: approachEdge)
        if !reachedEdge { return false }
        
        // Step B: Ballistic jump between surfaces
        await executeJump(from: approachEdge, to: landingSpot)
        self.currentZone = targetZone
        
        // Step C: Walk to final safe destination
        let finished = await walkSegment(from: landingSpot, to: safeDest)
        
        // Settle comfortably and persist
        entity.animationController?.playSettleReaction()
        CookieMemoryStore.shared.updatePosition(safeDest, rotationY: entity.rotationAngleY, zone: targetZone.rawValue)
        
        return finished
    }
    
    // MARK: - Walking & Locomotion
    
    private func walkSegment(from start: SIMD3<Float>, to end: SIMD3<Float>) async -> Bool {
        guard let entity = self.entity else { return false }
        
        let delta = end - start
        let distance = sqrt(delta.x * delta.x + delta.z * delta.z)
        if distance < 0.015 { return true }
        
        // 1. Orient Cookie smoothly toward destination
        let targetAngle = atan2(delta.x, delta.z)
        let targetRot = simd_quatf(angle: targetAngle, axis: [0, 1, 0])
        
        let turnSteps = 8
        let startRot = entity.orientation
        for step in 1...turnSteps {
            try? await Task.sleep(nanoseconds: 15_000_000)
            let t = Float(step) / Float(turnSteps)
            entity.orientation = simd_slerp(startRot, targetRot, t)
        }
        
        // 2. Walk forward with cute waddle and alternating paws
        entity.animationController?.startWalking()
        
        let speed: Float = 0.14 // meters per second (gentle cute waddle)
        let totalDuration = TimeInterval(distance / speed)
        let steps = max(Int(totalDuration * 40.0), 10)
        let dt = totalDuration / TimeInterval(steps)
        
        for step in 1...steps {
            try? await Task.sleep(nanoseconds: UInt64(dt * 1_000_000_000))
            let progress = Float(step) / Float(steps)
            
            let curX = start.x + delta.x * progress
            let curZ = start.z + delta.z * progress
            let curY = Self.surfaceHeight(at: curX, z: curZ)
            
            entity.position = [curX, curY, curZ]
        }
        
        entity.position = end
        entity.animationController?.stopWalking()
        return true
    }
    
    // MARK: - Physically Believable 5-Stage Jump
    
    /// Executes a 5-stage believable cat jump:
    /// 1. Crouch (anticipation/compression)
    /// 2. Push-off (spring extension)
    /// 3. Airborne parabolic arc
    /// 4. Landing squash
    /// 5. Recovery to resting posture
    public func executeJump(from start: SIMD3<Float>, to end: SIMD3<Float>) async {
        guard let entity = self.entity else { return }
        
        // Face jump direction
        let delta = end - start
        let jumpAngle = atan2(delta.x, delta.z)
        entity.orientation = simd_quatf(angle: jumpAngle, axis: [0, 1, 0])
        
        await entity.animationController?.playJumpSequence(from: start, to: end)
    }
    
    // MARK: - Specialized Destination Shortcuts
    
    public func goToBed() {
        Task { await navigateTo(destination: RoomNavZone.daybed.defaultSpot) }
    }
    
    public func goToDesk() {
        Task { await navigateTo(destination: RoomNavZone.desk.defaultSpot) }
    }
    
    public func goToWindow() {
        Task { await navigateTo(destination: RoomNavZone.windowLedge.defaultSpot) }
    }
    
    public func goToSunkenLounge() {
        Task { await navigateTo(destination: RoomNavZone.lowerFloor.defaultSpot) }
    }
}


