/**
 * Nook 3D - CookieNavigation
 * Walkable waypoints, rest locations, and navigation paths for Cookie the cat.
 * Calibrated directly to match the warm sun-spot sleeping pose from nook-room.jpeg.
 */

import * as THREE from 'three';
import { UPPER_FLOOR_Y, LOWER_FLOOR_Y } from '../utils/Constants.js';

export const COOKIE_LOCATIONS = {
  // 1. Bed Sun Spot (Sleeping cat in nook-room.jpeg curled up on sage blanket)
  BED_SUN_SPOT: new THREE.Vector3(2.2, 1.15, -0.65),

  // 2. Cat Bed / Bouclé Pouf Cushion
  POUF_LOUNGE: new THREE.Vector3(3.45, 0.46, 3.25),

  // 3. Desk Companion (next to keyboard and warm desk lamp)
  DESK_COMPANION: new THREE.Vector3(-1.8, 1.70, -2.0),

  // 4. Botanical Rug (desk chair area)
  RUG_CENTER: new THREE.Vector3(-2.65, MAIN_FLOOR_Y + 0.02, -0.7),

  // 5. Window Sill (watching birds outside in the warm sunlight)
  WINDOW_SILL: new THREE.Vector3(4.8, 2.15, -0.2)
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
