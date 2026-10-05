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
      minX: -1.95,
      maxX: -0.35,
      minZ: -1.05,
      maxZ: -0.25,
      height: 0.71
    });

    // 2. Bed Mattress Bounds
    this.surfaces.push({
      id: 'bed',
      name: 'Bed Mattress',
      minX: 0.32,
      maxX: 1.58,
      minZ: -1.62,
      maxZ: 0.12,
      height: 0.49
    });

    // 3. Foot Bench / Ottoman Bounds
    this.surfaces.push({
      id: 'bench',
      name: 'Bench Cushion',
      minX: 0.81,
      maxX: 1.49,
      minZ: 0.34,
      maxZ: 0.96,
      height: 0.29
    });

    // 4. Pouf Cushion Bounds
    this.surfaces.push({
      id: 'pouf',
      name: 'Bouclé Pouf',
      minX: 0.85,
      maxX: 1.58,
      minZ: 1.05,
      maxZ: 1.85,
      height: 0.18
    });

    // 5. Window Sill Bounds
    this.surfaces.push({
      id: 'window_sill',
      name: 'Window Sill',
      minX: 1.75,
      maxX: 1.98,
      minZ: -1.75,
      maxZ: -0.05,
      height: 0.80
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
