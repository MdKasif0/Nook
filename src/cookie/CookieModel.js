/**
 * Nook 3D - CookieModel
 * Assembles Cookie the cute chibi cat as a fully articulated 3D character matching the reference image:
 * - Oversized rounded head with mochi proportions
 * - Cream/off-white pear-shaped body with soft tummy
 * - Large glossy black eyes with crisp specular highlights (no 2D sprites)
 * - Pink cheeks and inner ears
 * - Tiny curved 'w' mouth and delicate nose
 * - Four articulated legs with soft paws
 * - Curved, expressive multi-segment tail
 * 
 * Built with named joints and hierarchical groups ready for THREE.AnimationMixer.
 */

import * as THREE from 'three';
import { PALETTE } from '../utils/Constants.js';

export class CookieModel {
  static build() {
    const root = new THREE.Group();
    root.name = 'CookieRig';

    // Scale calibrated for the diorama room
    root.scale.set(1.4, 1.4, 1.4);

    // 1. Materials
    // Body / Fur - Cream/off-white soft satin finish
    const bodyMat = new THREE.MeshStandardMaterial({
      color: 0xfcf9f2,
      roughness: 0.65,
      metalness: 0.02
    });

    // Calico Accent Patches (Ginger & Soft Dark Slate Brown)
    const gingerMat = new THREE.MeshStandardMaterial({
      color: 0xd98845,
      roughness: 0.68,
      metalness: 0.02
    });

    const darkPatchMat = new THREE.MeshStandardMaterial({
      color: 0x3d291a,
      roughness: 0.70,
      metalness: 0.02
    });

    // Inner Ears & Nose - Warm Soft Pink
    const innerEarMat = new THREE.MeshStandardMaterial({
      color: 0xf4a9b2,
      roughness: 0.75,
      metalness: 0.0
    });

    // Blushing Cheeks - Soft Rose Pink
    const blushMat = new THREE.MeshStandardMaterial({
      color: 0xf494a4,
      roughness: 0.85,
      transparent: true,
      opacity: 0.78
    });

    // Large Glossy Black Eyes with Clearcoat
    const eyeMat = new THREE.MeshPhysicalMaterial({
      color: 0x141212,
      roughness: 0.05,
      metalness: 0.1,
      clearcoat: 1.0,
      clearcoatRoughness: 0.05
    });

    // Specular Highlight Material
    const highlightMat = new THREE.MeshBasicMaterial({
      color: 0xffffff
    });

    // Mouth / Whiskers
    const mouthMat = new THREE.MeshStandardMaterial({
      color: 0x3a2d24,
      roughness: 0.6
    });

    // -------------------------------------------------------------
    // HIERARCHICAL RIGGING:
    // Root -> Hip -> Body/Chest -> Head (Ears, Eyes, Mouth)
    //             -> Legs (FL, FR, BL, BR)
    //             -> Tail (Base -> Mid -> Tip)
    // -------------------------------------------------------------

    // Hip / Pelvis Group
    const hip = new THREE.Group();
    hip.name = 'CookieHip';
    hip.position.set(0, 0.14, 0);
    root.add(hip);

    // Body / Torso (Chubby rounded pear shape)
    const bodyGroup = new THREE.Group();
    bodyGroup.name = 'CookieBody';
    hip.add(bodyGroup);

    const torsoGeo = new THREE.SphereGeometry(0.14, 24, 20);
    torsoGeo.scale(1.15, 1.25, 1.1);
    const torsoMesh = new THREE.Mesh(torsoGeo, bodyMat);
    torsoMesh.castShadow = true;
    torsoMesh.receiveShadow = true;
    bodyGroup.add(torsoMesh);

    // Cute chubby belly patch (slightly lighter cream)
    const bellyGeo = new THREE.SphereGeometry(0.12, 20, 16);
    bellyGeo.scale(1.0, 1.15, 0.6);
    const bellyMat = new THREE.MeshStandardMaterial({
      color: 0xfffcf7,
      roughness: 0.75
    });
    const bellyMesh = new THREE.Mesh(bellyGeo, bellyMat);
    bellyMesh.position.set(0, -0.02, 0.08);
    bodyGroup.add(bellyMesh);

    // Calico back patch (ginger accent)
    const backPatchGeo = new THREE.SphereGeometry(0.09, 16, 12);
    backPatchGeo.scale(1.1, 0.8, 0.9);
    const backPatch = new THREE.Mesh(backPatchGeo, gingerMat);
    backPatch.position.set(0.05, 0.04, -0.06);
    bodyGroup.add(backPatch);

    // -------------------------------------------------------------
    // HEAD & FACIAL FEATURES
    // -------------------------------------------------------------
    const headGroup = new THREE.Group();
    headGroup.name = 'CookieHead';
    // Pivot at neck level
    headGroup.position.set(0, 0.17, 0.05);
    bodyGroup.add(headGroup);

    // Oversized Mochi Chibi Head (wide, cute dumpling proportions)
    const headGeo = new THREE.SphereGeometry(0.165, 28, 24);
    headGeo.scale(1.22, 1.02, 1.08);
    const headMesh = new THREE.Mesh(headGeo, bodyMat);
    headMesh.castShadow = true;
    headMesh.receiveShadow = true;
    headGroup.add(headMesh);

    // Ginger patch on right side of head
    const headPatchGeo = new THREE.SphereGeometry(0.10, 16, 14);
    headPatchGeo.scale(1.0, 0.9, 0.9);
    const headPatch = new THREE.Mesh(headPatchGeo, gingerMat);
    headPatch.position.set(0.07, 0.06, 0.03);
    headGroup.add(headPatch);

    // Ears
    // Left Ear
    const earLGroup = new THREE.Group();
    earLGroup.name = 'CookieEarL';
    earLGroup.position.set(-0.095, 0.13, 0.02);
    earLGroup.rotation.set(-0.15, 0, 0.35);

    const earGeo = new THREE.ConeGeometry(0.062, 0.11, 16);
    earGeo.scale(1.0, 1.0, 0.65);
    const earLMesh = new THREE.Mesh(earGeo, bodyMat);
    earLMesh.castShadow = true;
    earLGroup.add(earLMesh);

    // Left Inner Ear (Pink)
    const earInnerGeo = new THREE.ConeGeometry(0.045, 0.08, 12);
    earInnerGeo.scale(0.9, 0.9, 0.5);
    const earInnerL = new THREE.Mesh(earInnerGeo, innerEarMat);
    earInnerL.position.set(0, -0.01, 0.015);
    earLGroup.add(earInnerL);
    headGroup.add(earLGroup);

    // Right Ear (with ginger patch coloring)
    const earRGroup = new THREE.Group();
    earRGroup.name = 'CookieEarR';
    earRGroup.position.set(0.095, 0.13, 0.02);
    earRGroup.rotation.set(-0.15, 0, -0.35);

    const earRMesh = new THREE.Mesh(earGeo, gingerMat);
    earRMesh.castShadow = true;
    earRGroup.add(earRMesh);

    const earInnerR = new THREE.Mesh(earInnerGeo, innerEarMat);
    earInnerR.position.set(0, -0.01, 0.015);
    earRGroup.add(earInnerR);
    headGroup.add(earRGroup);

    // Eyes (Large glossy black eyes with cute crisp anime/chibi highlights)
    const eyeContainerL = new THREE.Group();
    eyeContainerL.name = 'CookieEyeL';
    eyeContainerL.position.set(-0.072, 0.01, 0.158);
    headGroup.add(eyeContainerL);

    const eyeContainerR = new THREE.Group();
    eyeContainerR.name = 'CookieEyeR';
    eyeContainerR.position.set(0.072, 0.01, 0.158);
    headGroup.add(eyeContainerR);

    // Eye Spheres
    const eyeGeo = new THREE.SphereGeometry(0.038, 20, 16);
    eyeGeo.scale(1.0, 1.05, 0.5);

    const eyeLMesh = new THREE.Mesh(eyeGeo, eyeMat);
    eyeLMesh.castShadow = true;
    eyeContainerL.add(eyeLMesh);

    const eyeRMesh = new THREE.Mesh(eyeGeo, eyeMat);
    eyeRMesh.castShadow = true;
    eyeContainerR.add(eyeRMesh);

    // Large main specular highlight (top-left of each eye)
    const specMainGeo = new THREE.SphereGeometry(0.014, 12, 10);
    specMainGeo.scale(1.0, 1.0, 0.4);
    const specL1 = new THREE.Mesh(specMainGeo, highlightMat);
    specL1.position.set(-0.012, 0.012, 0.018);
    eyeContainerL.add(specL1);

    const specR1 = new THREE.Mesh(specMainGeo, highlightMat);
    specR1.position.set(-0.012, 0.012, 0.018);
    eyeContainerR.add(specR1);

    // Secondary tiny specular highlight (bottom-right of each eye)
    const specSubGeo = new THREE.SphereGeometry(0.007, 10, 8);
    specSubGeo.scale(1.0, 1.0, 0.4);
    const specL2 = new THREE.Mesh(specSubGeo, highlightMat);
    specL2.position.set(0.012, -0.012, 0.018);
    eyeContainerL.add(specL2);

    const specR2 = new THREE.Mesh(specSubGeo, highlightMat);
    specR2.position.set(0.012, -0.012, 0.018);
    eyeContainerR.add(specR2);

    // Blushing Pink Cheeks (Soft oval pads on cheeks)
    const blushGeo = new THREE.SphereGeometry(0.038, 16, 12);
    blushGeo.scale(1.2, 0.8, 0.25);

    const blushL = new THREE.Mesh(blushGeo, blushMat);
    blushL.position.set(-0.115, -0.028, 0.138);
    blushL.rotation.set(0, -0.35, 0.08);
    headGroup.add(blushL);

    const blushR = new THREE.Mesh(blushGeo, blushMat);
    blushR.position.set(0.115, -0.028, 0.138);
    blushR.rotation.set(0, 0.35, -0.08);
    headGroup.add(blushR);

    // Tiny pink nose
    const noseGeo = new THREE.SphereGeometry(0.010, 12, 10);
    noseGeo.scale(1.2, 0.8, 0.8);
    const nose = new THREE.Mesh(noseGeo, innerEarMat);
    nose.position.set(0, -0.012, 0.174);
    headGroup.add(nose);

    // Cute curved 'w' cat mouth
    const mouthGroup = new THREE.Group();
    mouthGroup.name = 'CookieMouth';
    mouthGroup.position.set(0, -0.032, 0.172);

    const curveL = new THREE.QuadraticBezierCurve3(
      new THREE.Vector3(-0.022, 0.004, 0),
      new THREE.Vector3(-0.011, -0.012, 0.003),
      new THREE.Vector3(0, -0.002, 0.004)
    );
    const mouthL = new THREE.Mesh(new THREE.TubeGeometry(curveL, 10, 0.0032, 6, false), mouthMat);
    mouthGroup.add(mouthL);

    const curveR = new THREE.QuadraticBezierCurve3(
      new THREE.Vector3(0, -0.002, 0.004),
      new THREE.Vector3(0.011, -0.012, 0.003),
      new THREE.Vector3(0.022, 0.004, 0)
    );
    const mouthR = new THREE.Mesh(new THREE.TubeGeometry(curveR, 10, 0.0032, 6, false), mouthMat);
    mouthGroup.add(mouthR);
    headGroup.add(mouthGroup);

    // -------------------------------------------------------------
    // ARTICULATED LEGS & PAWS (Four short rounded legs with soft paws)
    // -------------------------------------------------------------
    const createLeg = (name, isFront, isLeft) => {
      const legPivot = new THREE.Group();
      legPivot.name = name;

      const legH = isFront ? 0.11 : 0.10;
      const legR = isFront ? 0.040 : 0.048;

      // Leg Upper & Lower Limb
      const legGeo = new THREE.CylinderGeometry(legR * 0.9, legR, legH, 16);
      const legMesh = new THREE.Mesh(legGeo, bodyMat);
      legMesh.position.set(0, -legH * 0.5, 0);
      legMesh.castShadow = true;
      legPivot.add(legMesh);

      // Soft rounded paw at the bottom
      const pawGeo = new THREE.SphereGeometry(legR * 1.08, 16, 12);
      pawGeo.scale(1.0, 0.65, 1.25);
      const pawMesh = new THREE.Mesh(pawGeo, bodyMat);
      pawMesh.position.set(0, -legH, 0.018);
      pawMesh.castShadow = true;
      legPivot.add(pawMesh);

      // Toe indents
      const toeMat = new THREE.MeshStandardMaterial({
        color: 0xedd6c4,
        roughness: 0.8
      });
      for (let t = -1; t <= 1; t++) {
        const toeGeo = new THREE.SphereGeometry(0.011, 8, 8);
        const toe = new THREE.Mesh(toeGeo, toeMat);
        toe.position.set(t * 0.018, -legH - 0.008, 0.042);
        legPivot.add(toe);
      }

      return legPivot;
    };

    // Front Left Leg
    const legFL = createLeg('CookieLegFL', true, true);
    legFL.position.set(-0.08, -0.04, 0.08);
    hip.add(legFL);

    // Front Right Leg
    const legFR = createLeg('CookieLegFR', true, false);
    legFR.position.set(0.08, -0.04, 0.08);
    hip.add(legFR);

    // Hind Left Leg (Chubby haunch)
    const legBL = createLeg('CookieLegBL', false, true);
    legBL.position.set(-0.09, -0.05, -0.08);
    hip.add(legBL);

    // Hind Right Leg
    const legBR = createLeg('CookieLegBR', false, false);
    legBR.position.set(0.09, -0.05, -0.08);
    hip.add(legBR);

    // -------------------------------------------------------------
    // ARTICULATED CURVED TAIL (3-Segment Chain)
    // -------------------------------------------------------------
    const tailBase = new THREE.Group();
    tailBase.name = 'CookieTailBase';
    tailBase.position.set(0, -0.03, -0.13);
    tailBase.rotation.set(-0.35, 0, 0);
    hip.add(tailBase);

    const seg1Geo = new THREE.CylinderGeometry(0.024, 0.028, 0.09, 12);
    const seg1Mesh = new THREE.Mesh(seg1Geo, gingerMat);
    seg1Mesh.position.set(0, 0.045, 0);
    seg1Mesh.castShadow = true;
    tailBase.add(seg1Mesh);

    // Mid Segment
    const tailMid = new THREE.Group();
    tailMid.name = 'CookieTailMid';
    tailMid.position.set(0, 0.09, 0);
    tailMid.rotation.set(0.45, 0, 0);
    tailBase.add(tailMid);

    const seg2Geo = new THREE.CylinderGeometry(0.020, 0.024, 0.09, 12);
    const seg2Mesh = new THREE.Mesh(seg2Geo, gingerMat);
    seg2Mesh.position.set(0, 0.045, 0);
    seg2Mesh.castShadow = true;
    tailMid.add(seg2Mesh);

    // Tip Segment (Curves upward with soft rounded tip)
    const tailTip = new THREE.Group();
    tailTip.name = 'CookieTailTip';
    tailTip.position.set(0, 0.09, 0);
    tailTip.rotation.set(0.55, 0, 0);
    tailMid.add(tailTip);

    const tipGeo = new THREE.SphereGeometry(0.024, 14, 12);
    tipGeo.scale(0.85, 1.4, 0.85);
    const tipMesh = new THREE.Mesh(tipGeo, bodyMat); // White tail tip!
    tipMesh.position.set(0, 0.03, 0);
    tipMesh.castShadow = true;
    tailTip.add(tipMesh);

    return {
      root,
      rig: {
        hip,
        bodyGroup,
        headGroup,
        earLGroup,
        earRGroup,
        eyeContainerL,
        eyeContainerR,
        mouthGroup,
        legFL,
        legFR,
        legBL,
        legBR,
        tailBase,
        tailMid,
        tailTip
      }
    };
  }
}
