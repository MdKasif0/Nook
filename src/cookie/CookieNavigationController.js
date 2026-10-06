/**
 * Nook 3D - CookieNavigationController
 * Lightweight navigation graph and motion controller for Cookie the cat.
 * Defines walkable surfaces: Floor, Bed, Desk, WindowSill, CatBed, Ottoman.
 * Enforces room and obstacle boundaries (no walking through walls or furniture).
 * Handles synchronized natural walking, smooth deceleration before stops,
 * and 5-phase parabolic jump arcs (Crouch -> Push -> Airborne -> Land -> Recover).
 */

import * as THREE from 'three';
import { MAIN_FLOOR_Y, LOWER_FLOOR_Y } from '../utils/Constants.js';

// Walkable surface definitions with precise boundaries and elevations
export const WALKABLE_SURFACES = {
  FLOOR: {
    id: 'Floor',
    name: 'Main Floor & Sunken Deck',
    height: MAIN_FLOOR_Y, // 0.28
    lowerHeight: LOWER_FLOOR_Y, // 0.0
    // Walkable bounds avoiding outer walls
    bounds: { minX: -3.8, maxX: 1.0, minZ: -1.3, maxZ: 2.1 },
    lowerBounds: { minX: -0.8, maxX: 2.4, minZ: 2.4, maxZ: 3.8 }
  },
  BED: {
    id: 'Bed',
    name: 'Sage Duvet Bed',
    height: 1.30,
    bounds: { minX: 0.8, maxX: 2.9, minZ: -2.8, maxZ: 0.05 },
    approachNode: 'floor_near_bed',
    edgeNode: 'bed_edge',
    centerNode: 'bed_sun_spot'
  },
  DESK: {
    id: 'Desk',
    name: 'Oak Workstation Desk',
    height: 1.70,
    bounds: { minX: -4.2, maxX: -1.1, minZ: -2.8, maxZ: -1.8 },
    approachNode: 'floor_near_desk',
    edgeNode: 'desk_edge',
    centerNode: 'desk_laptop'
  },
  WINDOW_SILL: {
    id: 'WindowSill',
    name: 'Sunlit Window Sill',
    height: 2.15,
    bounds: { minX: 4.5, maxX: 5.0, minZ: -1.5, maxZ: 1.2 },
    approachNode: 'bed_window_approach',
    edgeNode: 'window_sill',
    centerNode: 'window_sill'
  },
  CAT_BED: {
    id: 'CatBed',
    name: 'Bouclé Pouf Cat Bed',
    height: 0.44,
    bounds: { minX: 2.8, maxX: 4.1, minZ: 2.5, maxZ: 3.9 },
    approachNode: 'floor_near_catbed',
    edgeNode: 'catbed_edge',
    centerNode: 'catbed_center'
  },
  OTTOMAN: {
    id: 'Ottoman',
    name: 'Green Velvet Ottoman',
    height: 0.88,
    bounds: { minX: 2.3, maxX: 3.6, minZ: 0.6, maxZ: 1.7 },
    approachNode: 'floor_near_ottoman',
    edgeNode: 'ottoman_edge',
    centerNode: 'ottoman_center'
  }
};

// Navigation Waypoints (Physical 3D positions in room coordinates)
export const NAV_NODES = {
  // Floor Nodes (upper floor Y = 0.28)
  floor_rug: {
    id: 'floor_rug',
    surface: 'Floor',
    position: new THREE.Vector3(-2.2, MAIN_FLOOR_Y, 0.2),
    neighbors: ['floor_center', 'floor_near_desk']
  },
  floor_center: {
    id: 'floor_center',
    surface: 'Floor',
    position: new THREE.Vector3(-0.5, MAIN_FLOOR_Y, 0.6),
    neighbors: ['floor_rug', 'floor_near_bed', 'floor_near_ottoman', 'stair_top']
  },
  floor_near_bed: {
    id: 'floor_near_bed',
    surface: 'Floor',
    position: new THREE.Vector3(0.6, MAIN_FLOOR_Y, 0.2),
    neighbors: ['floor_center', 'floor_near_ottoman', 'bed_edge'] // Jump link to bed
  },
  floor_near_desk: {
    id: 'floor_near_desk',
    surface: 'Floor',
    position: new THREE.Vector3(-1.6, MAIN_FLOOR_Y, -1.2),
    neighbors: ['floor_rug', 'desk_edge'] // Jump link to desk
  },
  floor_near_ottoman: {
    id: 'floor_near_ottoman',
    surface: 'Floor',
    position: new THREE.Vector3(1.8, MAIN_FLOOR_Y, 1.0),
    neighbors: ['floor_center', 'floor_near_bed', 'ottoman_edge'] // Jump link to ottoman
  },

  // Steps between upper and lower deck
  stair_top: {
    id: 'stair_top',
    surface: 'Floor',
    position: new THREE.Vector3(0.2, 0.14, 2.2),
    neighbors: ['floor_center', 'floor_lower_center']
  },
  floor_lower_center: {
    id: 'floor_lower_center',
    surface: 'Floor',
    position: new THREE.Vector3(0.8, LOWER_FLOOR_Y, 3.0),
    neighbors: ['stair_top', 'floor_near_catbed']
  },
  floor_near_catbed: {
    id: 'floor_near_catbed',
    surface: 'Floor',
    position: new THREE.Vector3(2.4, LOWER_FLOOR_Y, 3.0),
    neighbors: ['floor_lower_center', 'catbed_edge'] // Step link to cat bed
  },

  // Bed Nodes (Y = 1.30)
  bed_edge: {
    id: 'bed_edge',
    surface: 'Bed',
    position: new THREE.Vector3(1.1, 1.30, -0.15),
    neighbors: ['floor_near_bed', 'bed_sun_spot', 'bed_pillow_zone'],
    isJumpEdge: true
  },
  bed_sun_spot: {
    id: 'bed_sun_spot',
    surface: 'Bed',
    position: new THREE.Vector3(2.0, 1.30, -0.42),
    neighbors: ['bed_edge', 'bed_pillow_zone', 'bed_window_approach']
  },
  bed_pillow_zone: {
    id: 'bed_pillow_zone',
    surface: 'Bed',
    position: new THREE.Vector3(1.6, 1.30, -1.6),
    neighbors: ['bed_edge', 'bed_sun_spot']
  },
  bed_window_approach: {
    id: 'bed_window_approach',
    surface: 'Bed',
    position: new THREE.Vector3(2.8, 1.30, -0.3),
    neighbors: ['bed_sun_spot', 'window_sill'],
    isJumpEdge: true
  },

  // Desk Nodes (Y = 1.70)
  desk_edge: {
    id: 'desk_edge',
    surface: 'Desk',
    position: new THREE.Vector3(-1.4, 1.70, -1.85),
    neighbors: ['floor_near_desk', 'desk_laptop'],
    isJumpEdge: true
  },
  desk_laptop: {
    id: 'desk_laptop',
    surface: 'Desk',
    position: new THREE.Vector3(-1.8, 1.70, -2.1),
    neighbors: ['desk_edge', 'desk_monitor_view']
  },
  desk_monitor_view: {
    id: 'desk_monitor_view',
    surface: 'Desk',
    position: new THREE.Vector3(-2.8, 1.70, -2.1),
    neighbors: ['desk_laptop']
  },

  // Ottoman Nodes (Y = 0.88)
  ottoman_edge: {
    id: 'ottoman_edge',
    surface: 'Ottoman',
    position: new THREE.Vector3(2.5, 0.88, 1.15),
    neighbors: ['floor_near_ottoman', 'ottoman_center'],
    isJumpEdge: true
  },
  ottoman_center: {
    id: 'ottoman_center',
    surface: 'Ottoman',
    position: new THREE.Vector3(2.9, 0.88, 1.15),
    neighbors: ['ottoman_edge']
  },

  // Cat Bed Nodes (Y = 0.44)
  catbed_edge: {
    id: 'catbed_edge',
    surface: 'CatBed',
    position: new THREE.Vector3(3.0, 0.44, 3.1),
    neighbors: ['floor_near_catbed', 'catbed_center'],
    isJumpEdge: true
  },
  catbed_center: {
    id: 'catbed_center',
    surface: 'CatBed',
    position: new THREE.Vector3(3.45, 0.44, 3.25),
    neighbors: ['catbed_edge']
  },

  // Window Sill Node (Y = 2.15)
  window_sill: {
    id: 'window_sill',
    surface: 'WindowSill',
    position: new THREE.Vector3(4.75, 2.15, -0.2),
    neighbors: ['bed_window_approach'],
    isJumpEdge: true
  }
};

export class CookieNavigationController {
  constructor(cookieEntity) {
    this.cookie = cookieEntity;
    this.surfaces = WALKABLE_SURFACES;
    this.nodes = NAV_NODES;

    // Movement state
    this.currentPath = [];
    this.pathIndex = 0;
    this.isMoving = false;
    this.walkSpeed = 0.42; // Units per second, synchronized to walk stride length
    this.currentVelocity = 0;
    this.maxVelocity = 0.42;
    this.acceleration = 1.2; // Units/s^2
    this.decelerationDistance = 0.28; // Deceleration distance before waypoint

    // Jump state (5 phases: Crouch -> Push -> Airborne -> Land -> Recover)
    this.isJumping = false;
    this.jumpPhase = null; // 'crouch' | 'push' | 'airborne' | 'land' | 'recover'
    this.jumpTimer = 0;
    this.jumpStartPos = new THREE.Vector3();
    this.jumpTargetPos = new THREE.Vector3();
    this.jumpArcHeight = 0.4;
    this.onJumpComplete = null;
    this.onPathComplete = null;
  }

  /**
   * Identifies which surface contains a given 3D coordinate.
   */
  getSurfaceForPosition(pos) {
    // Check elevated surfaces first (they sit above the floor)
    const elevated = [this.surfaces.DESK, this.surfaces.BED, this.surfaces.WINDOW_SILL, this.surfaces.OTTOMAN, this.surfaces.CAT_BED];
    for (const s of elevated) {
      const b = s.bounds;
      if (pos.x >= b.minX && pos.x <= b.maxX && pos.z >= b.minZ && pos.z <= b.maxZ) {
        if (Math.abs(pos.y - s.height) < 0.35) {
          return s.id;
        }
      }
    }

    // Check lower deck floor
    const lb = this.surfaces.FLOOR.lowerBounds;
    if (pos.x >= lb.minX && pos.x <= lb.maxX && pos.z >= lb.minZ && pos.z <= lb.maxZ) {
      return 'Floor';
    }

    // Default floor
    return 'Floor';
  }

  /**
   * Returns closest navigation node to a 3D position on the same surface.
   */
  getNearestNode(pos, preferredSurface = null) {
    let bestNode = null;
    let minDistance = Infinity;

    for (const [id, node] of Object.entries(this.nodes)) {
      if (preferredSurface && node.surface !== preferredSurface) continue;
      const d = pos.distanceTo(node.position);
      if (d < minDistance) {
        minDistance = d;
        bestNode = node;
      }
    }

    // Fallback without surface filter if none matched
    if (!bestNode) {
      for (const [id, node] of Object.entries(this.nodes)) {
        const d = pos.distanceTo(node.position);
        if (d < minDistance) {
          minDistance = d;
          bestNode = node;
        }
      }
    }

    return bestNode;
  }

  /**
   * Breadth-First-Search shortest path through navigation node graph.
   */
  findPath(startNodeId, endNodeId) {
    if (startNodeId === endNodeId) {
      return [this.nodes[startNodeId]];
    }

    const queue = [[startNodeId]];
    const visited = new Set([startNodeId]);

    while (queue.length > 0) {
      const path = queue.shift();
      const currentId = path[path.length - 1];
      const currentNode = this.nodes[currentId];

      if (!currentNode) continue;

      if (currentId === endNodeId) {
        return path.map(id => this.nodes[id]);
      }

      for (const neighborId of currentNode.neighbors) {
        if (!visited.has(neighborId)) {
          visited.add(neighborId);
          queue.push([...path, neighborId]);
        }
      }
    }

    // Fallback: direct line if no graph path found
    return [this.nodes[endNodeId]];
  }

  /**
   * Navigates Cookie to a specific destination node or surface.
   */
  navigateToNode(targetNodeId, onComplete = null) {
    const currentSurface = this.getSurfaceForPosition(this.cookie.position);
    const startNode = this.getNearestNode(this.cookie.position, currentSurface);
    const targetNode = this.nodes[targetNodeId];

    if (!startNode || !targetNode) {
      if (onComplete) onComplete();
      return;
    }

    const path = this.findPath(startNode.id, targetNode.id);
    this.startPath(path, onComplete);
  }

  /**
   * Begins moving along an array of navigation nodes.
   */
  startPath(nodeArray, onComplete = null) {
    this.currentPath = nodeArray;
    this.pathIndex = 0;
    this.onPathComplete = onComplete;
    this.isMoving = true;
    this.currentVelocity = 0;
  }

  /**
   * Executes a physical parabolic jump from current position to a target position.
   * Jump sequence: Crouch -> Push -> Airborne -> Land -> Recover
   */
  initiateJump(targetPos, onComplete = null) {
    this.isJumping = true;
    this.jumpPhase = 'crouch';
    this.jumpTimer = 0;
    this.jumpStartPos.copy(this.cookie.position);
    this.jumpTargetPos.copy(targetPos);
    this.onJumpComplete = onComplete;

    // Face jump target immediately
    const dx = targetPos.x - this.jumpStartPos.x;
    const dz = targetPos.z - this.jumpStartPos.z;
    this.cookie.rotation.y = Math.atan2(dx, dz);

    // Calculate arc peak height
    const deltaY = targetPos.y - this.jumpStartPos.y;
    this.jumpArcHeight = Math.max(0.35, Math.abs(deltaY) * 0.4 + 0.25);

    // Crouch phase
    if (this.cookie.animController) {
      this.cookie.animController.play('Jump', 0.15);
    }
  }

  /**
   * Update frame handler for navigation and movement.
   */
  update(delta) {
    if (this.isJumping) {
      this.updateJump(delta);
      return;
    }

    if (this.isMoving && this.currentPath.length > 0) {
      this.updateMovement(delta);
    }
  }

  /**
   * Jump state machine: Crouch -> Push -> Airborne -> Land -> Recover
   */
  updateJump(delta) {
    this.jumpTimer += delta;

    // Phase 1: CROUCH (0.22s) - Compresses hind legs, lowers hips
    if (this.jumpPhase === 'crouch') {
      if (this.jumpTimer >= 0.22) {
        this.jumpPhase = 'push';
        this.jumpTimer = 0;
      }
      return;
    }

    // Phase 2: PUSH (0.16s) - Extends legs, pushes off surface
    if (this.jumpPhase === 'push') {
      if (this.jumpTimer >= 0.16) {
        this.jumpPhase = 'airborne';
        this.jumpTimer = 0;
      }
      return;
    }

    // Phase 3: AIRBORNE (0.50s) - Parabolic flight trajectory
    if (this.jumpPhase === 'airborne') {
      const airborneDuration = 0.50;
      const progress = Math.min(this.jumpTimer / airborneDuration, 1.0);

      // Horizontal linear interpolation
      this.cookie.position.x = THREE.MathUtils.lerp(this.jumpStartPos.x, this.jumpTargetPos.x, progress);
      this.cookie.position.z = THREE.MathUtils.lerp(this.jumpStartPos.z, this.jumpTargetPos.z, progress);

      // Vertical parabolic arc: p_y = lerp(y0, y1, t) + 4 * h * t * (1 - t)
      const baseHeight = THREE.MathUtils.lerp(this.jumpStartPos.y, this.jumpTargetPos.y, progress);
      const arc = 4.0 * this.jumpArcHeight * progress * (1.0 - progress);
      this.cookie.position.y = baseHeight + arc;

      // Natural pitch tilt during flight (pitch up on ascent, level at apex, pitch down on descent)
      const pitchProgress = progress * 2.0 - 1.0; // -1 to +1
      this.cookie.visualRoot.rotation.x = -pitchProgress * 0.25;

      if (progress >= 1.0) {
        this.cookie.position.copy(this.jumpTargetPos);
        this.cookie.visualRoot.rotation.x = 0;
        this.jumpPhase = 'land';
        this.jumpTimer = 0;

        if (this.cookie.animController) {
          this.cookie.animController.play('Land', 0.1);
        }
      }
      return;
    }

    // Phase 4: LAND (0.20s) - Impact cushion compression
    if (this.jumpPhase === 'land') {
      if (this.jumpTimer >= 0.20) {
        this.jumpPhase = 'recover';
        this.jumpTimer = 0;
      }
      return;
    }

    // Phase 5: RECOVER (0.18s) - Rises from landing crouch to normal posture
    if (this.jumpPhase === 'recover') {
      if (this.jumpTimer >= 0.18) {
        this.isJumping = false;
        this.jumpPhase = null;
        if (this.onJumpComplete) {
          const cb = this.onJumpComplete;
          this.onJumpComplete = null;
          cb();
        }
      }
    }
  }

  /**
   * Smooth, natural walking between waypoints.
   * Synchronizes legs, bob, and tail; decelerates smoothly before arrival.
   */
  updateMovement(delta) {
    if (this.pathIndex >= this.currentPath.length) {
      this.stopMovement();
      return;
    }

    const targetNode = this.currentPath[this.pathIndex];
    const targetPos = targetNode.position;

    // Check if next segment requires a jump (different surface elevation > 0.3m)
    const heightDiff = Math.abs(targetPos.y - this.cookie.position.y);
    if (heightDiff > 0.35 || targetNode.isJumpEdge) {
      const isStartEdge = this.currentPath[this.pathIndex - 1]?.isJumpEdge;
      if (isStartEdge || heightDiff > 0.35) {
        // Jump across the gap!
        this.initiateJump(targetPos, () => {
          this.pathIndex++;
          if (this.pathIndex >= this.currentPath.length) {
            this.stopMovement();
          }
        });
        return;
      }
    }

    // Turn towards waypoint
    const dx = targetPos.x - this.cookie.position.x;
    const dz = targetPos.z - this.cookie.position.z;
    const distToTarget = Math.hypot(dx, dz);

    if (distToTarget > 0.04) {
      const targetAngle = Math.atan2(dx, dz);
      // Smooth shortest-arc yaw rotation
      let diffAngle = targetAngle - this.cookie.rotation.y;
      while (diffAngle < -Math.PI) diffAngle += Math.PI * 2;
      while (diffAngle > Math.PI) diffAngle -= Math.PI * 2;
      this.cookie.rotation.y += diffAngle * Math.min(1.0, delta * 7.0);

      // Decelerate smoothly when approaching stopping destination
      const isLastNode = this.pathIndex === this.currentPath.length - 1;
      let desiredSpeed = this.maxVelocity;

      if (isLastNode && distToTarget < this.decelerationDistance) {
        // Smooth ease-out slowdown
        const slowFactor = Math.max(0.2, distToTarget / this.decelerationDistance);
        desiredSpeed = this.maxVelocity * slowFactor;
      }

      // Smooth acceleration / velocity damping
      this.currentVelocity = THREE.MathUtils.damp(this.currentVelocity, desiredSpeed, 8.0, delta);

      // Move forward
      const step = Math.min(this.currentVelocity * delta, distToTarget);
      const moveRatio = step / distToTarget;
      this.cookie.position.x += dx * moveRatio;
      this.cookie.position.z += dz * moveRatio;
      this.cookie.position.y = THREE.MathUtils.lerp(this.cookie.position.y, targetPos.y, delta * 10.0);

      // Ensure Walk animation is running smoothly
      if (this.cookie.animController && this.cookie.animController.getCurrentState() !== 'Walk') {
        this.cookie.animController.play('Walk', 0.2);
      }
    } else {
      // Reached this waypoint
      this.cookie.position.copy(targetPos);
      this.pathIndex++;

      if (this.pathIndex >= this.currentPath.length) {
        this.stopMovement();
      }
    }
  }

  stopMovement() {
    this.isMoving = false;
    this.currentVelocity = 0;
    this.currentPath = [];
    this.pathIndex = 0;

    if (this.onPathComplete) {
      const cb = this.onPathComplete;
      this.onPathComplete = null;
      cb();
    }
  }
}
