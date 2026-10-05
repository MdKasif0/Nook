/**
 * Nook 3D - Camera System
 * Sets up a telephoto/isometric-leaning PerspectiveCamera and clamped OrbitControls
 * framing the diorama room from the front-right axonometric angle of nook-room.jpeg.
 */

import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { CAMERA_CONFIG } from '../utils/Constants.js';

export class Camera {
  constructor(domElement) {
    this.domElement = domElement;
    this.target = new THREE.Vector3(...CAMERA_CONFIG.defaultTarget);

    // 1. Perspective camera with miniature/diorama telephoto FOV
    const aspect = window.innerWidth / window.innerHeight;
    this.camera = new THREE.PerspectiveCamera(
      CAMERA_CONFIG.fov,
      aspect,
      CAMERA_CONFIG.near,
      CAMERA_CONFIG.far
    );
    this.camera.position.set(...CAMERA_CONFIG.defaultPosition);
    this.camera.lookAt(this.target);

    // 2. OrbitControls configured specifically for diorama exploration
    this.controls = new OrbitControls(this.camera, this.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.target.copy(this.target);

    // Limits ensuring the viewer stays admiring the cutaway room rather than clipping solid walls
    this.controls.minDistance = CAMERA_CONFIG.minDistance;
    this.controls.maxDistance = CAMERA_CONFIG.maxDistance;
    this.controls.minPolarAngle = CAMERA_CONFIG.minPolarAngle;
    this.controls.maxPolarAngle = CAMERA_CONFIG.maxPolarAngle;
    this.controls.minAzimuthAngle = CAMERA_CONFIG.minAzimuthAngle;
    this.controls.maxAzimuthAngle = CAMERA_CONFIG.maxAzimuthAngle;

    // Smooth transition state
    this.isTransitioning = false;
    this.transitionStartPos = new THREE.Vector3();
    this.transitionEndPos = new THREE.Vector3();
    this.transitionStartTarget = new THREE.Vector3();
    this.transitionEndTarget = new THREE.Vector3();
    this.transitionProgress = 0;
    this.transitionDuration = 0.8;
  }

  resize(width, height) {
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
  }

  update(delta) {
    if (this.isTransitioning) {
      this.transitionProgress += delta / this.transitionDuration;
      const t = Math.min(1.0, this.transitionProgress);
      // Smooth cubic ease
      const ease = 1 - Math.pow(1 - t, 3);

      this.camera.position.lerpVectors(this.transitionStartPos, this.transitionEndPos, ease);
      this.controls.target.lerpVectors(this.transitionStartTarget, this.transitionEndTarget, ease);

      if (t >= 1.0) {
        this.isTransitioning = false;
      }
    }

    this.controls.update();
  }

  /**
   * Smoothly frames a specific 3D position in the room (e.g. an item, bed, or desk).
   */
  focusOn(position, offset = new THREE.Vector3(2.8, 2.2, 2.8)) {
    this.transitionStartPos.copy(this.camera.position);
    this.transitionEndPos.copy(position).add(offset);

    this.transitionStartTarget.copy(this.controls.target);
    this.transitionEndTarget.copy(position);

    this.transitionProgress = 0;
    this.isTransitioning = true;
  }

  /**
   * Resets camera back to default axonometric diorama framing.
   */
  resetToDefault() {
    this.transitionStartPos.copy(this.camera.position);
    this.transitionEndPos.set(...CAMERA_CONFIG.defaultPosition);

    this.transitionStartTarget.copy(this.controls.target);
    this.transitionEndTarget.set(...CAMERA_CONFIG.defaultTarget);

    this.transitionProgress = 0;
    this.isTransitioning = true;
  }
}
