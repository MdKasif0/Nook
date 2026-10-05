/**
 * Nook 3D - NookMainCamera
 * Dedicated three-quarter elevated perspective camera matching the exact
 * reference composition of nook-room.jpeg.
 */

import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { CAMERA_CONFIG } from '../utils/Constants.js';

export class Camera {
  constructor(domElement) {
    this.domElement = domElement;
    this.target = new THREE.Vector3(...CAMERA_CONFIG.defaultTarget);

    const aspect = window.innerWidth / window.innerHeight;

    // Dedicated NookMainCamera
    this.camera = new THREE.PerspectiveCamera(
      CAMERA_CONFIG.fov,
      aspect,
      CAMERA_CONFIG.near,
      CAMERA_CONFIG.far
    );
    this.camera.name = 'NookMainCamera';

    // Set initial position & orientation
    this.camera.position.set(...CAMERA_CONFIG.defaultPosition);
    this.camera.lookAt(this.target);

    // OrbitControls locked to stable subtle exploration
    this.controls = new OrbitControls(this.camera, this.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.target.copy(this.target);

    // Clamped strictly to maintain the stable reference framing
    this.controls.minDistance = CAMERA_CONFIG.minDistance;
    this.controls.maxDistance = CAMERA_CONFIG.maxDistance;
    this.controls.minPolarAngle = CAMERA_CONFIG.minPolarAngle;
    this.controls.maxPolarAngle = CAMERA_CONFIG.maxPolarAngle;
    this.controls.minAzimuthAngle = CAMERA_CONFIG.minAzimuthAngle;
    this.controls.maxAzimuthAngle = CAMERA_CONFIG.maxAzimuthAngle;
    this.controls.enablePan = false; // Keep composition centered on room diorama

    // Transition state
    this.isTransitioning = false;
    this.transitionStartPos = new THREE.Vector3();
    this.transitionEndPos = new THREE.Vector3();
    this.transitionStartTarget = new THREE.Vector3();
    this.transitionEndTarget = new THREE.Vector3();
    this.transitionProgress = 0;
    this.transitionDuration = 0.6;
  }

  resize(width, height) {
    this.camera.aspect = width / height;
    this.camera.updateProjectionMatrix();
  }

  update(delta) {
    if (this.isTransitioning) {
      this.transitionProgress += delta / this.transitionDuration;
      const t = Math.min(1.0, this.transitionProgress);
      const ease = 1 - Math.pow(1 - t, 3); // Cubic ease out

      this.camera.position.lerpVectors(this.transitionStartPos, this.transitionEndPos, ease);
      this.controls.target.lerpVectors(this.transitionStartTarget, this.transitionEndTarget, ease);

      if (t >= 1.0) {
        this.isTransitioning = false;
      }
    }

    this.controls.update();
  }

  /**
   * Resets camera back to the exact reference blueprint composition.
   */
  resetCamera() {
    this.transitionStartPos.copy(this.camera.position);
    this.transitionEndPos.set(...CAMERA_CONFIG.defaultPosition);

    this.transitionStartTarget.copy(this.controls.target);
    this.transitionEndTarget.set(...CAMERA_CONFIG.defaultTarget);

    this.transitionProgress = 0;
    this.isTransitioning = true;
  }

  focusOn(position, offset = new THREE.Vector3(2.5, 2.0, 2.5)) {
    this.transitionStartPos.copy(this.camera.position);
    this.transitionEndPos.copy(position).add(offset);

    this.transitionStartTarget.copy(this.controls.target);
    this.transitionEndTarget.copy(position);

    this.transitionProgress = 0;
    this.isTransitioning = true;
  }
}
