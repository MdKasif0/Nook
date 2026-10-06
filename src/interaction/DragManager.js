/**
 * Nook 3D - DragManager
 * Tactile physical 3D drag-and-drop controller.
 * Moves objects across room surfaces with smooth elevation lift, room boundary clamping,
 * surface placement validation, collision avoidance, and damped harmonic drop settling physics.
 */

import * as THREE from 'three';

export class DragManager {
  constructor(domElement, cameraInstance, raycastManager, surfaceManager, objectManager, roomState = null) {
    this.domElement = domElement;
    this.cameraInstance = cameraInstance;
    this.raycastManager = raycastManager;
    this.surfaceManager = surfaceManager;
    this.objectManager = objectManager;
    this.roomState = roomState;

    this.draggedObject = null;
    this.isDragging = false;
    this.pointerDownPos = { x: 0, y: 0 };
    this.dragThreshold = 4; // pixels
    this.potentialTarget = null;
    this.initialHitPoint = new THREE.Vector3();
    this.dragOffset = new THREE.Vector3();
    this.initialObjectPos = new THREE.Vector3();
    this.initialObjectRot = new THREE.Euler();

    this.onDragStartCallback = null;
    this.onDragEndCallback = null;

    this.initListeners();
  }

  initListeners() {
    this.domElement.addEventListener('pointerdown', this.onPointerDown.bind(this));
    window.addEventListener('pointermove', this.onPointerMove.bind(this));
    window.addEventListener('pointerup', this.onPointerUp.bind(this));
  }

  onPointerDown(event) {
    // Only primary (left) button initiates drag
    if (event.button !== 0) return;

    this.pointerDownPos = { x: event.clientX, y: event.clientY };

    const hit = this.raycastManager.getIntersectedObject();
    if (hit && hit.interactiveObject && hit.interactiveObject.isDraggable) {
      this.potentialTarget = hit.interactiveObject;
      this.initialHitPoint.copy(hit.hitPoint);
      this.initialObjectPos.copy(hit.interactiveObject.position);
      this.initialObjectRot.copy(hit.interactiveObject.rotation);

      // Preserve pick-up point offset relative to object root
      this.dragOffset.set(
        hit.interactiveObject.position.x - hit.hitPoint.x,
        0,
        hit.interactiveObject.position.z - hit.hitPoint.z
      );
    } else {
      this.potentialTarget = null;
    }
  }

  onPointerMove(event) {
    if (!this.potentialTarget) return;

    const dx = event.clientX - this.pointerDownPos.x;
    const dy = event.clientY - this.pointerDownPos.y;
    const dist = Math.hypot(dx, dy);

    // Initiate drag once moved beyond threshold
    if (!this.isDragging && dist > this.dragThreshold) {
      this.isDragging = true;
      this.draggedObject = this.potentialTarget;

      // Lock camera rotation to prevent accidental diorama rotation
      if (this.cameraInstance && this.cameraInstance.controls) {
        this.cameraInstance.controls.enabled = false;
      }
      this.domElement.style.cursor = 'grabbing';

      this.draggedObject.onDragStart(this.initialHitPoint);

      if (this.onDragStartCallback) {
        this.onDragStartCallback(this.draggedObject);
      }
    }

    if (this.isDragging && this.draggedObject) {
      // Cast ray against elevated horizontal plane
      const planeY = this.draggedObject.position.y;
      const hitPos = this.raycastManager.getFloorIntersection(planeY);

      if (hitPos) {
        // Apply pick-up offset
        const candidatePos = hitPos.clone().add(this.dragOffset);

        // Constrain strictly to room boundaries (prevent moving outside or through walls)
        const radius = this.draggedObject.collisionRadius || 0.15;
        const clampedPos = this.surfaceManager.clampToRoom(candidatePos, radius);

        // Maintain current elevation height during drag
        clampedPos.y = planeY;
        this.draggedObject.onDragUpdate(clampedPos);
      }
    }
  }

  onPointerUp(event) {
    if (this.isDragging && this.draggedObject) {
      const currentPos = this.draggedObject.position;
      const objectType = this.draggedObject.objectType;

      // 1. Surface Placement Check (boundary & allowed object type)
      const surfaceResult = this.surfaceManager.findSurface(
        currentPos.x,
        currentPos.y,
        currentPos.z,
        objectType
      );

      // 2. Collision Check (prevent unnatural overlapping with other objects on the same surface)
      const allObjects = this.objectManager ? this.objectManager.getAllObjects() : [];
      const collisionResult = this.surfaceManager.checkCollision(
        this.draggedObject,
        surfaceResult.position,
        allObjects,
        Math.max(0.20, (this.draggedObject.collisionRadius || 0.15) * 1.5)
      );

      const isValid = surfaceResult.isValid && !collisionResult.hasCollision;

      // 3. Drop settle or Invalid rebound
      if (isValid) {
        const targetRot = typeof this.draggedObject.adaptOrientationToSurface === 'function'
          ? this.draggedObject.adaptOrientationToSurface(surfaceResult.surface.id)
          : this.draggedObject.rotation.clone();

        const settlePos = surfaceResult.position.clone();
        if (this.draggedObject.objectType === 'book' && (surfaceResult.surface.id === 'shelf' || surfaceResult.surface.id.includes('shelf'))) {
          settlePos.y += 0.12;
        }

        this.draggedObject.onDragEnd(settlePos, true, targetRot);

        // Record undo action if position moved
        if (this.roomState && (this.initialObjectPos.distanceTo(settlePos) > 0.04 || !this.initialObjectRot.equals(targetRot))) {
          this.roomState.pushUndo({
            type: 'move',
            objectId: this.draggedObject.itemId,
            previousPosition: this.initialObjectPos.clone(),
            previousRotation: this.initialObjectRot.clone(),
            newPosition: settlePos.clone(),
            newRotation: targetRot.clone()
          });
        }
      } else {
        // Invalid surface or overlap -> Rebound back to previous position smoothly (object never disappears)
        this.draggedObject.onDragEnd(null, false);
      }

      // Re-enable camera controls
      if (this.cameraInstance && this.cameraInstance.controls) {
        this.cameraInstance.controls.enabled = true;
      }
      this.domElement.style.cursor = 'default';

      if (this.onDragEndCallback) {
        this.onDragEndCallback(this.draggedObject, surfaceResult, isValid);
      }

      this.isDragging = false;
      this.draggedObject = null;
    }

    this.potentialTarget = null;
  }
}

