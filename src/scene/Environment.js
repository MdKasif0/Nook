/**
 * Nook 3D - Environment
 * Creates a subtle, warm neutral backdrop and studio pedestal shadow plane.
 * The room diorama remains the absolute visual focal point.
 */

import * as THREE from 'three';
import { PALETTE, LOWER_FLOOR_Y } from '../utils/Constants.js';

export class Environment {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'Environment';
    this.scene.add(this.group);

    this.init();
  }

  init() {
    // 1. Subtle warm studio tabletop plane underneath the diorama box to catch soft grounded shadows
    const shadowPlaneGeo = new THREE.PlaneGeometry(32, 32);
    const shadowPlaneMat = new THREE.MeshStandardMaterial({
      color: 0xe8ddd0,
      roughness: 0.94,
      metalness: 0.01
    });
    const shadowPlane = new THREE.Mesh(shadowPlaneGeo, shadowPlaneMat);
    shadowPlane.rotation.x = -Math.PI / 2;
    shadowPlane.position.y = -0.52;
    shadowPlane.receiveShadow = true;
    shadowPlane.name = 'StudioGroundShadowPlane';
    this.group.add(shadowPlane);
  }

  update(delta) {
    // Can be used for subtle environmental shifts (time of day transitions)
  }
}
