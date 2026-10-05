/**
 * Nook 3D - MaterialSystem
 * Centralized, physically based PBR materials library.
 * Creates the exact material palette required for the warm, handcrafted miniature look:
 * - Wood_Warm, Wood_Light, Wood_Dark
 * - Wall_Cream
 * - Fabric_Cream, Fabric_Sage, Fabric_Boucle
 * - Metal_Warm
 * - Ceramic_Cream
 * - Glass_Warm
 * - Paper
 * - Plant_Green (with natural variations)
 * - Vinyl_Black
 */

import * as THREE from 'three';
import { TextureGenerator } from '../utils/TextureGenerator.js';
import { PALETTE } from '../utils/Constants.js';

export class MaterialSystem {
  static materials = null;

  static getMaterials() {
    if (!this.materials) {
      this.materials = this.buildAllMaterials();
    }
    return this.materials;
  }

  static buildAllMaterials() {
    // 1. Generate procedural PBR maps
    const woodColorMap = TextureGenerator.createHoneyWoodTexture(1024, 1024);
    const floorPlanksColorMap = TextureGenerator.createFloorPlanksTexture(1024, 1024, 12);
    const wallColorMap = TextureGenerator.createWallCreamTexture(512, 512);
    const blanketColorMap = TextureGenerator.createBlanketTexture(512, 512);
    const vinylColorMap = TextureGenerator.createVinylTexture(512, 512);

    const woodNormalMap = TextureGenerator.createWoodNormalMap(512, 512);
    const woodRoughnessMap = TextureGenerator.createWoodRoughnessMap(512, 512);
    const fabricNormalMap = TextureGenerator.createFabricNormalMap(512, 512);
    const boucleNormalMap = TextureGenerator.createBoucleNormalMap(512, 512);
    const plasterNormalMap = TextureGenerator.createPlasterNormalMap(512, 512);

    // Repeat settings for repeating architectural surfaces
    floorPlanksColorMap.repeat.set(3, 3);
    wallColorMap.repeat.set(4, 4);
    plasterNormalMap.repeat.set(4, 4);
    woodColorMap.repeat.set(2, 2);
    woodNormalMap.repeat.set(2, 2);
    woodRoughnessMap.repeat.set(2, 2);

    const materials = {
      // 1. Wood_Warm (Standard honey oak)
      Wood_Warm: new THREE.MeshStandardMaterial({
        color: 0xffffff,
        map: woodColorMap,
        normalMap: woodNormalMap,
        normalScale: new THREE.Vector2(0.45, 0.45),
        roughnessMap: woodRoughnessMap,
        roughness: 0.52,
        metalness: 0.02
      }),

      // 2. Wood_Light (Blonde Scandinavian honey oak for desktop, desk trims, platform accents)
      Wood_Light: new THREE.MeshStandardMaterial({
        color: 0xfff3e3,
        map: woodColorMap,
        normalMap: woodNormalMap,
        normalScale: new THREE.Vector2(0.35, 0.35),
        roughnessMap: woodRoughnessMap,
        roughness: 0.48,
        metalness: 0.01
      }),

      // 3. Wood_Dark (Richer caramel oak for heavy upper beams, base plinth, legs, curtain rod)
      Wood_Dark: new THREE.MeshStandardMaterial({
        color: 0xead3ba,
        map: woodColorMap,
        normalMap: woodNormalMap,
        normalScale: new THREE.Vector2(0.65, 0.65),
        roughnessMap: woodRoughnessMap,
        roughness: 0.54,
        metalness: 0.03
      }),

      // Dedicated Furniture Wood Variations:
      Wood_Floor: new THREE.MeshStandardMaterial({
        color: 0xffffff,
        map: floorPlanksColorMap,
        normalMap: woodNormalMap,
        normalScale: new THREE.Vector2(0.55, 0.55),
        roughnessMap: woodRoughnessMap,
        roughness: 0.50,
        metalness: 0.02
      }),

      Wood_Desk: new THREE.MeshStandardMaterial({
        color: 0xfef5e7,
        map: woodColorMap,
        normalMap: woodNormalMap,
        normalScale: new THREE.Vector2(0.38, 0.38),
        roughnessMap: woodRoughnessMap,
        roughness: 0.46,
        metalness: 0.01
      }),

      Wood_Bed: new THREE.MeshStandardMaterial({
        color: 0xfff0dc,
        map: woodColorMap,
        normalMap: woodNormalMap,
        normalScale: new THREE.Vector2(0.42, 0.42),
        roughnessMap: woodRoughnessMap,
        roughness: 0.52,
        metalness: 0.02
      }),

      Wood_Shelves: new THREE.MeshStandardMaterial({
        color: 0xfaedd9,
        map: woodColorMap,
        normalMap: woodNormalMap,
        normalScale: new THREE.Vector2(0.45, 0.45),
        roughnessMap: woodRoughnessMap,
        roughness: 0.50,
        metalness: 0.02
      }),

      // 4. Wall_Cream (Warm ivory plaster with subtle chalky stipple)
      Wall_Cream: new THREE.MeshStandardMaterial({
        color: PALETTE.wallCream,
        map: wallColorMap,
        normalMap: plasterNormalMap,
        normalScale: new THREE.Vector2(0.25, 0.25),
        roughness: 0.90,
        metalness: 0.00
      }),

      // 5. Fabric_Cream (Soft woven linen for sheets, pillows, curtains)
      Fabric_Cream: new THREE.MeshStandardMaterial({
        color: 0xfbf8f1,
        normalMap: fabricNormalMap,
        normalScale: new THREE.Vector2(0.55, 0.55),
        roughness: 0.88,
        metalness: 0.01
      }),

      // 6. Fabric_Sage (Soft sage knit duvet & pillows)
      Fabric_Sage: new THREE.MeshStandardMaterial({
        color: 0xffffff,
        map: blanketColorMap,
        normalMap: fabricNormalMap,
        normalScale: new THREE.Vector2(0.65, 0.65),
        roughness: 0.86,
        metalness: 0.01
      }),

      // Fabric_Boucle (Fluffy looped bouclé yarn for the cat bed pouf)
      Fabric_Boucle: new THREE.MeshStandardMaterial({
        color: 0xf8f4eb,
        normalMap: boucleNormalMap,
        normalScale: new THREE.Vector2(0.95, 0.95),
        roughness: 0.94,
        metalness: 0.00
      }),

      // 7. Metal_Warm (Brushed champagne / warm neutral brass)
      Metal_Warm: new THREE.MeshStandardMaterial({
        color: 0xd6cbb8,
        roughness: 0.32,
        metalness: 0.78
      }),

      // 8. Ceramic_Cream (Slightly glossy subtle surface for ceramics)
      Ceramic_Cream: new THREE.MeshPhysicalMaterial({
        color: 0xfaf7f0,
        roughness: 0.28,
        metalness: 0.01,
        clearcoat: 0.35,
        clearcoatRoughness: 0.25
      }),

      // 9. Glass_Warm (Realistic restrained transparency without mirror effect)
      Glass_Warm: new THREE.MeshPhysicalMaterial({
        color: 0xfffaee,
        transmission: 0.72,
        opacity: 1.0,
        transparent: true,
        roughness: 0.12,
        ior: 1.45,
        reflectivity: 0.32
      }),

      // 10. Paper (High roughness, matte, unbleached paper)
      Paper: new THREE.MeshStandardMaterial({
        color: 0xfaf7ee,
        roughness: 0.95,
        metalness: 0.00
      }),

      // 11. Plant_Green (Natural green variation)
      Plant_Green: new THREE.MeshStandardMaterial({
        color: 0x76946d, // Muted natural sage
        roughness: 0.62,
        metalness: 0.01,
        side: THREE.DoubleSide
      }),

      Plant_Olive: new THREE.MeshStandardMaterial({
        color: 0x627d58,
        roughness: 0.65,
        metalness: 0.01,
        side: THREE.DoubleSide
      }),

      Plant_Deep: new THREE.MeshStandardMaterial({
        color: 0x4f6946,
        roughness: 0.68,
        metalness: 0.01,
        side: THREE.DoubleSide
      }),

      Plant_GoldenGreen: new THREE.MeshStandardMaterial({
        color: 0x8ea873,
        roughness: 0.60,
        metalness: 0.01,
        side: THREE.DoubleSide
      }),

      // 12. Vinyl_Black (Concentric micro-grooved vinyl)
      Vinyl_Black: new THREE.MeshStandardMaterial({
        color: 0xffffff,
        map: vinylColorMap,
        roughness: 0.28,
        metalness: 0.18
      })
    };

    return materials;
  }
}
