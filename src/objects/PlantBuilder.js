/**
 * Nook 3D - PlantBuilder
 * Generates natural, organic 3D plants matching the lush greenery in nook-room.jpeg.
 * Includes cascading trailing vines, windowsill plants, floor planters,
 * shelf pots, and rosette succulents.
 */

import * as THREE from 'three';
import { PALETTE } from '../utils/Constants.js';
import { MaterialSystem } from '../materials/MaterialSystem.js';

export class PlantBuilder {
  constructor() {
    this.materials = this.createMaterials();
  }

  createMaterials() {
    const pbr = MaterialSystem.getMaterials();

    return {
      foliageMutedSage: pbr.Plant_Green,
      foliageOlive: pbr.Plant_Olive,
      foliageDeepGreen: pbr.Plant_Deep,
      foliageWarmYellowGreen: pbr.Plant_GoldenGreen,
      vineStem: new THREE.MeshStandardMaterial({
        color: 0x5a6e4d,
        roughness: 0.85
      }),
      terracottaPot: new THREE.MeshStandardMaterial({
        color: 0xbf7854,
        roughness: 0.76,
        metalness: 0.02
      }),
      ceramicWhitePot: pbr.Ceramic_Cream,
      ceramicWarmBeige: new THREE.MeshPhysicalMaterial({
        color: 0xd8caa8,
        roughness: 0.35,
        clearcoat: 0.25,
        clearcoatRoughness: 0.20
      }),
      soilMat: new THREE.MeshStandardMaterial({
        color: 0x3d3023,
        roughness: 0.95
      })
    };
  }

  /**
   * Builds cascading trailing ivy / pothos vines that drape down walls and shelf edges.
   */
  buildTrailingVines(vinePaths, leafScale = 1.0, leafDensity = 24) {
    const group = new THREE.Group();
    group.name = 'TrailingIvy';

    const leafMats = [
      this.materials.foliageMutedSage,
      this.materials.foliageOlive,
      this.materials.foliageDeepGreen,
      this.materials.foliageWarmYellowGreen
    ];

    for (let v = 0; v < vinePaths.length; v++) {
      const points = vinePaths[v];
      const curve = new THREE.CatmullRomCurve3(points);

      // Vine Stem Tube
      const tubeGeo = new THREE.TubeGeometry(curve, 32, 0.012, 6, false);
      const tubeMesh = new THREE.Mesh(tubeGeo, this.materials.vineStem);
      tubeMesh.castShadow = true;
      group.add(tubeMesh);

      // Heart-shaped Ivy Leaves along the vine
      const step = 1.0 / leafDensity;
      for (let t = 0.05; t <= 0.98; t += step) {
        const pt = curve.getPoint(t);
        const tangent = curve.getTangent(t);

        const leafGroup = new THREE.Group();
        leafGroup.position.copy(pt);

        // Petiole small stem
        const petioleGeo = new THREE.CylinderGeometry(0.004, 0.004, 0.05, 5);
        const petiole = new THREE.Mesh(petioleGeo, this.materials.vineStem);
        petiole.position.set(0, 0, 0.025);
        petiole.rotation.x = Math.PI * 0.5;
        leafGroup.add(petiole);

        // Heart-shaped leaf blade
        const leafW = (0.07 + (Math.sin(t * 12) * 0.02)) * leafScale;
        const leafL = (0.10 + (Math.cos(t * 10) * 0.025)) * leafScale;

        const leafShape = new THREE.Shape();
        leafShape.moveTo(0, 0);
        leafShape.bezierCurveTo(-leafW, leafL * 0.35, -leafW * 0.8, leafL * 0.85, 0, leafL);
        leafShape.bezierCurveTo(leafW * 0.8, leafL * 0.85, leafW, leafL * 0.35, 0, 0);

        const leafGeo = new THREE.ShapeGeometry(leafShape);
        const mat = leafMats[(Math.floor(t * 19) + v) % leafMats.length];
        const leafMesh = new THREE.Mesh(leafGeo, mat);
        leafMesh.position.set(0, 0, 0.05);

        // Gentle natural curve and drape
        leafMesh.rotation.x = -0.45 + (Math.sin(t * 15) * 0.25);
        leafMesh.rotation.z = (Math.sin(t * 22) * 0.5) + (v % 2 === 0 ? 0.3 : -0.3);
        leafMesh.castShadow = true;
        leafGroup.add(leafMesh);

        group.add(leafGroup);
      }
    }

    return group;
  }

  /**
   * Potted trailing shelf plant (pothos in ceramic pot on shelf or ledge).
   */
  buildPottedShelfPlant() {
    const group = new THREE.Group();
    group.name = 'PottedShelfPlant';

    // Ceramic pot
    const potH = 0.22;
    const potR = 0.14;
    const potGeo = new THREE.CylinderGeometry(potR, potR * 0.78, potH, 18);
    const pot = new THREE.Mesh(potGeo, this.materials.ceramicWarmBeige);
    pot.position.set(0, potH * 0.5, 0);
    pot.castShadow = true;
    group.add(pot);

    // Soil top
    const soilGeo = new THREE.CylinderGeometry(potR * 0.94, potR * 0.94, 0.02, 16);
    const soil = new THREE.Mesh(soilGeo, this.materials.soilMat);
    soil.position.set(0, potH - 0.01, 0);
    group.add(soil);

    // Cascading vine tendrils spilling forward and down over shelf front
    const vinePaths = [
      [
        new THREE.Vector3(0, potH, 0),
        new THREE.Vector3(0.06, potH + 0.04, 0.12),
        new THREE.Vector3(0.12, potH - 0.15, 0.18),
        new THREE.Vector3(0.15, potH - 0.42, 0.22),
        new THREE.Vector3(0.12, potH - 0.72, 0.24)
      ],
      [
        new THREE.Vector3(-0.04, potH, 0.02),
        new THREE.Vector3(-0.08, potH + 0.03, 0.14),
        new THREE.Vector3(-0.14, potH - 0.22, 0.20),
        new THREE.Vector3(-0.16, potH - 0.55, 0.22)
      ],
      [
        new THREE.Vector3(0.04, potH, -0.02),
        new THREE.Vector3(0.02, potH + 0.05, 0.08),
        new THREE.Vector3(0.01, potH - 0.10, 0.16),
        new THREE.Vector3(-0.02, potH - 0.32, 0.18)
      ]
    ];

    const vines = this.buildTrailingVines(vinePaths, 0.9, 14);
    group.add(vines);

    return group;
  }

  /**
   * Sunny windowsill potted plant with layered oval leaves.
   */
  buildWindowSillPlant(variant = 0) {
    const group = new THREE.Group();
    group.name = `WindowPlant_${variant}`;

    if (variant === 0) {
      // Terracotta potted leafy plant with upright leaves
      const potH = 0.24;
      const potGeo = new THREE.CylinderGeometry(0.13, 0.09, potH, 16);
      const pot = new THREE.Mesh(potGeo, this.materials.terracottaPot);
      pot.position.set(0, potH * 0.5, 0);
      pot.castShadow = true;
      group.add(pot);

      // Pot rim lip
      const rimGeo = new THREE.CylinderGeometry(0.145, 0.145, 0.04, 16);
      const rim = new THREE.Mesh(rimGeo, this.materials.terracottaPot);
      rim.position.set(0, potH - 0.02, 0);
      rim.castShadow = true;
      group.add(rim);

      // Clustered leaves
      const leafCount = 8;
      for (let i = 0; i < leafCount; i++) {
        const angle = (i / leafCount) * Math.PI * 2;
        const stemLen = 0.22 + (i % 3) * 0.05;

        const leafGroup = new THREE.Group();
        leafGroup.position.set(0, potH, 0);
        leafGroup.rotation.y = angle;

        // Arching stem
        const stemCurve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0, 0, 0),
          new THREE.Vector3(0, stemLen * 0.4, 0.04),
          new THREE.Vector3(0, stemLen * 0.8, 0.12),
          new THREE.Vector3(0, stemLen * 0.95, 0.20)
        ]);
        const stemGeo = new THREE.TubeGeometry(stemCurve, 12, 0.007, 6, false);
        const stem = new THREE.Mesh(stemGeo, this.materials.vineStem);
        leafGroup.add(stem);

        // Broad oval leaf
        const leafGeo = new THREE.SphereGeometry(0.08, 10, 8);
        leafGeo.scale(0.8, 0.15, 1.6);
        const leafMat = i % 2 === 0 ? this.materials.foliageMutedSage : this.materials.foliageWarmYellowGreen;
        const leaf = new THREE.Mesh(leafGeo, leafMat);
        leaf.position.set(0, stemLen * 0.95, 0.22);
        leaf.rotation.x = 0.55;
        leaf.castShadow = true;
        leafGroup.add(leaf);

        group.add(leafGroup);
      }
    } else {
      // White ceramic pot with multi-stem rounded coin leaves (Peperomia / Pilea)
      const potH = 0.20;
      const potGeo = new THREE.CylinderGeometry(0.11, 0.08, potH, 16);
      const pot = new THREE.Mesh(potGeo, this.materials.ceramicWhitePot);
      pot.position.set(0, potH * 0.5, 0);
      pot.castShadow = true;
      group.add(pot);

      for (let i = 0; i < 7; i++) {
        const angle = (i / 7) * Math.PI * 2 + 0.3;
        const h = 0.16 + (i % 3) * 0.06;
        const reach = 0.10 + (i % 2) * 0.05;

        const leafGroup = new THREE.Group();
        leafGroup.position.set(0, potH, 0);

        const stemGeo = new THREE.CylinderGeometry(0.005, 0.005, h, 6);
        const stem = new THREE.Mesh(stemGeo, this.materials.vineStem);
        stem.position.set(Math.sin(angle) * reach * 0.5, h * 0.5, Math.cos(angle) * reach * 0.5);
        stem.rotation.z = -Math.sin(angle) * 0.35;
        stem.rotation.x = Math.cos(angle) * 0.35;
        leafGroup.add(stem);

        // Circular pancake/coin leaf
        const coinGeo = new THREE.CylinderGeometry(0.055, 0.055, 0.006, 16);
        const coin = new THREE.Mesh(coinGeo, this.materials.foliageOlive);
        coin.position.set(Math.sin(angle) * reach, h, Math.cos(angle) * reach);
        coin.rotation.x = Math.cos(angle) * 0.35;
        coin.rotation.z = -Math.sin(angle) * 0.35;
        coin.castShadow = true;
        leafGroup.add(coin);

        group.add(leafGroup);
      }
    }

    return group;
  }

  /**
   * Floor planter sitting in the corner by desk drawers.
   */
  buildFloorPlanter() {
    const group = new THREE.Group();
    group.name = 'FloorPlanter';

    // Tall white cylinder planter on honey oak wooden tripod stand
    const potH = 0.44;
    const potR = 0.22;
    const legH = 0.24;

    // 3 Oak Tripod Legs
    for (let i = 0; i < 3; i++) {
      const angle = (i / 3) * Math.PI * 2;
      const legGeo = new THREE.CylinderGeometry(0.02, 0.025, legH + 0.16, 8);
      const legMat = new THREE.MeshStandardMaterial({ color: 0xdfab6f, roughness: 0.55 });
      const leg = new THREE.Mesh(legGeo, legMat);
      leg.position.set(Math.sin(angle) * (potR * 0.95), (legH + 0.16) * 0.5, Math.cos(angle) * (potR * 0.95));
      leg.rotation.z = -Math.sin(angle) * 0.12;
      leg.rotation.x = Math.cos(angle) * 0.12;
      leg.castShadow = true;
      group.add(leg);
    }

    // Ceramic Planter pot
    const potGeo = new THREE.CylinderGeometry(potR, potR * 0.88, potH, 20);
    const pot = new THREE.Mesh(potGeo, this.materials.ceramicWhitePot);
    pot.position.set(0, legH + potH * 0.5, 0);
    pot.castShadow = true;
    group.add(pot);

    // Soil
    const soilGeo = new THREE.CylinderGeometry(potR * 0.94, potR * 0.94, 0.03, 18);
    const soil = new THREE.Mesh(soilGeo, this.materials.soilMat);
    soil.position.set(0, legH + potH - 0.02, 0);
    group.add(soil);

    // Lush broad leaves radiating outwards (Fiddle leaf / Calathea)
    const baseY = legH + potH;
    for (let i = 0; i < 7; i++) {
      const angle = (i / 7) * Math.PI * 2 + 0.2;
      const leafL = 0.42 + (i % 2) * 0.08;
      const leafW = 0.22;

      const leafGroup = new THREE.Group();
      leafGroup.position.set(0, baseY, 0);
      leafGroup.rotation.y = angle;

      const stemCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0, 0, 0),
        new THREE.Vector3(0, 0.18, 0.08),
        new THREE.Vector3(0, 0.35, 0.22),
        new THREE.Vector3(0, 0.42, 0.36)
      ]);
      const stemGeo = new THREE.TubeGeometry(stemCurve, 12, 0.01, 6, false);
      const stem = new THREE.Mesh(stemGeo, this.materials.vineStem);
      leafGroup.add(stem);

      const bladeGeo = new THREE.SphereGeometry(leafW * 0.5, 12, 10);
      bladeGeo.scale(1.0, 0.18, leafL / leafW);
      const mat = i % 2 === 0 ? this.materials.foliageDeepGreen : this.materials.foliageMutedSage;
      const blade = new THREE.Mesh(bladeGeo, mat);
      blade.position.set(0, 0.38, 0.34);
      blade.rotation.x = 0.75;
      blade.castShadow = true;
      leafGroup.add(blade);

      group.add(leafGroup);
    }

    return group;
  }
}
