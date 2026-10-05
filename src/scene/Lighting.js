/**
 * Nook 3D - Lighting Rig
 * Recreates the golden, cozy sunlight stream and warm interior glow of nook-room.jpeg.
 */

import * as THREE from 'three';
import { PALETTE, LIGHTING_CONFIG, ROOM_WIDTH, ROOM_DEPTH, ROOM_HEIGHT } from '../utils/Constants.js';

export class Lighting {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'Lighting';
    this.scene.add(this.group);

    this.isDeskLampOn = true;
    this.isAccentLightOn = true;

    this.init();
  }

  init() {
    // 1. Warm Ambient Sky/Ground Hemisphere Light
    this.ambientLight = new THREE.HemisphereLight(
      PALETTE.ambientSky,
      PALETTE.ambientGround,
      LIGHTING_CONFIG.ambientSkyIntensity
    );
    this.ambientLight.position.set(0, 8, 0);
    this.group.add(this.ambientLight);

    // 2. Window Sunlight (DirectionalLight streaming from the right window)
    // In the reference, sun pours in through the window on the right wall at ~45 degrees
    this.sunlight = new THREE.DirectionalLight(
      PALETTE.sunlightWarm,
      LIGHTING_CONFIG.sunlightIntensity
    );
    this.sunlight.position.set(5.2, 3.8, 0.4);
    this.sunlight.target.position.set(0.0, 0.2, 0.2);
    this.scene.add(this.sunlight.target);

    // Soft high-res shadow configuration
    this.sunlight.castShadow = true;
    this.sunlight.shadow.mapSize.width = 2048;
    this.sunlight.shadow.mapSize.height = 2048;
    this.sunlight.shadow.camera.near = 0.5;
    this.sunlight.shadow.camera.far = 16.0;

    const shadowExtent = 3.6;
    this.sunlight.shadow.camera.left = -shadowExtent;
    this.sunlight.shadow.camera.right = shadowExtent;
    this.sunlight.shadow.camera.top = shadowExtent;
    this.sunlight.shadow.camera.bottom = -shadowExtent;
    this.sunlight.shadow.bias = -0.0004;
    this.sunlight.shadow.normalBias = 0.02;
    this.sunlight.shadow.radius = 2.4; // Soft PCF penumbra

    this.group.add(this.sunlight);

    // 3. Cozy Desk Lamp Warm Glow
    this.deskLamp = new THREE.PointLight(
      PALETTE.lampGlow,
      LIGHTING_CONFIG.deskLampIntensity,
      3.2,
      1.8
    );
    this.deskLamp.position.set(-1.15, 1.15, -0.65);
    this.deskLamp.castShadow = true;
    this.deskLamp.shadow.mapSize.width = 512;
    this.deskLamp.shadow.mapSize.height = 512;
    this.deskLamp.shadow.bias = -0.001;
    this.deskLamp.shadow.radius = 2.0;
    this.group.add(this.deskLamp);

    // 4. Bookshelf Warm Ambient Accent (under-shelf soft LED)
    this.shelfAccent = new THREE.PointLight(
      0xffba66,
      0.35,
      2.2,
      2.0
    );
    this.shelfAccent.position.set(0.15, 1.85, -1.8);
    this.group.add(this.shelfAccent);

    // 5. Wall Sconce Light (near window cutaway)
    this.wallSconce = new THREE.PointLight(
      0xffcf88,
      0.65,
      2.2,
      2.0
    );
    this.wallSconce.position.set(1.9, 1.45, 1.1);
    this.group.add(this.wallSconce);

    // 6. Gentle Front Fill Light (soft bounce from the open cutaway)
    this.frontFill = new THREE.DirectionalLight(
      0xfff5ea,
      0.25
    );
    this.frontFill.position.set(2.0, 2.5, 4.5);
    this.group.add(this.frontFill);
  }

  toggleDeskLamp() {
    this.isDeskLampOn = !this.isDeskLampOn;
    this.deskLamp.intensity = this.isDeskLampOn ? LIGHTING_CONFIG.deskLampIntensity : 0;
    return this.isDeskLampOn;
  }

  toggleAccentLights() {
    this.isAccentLightOn = !this.isAccentLightOn;
    this.shelfAccent.intensity = this.isAccentLightOn ? LIGHTING_CONFIG.accentShelfIntensity : 0;
    this.wallSconce.intensity = this.isAccentLightOn ? 0.65 : 0;
    return this.isAccentLightOn;
  }

  update(delta) {
    // Subtle organic breathing of desk lamp filament
    if (this.isDeskLampOn) {
      const time = performance.now() * 0.0015;
      const flicker = 1.0 + Math.sin(time * 3.7) * 0.015 + Math.sin(time * 11.2) * 0.008;
      this.deskLamp.intensity = LIGHTING_CONFIG.deskLampIntensity * flicker;
    }
  }
}
