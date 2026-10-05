/**
 * Nook 3D - CookieController
 * Assembles Cookie the calico companion cat with chibi anatomical features,
 * soft calico patches, expressive ears, and peaceful sun-spot sleeping posture.
 */

import * as THREE from 'three';
import { InteractiveObject } from '../objects/InteractiveObject.js';
import { PALETTE } from '../utils/Constants.js';
import { CookieNavigation, COOKIE_LOCATIONS } from './CookieNavigation.js';
import { CookieBehavior } from './CookieBehavior.js';

export class CookieController extends InteractiveObject {
  constructor(roomScene) {
    super({
      id: 'prop_cookie',
      name: 'Cookie the Cat',
      category: 'character',
      objectType: 'character',
      isDraggable: false, // Cookie moves autonomously or via user calls
      isSelectable: true
    });

    this.roomScene = roomScene;
    this.navigation = new CookieNavigation();

    this.buildCatGeometry();

    this.behavior = new CookieBehavior(this);

    // Initial position: Sleeping in the warm sun on the bed (identical to nook-room.jpeg!)
    this.position.copy(COOKIE_LOCATIONS.BED_SUN_SPOT);
    this.rotation.y = -0.4;

    this.roomScene.cookieGroup.add(this);
  }

  buildCatGeometry() {
    // 1. Materials
    this.bodyMat = new THREE.MeshStandardMaterial({
      color: PALETTE.cookieWhite,
      roughness: 0.8
    });
    this.gingerPatchMat = new THREE.MeshStandardMaterial({
      color: PALETTE.cookieGinger,
      roughness: 0.75
    });
    this.darkPatchMat = new THREE.MeshStandardMaterial({
      color: PALETTE.cookieDarkBrown,
      roughness: 0.75
    });
    this.earInnerMat = new THREE.MeshStandardMaterial({
      color: PALETTE.cookieEarsPink,
      roughness: 0.85
    });
    this.blushMat = new THREE.MeshStandardMaterial({
      color: PALETTE.cookieBlush,
      roughness: 0.9,
      transparent: true,
      opacity: 0.65
    });
    this.eyeMat = new THREE.MeshStandardMaterial({
      color: 0x221e1d,
      roughness: 0.2
    });

    // 2. Body (Curled sleeping loaf)
    const bodyGeo = new THREE.SphereGeometry(0.12, 24, 18);
    bodyGeo.scale(1.25, 0.75, 1.45);
    this.bodyMesh = new THREE.Mesh(bodyGeo, this.bodyMat);
    this.bodyMesh.position.set(0, 0.08, 0);
    this.bodyMesh.castShadow = true;
    this.bodyMesh.receiveShadow = true;
    this.visualRoot.add(this.bodyMesh);

    // Calico Back Ginger Patch
    const gingerPatchGeo = new THREE.SphereGeometry(0.09, 16, 12);
    gingerPatchGeo.scale(1.1, 0.6, 0.9);
    const gingerPatch = new THREE.Mesh(gingerPatchGeo, this.gingerPatchMat);
    gingerPatch.position.set(0.04, 0.095, -0.02);
    this.visualRoot.add(gingerPatch);

    // Calico Dark Patch
    const darkPatchGeo = new THREE.SphereGeometry(0.065, 16, 12);
    darkPatchGeo.scale(1.0, 0.5, 0.8);
    const darkPatch = new THREE.Mesh(darkPatchGeo, this.darkPatchMat);
    darkPatch.position.set(-0.05, 0.09, 0.05);
    this.visualRoot.add(darkPatch);

    // 3. Chibi Head
    this.headGroup = new THREE.Group();
    this.headGroup.position.set(-0.06, 0.11, 0.12);

    const headGeo = new THREE.SphereGeometry(0.08, 20, 16);
    headGeo.scale(1.15, 0.95, 1.0);
    const headMesh = new THREE.Mesh(headGeo, this.bodyMat);
    headMesh.castShadow = true;
    this.headGroup.add(headMesh);

    // Head Ginger Cap
    const headPatchGeo = new THREE.SphereGeometry(0.06, 16, 12);
    headPatchGeo.scale(0.8, 0.7, 0.9);
    const headPatch = new THREE.Mesh(headPatchGeo, this.gingerPatchMat);
    headPatch.position.set(0.025, 0.045, -0.01);
    this.headGroup.add(headPatch);

    // Ears
    const earGeo = new THREE.ConeGeometry(0.032, 0.055, 4);
    earGeo.scale(1.0, 1.0, 0.6);

    this.leftEar = new THREE.Mesh(earGeo, this.bodyMat);
    this.leftEar.position.set(-0.045, 0.075, 0.01);
    this.leftEar.rotation.set(-0.15, 0, 0.35);
    this.leftEar.castShadow = true;
    this.headGroup.add(this.leftEar);

    this.rightEar = new THREE.Mesh(earGeo, this.gingerPatchMat);
    this.rightEar.position.set(0.045, 0.075, 0.01);
    this.rightEar.rotation.set(-0.15, 0, -0.35);
    this.rightEar.castShadow = true;
    this.headGroup.add(this.rightEar);

    // Eyes (Closed Sleeping Crescents by default)
    const eyeGeo = new THREE.BoxGeometry(0.022, 0.005, 0.01);
    this.leftEye = new THREE.Mesh(eyeGeo, this.eyeMat);
    this.leftEye.position.set(-0.038, 0.01, 0.078);
    this.leftEye.rotation.z = -0.15;
    this.headGroup.add(this.leftEye);

    this.rightEye = new THREE.Mesh(eyeGeo, this.eyeMat);
    this.rightEye.position.set(0.038, 0.01, 0.078);
    this.rightEye.rotation.z = 0.15;
    this.headGroup.add(this.rightEye);

    // Sweet Cheek Blush
    const blushGeo = new THREE.CircleGeometry(0.018, 12);
    const leftBlush = new THREE.Mesh(blushGeo, this.blushMat);
    leftBlush.position.set(-0.052, -0.01, 0.075);
    leftBlush.rotation.y = -0.4;
    this.headGroup.add(leftBlush);

    const rightBlush = new THREE.Mesh(blushGeo, this.blushMat);
    rightBlush.position.set(0.052, -0.01, 0.075);
    rightBlush.rotation.y = 0.4;
    this.headGroup.add(rightBlush);

    this.visualRoot.add(this.headGroup);

    // 4. Curled Tail
    const tailCurve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0.0, 0.03, -0.15),
      new THREE.Vector3(0.08, 0.05, -0.18),
      new THREE.Vector3(0.14, 0.07, -0.12),
      new THREE.Vector3(0.15, 0.09, -0.04)
    ]);
    const tailGeo = new THREE.TubeGeometry(tailCurve, 16, 0.018, 8, false);
    this.tailMesh = new THREE.Mesh(tailGeo, this.gingerPatchMat);
    this.tailMesh.castShadow = true;
    this.visualRoot.add(this.tailMesh);
  }

  setEyesClosed(closed) {
    if (closed) {
      this.leftEye.scale.set(1.0, 0.25, 1.0);
      this.rightEye.scale.set(1.0, 0.25, 1.0);
    } else {
      this.leftEye.scale.set(1.0, 1.0, 1.0);
      this.rightEye.scale.set(1.0, 1.0, 1.0);
    }
  }

  setCurledPose(curled) {
    if (curled) {
      this.headGroup.position.set(-0.06, 0.08, 0.08);
      this.headGroup.rotation.set(0.2, -0.3, 0.1);
    } else {
      this.headGroup.position.set(0, 0.13, 0.12);
      this.headGroup.rotation.set(0, 0, 0);
    }
  }

  triggerPetBounce() {
    const originalY = this.position.y;
    let t = 0;
    const interval = setInterval(() => {
      t += 0.15;
      this.position.y = originalY + Math.sin(t * Math.PI) * 0.025;
      if (t >= 1.0) {
        clearInterval(interval);
        this.position.y = originalY;
      }
    }, 25);
  }

  /**
   * User clicked/petted Cookie!
   */
  onSelect() {
    super.onSelect();
    this.behavior.pet();
  }

  update(delta) {
    super.update(delta);
    this.behavior.update(delta);
  }
}
