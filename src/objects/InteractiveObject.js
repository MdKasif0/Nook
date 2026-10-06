/**
 * Nook 3D - InteractiveObject
 * Base physical entity class for all movable, static, and special props in the diorama.
 * Implements physically based lift, subtle warm highlights, spring settling physics,
 * velocity-dependent motion tilting, plant secondary leaf wobble, skateboard deck rocking,
 * smart surface book orientation, and rebound on invalid placement.
 */

import * as THREE from 'three';
import { MathUtils } from '../utils/MathUtils.js';
import { soundManager } from '../audio/SoundManager.js';

export class InteractiveObject extends THREE.Group {
  constructor(options = {}) {
    super();

    this.itemId = options.id || THREE.MathUtils.generateUUID();
    this.name = options.name || 'Interactive Object';
    this.accessibilityLabel = options.accessibilityLabel || this.name;
    this.category = options.category || 'movable'; // 'movable' | 'static' | 'special' | 'thought'
    this.objectType = options.objectType || 'prop'; // 'plant', 'book', 'lamp', 'skateboard', 'pebble', etc.

    // Metadata for thoughts and props
    this.metadata = options.metadata || {
      title: options.title || this.name,
      description: options.content || options.description || '',
      date: options.date || new Date().toISOString().split('T')[0],
      author: options.author || 'User'
    };

    // Permissions
    this.isMovable = options.isMovable !== undefined ? options.isMovable : (this.category !== 'static');
    this.isDraggable = this.isMovable;
    this.isSelectable = options.isSelectable !== undefined ? options.isSelectable : true;
    this.isRotatable = options.isRotatable !== undefined ? options.isRotatable : this.isMovable;
    this.isDeletable = options.isDeletable !== undefined ? options.isDeletable : (this.category === 'movable' || this.category === 'thought');
    this.isDuplicatable = options.isDuplicatable !== undefined ? options.isDuplicatable : (this.category === 'movable' || this.category === 'thought');

    // Physical sizing for collision detection
    this.collisionRadius = options.collisionRadius || 0.16;

    // Interaction states
    this.isHovered = false;
    this.isSelected = false;
    this.isDragging = false;
    this.isInvalid = false;

    // Elevation & Visual smoothing
    this.currentElevation = 0.0;
    this.targetElevation = 0.0;

    // Velocity-based motion tilt
    this.currentTiltX = 0.0;
    this.currentTiltZ = 0.0;
    this.targetTiltX = 0.0;
    this.targetTiltZ = 0.0;
    this.lastDragPos = new THREE.Vector3();

    // Transforms & History
    this.defaultPosition = new THREE.Vector3();
    this.defaultRotation = new THREE.Euler();
    this.previousValidPosition = new THREE.Vector3();
    this.previousValidRotation = new THREE.Euler();

    // Visual Root Container (contains all 3D child meshes)
    this.visualRoot = new THREE.Group();
    this.visualRoot.name = 'VisualRoot';
    this.add(this.visualRoot);

    // Raycast lookup tag
    this.userData.isInteractiveObject = true;
    this.userData.instance = this;

    // Settling & Rebound Physics
    this.isSettling = false;
    this.settleProgress = 0;
    this.settleDuration = 0.35; // seconds
    this.settleStartPos = new THREE.Vector3();
    this.settleEndPos = new THREE.Vector3();
    this.settleStartRot = new THREE.Euler();
    this.settleEndRot = new THREE.Euler();
    this.settleTiltAngle = 0;

    this.isRebounding = false;
    this.reboundProgress = 0;
    this.reboundStartPos = new THREE.Vector3();

    // Secondary motion for plants (leaf inertia wobble)
    this.isPlant = this.objectType === 'plant';
    this.leafSwayTarget = new THREE.Vector2(0, 0);
    this.leafSwayCurrent = new THREE.Vector2(0, 0);
    this.leafMeshes = []; // meshes that receive secondary motion

    // Skateboard physical deck rock animation
    this.isSkateboard = this.objectType === 'skateboard';
    this.isRocking = false;
    this.rockTime = 0.0;
    this.rockDuration = 0.65;
    this.rockAmp = 0.06; // radians

    // Material original emissive storage
    this.cachedMaterials = new Map();

    // Special click callback (e.g. lamp toggle, record player, cat pet)
    this.specialAction = options.specialAction || null;
  }

  /**
   * Sets and saves the initial home position for the "Reset Position" command.
   */
  setDefaultTransform(position, rotation = null) {
    this.position.copy(position);
    this.defaultPosition.copy(position);
    this.previousValidPosition.copy(position);

    if (rotation) {
      this.rotation.copy(rotation);
      this.defaultRotation.copy(rotation);
      this.previousValidRotation.copy(rotation);
    }
  }

  /**
   * Caches material references for clean emissive highlights.
   */
  cacheMaterials() {
    this.visualRoot.traverse(child => {
      if (child.isMesh && child.material) {
        if (!this.cachedMaterials.has(child)) {
          const mat = child.material;
          this.cachedMaterials.set(child, {
            originalEmissive: mat.emissive ? mat.emissive.clone() : new THREE.Color(0x000000),
            originalEmissiveIntensity: mat.emissiveIntensity !== undefined ? mat.emissiveIntensity : 1.0
          });
        }
      }
    });
  }

  /**
   * Subtly adjusts material emissive tint for warm tactile hover/selection feedback.
   */
  applyWarmHighlight(hexColor = 0x000000) {
    if (this.cachedMaterials.size === 0) {
      this.cacheMaterials();
    }

    const highlightColor = new THREE.Color(hexColor);
    for (const [mesh, cache] of this.cachedMaterials.entries()) {
      if (mesh.material && mesh.material.emissive) {
        if (hexColor === 0x000000) {
          mesh.material.emissive.copy(cache.originalEmissive);
        } else {
          mesh.material.emissive.copy(highlightColor);
        }
      }
    }
  }

  // MARK: - Hover Handlers

  onHoverEnter() {
    if (this.isHovered) return;
    this.isHovered = true;

    if (!this.isSelected && !this.isDragging) {
      this.targetElevation = 0.035;
      this.applyWarmHighlight(0x1a1208); // Very subtle warm amber glow
    }
  }

  onHoverExit() {
    if (!this.isHovered) return;
    this.isHovered = false;

    if (!this.isSelected && !this.isDragging) {
      this.targetElevation = 0.0;
      this.applyWarmHighlight(0x000000);
    }
  }

  // MARK: - Selection Handlers

  onSelect() {
    this.isSelected = true;
    this.targetElevation = 0.075;
    this.applyWarmHighlight(0x352510); // Warm golden highlight
  }

  onDeselect() {
    this.isSelected = false;
    this.targetElevation = this.isHovered ? 0.035 : 0.0;
    this.applyWarmHighlight(this.isHovered ? 0x1a1208 : 0x000000);
  }

  // MARK: - Drag Handlers

  onDragStart(hitPoint) {
    this.isDragging = true;
    this.isSettling = false;
    this.isRebounding = false;

    this.previousValidPosition.copy(this.position);
    this.previousValidRotation.copy(this.rotation);
    this.lastDragPos.copy(this.position);

    this.targetElevation = 0.16; // Elevate during pick-up
    this.applyWarmHighlight(0x422f14);
  }

  onDragUpdate(targetPos) {
    // Physical velocity-dependent tilt
    const vx = targetPos.x - this.position.x;
    const vz = targetPos.z - this.position.z;

    // Subtly tilt object in motion direction (clamped to prevent extremes)
    this.targetTiltZ = THREE.MathUtils.clamp(-vx * 0.45, -0.10, 0.10);
    this.targetTiltX = THREE.MathUtils.clamp(vz * 0.45, -0.10, 0.10);

    // Secondary motion for plant foliage
    if (this.isPlant) {
      this.leafSwayTarget.x += -vx * 1.8;
      this.leafSwayTarget.y += -vz * 1.8;
    }

    this.position.x = targetPos.x;
    this.position.z = targetPos.z;
    this.position.y = targetPos.y;
    this.lastDragPos.copy(targetPos);
  }

  onDragEnd(finalSurfacePosition, isValid = true, targetRotation = null) {
    this.isDragging = false;
    this.targetElevation = this.isSelected ? 0.075 : (this.isHovered ? 0.035 : 0.0);
    this.targetTiltX = 0;
    this.targetTiltZ = 0;
    this.applyWarmHighlight(this.isSelected ? 0x352510 : 0x000000);

    if (isValid && finalSurfacePosition) {
      // Valid placement: Physical drop settling bounce & sound
      this.isSettling = true;
      this.settleProgress = 0;
      this.settleStartPos.copy(this.position);
      this.settleEndPos.copy(finalSurfacePosition);

      this.settleStartRot.copy(this.rotation);
      this.settleEndRot.copy(targetRotation || this.rotation);

      this.settleTiltAngle = (Math.random() - 0.5) * 0.04;

      this.previousValidPosition.copy(finalSurfacePosition);
      this.previousValidRotation.copy(this.settleEndRot);

      // Play soft placement audio
      soundManager.playPlacementSound(this.objectType);

      // Settle leaf secondary wobble
      if (this.isPlant) {
        this.leafSwayTarget.set((Math.random() - 0.5) * 0.08, (Math.random() - 0.5) * 0.08);
      }
    } else {
      // Invalid placement: Rebound back to previous position
      this.playInvalidRebound();
    }
  }

  /**
   * Adapts orientation according to target surface (e.g. books stand upright on shelves, lie flat on desk).
   */
  adaptOrientationToSurface(surfaceId) {
    if (this.objectType === 'book') {
      const targetRot = this.rotation.clone();
      if (surfaceId && (surfaceId === 'shelf' || surfaceId.includes('shelf'))) {
        // Shelf: Settle upright on spine/bottom edge
        targetRot.x = 0;
        targetRot.z = Math.PI * 0.5;
      } else {
        // Desk, Bed, Ottoman, Floor: Lie flat
        targetRot.x = 0;
        targetRot.z = 0;
      }
      return targetRot;
    }
    return this.rotation;
  }

  /**
   * Skateboard deck rock interaction (urethane bushings compression & rebound).
   */
  rockDeck() {
    this.isRocking = true;
    this.rockTime = 0.0;
    this.rockAmp = (Math.random() > 0.5 ? 1 : -1) * 0.065;
    soundManager.playSkateboardRock();
  }

  /**
   * Rebounds smoothly back to previous valid position when placed on an invalid surface or in collision.
   */
  playInvalidRebound() {
    this.isRebounding = true;
    this.reboundProgress = 0;
    this.reboundStartPos.copy(this.position);
    this.targetElevation = 0.0;
    this.targetTiltX = 0;
    this.targetTiltZ = 0;
    this.applyWarmHighlight(0x000000);
  }

  /**
   * Resets smoothly back to the original default scene spot.
   */
  resetToDefault() {
    this.isSettling = true;
    this.settleProgress = 0;
    this.settleStartPos.copy(this.position);
    this.settleEndPos.copy(this.defaultPosition);
    this.settleStartRot.copy(this.rotation);
    this.settleEndRot.copy(this.defaultRotation);
    this.rotation.copy(this.defaultRotation);
    this.previousValidPosition.copy(this.defaultPosition);
    this.previousValidRotation.copy(this.defaultRotation);
    soundManager.playPlacementSound(this.objectType);
  }

  /**
   * Rotates clockwise by specified radians.
   */
  rotateBy(angleRad = Math.PI * 0.25) {
    if (!this.isRotatable) return;
    this.rotation.y += angleRad;
    this.previousValidRotation.copy(this.rotation);
  }

  /**
   * Triggers special action (lamp toggle, record player, skateboard rock, monitor visual cycle, etc.).
   */
  triggerSpecialAction() {
    if (this.isSkateboard) {
      this.rockDeck();
    }

    if (typeof this.specialAction === 'function') {
      this.specialAction(this);
    }
  }

  // MARK: - Frame Update Loop

  update(delta) {
    // 1. Smooth physical elevation lerping
    this.currentElevation = MathUtils.damp(this.currentElevation, this.targetElevation, 12, delta);
    this.visualRoot.position.y = this.currentElevation;

    // 2. Velocity motion tilt smoothing
    this.currentTiltX = MathUtils.damp(this.currentTiltX, this.targetTiltX, 10, delta);
    this.currentTiltZ = MathUtils.damp(this.currentTiltZ, this.targetTiltZ, 10, delta);
    if (this.isDragging) {
      this.visualRoot.rotation.x = this.currentTiltX;
      this.visualRoot.rotation.z = this.currentTiltZ;
    }

    // 3. Physical Settling Animation (Drop onto surface)
    if (this.isSettling) {
      this.settleProgress += delta / this.settleDuration;

      if (this.settleProgress >= 1.0) {
        this.position.copy(this.settleEndPos);
        this.rotation.copy(this.settleEndRot);
        this.visualRoot.rotation.set(0, 0, 0);
        this.isSettling = false;
      } else {
        const t = this.settleProgress;
        // Damped harmonic bounce & tilt
        const bounce = Math.sin(t * Math.PI) * Math.exp(-t * 5.0) * 0.06;
        const tilt = Math.sin(t * Math.PI * 2) * Math.exp(-t * 4.0) * this.settleTiltAngle;

        this.position.x = MathUtils.lerp(this.settleStartPos.x, this.settleEndPos.x, t);
        this.position.z = MathUtils.lerp(this.settleStartPos.z, this.settleEndPos.z, t);
        this.position.y = MathUtils.lerp(this.settleStartPos.y, this.settleEndPos.y, t) + bounce;

        this.rotation.x = MathUtils.lerp(this.settleStartRot.x, this.settleEndRot.x, t);
        this.rotation.y = MathUtils.lerp(this.settleStartRot.y, this.settleEndRot.y, t);
        this.rotation.z = MathUtils.lerp(this.settleStartRot.z, this.settleEndRot.z, t);

        this.visualRoot.rotation.z = tilt;
      }
    }

    // 4. Rebound Animation (return to previous valid position with a subtle wobble)
    if (this.isRebounding) {
      this.reboundProgress += delta / 0.40;

      if (this.reboundProgress >= 1.0) {
        this.position.copy(this.previousValidPosition);
        this.rotation.copy(this.previousValidRotation);
        this.visualRoot.rotation.set(0, 0, 0);
        this.isRebounding = false;
      } else {
        const t = this.reboundProgress;
        const wobble = Math.sin(t * Math.PI * 4) * Math.exp(-t * 4.0) * 0.05;

        this.position.x = MathUtils.lerp(this.reboundStartPos.x, this.previousValidPosition.x, t);
        this.position.z = MathUtils.lerp(this.reboundStartPos.z, this.previousValidPosition.z, t);
        this.position.y = MathUtils.lerp(this.reboundStartPos.y, this.previousValidPosition.y, t) + Math.abs(wobble);

        this.visualRoot.rotation.z = wobble * 0.35;
      }
    }

    // 5. Skateboard deck rocking
    if (this.isRocking) {
      this.rockTime += delta;
      if (this.rockTime >= this.rockDuration) {
        this.visualRoot.rotation.z = 0;
        this.isRocking = false;
      } else {
        const t = this.rockTime;
        // Damped harmonic roll oscillation (polyurethane truck bushing behavior)
        const roll = Math.sin(t * 16.0) * Math.exp(-t * 6.5) * this.rockAmp;
        this.visualRoot.rotation.z = roll;
      }
    }

    // 6. Plant foliage secondary inertia sway
    if (this.isPlant && this.leafMeshes.length > 0) {
      this.leafSwayTarget.x = MathUtils.damp(this.leafSwayTarget.x, 0, 4.0, delta);
      this.leafSwayTarget.y = MathUtils.damp(this.leafSwayTarget.y, 0, 4.0, delta);

      this.leafSwayCurrent.x = MathUtils.damp(this.leafSwayCurrent.x, this.leafSwayTarget.x, 8.0, delta);
      this.leafSwayCurrent.y = MathUtils.damp(this.leafSwayCurrent.y, this.leafSwayTarget.y, 8.0, delta);

      for (let i = 0; i < this.leafMeshes.length; i++) {
        const leaf = this.leafMeshes[i];
        const phase = (i * 0.7);
        leaf.rotation.x += Math.sin(phase) * this.leafSwayCurrent.y * 0.15;
        leaf.rotation.z += Math.cos(phase) * this.leafSwayCurrent.x * 0.15;
      }
    }
  }
}
