import Foundation
import Spatial

/// Defines intelligent physical placement surfaces and zones within the miniature room diorama.
///
/// Ensures thoughts, ideas, quotes, notes, and photos are placed naturally on real room surfaces
/// (desk, bookshelf, pegboard, nightstand, vinyl bench) without stacking or overlapping.
enum PlacementZone: String, CaseIterable, Identifiable, Codable, Sendable {
    case deskCenter = "Desk Center"
    case deskLeft = "Desk Left (Writing Area)"
    case deskRight = "Desk Right (Drawer Area)"
    case bookshelfUpper = "Upper Desk Shelf"
    case bookshelfMain = "Built-in Bookshelf"
    case wallPegboard = "Wall Pegboard (Bulletin)"
    case nightstand = "Bedside Table"
    case recordBench = "Vinyl Bench"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .deskCenter, .deskLeft, .deskRight:
            return "desk"
        case .bookshelfUpper, .bookshelfMain:
            return "books.vertical"
        case .wallPegboard:
            return "pin.fill"
        case .nightstand:
            return "bed.double"
        case .recordBench:
            return "opticaldisc"
        }
    }
    
    var basePosition: RoomPosition {
        let (center, _, _, _) = surfaceDescriptor
        return ThoughtEntityBuilder.roomPosition(from: center)
    }
    
    var naturalPosition: RoomPosition {
        naturalPosition(existingCount: 0)
    }
    
    func naturalPosition(existingCount: Int) -> RoomPosition {
        let (center, spanX, spanZ, _) = surfaceDescriptor
        let offset = Float(existingCount % 5) * 0.03
        let jitterX = Float.random(in: -spanX * 0.25...spanX * 0.25) + offset * 0.2
        let jitterZ = Float.random(in: -spanZ * 0.25...spanZ * 0.25)
        return ThoughtEntityBuilder.roomPosition(from: SIMD3<Float>(center.x + jitterX, center.y, center.z + jitterZ))
    }
    
    /// The default placement zone for a given thought type.
    static func defaultZone(for itemType: NookItemType, objectType: NookObjectType) -> PlacementZone {
        // Sticky notes and polaroids naturally pin to the wall pegboard
        if objectType == .stickyNote || objectType == .polaroid {
            return .wallPegboard
        }
        
        switch itemType {
        case .thought:
            return .deskCenter
        case .idea:
            return .deskLeft
        case .note:
            return .deskRight
        case .reminder:
            return .wallPegboard
        case .quote:
            return .bookshelfMain
        case .link:
            return .bookshelfUpper
        case .photo:
            return .wallPegboard
        }
    }
    
    /// World anchor position and surface dimensions [originX, originY, originZ, spanX, spanZ]
    var surfaceDescriptor: (center: SIMD3<Float>, spanX: Float, spanZ: Float, isWallMounted: Bool) {
        let upperFloorY: Float = 0.28
        let deskHeight: Float = 0.44
        let deskSurfaceY = upperFloorY + deskHeight + 0.015 // ~0.735m
        
        switch self {
        case .deskCenter:
            return (SIMD3<Float>(-0.70, deskSurfaceY, -0.56), 0.24, 0.18, false)
        case .deskLeft:
            return (SIMD3<Float>(-0.92, deskSurfaceY, -0.52), 0.18, 0.22, false)
        case .deskRight:
            return (SIMD3<Float>(-0.48, deskSurfaceY, -0.58), 0.18, 0.20, false)
        case .bookshelfUpper:
            // Shelf running above desk on left wall
            return (SIMD3<Float>(-1.04, upperFloorY + deskHeight + 0.60 + 0.015, -0.32), 0.14, 0.45, false)
        case .bookshelfMain:
            // Tall bookcase on back wall between desk and bed
            return (SIMD3<Float>(-0.22, upperFloorY + 0.72 + 0.015, -1.04), 0.38, 0.14, false)
        case .wallPegboard:
            // Pinned vertically on the left wall pegboard
            return (SIMD3<Float>(-1.14, upperFloorY + deskHeight + 0.32, -0.32), 0.02, 0.40, true)
        case .nightstand:
            // Nightstand table beside the daybed
            return (SIMD3<Float>(-0.265, upperFloorY + 0.26 + 0.015, -1.03), 0.16, 0.16, false)
        case .recordBench:
            // Sage green upholstered listening bench
            return (SIMD3<Float>(0.78, upperFloorY + 0.22 + 0.02, -0.18), 0.26, 0.38, false)
        }
    }
    
    /// Nearby fallback zones to check if this surface becomes crowded.
    var fallbackZones: [PlacementZone] {
        switch self {
        case .deskCenter:
            return [.deskRight, .deskLeft, .bookshelfUpper, .nightstand]
        case .deskLeft:
            return [.deskCenter, .deskRight, .bookshelfUpper]
        case .deskRight:
            return [.deskCenter, .deskLeft, .nightstand, .recordBench]
        case .bookshelfUpper:
            return [.bookshelfMain, .deskLeft, .deskCenter]
        case .bookshelfMain:
            return [.bookshelfUpper, .nightstand, .deskRight]
        case .wallPegboard:
            return [.bookshelfUpper, .deskCenter, .bookshelfMain]
        case .nightstand:
            return [.recordBench, .deskRight, .bookshelfMain]
        case .recordBench:
            return [.nightstand, .deskRight, .bookshelfUpper]
        }
    }
    
    /// Generates a natural 3D world position with collision clearance against existing items.
    /// If this surface becomes crowded, intelligently finds an uncrowded nearby surface.
    func allocateNaturalPosition(existingWorldPositions: [SIMD3<Float>]) -> SIMD3<Float> {
        return allocateNaturalPositionInternal(existingWorldPositions: existingWorldPositions, allowFallback: true)
    }
    
    private func allocateNaturalPositionInternal(existingWorldPositions: [SIMD3<Float>], allowFallback: Bool) -> SIMD3<Float> {
        let (center, spanX, spanZ, isWall) = surfaceDescriptor
        let minClearance: Float = 0.09 // 9cm minimum separation between objects
        
        // Define discrete slot candidates on this surface
        var candidates: [SIMD3<Float>] = []
        let stepsX = isWall ? 1 : 4
        let stepsZ = 4
        
        for ix in 0..<stepsX {
            let fracX = stepsX > 1 ? (Float(ix) / Float(stepsX - 1) - 0.5) : 0.0
            for iz in 0..<stepsZ {
                let fracZ = stepsZ > 1 ? (Float(iz) / Float(stepsZ - 1) - 0.5) : 0.0
                
                let posX = center.x + fracX * spanX
                let posZ = center.z + fracZ * spanZ
                let posY = isWall ? (center.y + fracZ * 0.15) : center.y
                
                candidates.append(SIMD3<Float>(posX, posY, posZ))
            }
        }
        
        // Find candidate with maximum distance from any existing object
        var bestCandidate = center
        var maxMinDist: Float = -1.0
        
        for candidate in candidates {
            var nearestDist: Float = Float.greatestFiniteMagnitude
            for existing in existingWorldPositions {
                let d = simd_distance(candidate, existing)
                if d < nearestDist {
                    nearestDist = d
                }
            }
            
            // If completely uncrowded, pick the first slot with good clearance
            if nearestDist >= minClearance {
                // Add subtle organic jitter so items don't look computer-grid aligned
                let jitterX = Float.random(in: -0.018...0.018)
                let jitterZ = Float.random(in: -0.018...0.018)
                return SIMD3<Float>(candidate.x + jitterX, candidate.y, candidate.z + jitterZ)
            }
            
            if nearestDist > maxMinDist {
                maxMinDist = nearestDist
                bestCandidate = candidate
            }
        }
        
        // If crowded and fallback is allowed, seek an uncrowded nearby surface
        if allowFallback && maxMinDist < minClearance {
            for fallback in fallbackZones {
                let fallbackPos = fallback.allocateNaturalPositionInternal(existingWorldPositions: existingWorldPositions, allowFallback: false)
                // Check if the fallback position has acceptable clearance
                let minFallbackDist = existingWorldPositions.map { simd_distance(fallbackPos, $0) }.min() ?? Float.greatestFiniteMagnitude
                if minFallbackDist >= minClearance {
                    return fallbackPos
                }
            }
        }
        
        // Add subtle organic jitter
        let jitterX = Float.random(in: -0.015...0.015)
        let jitterZ = Float.random(in: -0.015...0.015)
        return SIMD3<Float>(bestCandidate.x + jitterX, bestCandidate.y, bestCandidate.z + jitterZ)
    }
}
