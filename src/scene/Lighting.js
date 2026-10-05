/**
 * Nook 3D - Lighting Rig
 * Recreates the golden, warm morning sunlight streaming in through the right-side window
 * and soft ambient interior bounce matching nook-room.jpeg.
 */

import * as THREE from 'three';
import { PALETTE, LIGHTING_CONFIG } from '../utils/Constants.js';

export class Lighting {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'Lighting';
    this.scene.add(this.group);

    this.init();
  }

  init() {
    // 1. Warm Ambient Sky/Ground Fill (HemisphereLight)
    this.ambientLight = new THREE.HemisphereLight(
      PALETTE.ambientSky,
      PALETTE.ambientGround,
      LIGHTING_CONFIG.ambientSkyIntensity
    );
    this.ambientLight.position.set(0, 14, 0);
    this.group.add(this.ambientLight);

    // 2. Window Sunlight (DirectionalLight pouring through the right window at ~45°)
    this.sunlight = new THREE.DirectionalLight(
      PALETTE.sunlightGolden,
      LIGHTING_CONFIG.sunlightIntensity
    );
    this.sunlight.position.set(9.2, 7.2, -0.4);
    this.sunlight.target.position.set(-0.5, 1.2, 0.4);
    this.scene.add(this.sunlight.target);

    // High quality soft shadow map
    this.sunlight.castShadow = true;
    this.sunlight.shadow.mapSize.width = 2048;
    this.sunlight.shadow.mapSize.height = 2048;
    this.sunlight.shadow.camera.near = 1.0;
    this.sunlight.shadow.camera.far = 24.0;

    const shadowExtent = 6.2;
    this.sunlight.shadow.camera.left = -shadowExtent;
    this.sunlight.shadow.camera.right = shadowExtent;
    this.sunlight.shadow.camera.top = shadowExtent;
    this.sunlight.shadow.camera.bottom = -shadowExtent;
    this.sunlight.shadow.bias = -0.0003;
    this.sunlight.shadow.normalBias = 0.025;
    this.sunlight.shadow.radius = 2.4;

    this.group.add(this.sunlight);

    // 3. Subtle Front Fill Light (from open front cutaway to soften deep shadows)
    this.frontFill = new THREE.DirectionalLight(
      0xfff6ec,
      LIGHTING_CONFIG.frontFillIntensity
    );
    this.frontFill.position.set(-2.0, 5.5, 9.0);
    this.group.add(this.frontFill);

    // 4. Soft Shelf Accent Glow
    this.shelfAccent = new THREE.PointLight(
      PALETTE.accentGlow,
      LIGHTING_CONFIG.shelfAccentIntensity,
      5.0,
      1.8
    );
    this.shelfAccent.position.set(1.5, 3.8, -3.1);
    this.group.add(this.shelfAccent);
  }

  update(delta) {
    // Stable lighting
  }
}
