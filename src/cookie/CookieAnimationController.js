/**
 * Nook 3D - CookieAnimationController
 * Centralized feline animation engine driven entirely by THREE.AnimationMixer and THREE.AnimationClip.
 * Implements all 17 required animation states:
 * Idle, Blink, LookAround, HeadTilt, Walk, Sit, Stand, Jump, Land, Stretch,
 * Yawn, Sleep, Wake, Groom, Play, Happy, Curious.
 * 
 * Features smooth cross-fading, loop controls, and event listeners.
 */

import * as THREE from 'three';

export const COOKIE_ANIM_STATES = {
  IDLE: 'Idle',
  BLINK: 'Blink',
  LOOK_AROUND: 'LookAround',
  HEAD_TILT: 'HeadTilt',
  WALK: 'Walk',
  SIT: 'Sit',
  STAND: 'Stand',
  JUMP: 'Jump',
  LAND: 'Land',
  STRETCH: 'Stretch',
  YAWN: 'Yawn',
  SLEEP: 'Sleep',
  WAKE: 'Wake',
  GROOM: 'Groom',
  PLAY: 'Play',
  HAPPY: 'Happy',
  CURIOUS: 'Curious'
};

export class CookieAnimationController {
  constructor(cookieRoot) {
    this.root = cookieRoot;
    this.mixer = new THREE.AnimationMixer(this.root);

    this.clips = new Map();
    this.actions = new Map();

    this.currentState = null;
    this.currentAction = null;

    this.buildAllClips();
    this.initActions();

    // Default starting state
    this.play(COOKIE_ANIM_STATES.SLEEP, 0.0);
  }

  // MARK: - Keyframe Track Generators

  static makeQuatTrack(name, times, eulerValues) {
    const quatValues = [];
    const euler = new THREE.Euler();
    const quat = new THREE.Quaternion();

    for (let i = 0; i < eulerValues.length; i++) {
      const [x, y, z] = eulerValues[i];
      euler.set(x, y, z);
      quat.setFromEuler(euler);
      quatValues.push(quat.x, quat.y, quat.z, quat.w);
    }

    return new THREE.QuaternionKeyframeTrack(`${name}.quaternion`, times, quatValues);
  }

  static makeVecTrack(property, times, values) {
    const flatValues = [];
    for (let i = 0; i < values.length; i++) {
      flatValues.push(values[i][0], values[i][1], values[i][2]);
    }
    return new THREE.VectorKeyframeTrack(property, times, flatValues);
  }

  // MARK: - Build All 17 Animation Clips

  buildAllClips() {
    const Q = CookieAnimationController.makeQuatTrack;
    const V = CookieAnimationController.makeVecTrack;

    // 1. IDLE (Gentle breathing, soft tail wave, subtle ear twitch)
    {
      const d = 3.2;
      const t = [0, 0.8, 1.6, 2.4, 3.2];
      const tracks = [
        V('CookieBody.scale', t, [
          [1, 1, 1], [1.02, 1.03, 1.02], [1, 1, 1], [1.02, 1.03, 1.02], [1, 1, 1]
        ]),
        V('CookieHip.position', t, [
          [0, 0.14, 0], [0, 0.142, 0], [0, 0.14, 0], [0, 0.142, 0], [0, 0.14, 0]
        ]),
        Q('CookieTailBase', t, [
          [-0.35, -0.08, 0], [-0.35, 0.08, 0], [-0.35, -0.08, 0], [-0.35, 0.08, 0], [-0.35, -0.08, 0]
        ]),
        Q('CookieTailMid', t, [
          [0.45, -0.12, 0], [0.45, 0.12, 0], [0.45, -0.12, 0], [0.45, 0.12, 0], [0.45, -0.12, 0]
        ]),
        Q('CookieHead', [0, 1.2, 1.6, 2.8, 3.2], [
          [0, 0, 0], [0.03, 0.04, 0.02], [0, 0, 0], [0.02, -0.03, -0.01], [0, 0, 0]
        ]),
        Q('CookieEarL', [0, 1.5, 1.65, 1.8, 3.2], [
          [-0.15, 0, 0.35], [-0.15, 0, 0.35], [-0.25, 0, 0.45], [-0.15, 0, 0.35], [-0.15, 0, 0.35]
        ]),
        V('CookieEyeL.scale', [0, 3.2], [[1, 1, 1], [1, 1, 1]]),
        V('CookieEyeR.scale', [0, 3.2], [[1, 1, 1], [1, 1, 1]])
      ];
      this.clips.set(COOKIE_ANIM_STATES.IDLE, new THREE.AnimationClip(COOKIE_ANIM_STATES.IDLE, d, tracks));
    }

    // 2. BLINK (Crisp natural eyelid blink)
    {
      const d = 0.35;
      const t = [0, 0.14, 0.22, 0.35];
      const tracks = [
        V('CookieEyeL.scale', t, [[1, 1, 1], [1, 0.12, 1], [1, 0.12, 1], [1, 1, 1]]),
        V('CookieEyeR.scale', t, [[1, 1, 1], [1, 0.12, 1], [1, 0.12, 1], [1, 1, 1]])
      ];
      this.clips.set(COOKIE_ANIM_STATES.BLINK, new THREE.AnimationClip(COOKIE_ANIM_STATES.BLINK, d, tracks));
    }

    // 3. LOOK AROUND (Curious feline head turn left, pause, turn right)
    {
      const d = 3.6;
      const t = [0, 0.8, 1.6, 2.4, 3.2, 3.6];
      const tracks = [
        Q('CookieHead', t, [
          [0, 0, 0],
          [0.02, 0.45, 0.05],
          [0.04, 0.45, 0.08],
          [0.02, -0.45, -0.05],
          [0.04, -0.45, -0.08],
          [0, 0, 0]
        ]),
        Q('CookieEarL', t, [
          [-0.15, 0, 0.35], [-0.10, 0.1, 0.42], [-0.10, 0.1, 0.42], [-0.20, -0.1, 0.28], [-0.20, -0.1, 0.28], [-0.15, 0, 0.35]
        ]),
        Q('CookieEarR', t, [
          [-0.15, 0, -0.35], [-0.20, 0.1, -0.28], [-0.20, 0.1, -0.28], [-0.10, -0.1, -0.42], [-0.10, -0.1, -0.42], [-0.15, 0, -0.35]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.LOOK_AROUND, new THREE.AnimationClip(COOKIE_ANIM_STATES.LOOK_AROUND, d, tracks));
    }

    // 4. HEAD TILT (Adorable inquisitive head tilt)
    {
      const d = 2.2;
      const t = [0, 0.5, 1.5, 2.2];
      const tracks = [
        Q('CookieHead', t, [
          [0, 0, 0],
          [-0.04, 0.08, 0.28],
          [-0.04, 0.08, 0.28],
          [0, 0, 0]
        ]),
        Q('CookieEarL', t, [
          [-0.15, 0, 0.35], [-0.05, 0, 0.50], [-0.05, 0, 0.50], [-0.15, 0, 0.35]
        ]),
        Q('CookieTailTip', t, [
          [0.55, 0, 0], [0.55, 0.25, 0], [0.55, 0.25, 0], [0.55, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.HEAD_TILT, new THREE.AnimationClip(COOKIE_ANIM_STATES.HEAD_TILT, d, tracks));
    }

    // 5. WALK (Synchronized 4-beat gait cycle)
    {
      const d = 0.8;
      const t = [0, 0.2, 0.4, 0.6, 0.8];
      const tracks = [
        // Front Left & Back Right swing forward in phase 1
        Q('CookieLegFL', t, [
          [0, 0, 0], [0.42, 0, 0], [0, 0, 0], [-0.38, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBR', t, [
          [0, 0, 0], [-0.32, 0, 0], [0, 0, 0], [0.38, 0, 0], [0, 0, 0]
        ]),
        // Front Right & Back Left swing forward in phase 2
        Q('CookieLegFR', t, [
          [0, 0, 0], [-0.38, 0, 0], [0, 0, 0], [0.42, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBL', t, [
          [0, 0, 0], [0.38, 0, 0], [0, 0, 0], [-0.32, 0, 0], [0, 0, 0]
        ]),
        // Body Vertical Bobbing & Roll
        V('CookieHip.position', t, [
          [0, 0.14, 0], [0, 0.152, 0], [0, 0.14, 0], [0, 0.152, 0], [0, 0.14, 0]
        ]),
        Q('CookieHip', t, [
          [0, 0, 0], [0.03, 0, 0.02], [0, 0, 0], [0.03, 0, -0.02], [0, 0, 0]
        ]),
        // Tail counterbalance sway
        Q('CookieTailBase', t, [
          [-0.25, 0, 0], [-0.25, -0.25, 0], [-0.25, 0, 0], [-0.25, 0.25, 0], [-0.25, 0, 0]
        ]),
        // Head subtle forward bob
        Q('CookieHead', t, [
          [0, 0, 0], [-0.04, 0, 0], [0.02, 0, 0], [-0.04, 0, 0], [0, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.WALK, new THREE.AnimationClip(COOKIE_ANIM_STATES.WALK, d, tracks));
    }

    // 6. SIT (Hind legs fold in, torso sits back and low)
    {
      const d = 1.0;
      const t = [0, 0.5, 1.0];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.14, 0], [0, 0.10, -0.03], [0, 0.08, -0.05]
        ]),
        Q('CookieHip', t, [
          [0, 0, 0], [-0.15, 0, 0], [-0.28, 0, 0]
        ]),
        Q('CookieLegBL', t, [
          [0, 0, 0], [0.65, 0.2, 0], [1.1, 0.3, 0]
        ]),
        Q('CookieLegBR', t, [
          [0, 0, 0], [0.65, -0.2, 0], [1.1, -0.3, 0]
        ]),
        Q('CookieLegFL', t, [
          [0, 0, 0], [-0.12, 0, 0], [-0.20, 0, 0]
        ]),
        Q('CookieLegFR', t, [
          [0, 0, 0], [-0.12, 0, 0], [-0.20, 0, 0]
        ]),
        Q('CookieHead', t, [
          [0, 0, 0], [0.15, 0, 0], [0.28, 0, 0] // Head compensates to stay level
        ]),
        Q('CookieTailBase', t, [
          [-0.35, 0, 0], [0.2, 0.4, 0], [0.4, 0.75, 0] // Tail wraps around side
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.SIT, new THREE.AnimationClip(COOKIE_ANIM_STATES.SIT, d, tracks));
    }

    // 7. STAND (Rises up onto all fours)
    {
      const d = 0.8;
      const t = [0, 0.4, 0.8];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.08, -0.05], [0, 0.12, -0.02], [0, 0.14, 0]
        ]),
        Q('CookieHip', t, [
          [-0.28, 0, 0], [-0.12, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBL', t, [
          [1.1, 0.3, 0], [0.5, 0.1, 0], [0, 0, 0]
        ]),
        Q('CookieLegBR', t, [
          [1.1, -0.3, 0], [0.5, -0.1, 0], [0, 0, 0]
        ]),
        Q('CookieLegFL', t, [
          [-0.20, 0, 0], [-0.08, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegFR', t, [
          [-0.20, 0, 0], [-0.08, 0, 0], [0, 0, 0]
        ]),
        Q('CookieHead', t, [
          [0.28, 0, 0], [0.12, 0, 0], [0, 0, 0]
        ]),
        Q('CookieTailBase', t, [
          [0.4, 0.75, 0], [0.1, 0.3, 0], [-0.35, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.STAND, new THREE.AnimationClip(COOKIE_ANIM_STATES.STAND, d, tracks));
    }

    // 8. JUMP (Complete sequence: Crouch -> Push -> Airborne -> Land -> Recover)
    {
      const d = 1.1;
      const t = [0, 0.22, 0.38, 0.72, 0.92, 1.1];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.14, 0],     // 0: Start
          [0, 0.07, -0.04], // 0.22: Crouch deep
          [0, 0.18, 0.06],  // 0.38: Push extension
          [0, 0.16, 0.02],  // 0.72: Airborne tuck
          [0, 0.08, 0],     // 0.92: Land compression
          [0, 0.14, 0]      // 1.1: Recover
        ]),
        Q('CookieHip', t, [
          [0, 0, 0],
          [-0.25, 0, 0], // Crouch pitch down
          [0.35, 0, 0],  // Leap pitch up
          [0.10, 0, 0],  // Airborne glide
          [-0.22, 0, 0], // Land compression
          [0, 0, 0]
        ]),
        Q('CookieLegFL', t, [
          [0, 0, 0], [-0.3, 0, 0], [0.55, 0, 0], [0.2, 0, 0], [-0.25, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegFR', t, [
          [0, 0, 0], [-0.3, 0, 0], [0.55, 0, 0], [0.2, 0, 0], [-0.25, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBL', t, [
          [0, 0, 0], [0.5, 0, 0], [-0.6, 0, 0], [0.35, 0, 0], [0.45, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBR', t, [
          [0, 0, 0], [0.5, 0, 0], [-0.6, 0, 0], [0.35, 0, 0], [0.45, 0, 0], [0, 0, 0]
        ]),
        Q('CookieTailBase', t, [
          [-0.35, 0, 0], [-0.6, 0, 0], [0.2, 0, 0], [0.4, 0, 0], [-0.2, 0, 0], [-0.35, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.JUMP, new THREE.AnimationClip(COOKIE_ANIM_STATES.JUMP, d, tracks));
    }

    // 9. LAND (Impact cushion and recovery)
    {
      const d = 0.45;
      const t = [0, 0.18, 0.45];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.14, 0], [0, 0.07, 0], [0, 0.14, 0]
        ]),
        Q('CookieHip', t, [
          [0, 0, 0], [-0.18, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegFL', t, [
          [0, 0, 0], [-0.25, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegFR', t, [
          [0, 0, 0], [-0.25, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBL', t, [
          [0, 0, 0], [0.35, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBR', t, [
          [0, 0, 0], [0.35, 0, 0], [0, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.LAND, new THREE.AnimationClip(COOKIE_ANIM_STATES.LAND, d, tracks));
    }

    // 10. STRETCH (Classical feline morning bow and arch)
    {
      const d = 2.8;
      const t = [0, 0.8, 1.8, 2.5, 2.8];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.14, 0], [0, 0.07, 0.08], [0, 0.07, 0.08], [0, 0.15, -0.04], [0, 0.14, 0]
        ]),
        Q('CookieHip', t, [
          [0, 0, 0], [0.38, 0, 0], [0.38, 0, 0], [-0.25, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegFL', t, [
          [0, 0, 0], [0.65, 0, 0], [0.65, 0, 0], [-0.1, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegFR', t, [
          [0, 0, 0], [0.65, 0, 0], [0.65, 0, 0], [-0.1, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBL', t, [
          [0, 0, 0], [-0.35, 0, 0], [-0.35, 0, 0], [0.45, 0, 0], [0, 0, 0]
        ]),
        Q('CookieLegBR', t, [
          [0, 0, 0], [-0.35, 0, 0], [-0.35, 0, 0], [0.45, 0, 0], [0, 0, 0]
        ]),
        Q('CookieTailBase', t, [
          [-0.35, 0, 0], [0.45, 0, 0], [0.45, 0, 0], [-0.65, 0, 0], [-0.35, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.STRETCH, new THREE.AnimationClip(COOKIE_ANIM_STATES.STRETCH, d, tracks));
    }

    // 11. YAWN (Head tilts up, mouth opens wide, eyes squeeze shut)
    {
      const d = 2.4;
      const t = [0, 0.6, 1.4, 2.0, 2.4];
      const tracks = [
        Q('CookieHead', t, [
          [0, 0, 0], [-0.28, 0, 0], [-0.32, 0, 0], [-0.08, 0, 0], [0, 0, 0]
        ]),
        V('CookieEyeL.scale', t, [
          [1, 1, 1], [1, 0.15, 1], [1, 0.10, 1], [1, 0.6, 1], [1, 1, 1]
        ]),
        V('CookieEyeR.scale', t, [
          [1, 1, 1], [1, 0.15, 1], [1, 0.10, 1], [1, 0.6, 1], [1, 1, 1]
        ]),
        V('CookieMouth.scale', t, [
          [1, 1, 1], [1.2, 2.2, 1.2], [1.2, 2.4, 1.2], [1.1, 1.3, 1], [1, 1, 1]
        ]),
        Q('CookieEarL', t, [
          [-0.15, 0, 0.35], [-0.35, 0, 0.55], [-0.35, 0, 0.55], [-0.20, 0, 0.40], [-0.15, 0, 0.35]
        ]),
        Q('CookieEarR', t, [
          [-0.15, 0, -0.35], [-0.35, 0, -0.55], [-0.35, 0, -0.55], [-0.20, 0, -0.40], [-0.15, 0, -0.35]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.YAWN, new THREE.AnimationClip(COOKIE_ANIM_STATES.YAWN, d, tracks));
    }

    // 12. SLEEP (Curled loaf pose with deep peaceful rhythmic breathing)
    {
      const d = 3.6;
      const t = [0, 0.9, 1.8, 2.7, 3.6];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.05, 0], [0, 0.054, 0], [0, 0.05, 0], [0, 0.054, 0], [0, 0.05, 0]
        ]),
        V('CookieBody.scale', t, [
          [1.08, 0.88, 1.08], [1.12, 0.92, 1.12], [1.08, 0.88, 1.08], [1.12, 0.92, 1.12], [1.08, 0.88, 1.08]
        ]),
        Q('CookieHead', t, [
          [0.18, -0.32, 0.12], [0.20, -0.32, 0.14], [0.18, -0.32, 0.12], [0.20, -0.32, 0.14], [0.18, -0.32, 0.12]
        ]),
        // Eyes completely closed in deep sleep
        V('CookieEyeL.scale', [0, 3.6], [[1, 0.12, 1], [1, 0.12, 1]]),
        V('CookieEyeR.scale', [0, 3.6], [[1, 0.12, 1], [1, 0.12, 1]]),
        // Legs tucked in cozy loaf
        Q('CookieLegFL', [0, 3.6], [[0.8, -0.3, 0], [0.8, -0.3, 0]]),
        Q('CookieLegFR', [0, 3.6], [[0.8, 0.3, 0], [0.8, 0.3, 0]]),
        Q('CookieLegBL', [0, 3.6], [[1.2, 0.4, 0], [1.2, 0.4, 0]]),
        Q('CookieLegBR', [0, 3.6], [[1.2, -0.4, 0], [1.2, -0.4, 0]]),
        // Tail wrapped snugly around paws
        Q('CookieTailBase', [0, 3.6], [[0.35, 0.85, 0], [0.35, 0.85, 0]]),
        Q('CookieTailMid', [0, 3.6], [[0.55, 0.45, 0], [0.55, 0.45, 0]])
      ];
      this.clips.set(COOKIE_ANIM_STATES.SLEEP, new THREE.AnimationClip(COOKIE_ANIM_STATES.SLEEP, d, tracks));
    }

    // 13. WAKE (Gently opens eyes, lifts head from loaf, ear flicks)
    {
      const d = 1.8;
      const t = [0, 0.5, 1.2, 1.8];
      const tracks = [
        V('CookieEyeL.scale', t, [[1, 0.12, 1], [1, 0.4, 1], [1, 0.9, 1], [1, 1, 1]]),
        V('CookieEyeR.scale', t, [[1, 0.12, 1], [1, 0.4, 1], [1, 0.9, 1], [1, 1, 1]]),
        Q('CookieHead', t, [
          [0.18, -0.32, 0.12], [0.08, -0.15, 0.05], [0.02, 0, 0], [0, 0, 0]
        ]),
        V('CookieHip.position', t, [
          [0, 0.05, 0], [0, 0.08, 0], [0, 0.12, 0], [0, 0.14, 0]
        ]),
        Q('CookieEarL', [0, 0.8, 0.95, 1.1, 1.8], [
          [-0.25, 0, 0.40], [-0.25, 0, 0.40], [-0.35, 0, 0.55], [-0.15, 0, 0.35], [-0.15, 0, 0.35]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.WAKE, new THREE.AnimationClip(COOKIE_ANIM_STATES.WAKE, d, tracks));
    }

    // 14. GROOM (Sits and rubs face/ear with raised front paw)
    {
      const d = 3.2;
      const t = [0, 0.6, 1.2, 1.8, 2.4, 3.2];
      const tracks = [
        V('CookieHip.position', [0, 3.2], [[0, 0.08, -0.05], [0, 0.08, -0.05]]),
        Q('CookieLegFL', t, [
          [-0.20, 0, 0],
          [0.85, 0.2, 0.3],
          [0.95, 0.3, 0.4],
          [0.85, 0.2, 0.3],
          [0.95, 0.3, 0.4],
          [-0.20, 0, 0]
        ]),
        Q('CookieHead', t, [
          [0.28, 0, 0],
          [0.32, 0.25, 0.15],
          [0.25, 0.20, 0.10],
          [0.32, 0.25, 0.15],
          [0.25, 0.20, 0.10],
          [0.28, 0, 0]
        ]),
        V('CookieEyeL.scale', t, [
          [1, 1, 1], [1, 0.25, 1], [1, 0.20, 1], [1, 0.25, 1], [1, 0.20, 1], [1, 1, 1]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.GROOM, new THREE.AnimationClip(COOKIE_ANIM_STATES.GROOM, d, tracks));
    }

    // 15. PLAY (Playful cat pounce stance with wiggly rear)
    {
      const d = 2.4;
      const t = [0, 0.4, 0.7, 1.0, 1.3, 1.7, 2.4];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.14, 0],
          [0, 0.09, 0.02],
          [0, 0.09, 0.02],
          [0, 0.09, 0.02],
          [0, 0.09, 0.02],
          [0, 0.16, 0.06],
          [0, 0.14, 0]
        ]),
        Q('CookieHip', t, [
          [0, 0, 0],
          [0.25, 0, 0],
          [0.25, 0.18, 0.12],   // Wiggle right
          [0.25, -0.18, -0.12], // Wiggle left
          [0.25, 0.18, 0.12],   // Wiggle right
          [0.35, 0, 0],         // Pounce leap
          [0, 0, 0]
        ]),
        Q('CookieTailBase', t, [
          [-0.35, 0, 0],
          [0.25, 0.35, 0],
          [0.25, -0.35, 0],
          [0.25, 0.35, 0],
          [0.25, -0.35, 0],
          [0.45, 0, 0],
          [-0.35, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.PLAY, new THREE.AnimationClip(COOKIE_ANIM_STATES.PLAY, d, tracks));
    }

    // 16. HAPPY (Tail held high wagging, happy crescent eyes, perky nod)
    {
      const d = 2.0;
      const t = [0, 0.5, 1.0, 1.5, 2.0];
      const tracks = [
        Q('CookieTailBase', t, [
          [0.45, -0.32, 0], [0.45, 0.32, 0], [0.45, -0.32, 0], [0.45, 0.32, 0], [0.45, -0.32, 0]
        ]),
        Q('CookieHead', t, [
          [0, 0, 0], [-0.08, 0, 0.04], [0.04, 0, 0], [-0.08, 0, -0.04], [0, 0, 0]
        ]),
        V('CookieEyeL.scale', t, [
          [1, 0.35, 1], [1, 0.30, 1], [1, 0.35, 1], [1, 0.30, 1], [1, 0.35, 1]
        ]),
        V('CookieEyeR.scale', t, [
          [1, 0.35, 1], [1, 0.30, 1], [1, 0.35, 1], [1, 0.30, 1], [1, 0.35, 1]
        ]),
        V('CookieHip.position', t, [
          [0, 0.14, 0], [0, 0.155, 0], [0, 0.14, 0], [0, 0.155, 0], [0, 0.14, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.HAPPY, new THREE.AnimationClip(COOKIE_ANIM_STATES.HAPPY, d, tracks));
    }

    // 17. CURIOUS (Leans forward, head tilts, alert ears)
    {
      const d = 2.6;
      const t = [0, 0.6, 1.8, 2.6];
      const tracks = [
        V('CookieHip.position', t, [
          [0, 0.14, 0], [0, 0.13, 0.05], [0, 0.13, 0.05], [0, 0.14, 0]
        ]),
        Q('CookieHead', t, [
          [0, 0, 0], [-0.06, 0.18, 0.22], [-0.06, 0.18, 0.22], [0, 0, 0]
        ]),
        Q('CookieEarL', t, [
          [-0.15, 0, 0.35], [-0.05, 0.15, 0.45], [-0.05, 0.15, 0.45], [-0.15, 0, 0.35]
        ]),
        Q('CookieEarR', t, [
          [-0.15, 0, -0.35], [-0.05, 0.15, -0.25], [-0.05, 0.15, -0.25], [-0.15, 0, -0.35]
        ]),
        Q('CookieTailTip', t, [
          [0.55, 0, 0], [0.55, 0.35, 0], [0.55, -0.35, 0], [0.55, 0, 0]
        ])
      ];
      this.clips.set(COOKIE_ANIM_STATES.CURIOUS, new THREE.AnimationClip(COOKIE_ANIM_STATES.CURIOUS, d, tracks));
    }
  }

  initActions() {
    for (const [stateName, clip] of this.clips.entries()) {
      const action = this.mixer.clipAction(clip);

      // Loop configuration
      if ([
        COOKIE_ANIM_STATES.IDLE,
        COOKIE_ANIM_STATES.WALK,
        COOKIE_ANIM_STATES.SLEEP,
        COOKIE_ANIM_STATES.HAPPY
      ].includes(stateName)) {
        action.setLoop(THREE.LoopRepeat);
      } else {
        action.setLoop(THREE.LoopOnce);
        action.clampWhenFinished = true;
      }

      this.actions.set(stateName, action);
    }
  }

  // MARK: - Playback Controls

  play(stateName, crossFadeDuration = 0.3) {
    const nextAction = this.actions.get(stateName);
    if (!nextAction) {
      console.warn(`CookieAnimationController: Unknown state ${stateName}`);
      return;
    }

    if (this.currentAction === nextAction && nextAction.isRunning()) {
      return;
    }

    nextAction.reset();

    if (this.currentAction && crossFadeDuration > 0) {
      nextAction.play();
      this.currentAction.crossFadeTo(nextAction, crossFadeDuration, true);
    } else {
      if (this.currentAction) {
        this.currentAction.stop();
      }
      nextAction.play();
    }

    this.currentAction = nextAction;
    this.currentState = stateName;
  }

  playOnce(stateName, onComplete = null, crossFadeDuration = 0.25) {
    const nextAction = this.actions.get(stateName);
    if (!nextAction) return;

    this.play(stateName, crossFadeDuration);

    const onFinished = e => {
      if (e.action === nextAction) {
        this.mixer.removeEventListener('finished', onFinished);
        if (typeof onComplete === 'function') {
          onComplete();
        }
      }
    };

    this.mixer.addEventListener('finished', onFinished);
  }

  getCurrentState() {
    return this.currentState;
  }

  update(delta) {
    if (this.mixer) {
      this.mixer.update(delta);
    }
  }
}
