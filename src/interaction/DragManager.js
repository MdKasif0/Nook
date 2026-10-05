/**
 * Nook 3D - DragManager
 * Tactile physical 3D drag-and-drop controller.
 * Moves objects across room surfaces with smooth elevation lift and settling physics.
 */

import * as THREE from 'three';

export class DragManager {
  constructor(domElement, cameraInstance, raycastManager, placementManager) {
    this.domElement = domElement;
    this.cameraInstance = cameraInstance;
    this.raycastManager = raycastManager;
    this.placementManager = placementManager;

    this.draggedObject = null;
    this.isDragging = false;
    this.pointerDownPos = { x: 0, y: 0 };
    this.dragThreshold = 4; // pixels
    this.potentialTarget = null;
    this.initialHitPoint = new THREE.Vector3();

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
    // Only primary button initiates drag
    if (event.button !== 0) return;

    this.pointerDownPos = { x: event.clientX, y: event.clientY };

    const hit = this.raycastManager.getIntersectedObject();
    if (hit && hit.interactiveObject && hit.interactiveObject.isDraggable) {
      this.potentialTarget = hit.interactiveObject;
      this.initialHitPoint.copy(hit.hitPoint);
    } else {
      this.potentialTarget = null;
    }
  }

  onPointerMove(event) {
    if (!this.potentialTarget) return;

    const dx = event.clientX - this.pointerDownPos.x;
    const dy = event.clientY - this.pointerDownPos.y;
    const dist = Math.hypot(dx, dy);

    if (!this.isDragging && dist > this.dragThreshold) {
      // Start drag
      this.isDragging = true;
      this.draggedObject = this.potentialTarget;
      this.cameraInstance.controls.enabled = false;
      this.domElement.style.cursor = 'grabbing';

      this.draggedObject.onDragStart(this.initialHitPoint);

      if (this.onDragStartCallback) {
        this.onDragStartCallback(this.draggedObject);
      }
    }

    if (this.isDragging && this.draggedObject) {
      // Cast ray to horizontal plane at object's approximate current height
      const targetPos = this.raycastManager.getFloorIntersection(this.draggedObject.position.y);
      if (targetPos) {
        const snapped = this.placementManager.clampAndSnapPosition(targetPos);
        this.draggedObject.onDragUpdate(snapped.position);
      }
    }
  }

  onPointerUp(event) {
    if (this.isDragging && this.draggedObject) {
      // Compute final resting surface height
      const finalResult = this.placementManager.clampAndSnapPosition(this.draggedObject.position);
      this.draggedObject.onDragEnd(finalResult.position);

      this.cameraInstance.controls.enabled = true;
      this.domElement.style.cursor = 'default';

      if (this.onDragEndCallback) {
        this.onDragEndCallback(this.draggedObject, finalResult);
      }

      this.isDragging = false;
      this.draggedObject = null;
    }

    this.potentialTarget = null;
  }
}
