import RealityKit
import Foundation
import simd

/// Helper utility for creating specialized procedural 3D meshes for Nook.
///
/// Provides geometry for cushions, daisy pillows, folded blankets,
/// drapery folds, plant leaves, and turntable components.
enum ProceduralMeshGenerator {
    
    // MARK: - Pillow Mesh (Plump curved cushion with rounded edges)
    
    static func generatePillowMesh(width: Float, height: Float, depth: Float, subdivisions: Int = 12) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let cols = subdivisions
        let rows = subdivisions
        
        // Generate top surface (puffed up in the center)
        for r in 0...rows {
            let v = Float(r) / Float(rows)
            let z = (v - 0.5) * depth
            let factorZ = cos((v - 0.5) * Float.pi)
            
            for c in 0...cols {
                let u = Float(c) / Float(cols)
                let x = (u - 0.5) * width
                let factorX = cos((u - 0.5) * Float.pi)
                
                // Puffed curve
                let y = height * 0.5 * factorX * factorZ
                
                positions.append(SIMD3<Float>(x, y, z))
                // Approximate normal
                let normal = simd_normalize(SIMD3<Float>(x * 0.3, 1.0, z * 0.3))
                normals.append(normal)
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        // Generate bottom surface (puffed down in the center)
        let bottomOffset = UInt32(positions.count)
        for r in 0...rows {
            let v = Float(r) / Float(rows)
            let z = (v - 0.5) * depth
            let factorZ = cos((v - 0.5) * Float.pi)
            
            for c in 0...cols {
                let u = Float(c) / Float(cols)
                let x = (u - 0.5) * width
                let factorX = cos((u - 0.5) * Float.pi)
                
                let y = -height * 0.5 * factorX * factorZ
                
                positions.append(SIMD3<Float>(x, y, z))
                let normal = simd_normalize(SIMD3<Float>(x * 0.3, -1.0, z * 0.3))
                normals.append(normal)
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        // Triangulate top surface
        for r in 0..<rows {
            for c in 0..<cols {
                let p0 = UInt32(r * (cols + 1) + c)
                let p1 = p0 + 1
                let p2 = p0 + UInt32(cols + 1)
                let p3 = p2 + 1
                
                indices.append(contentsOf: [p0, p1, p2, p1, p3, p2])
            }
        }
        
        // Triangulate bottom surface (flipped winding)
        for r in 0..<rows {
            for c in 0..<cols {
                let p0 = bottomOffset + UInt32(r * (cols + 1) + c)
                let p1 = p0 + 1
                let p2 = p0 + UInt32(cols + 1)
                let p3 = p2 + 1
                
                indices.append(contentsOf: [p0, p2, p1, p1, p2, p3])
            }
        }
        
        // Stitch the edges together
        for c in 0..<cols {
            // Front edge (r = 0)
            let t0 = UInt32(c)
            let t1 = t0 + 1
            let b0 = bottomOffset + UInt32(c)
            let b1 = b0 + 1
            indices.append(contentsOf: [t0, b0, t1, t1, b0, b1])
            
            // Back edge (r = rows)
            let t2 = UInt32(rows * (cols + 1) + c)
            let t3 = t2 + 1
            let b2 = bottomOffset + UInt32(rows * (cols + 1) + c)
            let b3 = b2 + 1
            indices.append(contentsOf: [t2, t3, b2, t3, b3, b2])
        }
        
        for r in 0..<rows {
            // Left edge (c = 0)
            let t0 = UInt32(r * (cols + 1))
            let t1 = UInt32((r + 1) * (cols + 1))
            let b0 = bottomOffset + t0
            let b1 = bottomOffset + t1
            indices.append(contentsOf: [t0, t1, b0, t1, b1, b0])
            
            // Right edge (c = cols)
            let t2 = UInt32(r * (cols + 1) + cols)
            let t3 = UInt32((r + 1) * (cols + 1) + cols)
            let b2 = bottomOffset + t2
            let b3 = bottomOffset + t3
            indices.append(contentsOf: [t2, b2, t3, t3, b2, b3])
        }
        
        var desc = MeshDescriptor(name: "pillow")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        desc.primitives = .triangles(indices)
        
        if let mesh = try? MeshResource.generate(from: [desc]) {
            return mesh
        }
        return .generateBox(size: [width, height, depth], cornerRadius: 0.04)
    }
    
    // MARK: - Folded Blanket Mesh (Organic wavy folds across bed)
    
    static func generateBlanketMesh(width: Float, depth: Float, drapeY: Float = 0.18) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let cols = 14
        let rows = 14
        
        for r in 0...rows {
            let v = Float(r) / Float(rows)
            let z = (v - 0.5) * depth
            
            for c in 0...cols {
                let u = Float(c) / Float(cols)
                let x = (u - 0.5) * width
                
                // Subtle organic ripple waves
                let wave1 = sin(u * Float.pi * 3.0) * 0.012
                let wave2 = cos(v * Float.pi * 2.5) * 0.008
                
                // Side drape downward on outer edge (u > 0.8)
                var y = wave1 + wave2
                if u > 0.8 {
                    let drapeFactor = (u - 0.8) / 0.2
                    y -= drapeFactor * drapeFactor * drapeY
                }
                // Front drape (v > 0.8)
                if v > 0.8 {
                    let drapeFactor = (v - 0.8) / 0.2
                    y -= drapeFactor * drapeFactor * (drapeY * 0.8)
                }
                
                positions.append(SIMD3<Float>(x, y, z))
                normals.append(SIMD3<Float>(0, 1, 0))
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        for r in 0..<rows {
            for c in 0..<cols {
                let p0 = UInt32(r * (cols + 1) + c)
                let p1 = p0 + 1
                let p2 = p0 + UInt32(cols + 1)
                let p3 = p2 + 1
                
                // Double-sided faces for cloth
                indices.append(contentsOf: [p0, p1, p2, p1, p3, p2])
                indices.append(contentsOf: [p0, p2, p1, p1, p2, p3])
            }
        }
        
        var desc = MeshDescriptor(name: "blanket")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        desc.primitives = .triangles(indices)
        
        if let mesh = try? MeshResource.generate(from: [desc]) {
            return mesh
        }
        return .generatePlane(width: width, depth: depth, cornerRadius: 0.02)
    }
    
    // MARK: - Drapery Curtains (Vertical undulating linen folds)
    
    static func generateCurtainMesh(width: Float, height: Float, folds: Int = 4) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        
        let cols = folds * 4
        let rows = 10
        
        for r in 0...rows {
            let v = Float(r) / Float(rows)
            let y = -v * height
            
            for c in 0...cols {
                let u = Float(c) / Float(cols)
                let x = (u - 0.5) * width
                
                // Undulating sinusoidal curtain fold depth
                let z = sin(u * Float(folds) * Float.pi * 2.0) * 0.035 * (0.8 + 0.2 * (1.0 - v))
                
                positions.append(SIMD3<Float>(x, y, z))
                let nx = -cos(u * Float(folds) * Float.pi * 2.0) * 0.4
                normals.append(simd_normalize(SIMD3<Float>(nx, 0, 1)))
                uvs.append(SIMD2<Float>(u, v))
            }
        }
        
        for r in 0..<rows {
            for c in 0..<cols {
                let p0 = UInt32(r * (cols + 1) + c)
                let p1 = p0 + 1
                let p2 = p0 + UInt32(cols + 1)
                let p3 = p2 + 1
                
                indices.append(contentsOf: [p0, p1, p2, p1, p3, p2])
                indices.append(contentsOf: [p0, p2, p1, p1, p2, p3])
            }
        }
        
        var desc = MeshDescriptor(name: "curtain")
        desc.positions = MeshBuffers.Positions(positions)
        desc.normals = MeshBuffers.Normals(normals)
        desc.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        desc.primitives = .triangles(indices)
        
        if let mesh = try? MeshResource.generate(from: [desc]) {
            return mesh
        }
        return .generatePlane(width: width, depth: height, cornerRadius: 0.01)
    }
}
