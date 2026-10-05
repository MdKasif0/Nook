/**
 * Nook 3D - InteractiveObject
 * Base class for all tactile interactive entities (thoughts, props, movable decor)
 * living inside the 3D diorama room.
 */

import * as THREE from 'three';
import { MathUtils } from '../utils/MathUtils.js';

export class InteractiveObject extends THREE.Group {
  constructor(options = {}) {
    super();

    this.id = options.id || THREE.MathUtils.generateUUID();
    this.name = options.name || 'Interactive Object';
    this.category = options.category || 'thought';
    this.objectType = options.objectType || 'pebble';
    this.isDraggable = options.isDraggable !== undefined ? options.isDraggable : true;
    this.isSelectable = options.isSelectable !== undefined ? options.isSelectable : true;

    // Interaction states
    this.isHovered = false;
    this.isSelected = false;
    this.isDragging = false;

    // Transform tracking
    this.baseScale = new THREE.Vector3(1, 1, 1);
    this.targetScale = new THREE.Vector3(1, 1, 1);
    this.settlePosition = new THREE.Vector3();
    this.dragOffset = new THREE.Vector3();

    // Visual root group inside this container
    this.visualRoot = new THREE.Group();
    this.visualRoot.name = 'VisualRoot';
    this.add(this.visualRoot);

    // Tag for raycasting identification
    this.userData.isInteractiveObject = true;
    this.userData.instance = this;

    // Settling animation state
    this.isSettling = false;
    this.settleTimer = 0;
    this.settleStartPos = new THREE.Vector3();
    this.settleEndPos = new THREE.Vector3();
  }

  /**
   * Called when pointer enters the object's hit volume.
   */
  onHoverEnter() {
    if (this.isHovered) return;
    this.isHovered = true;
    this.targetScale.set(1.06, 1.06, 1.06);
  }

  /**
   * Called when pointer leaves the object's hit volume.
   */
  onHoverExit() {
    if (!this.isHovered) return;
    this.isHovered = false;
    if (!this.isSelected) {
      this.targetScale.copy(this.baseScale);
    }
  }

  /**
   * Called when object is selected by user.
   */
  onSelect() {
    this.isSelected = true;
    this.targetScale.set(1.10, 1.10, 1.10);
  }

  /**
   * Called when object is deselected.
   */
  onDeselect() {
    this.isSelected = false;
    this.targetScale.copy(this.baseScale);
  }

  /**
   * Called when user initiates dragging.
   */
  onDragStart(hitPoint) {
    this.isDragging = true;
    this.isSettling = false;
    this.dragOffset.copy(this.position).sub(hitPoint);
    this.targetScale.set(1.12, 1.12, 1.12);
  }

  /**
   * Called on every pointer drag move with the target surface coordinate.
   */
  onDragUpdate(targetPosition) {
    // Elevate slightly while dragging for tactile hover feel
    const elevatedPos = targetPosition.clone();
    elevatedPos.y += 0.06;
    this.position.copy(elevatedPos);
  }

  /**
   * Called when user releases drag to physically settle onto surface.
   */
  onDragEnd(finalSurfacePosition) {
    this.isDragging = false;
    this.targetScale.copy(this.isSelected ? new THREE.Vector3(1.1, 1.1, 1.1) : this.baseScale);

    // Start physical settling bounce
    this.isSettling = true;
    this.settleTimer = 0;
    this.settleStartPos.copy(this.position);
    this.settleEndPos.copy(finalSurfacePosition);
  }

  /**
   * Frame update for springy scale and settling physics.
   */
  update(delta) {
    // 1. Smooth scale interpolation
    this.visualRoot.scale.x = MathUtils.damp(this.visualRoot.scale.x, this.targetScale.x, 14, delta);
    this.visualRoot.scale.y = MathUtils.damp(this.visualRoot.scale.y, this.targetScale.y, 14, delta);
    this.visualRoot.scale.z = MathUtils.damp(this.visualRoot.scale.z, this.targetScale.z, 14, delta);

    // 2. Settle bounce animation
    if (this.isSettling) {
      this.settleTimer += delta * 4.5;
      if (this.settleTimer >= 1.0) {
        this.position.copy(this.settleEndPos);
        this.isSettling = false;
      } else {
        const t = this.settleTimer;
        // Dampened vertical sine bounce
        const bounce = Math.sin(t * Math.PI) * Math.exp(-t * 3.0) * 0.04;
        this.position.x = MathUtils.lerp(this.settleStartPos.x, this.settleEndPos.x, t);
        this.position.z = MathUtils.lerp(this.settleStartPos.z, this.settleEndPos.z, t);
        this.position.y = MathUtils.lerp(this.settleStartPos.y, this.settleEndPos.y, t) + bounce;
      }
    }
  }
}
