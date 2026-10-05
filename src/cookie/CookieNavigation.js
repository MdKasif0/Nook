/**
 * Nook 3D - CookieNavigation
 * Walkable waypoints, rest locations, and navigation paths for Cookie the cat.
 * Calibrated directly to match the warm sun-spot sleeping pose from nook-room.jpeg.
 */

import * as THREE from 'three';
import { UPPER_FLOOR_Y, LOWER_FLOOR_Y } from '../utils/Constants.js';

export const COOKIE_LOCATIONS = {
  // 1. Bed Sun Spot (Exact position of the sleeping cat in nook-room.jpeg!)
  BED_SUN_SPOT: new THREE.Vector3(0.95, UPPER_FLOOR_Y + 0.49, -0.65),

  // 2. Bouclé Pouf Cushion
  POUF_LOUNGE: new THREE.Vector3(1.22, LOWER_FLOOR_Y + 0.28, 1.45),

  // 3. Desk Companion (next to keyboard and warm desk lamp)
  DESK_COMPANION: new THREE.Vector3(-0.55, 0.71, -0.55),

  // 4. Woven Rug (Sunken desk area)
  RUG_CENTER: new THREE.Vector3(-0.65, LOWER_FLOOR_Y, 0.25),

  // 5. Window Sill (watching birds outside in the warm breeze)
  WINDOW_SILL: new THREE.Vector3(1.82, 0.80, -0.90)
};

export class CookieNavigation {
  constructor() {
    this.locations = COOKIE_LOCATIONS;
  }

  getRandomRestLocation() {
    const keys = Object.keys(this.locations);
    const randomKey = keys[Math.floor(Math.random() * keys.length)];
    return {
      name: randomKey,
      position: this.locations[randomKey].clone()
    };
  }
}
