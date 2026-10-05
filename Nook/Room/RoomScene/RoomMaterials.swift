import RealityKit
import AppKit

/// Central registry of physically based materials (PBR) and procedural textures for the Nook diorama.
///
/// Strictly adheres to the Nook aesthetic:
/// - Warm ivory, cream, natural honey oak, muted sage, warm beige, soft terracotta, warm gray.
/// - Physically plausible roughness, specular, and metallic values.
/// - High-resolution procedural textures for screens, art, vinyl, and ceramics.
@MainActor
final class RoomMaterials {
    
    static let shared = RoomMaterials()
    
    // MARK: - Core Color Palette
    
    static let honeyWoodColor = NSColor(red: 0.88, green: 0.68, blue: 0.44, alpha: 1.0)
    static let honeyWoodDarkColor = NSColor(red: 0.78, green: 0.56, blue: 0.34, alpha: 1.0)
    static let ivoryWallColor = NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0)
    static let creamFabricColor = NSColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1.0)
    static let sageGreenColor = NSColor(red: 0.56, green: 0.64, blue: 0.53, alpha: 1.0)
    static let sageGreenDarkColor = NSColor(red: 0.46, green: 0.54, blue: 0.43, alpha: 1.0)
    static let terracottaColor = NSColor(red: 0.82, green: 0.50, blue: 0.38, alpha: 1.0)
    static let ceramicWhiteColor = NSColor(red: 0.95, green: 0.95, blue: 0.94, alpha: 1.0)
    static let warmGrayColor = NSColor(red: 0.76, green: 0.74, blue: 0.72, alpha: 1.0)
    static let foliageDeepGreen = NSColor(red: 0.32, green: 0.46, blue: 0.28, alpha: 1.0)
    static let foliageLightGreen = NSColor(red: 0.45, green: 0.58, blue: 0.38, alpha: 1.0)
    static let vinylBlackColor = NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
    static let aluminumSilverColor = NSColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1.0)
    static let brassGoldColor = NSColor(red: 0.86, green: 0.72, blue: 0.40, alpha: 1.0)
    static let daisyYellowColor = NSColor(red: 0.96, green: 0.82, blue: 0.28, alpha: 1.0)
    
    // MARK: - Cached PBR Materials
    
    private(set) var honeyOakWood: PhysicallyBasedMaterial
    private(set) var hardwoodPlankFloor: PhysicallyBasedMaterial
    private(set) var ivoryPlasterWall: PhysicallyBasedMaterial
    private(set) var creamLinenFabric: PhysicallyBasedMaterial
    private(set) var sageGreenFabric: PhysicallyBasedMaterial
    private(set) var whiteBoucleFabric: PhysicallyBasedMaterial
    private(set) var glazedWhiteCeramic: PhysicallyBasedMaterial
    private(set) var terracottaClay: PhysicallyBasedMaterial
    private(set) var brushedAluminum: PhysicallyBasedMaterial
    private(set) var warmBrass: PhysicallyBasedMaterial
    private(set) var foliageDeep: PhysicallyBasedMaterial
    private(set) var foliageLight: PhysicallyBasedMaterial
    private(set) var vinylRecord: PhysicallyBasedMaterial
    private(set) var windowGlass: PhysicallyBasedMaterial
    private(set) var daisyYellow: PhysicallyBasedMaterial
    private(set) var skateboardGrip: PhysicallyBasedMaterial
    
    // Screen and decorative texture materials
    private(set) var monitorScreenMaterial: PhysicallyBasedMaterial
    private(set) var laptopScreenMaterial: PhysicallyBasedMaterial
    private(set) var smileyMugMaterial: PhysicallyBasedMaterial
    private(set) var vinylLabelMaterial: PhysicallyBasedMaterial
    private(set) var botanicalArt1Material: PhysicallyBasedMaterial
    private(set) var botanicalArt2Material: PhysicallyBasedMaterial
    private(set) var openNotebookMaterial: PhysicallyBasedMaterial
    private(set) var pegboardPatternMaterial: PhysicallyBasedMaterial
    private(set) var rugBotanicalMaterial: PhysicallyBasedMaterial
    
    private init() {
        // 1. Honey Oak Wood (Furniture, Trim, Bed, Desk)
        var honeyOak = PhysicallyBasedMaterial()
        honeyOak.baseColor = .init(tint: Self.honeyWoodColor)
        honeyOak.roughness = .init(floatLiteral: 0.38)
        honeyOak.metallic = .init(floatLiteral: 0.0)
        honeyOak.specular = .init(floatLiteral: 0.35)
        self.honeyOakWood = honeyOak
        
        // 2. Hardwood Plank Floor (Multi-tier diorama base)
        var floor = PhysicallyBasedMaterial()
        floor.baseColor = .init(tint: Self.honeyWoodColor)
        floor.roughness = .init(floatLiteral: 0.32)
        floor.metallic = .init(floatLiteral: 0.0)
        floor.specular = .init(floatLiteral: 0.40)
        self.hardwoodPlankFloor = floor
        
        // 3. Ivory Plaster Wall (Back & Left walls)
        var wall = PhysicallyBasedMaterial()
        wall.baseColor = .init(tint: Self.ivoryWallColor)
        wall.roughness = .init(floatLiteral: 0.88)
        wall.metallic = .init(floatLiteral: 0.0)
        wall.specular = .init(floatLiteral: 0.15)
        self.ivoryPlasterWall = wall
        
        // 4. Cream Linen Fabric (Duvet, Pillows, Curtains)
        var linen = PhysicallyBasedMaterial()
        linen.baseColor = .init(tint: Self.creamFabricColor)
        linen.roughness = .init(floatLiteral: 0.75)
        linen.metallic = .init(floatLiteral: 0.0)
        linen.specular = .init(floatLiteral: 0.2)
        self.creamLinenFabric = linen
        
        // 5. Sage Green Fabric (Throw blanket, bench cushion, sage pillow)
        var sage = PhysicallyBasedMaterial()
        sage.baseColor = .init(tint: Self.sageGreenColor)
        sage.roughness = .init(floatLiteral: 0.70)
        sage.metallic = .init(floatLiteral: 0.0)
        sage.specular = .init(floatLiteral: 0.2)
        self.sageGreenFabric = sage
        
        // 6. White Boucle Fabric (Floor pouf / beanbag)
        var boucle = PhysicallyBasedMaterial()
        boucle.baseColor = .init(tint: Self.creamFabricColor)
        boucle.roughness = .init(floatLiteral: 0.82)
        boucle.metallic = .init(floatLiteral: 0.0)
        boucle.specular = .init(floatLiteral: 0.18)
        self.whiteBoucleFabric = boucle
        
        // 7. Glazed White Ceramic (Mugs, Pots, Figurines)
        var ceramic = PhysicallyBasedMaterial()
        ceramic.baseColor = .init(tint: Self.ceramicWhiteColor)
        ceramic.roughness = .init(floatLiteral: 0.12)
        ceramic.metallic = .init(floatLiteral: 0.0)
        ceramic.specular = .init(floatLiteral: 0.6)
        self.glazedWhiteCeramic = ceramic
        
        // 8. Terracotta Clay (Pots, book covers)
        var terra = PhysicallyBasedMaterial()
        terra.baseColor = .init(tint: Self.terracottaColor)
        terra.roughness = .init(floatLiteral: 0.75)
        terra.metallic = .init(floatLiteral: 0.0)
        self.terracottaClay = terra
        
        // 9. Brushed Aluminum (Laptop, Monitor stand, Lamp stem)
        var alum = PhysicallyBasedMaterial()
        alum.baseColor = .init(tint: Self.aluminumSilverColor)
        alum.roughness = .init(floatLiteral: 0.25)
        alum.metallic = .init(floatLiteral: 0.85)
        alum.specular = .init(floatLiteral: 0.5)
        self.brushedAluminum = alum
        
        // 10. Warm Brass (Alarm clock, wall sconce bracket, tonearm)
        var brass = PhysicallyBasedMaterial()
        brass.baseColor = .init(tint: Self.brassGoldColor)
        brass.roughness = .init(floatLiteral: 0.28)
        brass.metallic = .init(floatLiteral: 0.75)
        brass.specular = .init(floatLiteral: 0.6)
        self.warmBrass = brass
        
        // 11. Foliage Deep & Light (Monstera, Ivy, Succulents)
        var folDeep = PhysicallyBasedMaterial()
        folDeep.baseColor = .init(tint: Self.foliageDeepGreen)
        folDeep.roughness = .init(floatLiteral: 0.42)
        folDeep.metallic = .init(floatLiteral: 0.0)
        folDeep.specular = .init(floatLiteral: 0.3)
        self.foliageDeep = folDeep
        
        var folLight = PhysicallyBasedMaterial()
        folLight.baseColor = .init(tint: Self.foliageLightGreen)
        folLight.roughness = .init(floatLiteral: 0.45)
        folLight.metallic = .init(floatLiteral: 0.0)
        folLight.specular = .init(floatLiteral: 0.28)
        self.foliageLight = folLight
        
        // 12. Vinyl Record
        var vinyl = PhysicallyBasedMaterial()
        vinyl.baseColor = .init(tint: Self.vinylBlackColor)
        vinyl.roughness = .init(floatLiteral: 0.22)
        vinyl.metallic = .init(floatLiteral: 0.1)
        vinyl.specular = .init(floatLiteral: 0.5)
        self.vinylRecord = vinyl
        
        // 13. Window Glass
        var glass = PhysicallyBasedMaterial()
        glass.baseColor = .init(tint: NSColor(white: 0.98, alpha: 0.25))
        glass.roughness = .init(floatLiteral: 0.05)
        glass.metallic = .init(floatLiteral: 0.0)
        glass.specular = .init(floatLiteral: 0.9)
        glass.blending = .transparent(opacity: .init(floatLiteral: 0.25))
        self.windowGlass = glass
        
        // 14. Daisy Center Yellow
        var daisy = PhysicallyBasedMaterial()
        daisy.baseColor = .init(tint: Self.daisyYellowColor)
        daisy.roughness = .init(floatLiteral: 0.65)
        daisy.metallic = .init(floatLiteral: 0.0)
        self.daisyYellow = daisy
        
        // 15. Skateboard Grip Tape
        var grip = PhysicallyBasedMaterial()
        grip.baseColor = .init(tint: NSColor(white: 0.18, alpha: 1.0))
        grip.roughness = .init(floatLiteral: 0.95)
        grip.metallic = .init(floatLiteral: 0.0)
        self.skateboardGrip = grip
        
        // 16. Procedural Textures & Materials
        self.monitorScreenMaterial = Self.makeMonitorScreenMaterial()
        self.laptopScreenMaterial = Self.makeLaptopScreenMaterial()
        self.smileyMugMaterial = Self.makeSmileyMugMaterial()
        self.vinylLabelMaterial = Self.makeVinylLabelMaterial()
        self.botanicalArt1Material = Self.makeBotanicalArt1Material()
        self.botanicalArt2Material = Self.makeBotanicalArt2Material()
        self.openNotebookMaterial = Self.makeOpenNotebookMaterial()
        self.pegboardPatternMaterial = Self.makePegboardMaterial()
        self.rugBotanicalMaterial = Self.makeRugBotanicalMaterial()
    }
    
    // MARK: - Procedural Texture Generators
    
    private static func makeMonitorScreenMaterial() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let width = 512
        let height = 320
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Warm cream backdrop
        NSColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        // Subtle soft green rolling hills in bottom third
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 0))
        path.line(to: NSPoint(x: 0, y: 80))
        path.curve(to: NSPoint(x: 256, y: 95), controlPoint1: NSPoint(x: 100, y: 110), controlPoint2: NSPoint(x: 180, y: 65))
        path.curve(to: NSPoint(x: 512, y: 70), controlPoint1: NSPoint(x: 350, y: 120), controlPoint2: NSPoint(x: 440, y: 85))
        path.line(to: NSPoint(x: 512, y: 0))
        path.close()
        NSColor(red: 0.72, green: 0.78, blue: 0.68, alpha: 0.85).setFill()
        path.fill()
        
        let path2 = NSBezierPath()
        path2.move(to: NSPoint(x: 0, y: 0))
        path2.line(to: NSPoint(x: 0, y: 45))
        path2.curve(to: NSPoint(x: 320, y: 55), controlPoint1: NSPoint(x: 120, y: 35), controlPoint2: NSPoint(x: 220, y: 65))
        path2.curve(to: NSPoint(x: 512, y: 30), controlPoint1: NSPoint(x: 400, y: 45), controlPoint2: NSPoint(x: 470, y: 35))
        path2.line(to: NSPoint(x: 512, y: 0))
        path2.close()
        NSColor(red: 0.58, green: 0.66, blue: 0.54, alpha: 0.95).setFill()
        path2.fill()
        
        // "hello ♡" warm handwritten typography
        let text = "hello ♡"
        let font = NSFont(name: "Snell Roundhand", size: 68) ?? NSFont.systemFont(ofSize: 58, weight: .light)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 0.28, green: 0.26, blue: 0.24, alpha: 0.92)
        ]
        let str = NSAttributedString(string: text, attributes: attrs)
        let textSize = str.size()
        str.draw(at: NSPoint(x: (CGFloat(width) - textSize.width) / 2, y: (CGFloat(height) - textSize.height) / 2 + 25))
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
            mat.emissiveColor = .init(texture: .init(tex))
            mat.emissiveIntensity = 0.85
        } else {
            mat.baseColor = .init(tint: NSColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1.0))
        }
        mat.roughness = .init(floatLiteral: 0.2)
        return mat
    }
    
    private static func makeLaptopScreenMaterial() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let width = 256
        let height = 160
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Calming green nature gradient
        let gradient = NSGradient(
            colors: [
                NSColor(red: 0.82, green: 0.88, blue: 0.80, alpha: 1.0),
                NSColor(red: 0.45, green: 0.58, blue: 0.42, alpha: 1.0)
            ]
        )
        gradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
            mat.emissiveColor = .init(texture: .init(tex))
            mat.emissiveIntensity = 0.75
        } else {
            mat.baseColor = .init(tint: NSColor(red: 0.52, green: 0.65, blue: 0.48, alpha: 1.0))
        }
        mat.roughness = .init(floatLiteral: 0.25)
        return mat
    }
    
    private static func makeSmileyMugMaterial() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let width = 256
        let height = 256
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Cream ceramic base
        NSColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        // Cute smiling face (two eyes and an arc smile)
        NSColor(red: 0.20, green: 0.18, blue: 0.18, alpha: 0.95).setFill()
        // Left eye
        NSRect(x: 95, y: 145, width: 14, height: 18).fill()
        // Right eye
        NSRect(x: 147, y: 145, width: 14, height: 18).fill()
        
        // Smiling mouth
        let smile = NSBezierPath()
        smile.appendArc(withCenter: NSPoint(x: 128, y: 125), radius: 24, startAngle: 200, endAngle: 340, clockwise: true)
        smile.lineWidth = 6
        NSColor(red: 0.20, green: 0.18, blue: 0.18, alpha: 0.95).setStroke()
        smile.stroke()
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
        } else {
            mat.baseColor = .init(tint: Self.ceramicWhiteColor)
        }
        mat.roughness = .init(floatLiteral: 0.15)
        mat.specular = .init(floatLiteral: 0.6)
        return mat
    }
    
    private static func makeVinylLabelMaterial() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let size = 256
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Red / Terracotta circular label
        NSColor(red: 0.85, green: 0.32, blue: 0.28, alpha: 1.0).setFill()
        let circle = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
        circle.fill()
        
        // Concentric rings
        NSColor(red: 0.96, green: 0.92, blue: 0.86, alpha: 0.8).setStroke()
        let inner1 = NSBezierPath(ovalIn: NSRect(x: 25, y: 25, width: size - 50, height: size - 50))
        inner1.lineWidth = 3
        inner1.stroke()
        
        // Center spindle hole
        NSColor.black.setFill()
        NSBezierPath(ovalIn: NSRect(x: 112, y: 112, width: 32, height: 32)).fill()
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
        } else {
            mat.baseColor = .init(tint: NSColor(red: 0.85, green: 0.32, blue: 0.28, alpha: 1.0))
        }
        mat.roughness = .init(floatLiteral: 0.35)
        return mat
    }
    
    private static func makeBotanicalArt1Material() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let width = 256
        let height = 340
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Warm ivory parchment
        NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        // Minimalist botanical stem and leaves
        NSColor(red: 0.42, green: 0.52, blue: 0.40, alpha: 0.9).setStroke()
        NSColor(red: 0.42, green: 0.52, blue: 0.40, alpha: 0.9).setFill()
        
        let stem = NSBezierPath()
        stem.move(to: NSPoint(x: 128, y: 40))
        stem.curve(to: NSPoint(x: 135, y: 280), controlPoint1: NSPoint(x: 120, y: 140), controlPoint2: NSPoint(x: 140, y: 220))
        stem.lineWidth = 5
        stem.stroke()
        
        // Leaf pairs
        for y in stride(from: 80, to: 250, by: 40) {
            let leftLeaf = NSBezierPath(ovalIn: NSRect(x: 95, y: CGFloat(y), width: 30, height: 16))
            leftLeaf.fill()
            let rightLeaf = NSBezierPath(ovalIn: NSRect(x: 135, y: CGFloat(y) + 10, width: 30, height: 16))
            rightLeaf.fill()
        }
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
        } else {
            mat.baseColor = .init(tint: Self.ivoryWallColor)
        }
        mat.roughness = .init(floatLiteral: 0.6)
        return mat
    }
    
    private static func makeBotanicalArt2Material() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let width = 256
        let height = 340
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Soft warm beige
        NSColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        // Terracotta sun and sage monstera leaf
        NSColor(red: 0.85, green: 0.56, blue: 0.42, alpha: 0.85).setFill()
        NSBezierPath(ovalIn: NSRect(x: 78, y: 160, width: 100, height: 100)).fill()
        
        NSColor(red: 0.38, green: 0.48, blue: 0.38, alpha: 0.9).setFill()
        let monstera = NSBezierPath(ovalIn: NSRect(x: 90, y: 70, width: 76, height: 110))
        monstera.fill()
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
        } else {
            mat.baseColor = .init(tint: Self.ivoryWallColor)
        }
        mat.roughness = .init(floatLiteral: 0.6)
        return mat
    }
    
    private static func makeOpenNotebookMaterial() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let width = 256
        let height = 180
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Cream notebook paper
        NSColor(red: 0.97, green: 0.96, blue: 0.92, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        // Subtle faint ruled lines
        NSColor(red: 0.85, green: 0.83, blue: 0.80, alpha: 0.7).setStroke()
        for y in stride(from: 25, to: 165, by: 15) {
            let line = NSBezierPath()
            line.move(to: NSPoint(x: 15, y: CGFloat(y)))
            line.line(to: NSPoint(x: 115, y: CGFloat(y)))
            line.lineWidth = 1.5
            line.stroke()
            
            let line2 = NSBezierPath()
            line2.move(to: NSPoint(x: 140, y: CGFloat(y)))
            line2.line(to: NSPoint(x: 240, y: CGFloat(y)))
            line2.lineWidth = 1.5
            line2.stroke()
        }
        
        // Center spine shadow
        NSColor(red: 0.75, green: 0.72, blue: 0.68, alpha: 0.5).setFill()
        NSRect(x: 124, y: 0, width: 8, height: height).fill()
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
        } else {
            mat.baseColor = .init(tint: Self.creamFabricColor)
        }
        mat.roughness = .init(floatLiteral: 0.7)
        return mat
    }
    
    private static func makePegboardMaterial() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let size = 256
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        
        // Light natural wood pegboard background
        NSColor(red: 0.92, green: 0.86, blue: 0.78, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: size, height: size).fill()
        
        // Grid of dark peg holes
        NSColor(red: 0.45, green: 0.38, blue: 0.30, alpha: 0.85).setFill()
        for x in stride(from: 16, to: size - 8, by: 32) {
            for y in stride(from: 16, to: size - 8, by: 32) {
                let dot = NSBezierPath(ovalIn: NSRect(x: CGFloat(x) - 3, y: CGFloat(y) - 3, width: 6, height: 6))
                dot.fill()
            }
        }
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
        } else {
            mat.baseColor = .init(tint: Self.honeyWoodColor)
        }
        mat.roughness = .init(floatLiteral: 0.6)
        return mat
    }
    
    private static func makeRugBotanicalMaterial() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let width = 256
        let height = 384
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Cream woven wool base
        NSColor(red: 0.94, green: 0.93, blue: 0.88, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        // Minimalist botanical branch illustration
        NSColor(red: 0.70, green: 0.76, blue: 0.68, alpha: 0.7).setFill()
        NSColor(red: 0.70, green: 0.76, blue: 0.68, alpha: 0.7).setStroke()
        
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 40, y: 40))
        path.curve(to: NSPoint(x: 210, y: 340), controlPoint1: NSPoint(x: 180, y: 140), controlPoint2: NSPoint(x: 80, y: 240))
        path.lineWidth = 4
        path.stroke()
        
        for y in stride(from: 80, to: 310, by: 50) {
            let oval = NSBezierPath(ovalIn: NSRect(x: 110 + (y % 40) - 20, y: y, width: 28, height: 16))
            oval.fill()
        }
        
        image.unlockFocus()
        
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let tex = try? TextureResource(image: cg, options: .init(semantic: .color)) {
            mat.baseColor = .init(texture: .init(tex))
        } else {
            mat.baseColor = .init(tint: Self.creamFabricColor)
        }
        mat.roughness = .init(floatLiteral: 0.85)
        return mat
    }
}
