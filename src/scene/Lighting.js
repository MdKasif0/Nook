/**
 * Nook 3D - Lighting Rig
 * Recreates the golden, warm morning sunlight streaming in through the right-side window,
 * evening golden hour, and cozy soft warm interior night illumination (strictly no blue night lighting).
 * Provides coherent desk lamp task lighting that harmonizes with sunlight and time of day.
 */

import * as THREE from 'three';
import { PALETTE, LIGHTING_CONFIG } from '../utils/Constants.js';
import { MathUtils } from '../utils/MathUtils.js';

export class Lighting {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'Lighting';
    this.scene.add(this.group);

    // Current State
    this.timeOfDay = 'morning'; // 'morning' | 'evening' | 'night'
    this.isDeskLampOn = true;

    // Transition interpolation tracking
    this.transitionProgress = 1.0;
    this.transitionDuration = 0.8; // seconds

    this.init();
    this.applyTimeOfDayConfig('morning', true);
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
    this.sunlight.position.set(7.8, 9.5, 3.2);
    this.sunlight.target.position.set(-0.8, 1.4, -0.6);
    this.scene.add(this.sunlight.target);

    // High quality soft shadow map matching soft morning light in reference
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
    this.sunlight.shadow.bias = -0.0002;
    this.sunlight.shadow.normalBias = 0.02;
    this.sunlight.shadow.radius = 4.2;

    this.group.add(this.sunlight);

    // 3. Subtle Front Fill Light (from open front cutaway to soften deep shadows with warm bounce)
    this.frontFill = new THREE.DirectionalLight(
      0xfff5ea,
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

    // 5. Warm Interior Desk Lamp (cozy glow pooling over desk, keyboard and notes)
    // Coherent task light that illuminates desk without overpowering sunlight
    this.deskLampLight = new THREE.PointLight(
      0xffca80,
      0.55,
      3.8,
      1.6
    );
    this.deskLampLight.position.set(-2.0, 2.35, -2.6);
    this.group.add(this.deskLampLight);

    // 6. Warm Wall Sconce Accent Glow above window nook
    this.sconceLight = new THREE.PointLight(
      0xffcf88,
      0.40,
      3.2,
      1.8
    );
    this.sconceLight.position.set(4.65, 3.85, -2.2);
    this.group.add(this.sconceLight);

    // Internal lerp targets
    this.targets = {
      sunColor: new THREE.Color(),
      sunIntensity: 0,
      sunPos: new THREE.Vector3(),
      ambientSkyColor: new THREE.Color(),
      ambientGroundColor: new THREE.Color(),
      ambientIntensity: 0,
      frontFillColor: new THREE.Color(),
      frontFillIntensity: 0,
      shelfColor: new THREE.Color(),
      shelfIntensity: 0,
      sconceColor: new THREE.Color(),
      sconceIntensity: 0,
      deskLampColor: new THREE.Color(),
      deskLampIntensity: 0
    };
  }

  // MARK: - Time of Day Management

  /**
   * Sets time of day ('morning' | 'evening' | 'night')
   * Morning: warm bright light
   * Evening: golden hour light
   * Night: soft warm interior lighting (Strictly NO blue night lighting)
   */
  setTimeOfDay(timeOfDay, immediate = false) {
    if (!['morning', 'evening', 'night'].includes(timeOfDay)) return;
    this.timeOfDay = timeOfDay;
    this.applyTimeOfDayConfig(timeOfDay, immediate);
  }

  cycleTimeOfDay() {
    const cycle = ['morning', 'evening', 'night'];
    const nextIdx = (cycle.indexOf(this.timeOfDay) + 1) % cycle.length;
    this.setTimeOfDay(cycle[nextIdx]);
    return this.timeOfDay;
  }

  applyTimeOfDayConfig(timeOfDay, immediate = false) {
    let cfg = {};

    switch (timeOfDay) {
      case 'morning':
        // Crisp, warm, cheerful morning daylight matching reference artwork
        cfg = {
          sunColor: 0xfff4e2,
          sunIntensity: 2.6,
          sunPos: new THREE.Vector3(7.8, 9.5, 3.2),
          ambientSkyColor: 0xfff8ee,
          ambientGroundColor: 0xf0d6b5,
          ambientIntensity: 1.15,
          frontFillColor: 0xfff5ea,
          frontFillIntensity: 0.85,
          shelfColor: 0xffcaa0,
          shelfIntensity: 0.35,
          sconceColor: 0xffd990,
          sconceIntensity: 0.35,
          deskLampColor: 0xffc87a,
          deskLampIntensity: this.isDeskLampOn ? 0.45 : 0.0 // Soft accent, does not fight morning sun
        };
        break;

      case 'evening':
        // Deep golden sunset with warm long shadows
        cfg = {
          sunColor: 0xff9c36,
          sunIntensity: 2.5,
          sunPos: new THREE.Vector3(8.5, 5.2, 2.5),
          ambientSkyColor: 0xffd4a8,
          ambientGroundColor: 0xc89062,
          ambientIntensity: 1.05,
          frontFillColor: 0xffdfc4,
          frontFillIntensity: 0.70,
          shelfColor: 0xffaa44,
          shelfIntensity: 0.60,
          sconceColor: 0xffab46,
          sconceIntensity: 0.65,
          deskLampColor: 0xffba64,
          deskLampIntensity: this.isDeskLampOn ? 0.68 : 0.0
        };
        break;

      case 'night':
        // Soft warm interior lighting. NO BLUE NIGHT LIGHTING.
        // Sunlight is disabled. Ambient is warm dim amber bounce.
        // Wall sconce, shelf nook, and desk lamp illuminate the room cozy and intimate.
        cfg = {
          sunColor: 0x443020,
          sunIntensity: 0.0,
          sunPos: new THREE.Vector3(9.2, 7.2, -0.4),
          ambientSkyColor: 0x48321e,
          ambientGroundColor: 0x28190e,
          ambientIntensity: 0.42,
          frontFillColor: 0x3d2817,
          frontFillIntensity: 0.14,
          shelfColor: 0xffa44a,
          shelfIntensity: 1.15,
          sconceColor: 0xffab50,
          sconceIntensity: 1.25,
          deskLampColor: 0xffba66,
          deskLampIntensity: this.isDeskLampOn ? 1.05 : 0.0 // Main task light at night
        };
        break;
    }

    this.targets.sunColor.setHex(cfg.sunColor);
    this.targets.sunIntensity = cfg.sunIntensity;
    this.targets.sunPos.copy(cfg.sunPos);

    this.targets.ambientSkyColor.setHex(cfg.ambientSkyColor);
    this.targets.ambientGroundColor.setHex(cfg.ambientGroundColor);
    this.targets.ambientIntensity = cfg.ambientIntensity;

    this.targets.frontFillColor.setHex(cfg.frontFillColor);
    this.targets.frontFillIntensity = cfg.frontFillIntensity;

    this.targets.shelfColor.setHex(cfg.shelfColor);
    this.targets.shelfIntensity = cfg.shelfIntensity;

    this.targets.sconceColor.setHex(cfg.sconceColor);
    this.targets.sconceIntensity = cfg.sconceIntensity;

    this.targets.deskLampColor.setHex(cfg.deskLampColor);
    this.targets.deskLampIntensity = cfg.deskLampIntensity;

    if (immediate) {
      this.sunlight.color.copy(this.targets.sunColor);
      this.sunlight.intensity = this.targets.sunIntensity;
      this.sunlight.position.copy(this.targets.sunPos);

      this.ambientLight.color.copy(this.targets.ambientSkyColor);
      this.ambientLight.groundColor.copy(this.targets.ambientGroundColor);
      this.ambientLight.intensity = this.targets.ambientIntensity;

      this.frontFill.color.copy(this.targets.frontFillColor);
      this.frontFill.intensity = this.targets.frontFillIntensity;

      this.shelfAccent.color.copy(this.targets.shelfColor);
      this.shelfAccent.intensity = this.targets.shelfIntensity;

      this.sconceLight.color.copy(this.targets.sconceColor);
      this.sconceLight.intensity = this.targets.sconceIntensity;

      this.deskLampLight.color.copy(this.targets.deskLampColor);
      this.deskLampLight.intensity = this.targets.deskLampIntensity;
    }
  }

  // MARK: - Desk Lamp Toggle

  toggleDeskLamp() {
    this.isDeskLampOn = !this.isDeskLampOn;
    this.applyTimeOfDayConfig(this.timeOfDay, false);
    return this.isDeskLampOn;
  }

  setDeskLamp(state) {
    this.isDeskLampOn = Boolean(state);
    this.applyTimeOfDayConfig(this.timeOfDay, false);
  }

  // MARK: - Smooth Frame Interpolation

  update(delta) {
    const rate = Math.min(delta * 4.0, 1.0);

    // Smoothly blend intensities and colors
    this.sunlight.intensity = MathUtils.lerp(this.sunlight.intensity, this.targets.sunIntensity, rate);
    this.sunlight.color.lerp(this.targets.sunColor, rate);
    this.sunlight.position.lerp(this.targets.sunPos, rate);

    this.ambientLight.intensity = MathUtils.lerp(this.ambientLight.intensity, this.targets.ambientIntensity, rate);
    this.ambientLight.color.lerp(this.targets.ambientSkyColor, rate);
    this.ambientLight.groundColor.lerp(this.targets.ambientGroundColor, rate);

    this.frontFill.intensity = MathUtils.lerp(this.frontFill.intensity, this.targets.frontFillIntensity, rate);
    this.frontFill.color.lerp(this.targets.frontFillColor, rate);

    this.shelfAccent.intensity = MathUtils.lerp(this.shelfAccent.intensity, this.targets.shelfIntensity, rate);
    this.shelfAccent.color.lerp(this.targets.shelfColor, rate);

    this.sconceLight.intensity = MathUtils.lerp(this.sconceLight.intensity, this.targets.sconceIntensity, rate);
    this.sconceLight.color.lerp(this.targets.sconceColor, rate);

    this.deskLampLight.intensity = MathUtils.lerp(this.deskLampLight.intensity, this.targets.deskLampIntensity, rate);
    this.deskLampLight.color.lerp(this.targets.deskLampColor, rate);
  }
}
