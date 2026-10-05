/**
 * Nook 3D - PlacementManager
 * Determines valid droppable surfaces (floor levels, desk, bed, ottoman, pouf, window sill),
 * clamps coordinates, and computes natural tactile drop heights.
 */

import * as THREE from 'three';
import {
  ROOM_WIDTH,
  ROOM_DEPTH,
  UPPER_FLOOR_Y,
  LOWER_FLOOR_Y,
  SURFACE_HEIGHTS
} from '../utils/Constants.js';
import { MathUtils } from '../utils/MathUtils.js';

export class PlacementManager {
  constructor(roomScene) {
    this.roomScene = roomScene;
    this.surfaces = [];

    this.initSurfaces();
  }

  initSurfaces() {
    // 1. Desk Surface Bounds
    this.surfaces.push({
      id: 'desk',
      name: 'Desk Top',
      minX: -4.9,
      maxX: -0.8,
      minZ: -3.4,
      maxZ: -1.6,
      height: 1.70
    });

    // 2. Bed Mattress Bounds
    this.surfaces.push({
      id: 'bed',
      name: 'Bed Mattress',
      minX: 0.22,
      maxX: 3.48,
      minZ: -3.3,
      maxZ: 0.42,
      height: 1.42
    });

    // 3. Foot Bench / Ottoman Bounds
    this.surfaces.push({
      id: 'bench',
      name: 'Ottoman Cushion',
      minX: 2.2,
      maxX: 3.7,
      minZ: 0.45,
      maxZ: 1.85,
      height: 0.78
    });

    // 4. Cat Bed / Pouf Cushion Bounds
    this.surfaces.push({
      id: 'pouf',
      name: 'Cat Bed Pouf',
      minX: 2.6,
      maxX: 4.3,
      minZ: 2.4,
      maxZ: 4.1,
      height: 0.46
    });

    // 5. Window Sill Bounds
    this.surfaces.push({
      id: 'window_sill',
      name: 'Window Sill',
      minX: 4.6,
      maxX: 5.3,
      minZ: -1.8,
      maxZ: 1.6,
      height: 2.15
    });
  }

  /**
   * Evaluates a world (X, Z) coordinate and returns the appropriate resting Y height
   * by checking elevated furniture surfaces first, then falling back to stepped floors.
   */
  getSurfaceElevation(x, z) {
    // Check specific elevated furniture surfaces first
    for (const s of this.surfaces) {
      if (x >= s.minX && x <= s.maxX && z >= s.minZ && z <= s.maxZ) {
        return {
          height: s.height,
          surfaceId: s.id,
          surfaceName: s.name
        };
      }
    }

    // Stepped floor fallback (sunken vs upper platform)
    const floorY = MathUtils.getNaturalFloorHeight(x, z);
    return {
      height: floorY,
      surfaceId: floorY === UPPER_FLOOR_Y ? 'floor_upper' : 'floor_lower',
      surfaceName: floorY === UPPER_FLOOR_Y ? 'Upper Floor Platform' : 'Sunken Floor Pit'
    };
  }

  /**
   * Clamps and projects a ray intersection point to a safe resting coordinate inside the room.
   */
  clampAndSnapPosition(rawPosition, objectBoundingRadius = 0.08) {
    // Clamp within room walls
    const clamped = MathUtils.clampToRoom(rawPosition, objectBoundingRadius + 0.12);

    // Compute proper height for the clamped X/Z position
    const surfaceInfo = this.getSurfaceElevation(clamped.x, clamped.z);
    clamped.y = surfaceInfo.height;

    return {
      position: clamped,
      surfaceInfo
    };
  }
}
