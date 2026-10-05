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
    // 1. Subtle warm studio floor plane underneath the diorama box to catch soft ground shadows
    const shadowPlaneGeo = new THREE.PlaneGeometry(24, 24);
    const shadowPlaneMat = new THREE.ShadowMaterial({
      opacity: 0.18,
      transparent: true
    });
    const shadowPlane = new THREE.Mesh(shadowPlaneGeo, shadowPlaneMat);
    shadowPlane.rotation.x = -Math.PI / 2;
    shadowPlane.position.y = LOWER_FLOOR_Y - 0.22;
    shadowPlane.receiveShadow = true;
    shadowPlane.name = 'StudioGroundShadowPlane';
    this.group.add(shadowPlane);

    // 2. Pedestal plinth / tabletop beneath the diorama slice
    const plinthGeo = new THREE.BoxGeometry(4.4, 0.12, 4.4);
    const plinthMat = new THREE.MeshStandardMaterial({
      color: 0xdfd4c5,
      roughness: 0.9,
      metalness: 0.05
    });
    const plinth = new THREE.Mesh(plinthGeo, plinthMat);
    plinth.position.y = LOWER_FLOOR_Y - 0.12;
    plinth.receiveShadow = true;
    plinth.castShadow = true;
    plinth.name = 'DioramaBasePlinth';
    this.group.add(plinth);
  }

  update(delta) {
    // Can be used for subtle environmental shifts (time of day transitions)
  }
}
