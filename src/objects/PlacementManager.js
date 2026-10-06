/**
 * Nook 3D - PlacementManager
 * Maps thought types to preferred physical surfaces (Desk, Shelf, Wall, Bed)
 * and computes organic, collision-free 3D coordinates.
 * 
 * Rules:
 * - Thought (Pebble): Desk
 * - Idea (Folded Paper): Desk / Shelf
 * - Reminder (Sticky Note): Desk / Wall
 * - Quote (Card): Shelf / Wall
 * - Photo (Polaroid): Shelf / Wall
 * - Link (Bookmark): Shelf / Bed
 * - Note (Notebook): Desk
 */

import * as THREE from 'three';
import { MAIN_FLOOR_Y } from '../utils/Constants.js';

export const SURFACE_DEFINITIONS = {
  desk: {
    id: 'desk',
    name: 'Oak Workstation Desk',
    height: 1.70,
    bounds: { minX: -3.85, maxX: -1.25, minZ: -2.65, maxZ: -1.85 },
    defaultRotation: new THREE.Euler(0, 0, 0),
    isWall: false
  },
  shelf_bed_1: {
    id: 'shelf_bed_1',
    name: 'Bedside Bookshelf (Lower)',
    height: 2.22,
    bounds: { minX: 0.5, maxX: 2.5, minZ: -3.22, maxZ: -3.02 },
    defaultRotation: new THREE.Euler(0, 0, 0),
    isWall: false
  },
  shelf_desk: {
    id: 'shelf_desk',
    name: 'Desk Upper Shelf',
    height: 3.90,
    bounds: { minX: -3.8, maxX: -1.4, minZ: -3.22, maxZ: -3.02 },
    defaultRotation: new THREE.Euler(0, 0, 0),
    isWall: false
  },
  wall_pegboard: {
    id: 'wall_pegboard',
    name: 'Desk Pegboard Wall',
    height: 2.65,
    bounds: { minX: -3.5, maxX: -1.4, minZ: -3.31, maxZ: -3.31 },
    heightBounds: { minY: 2.25, maxY: 3.25 },
    defaultRotation: new THREE.Euler(0, 0, 0),
    isWall: true
  },
  bed: {
    id: 'bed',
    name: 'Sage Blanket Duvet',
    height: 1.30,
    bounds: { minX: 0.9, maxX: 2.4, minZ: -1.8, maxZ: -0.6 },
    defaultRotation: new THREE.Euler(0, 0, 0),
    isWall: false
  }
};

// Map each thought type to prioritized surfaces
export const TYPE_SURFACE_PRIORITIES = {
  thought: ['desk'],
  idea: ['desk', 'shelf_desk', 'shelf_bed_1'],
  reminder: ['desk', 'wall_pegboard'],
  quote: ['shelf_bed_1', 'shelf_desk', 'wall_pegboard'],
  photo: ['wall_pegboard', 'shelf_bed_1', 'shelf_desk'],
  link: ['shelf_bed_1', 'shelf_desk', 'bed'],
  note: ['desk']
};

export class PlacementManager {
  constructor(roomScene) {
    this.roomScene = roomScene;
    this.surfaces = SURFACE_DEFINITIONS;
  }

  /**
   * Finds a natural, collision-free placement position and rotation for a thought object.
   * @param {string} type - 'thought' | 'idea' | 'reminder' | 'quote' | 'photo' | 'link' | 'note'
   * @param {Array<InteractiveObject>} existingObjects - Current room objects to test collisions against
   * @param {string|null} preferredSurfaceId - Optional requested surface
   * @returns {{ position: THREE.Vector3, rotation: THREE.Euler, surfaceId: string }}
   */
  findPlacement(type, existingObjects = [], preferredSurfaceId = null) {
    const normType = (type || 'thought').toLowerCase();
    const candidateSurfaceIds = preferredSurfaceId 
      ? [preferredSurfaceId, ...(TYPE_SURFACE_PRIORITIES[normType] || ['desk'])]
      : (TYPE_SURFACE_PRIORITIES[normType] || ['desk']);

    for (const surfaceId of candidateSurfaceIds) {
      const surface = this.surfaces[surfaceId];
      if (!surface) continue;

      const spot = this.findFreeSpotOnSurface(surface, existingObjects, normType);
      if (spot) {
        return {
          position: spot.position,
          rotation: spot.rotation,
          surfaceId: surface.id
        };
      }
    }

    // Ultimate fallback: desk default with safe offset
    const desk = this.surfaces.desk;
    return {
      position: new THREE.Vector3(-2.2 + (Math.random() - 0.5) * 0.8, desk.height, -2.1 + (Math.random() - 0.5) * 0.4),
      rotation: new THREE.Euler(0, (Math.random() - 0.5) * 0.4, 0),
      surfaceId: 'desk'
    };
  }

  /**
   * Attempts multiple candidate positions on a surface to find one with no physical collision.
   */
  findFreeSpotOnSurface(surface, existingObjects, thoughtType) {
    const maxAttempts = 24;
    const clearanceRadius = 0.18; // Minimum distance between thought objects

    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      let x, y, z;
      const rot = new THREE.Euler();

      if (surface.isWall) {
        // Wall placement (pegboard / wall art)
        x = THREE.MathUtils.lerp(surface.bounds.minX, surface.bounds.maxX, 0.15 + Math.random() * 0.7);
        y = THREE.MathUtils.lerp(surface.heightBounds.minY, surface.heightBounds.maxY, 0.15 + Math.random() * 0.7);
        z = surface.bounds.minZ;
        rot.set(0, 0, (Math.random() - 0.5) * 0.08); // Slight natural tilt on pegboard
      } else {
        // Horizontal surface placement
        x = THREE.MathUtils.lerp(surface.bounds.minX, surface.bounds.maxX, 0.1 + Math.random() * 0.8);
        y = surface.height;
        z = THREE.MathUtils.lerp(surface.bounds.minZ, surface.bounds.maxZ, 0.1 + Math.random() * 0.8);
        rot.set(0, (Math.random() - 0.5) * 0.35, 0); // Gentle random yaw angle
      }

      const candidatePos = new THREE.Vector3(x, y, z);

      // Check collision against all existing objects
      let hasCollision = false;
      for (const obj of existingObjects) {
        if (!obj || !obj.position) continue;
        const dist = candidatePos.distanceTo(obj.position);
        const combinedRadius = (obj.collisionRadius || 0.14) + clearanceRadius;
        if (dist < combinedRadius) {
          hasCollision = true;
          break;
        }
      }

      if (!hasCollision) {
        return { position: candidatePos, rotation: rot };
      }
    }

    return null;
  }
}
