/**
 * Nook 3D - SurfaceManager
 * Comprehensive surface placement and boundary validation system.
 * Manages physical surfaces in the miniature room:
 * - FloorSurface (main floor and sunken deck)
 * - DeskSurface (workstation desktop)
 * - ShelfSurface (bookcase tiers and desk shelf)
 * - BedSurface (mattress and duvet)
 * - OttomanSurface (lounge cushion)
 * - WindowSillSurface (sunny sill shelf)
 * - CatBedSurface (bouclé pouf)
 */

import * as THREE from 'three';
import {
  ROOM_WIDTH,
  ROOM_DEPTH,
  MAIN_FLOOR_Y,
  LOWER_FLOOR_Y
} from '../utils/Constants.js';

export class BaseSurface {
  constructor(options = {}) {
    this.id = options.id;
    this.name = options.name;
    this.boundary = options.boundary || { minX: -4, maxX: 4, minZ: -3, maxZ: 3 };
    this.height = options.height || 0;
    this.allowedObjectTypes = new Set(options.allowedObjectTypes || ['*']);
    this.localCenter = options.localCenter || new THREE.Vector3(
      (this.boundary.minX + this.boundary.maxX) * 0.5,
      this.height,
      (this.boundary.minZ + this.boundary.maxZ) * 0.5
    );
  }

  contains(x, z, margin = 0.0) {
    const b = this.boundary;
    return (
      x >= b.minX - margin &&
      x <= b.maxX + margin &&
      z >= b.minZ - margin &&
      z <= b.maxZ + margin
    );
  }

  isAllowed(objectType) {
    if (!objectType) return true;
    if (this.allowedObjectTypes.has('*')) return true;
    const lower = objectType.toLowerCase();
    const thoughtTypes = ['thought', 'pebble', 'paper_note', 'polaroid', 'bookmark', 'sticky_note'];
    if (thoughtTypes.includes(lower) && this.allowedObjectTypes.has('thought')) {
      return true;
    }
    return this.allowedObjectTypes.has(lower);
  }

  clamp(x, z, padding = 0.08) {
    const b = this.boundary;
    return {
      x: Math.max(b.minX + padding, Math.min(b.maxX - padding, x)),
      z: Math.max(b.minZ + padding, Math.min(b.maxZ - padding, z))
    };
  }
}

export class DeskSurface extends BaseSurface {
  constructor() {
    super({
      id: 'desk',
      name: 'DeskSurface',
      boundary: { minX: -4.82, maxX: -0.82, minZ: -3.32, maxZ: -1.68 },
      height: 1.70,
      allowedObjectTypes: [
        'plant',
        'book',
        'notebook',
        'mug',
        'phone',
        'headphones',
        'decoration',
        'clock',
        'lamp',
        'laptop',
        'keyboard',
        'mouse',
        'thought',
        'pebble',
        'cat'
      ],
      localCenter: new THREE.Vector3(-2.85, 1.70, -2.52)
    });
  }
}

export class BedSurface extends BaseSurface {
  constructor() {
    super({
      id: 'bed',
      name: 'BedSurface',
      boundary: { minX: 0.35, maxX: 3.35, minZ: -3.20, maxZ: 0.35 },
      height: 1.30,
      allowedObjectTypes: [
        'pillow',
        'cat',
        'book',
        'notebook',
        'phone',
        'headphones',
        'thought',
        'pebble'
      ],
      localCenter: new THREE.Vector3(1.85, 1.30, -1.45)
    });
  }
}

export class ShelfSurface extends BaseSurface {
  constructor() {
    super({
      id: 'shelf',
      name: 'ShelfSurface',
      boundary: { minX: 0.22, maxX: 2.78, minZ: -3.45, maxZ: -2.92 },
      height: 2.22,
      allowedObjectTypes: [
        'book',
        'plant',
        'clock',
        'decoration',
        'mug',
        'phone',
        'thought',
        'pebble'
      ],
      localCenter: new THREE.Vector3(1.50, 2.22, -3.20)
    });

    // Multi-tier shelf heights
    this.tiers = [
      { height: 2.22, minZ: -3.45, maxZ: -2.92 },
      { height: 3.02, minZ: -3.45, maxZ: -2.92 },
      { height: 3.82, minZ: -3.45, maxZ: -2.92 },
      { height: 4.02, minX: -4.5, maxX: -1.0, minZ: -3.45, maxZ: -2.98 } // Desk upper shelf
    ];
  }

  getHeightForPoint(x, y, z) {
    // If Y is near a specific tier, snap to that tier
    let closestTier = this.tiers[0];
    let minDiff = 999;
    for (const tier of this.tiers) {
      if (tier.minX && (x < tier.minX || x > tier.maxX)) continue;
      const diff = Math.abs(y - tier.height);
      if (diff < minDiff) {
        minDiff = diff;
        closestTier = tier;
      }
    }
    return closestTier.height;
  }
}

export class OttomanSurface extends BaseSurface {
  constructor() {
    super({
      id: 'ottoman',
      name: 'OttomanSurface',
      boundary: { minX: 2.25, maxX: 3.65, minZ: 0.50, maxZ: 1.80 },
      height: 0.88,
      allowedObjectTypes: [
        'record_player',
        'vinyl',
        'book',
        'cat',
        'pillow',
        'thought'
      ],
      localCenter: new THREE.Vector3(2.95, 0.88, 1.15)
    });
  }
}

export class WindowSillSurface extends BaseSurface {
  constructor() {
    super({
      id: 'windowsill',
      name: 'WindowSillSurface',
      boundary: { minX: 4.50, maxX: 5.25, minZ: -1.75, maxZ: 1.55 },
      height: 2.15,
      allowedObjectTypes: [
        'plant',
        'cat',
        'decoration',
        'thought',
        'book'
      ],
      localCenter: new THREE.Vector3(4.85, 2.15, -0.10)
    });
  }
}

export class CatBedSurface extends BaseSurface {
  constructor() {
    super({
      id: 'catbed',
      name: 'CatBedSurface',
      boundary: { minX: 2.65, maxX: 4.25, minZ: 2.45, maxZ: 4.05 },
      height: 0.44,
      allowedObjectTypes: [
        'cat',
        'pillow',
        'thought',
        'pebble'
      ],
      localCenter: new THREE.Vector3(3.45, 0.44, 3.25)
    });
  }
}

export class FloorSurface extends BaseSurface {
  constructor() {
    super({
      id: 'floor',
      name: 'FloorSurface',
      boundary: { minX: -4.80, maxX: 4.80, minZ: -3.30, maxZ: 4.50 },
      height: MAIN_FLOOR_Y,
      allowedObjectTypes: [
        'skateboard',
        'plant',
        'cat',
        'book',
        'thought',
        'pebble',
        'decoration'
      ],
      localCenter: new THREE.Vector3(0, MAIN_FLOOR_Y, 0)
    });
  }

  getFloorHeightAt(x, z) {
    // Stepped floor logic
    // Sunken front passage / lower deck
    if (z > 2.8 || (z > 2.0 && x > -1.2 && x < 0.8)) {
      return LOWER_FLOOR_Y;
    }
    // Intermediate step
    if (z > 1.6 && z <= 2.8 && x > -1.2 && x < 0.8) {
      return 0.14;
    }
    // Main living room floor
    return MAIN_FLOOR_Y;
  }
}

export class SurfaceManager {
  constructor(roomScene) {
    this.roomScene = roomScene;

    // Room boundaries (prevents moving outside or through walls)
    this.roomBounds = {
      minX: -4.80, // Left wall inner surface
      maxX: 4.80,  // Right wall inner surface
      minZ: -3.30, // Back wall inner surface
      maxZ: 4.50,  // Open front perimeter
      minY: 0.0,
      maxY: 5.2
    };

    // Instantiate all defined physical surfaces
    this.deskSurface = new DeskSurface();
    this.bedSurface = new BedSurface();
    this.shelfSurface = new ShelfSurface();
    this.ottomanSurface = new OttomanSurface();
    this.windowSillSurface = new WindowSillSurface();
    this.catBedSurface = new CatBedSurface();
    this.floorSurface = new FloorSurface();

    // Priority-ordered surface list (elevated furniture checked before floor)
    this.surfaces = [
      this.windowSillSurface,
      this.shelfSurface,
      this.deskSurface,
      this.bedSurface,
      this.ottomanSurface,
      this.catBedSurface,
      this.floorSurface
    ];
  }

  /**
   * Constrains an arbitrary 3D position to stay strictly inside the room boundaries.
   */
  clampToRoom(position, radius = 0.10) {
    return new THREE.Vector3(
      Math.max(this.roomBounds.minX + radius, Math.min(this.roomBounds.maxX - radius, position.x)),
      Math.max(this.roomBounds.minY, Math.min(this.roomBounds.maxY, position.y)),
      Math.max(this.roomBounds.minZ + radius, Math.min(this.roomBounds.maxZ - radius, position.z))
    );
  }

  /**
   * Identifies the best surface under given (X, Y, Z) coordinates,
   * checks if the objectType is allowed, and returns placement coordinates.
   */
  findSurface(x, y, z, objectType = null) {
    // 1. Check elevated furniture surfaces first
    for (const surface of this.surfaces) {
      if (surface === this.floorSurface) continue;

      if (surface.contains(x, z, 0.05)) {
        let surfaceHeight = surface.height;
        if (surface === this.shelfSurface) {
          surfaceHeight = this.shelfSurface.getHeightForPoint(x, y, z);
        }

        const isAllowed = surface.isAllowed(objectType);
        const clampedXZ = surface.clamp(x, z);

        return {
          surface,
          surfaceId: surface.id,
          surfaceName: surface.name,
          position: new THREE.Vector3(clampedXZ.x, surfaceHeight, clampedXZ.z),
          isValid: isAllowed,
          reason: isAllowed ? 'ok' : `Objects of type "${objectType}" cannot be placed on ${surface.name}.`
        };
      }
    }

    // 2. Fall back to FloorSurface
    const floorY = this.floorSurface.getFloorHeightAt(x, z);
    const isFloorAllowed = this.floorSurface.isAllowed(objectType);
    const clampedFloorXZ = this.floorSurface.clamp(x, z, 0.12);

    return {
      surface: this.floorSurface,
      surfaceId: this.floorSurface.id,
      surfaceName: this.floorSurface.name,
      position: new THREE.Vector3(clampedFloorXZ.x, floorY, clampedFloorXZ.z),
      isValid: isFloorAllowed,
      reason: isFloorAllowed ? 'ok' : `Objects of type "${objectType}" cannot be placed on the floor.`
    };
  }

  /**
   * Checks whether placing `targetObject` at `candidatePosition` overlaps unnaturally
   * with any other object on the same surface.
   */
  checkCollision(targetObject, candidatePosition, allObjects, minSeparation = 0.22) {
    if (!targetObject || !allObjects) return { hasCollision: false };

    const targetRadius = targetObject.collisionRadius || 0.12;

    for (const other of allObjects) {
      if (!other || other === targetObject || !other.visible) continue;

      // Only check objects at approximately similar vertical heights (same surface plane)
      if (Math.abs(other.position.y - candidatePosition.y) > 0.40) continue;

      const otherRadius = other.collisionRadius || 0.12;
      const requiredDist = Math.max(minSeparation, targetRadius + otherRadius);

      const dx = candidatePosition.x - other.position.x;
      const dz = candidatePosition.z - other.position.z;
      const distSq = dx * dx + dz * dz;

      if (distSq < requiredDist * requiredDist) {
        return {
          hasCollision: true,
          collidingWith: other,
          distance: Math.sqrt(distSq),
          requiredDistance: requiredDist
        };
      }
    }

    return { hasCollision: false };
  }
}
