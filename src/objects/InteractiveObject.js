/**
 * Nook 3D - InteractiveObject
 * Base physical entity class for all movable, static, and special props in the diorama.
 * Implements physically based lift, subtle warm highlights, spring settling physics,
 * rebound on invalid placement, and transform history.
 */

import * as THREE from 'three';
import { MathUtils } from '../utils/MathUtils.js';

export class InteractiveObject extends THREE.Group {
  constructor(options = {}) {
    super();

    this.itemId = options.id || THREE.MathUtils.generateUUID();
    this.name = options.name || 'Interactive Object';
    this.accessibilityLabel = options.accessibilityLabel || this.name;
    this.category = options.category || 'movable'; // 'movable' | 'static' | 'special'
    this.objectType = options.objectType || 'prop'; // 'plant', 'book', 'lamp', 'skateboard', etc.

    // Permissions
    this.isMovable = options.isMovable !== undefined ? options.isMovable : (this.category !== 'static');
    this.isDraggable = this.isMovable;
    this.isSelectable = options.isSelectable !== undefined ? options.isSelectable : true;
    this.isRotatable = options.isRotatable !== undefined ? options.isRotatable : this.isMovable;
    this.isDeletable = options.isDeletable !== undefined ? options.isDeletable : (this.category === 'movable');
    this.isDuplicatable = options.isDuplicatable !== undefined ? options.isDuplicatable : (this.category === 'movable');

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
    this.settleTiltAngle = 0;

    this.isRebounding = false;
    this.reboundProgress = 0;
    this.reboundStartPos = new THREE.Vector3();

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

    this.targetElevation = 0.16; // Elevate during pick-up
    this.applyWarmHighlight(0x422f14);
  }

  onDragUpdate(targetPos) {
    this.position.x = targetPos.x;
    this.position.z = targetPos.z;
    this.position.y = targetPos.y;
  }

  onDragEnd(finalSurfacePosition, isValid = true) {
    this.isDragging = false;
    this.targetElevation = this.isSelected ? 0.075 : (this.isHovered ? 0.035 : 0.0);
    this.applyWarmHighlight(this.isSelected ? 0x352510 : 0x000000);

    if (isValid && finalSurfacePosition) {
      // Valid placement: Physical drop settling bounce
      this.isSettling = true;
      this.settleProgress = 0;
      this.settleStartPos.copy(this.position);
      this.settleEndPos.copy(finalSurfacePosition);
      this.settleTiltAngle = (Math.random() - 0.5) * 0.05;

      this.previousValidPosition.copy(finalSurfacePosition);
      this.previousValidRotation.copy(this.rotation);
    } else {
      // Invalid placement: Rebound back to previous position
      this.playInvalidRebound();
    }
  }

  /**
   * Rebounds smoothly back to previous valid position when placed on an invalid surface or in collision.
   */
  playInvalidRebound() {
    this.isRebounding = true;
    this.reboundProgress = 0;
    this.reboundStartPos.copy(this.position);
    this.targetElevation = 0.0;
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
    this.rotation.copy(this.defaultRotation);
    this.previousValidPosition.copy(this.defaultPosition);
    this.previousValidRotation.copy(this.defaultRotation);
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
   * Triggers special action (lamp toggle, record player, cat pet).
   */
  triggerSpecialAction() {
    if (typeof this.specialAction === 'function') {
      this.specialAction(this);
    }
  }

  // MARK: - Frame Update Loop

  update(delta) {
    // 1. Smooth physical elevation lerping
    this.currentElevation = MathUtils.damp(this.currentElevation, this.targetElevation, 12, delta);
    this.visualRoot.position.y = this.currentElevation;

    // 2. Physical Settling Animation (Drop onto surface)
    if (this.isSettling) {
      this.settleProgress += delta / this.settleDuration;

      if (this.settleProgress >= 1.0) {
        this.position.copy(this.settleEndPos);
        this.visualRoot.rotation.z = 0;
        this.isSettling = false;
      } else {
        const t = this.settleProgress;
        // Damped harmonic bounce
        const bounce = Math.sin(t * Math.PI) * Math.exp(-t * 4.0) * 0.08;
        const tilt = Math.sin(t * Math.PI * 2) * Math.exp(-t * 3.5) * this.settleTiltAngle;

        this.position.x = MathUtils.lerp(this.settleStartPos.x, this.settleEndPos.x, t);
        this.position.z = MathUtils.lerp(this.settleStartPos.z, this.settleEndPos.z, t);
        this.position.y = MathUtils.lerp(this.settleStartPos.y, this.settleEndPos.y, t) + bounce;

        this.visualRoot.rotation.z = tilt;
      }
    }

    // 3. Rebound Animation (return to previous valid position with a subtle wobble)
    if (this.isRebounding) {
      this.reboundProgress += delta / 0.40;

      if (this.reboundProgress >= 1.0) {
        this.position.copy(this.previousValidPosition);
        this.rotation.copy(this.previousValidRotation);
        this.visualRoot.rotation.z = 0;
        this.isRebounding = false;
      } else {
        const t = this.reboundProgress;
        const wobble = Math.sin(t * Math.PI * 4) * Math.exp(-t * 4.0) * 0.06;

        this.position.x = MathUtils.lerp(this.reboundStartPos.x, this.previousValidPosition.x, t);
        this.position.z = MathUtils.lerp(this.reboundStartPos.z, this.previousValidPosition.z, t);
        this.position.y = MathUtils.lerp(this.reboundStartPos.y, this.previousValidPosition.y, t) + Math.abs(wobble);

        this.visualRoot.rotation.z = wobble * 0.4;
      }
    }
  }
}
