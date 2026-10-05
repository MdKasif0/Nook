/**
 * Nook 3D - Mathematical and Geometric Utilities
 */

import * as THREE from 'three';
import { ROOM_WIDTH, ROOM_DEPTH, UPPER_FLOOR_Y, LOWER_FLOOR_Y } from './Constants.js';

export class MathUtils {
  /**
   * Linear interpolation between a and b.
   */
  static lerp(a, b, t) {
    return a + (b - a) * t;
  }

  /**
   * Smooth frame-rate independent spring-damper.
   */
  static damp(current, target, smoothing, delta) {
    return THREE.MathUtils.damp(current, target, smoothing, delta);
  }

  /**
   * Cubic ease out for tactile settling motions.
   */
  static easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
  }

  /**
   * Spring bounce interpolation for juicy physical feedback.
   */
  static easeOutElastic(t) {
    const p = 0.3;
    return Math.pow(2, -10 * t) * Math.sin((t - p / 4) * (2 * Math.PI) / p) + 1;
  }

  /**
   * Clamps a position inside the room's interior boundaries.
   */
  static clampToRoom(position, margin = 0.2) {
    const halfW = ROOM_WIDTH * 0.5 - margin;
    const halfD = ROOM_DEPTH * 0.5 - margin;

    return new THREE.Vector3(
      THREE.MathUtils.clamp(position.x, -halfW, halfW),
      Math.max(LOWER_FLOOR_Y, position.y),
      THREE.MathUtils.clamp(position.z, -halfD, halfD)
    );
  }

  /**
   * Determines whether coordinates lie in the sunken pit vs raised platform.
   */
  static getNaturalFloorHeight(x, z) {
    // Reference layout:
    // Sunken pit is in the front/center region (X between -1.8 and 0.4, Z between -0.4 and 1.8)
    if (x < 0.4 && z > -0.6) {
      return LOWER_FLOOR_Y;
    }
    return UPPER_FLOOR_Y;
  }

  /**
   * Formats 3D vector coordinates to readable fixed decimals.
   */
  static formatVector(v, precision = 2) {
    return `(${v.x.toFixed(precision)}, ${v.y.toFixed(precision)}, ${v.z.toFixed(precision)})`;
  }
}
