/**
 * Nook 3D - RaycastManager
 * High-performance pointer tracking and raycasting for hover, selection, and drag operations.
 * Tracks pointerdown, pointermove, pointerup, pointerenter, and pointerleave.
 */

import * as THREE from 'three';

export class RaycastManager {
  constructor(domElement, cameraInstance, objectManager) {
    this.domElement = domElement;
    this.cameraInstance = cameraInstance;
    this.objectManager = objectManager;

    this.raycaster = new THREE.Raycaster();
    this.pointer = new THREE.Vector2(-1000, -1000);
    this.rawPointer = { x: 0, y: 0 };

    this.hoveredObject = null;
    this.isPointerDown = false;
    this.isPointerInside = false;

    // Callbacks & Event Hooks
    this.onHoverChange = null;
    this.onPointerDownEvent = null;
    this.onPointerUpEvent = null;
    this.onPointerEnterEvent = null;
    this.onPointerLeaveEvent = null;

    this.initListeners();
  }

  initListeners() {
    this.domElement.addEventListener('pointerenter', this.onPointerEnter.bind(this));
    this.domElement.addEventListener('pointerleave', this.onPointerLeave.bind(this));
    this.domElement.addEventListener('pointerdown', this.onPointerDown.bind(this));
    this.domElement.addEventListener('pointermove', this.onPointerMove.bind(this));
    window.addEventListener('pointerup', this.onPointerUp.bind(this));
  }

  updatePointerCoordinates(event) {
    const rect = this.domElement.getBoundingClientRect();
    this.rawPointer.x = event.clientX;
    this.rawPointer.y = event.clientY;

    this.pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this.pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
  }

  onPointerEnter(event) {
    this.isPointerInside = true;
    this.updatePointerCoordinates(event);
    if (this.onPointerEnterEvent) this.onPointerEnterEvent(event);
  }

  onPointerLeave(event) {
    this.isPointerInside = false;
    this.pointer.set(-1000, -1000);

    if (this.hoveredObject) {
      this.hoveredObject.onHoverExit();
      this.hoveredObject = null;
      this.domElement.style.cursor = 'default';
      if (this.onHoverChange) this.onHoverChange(null);
    }

    if (this.onPointerLeaveEvent) this.onPointerLeaveEvent(event);
  }

  onPointerDown(event) {
    this.isPointerDown = true;
    this.updatePointerCoordinates(event);
    if (this.onPointerDownEvent) this.onPointerDownEvent(event);
  }

  onPointerMove(event) {
    this.updatePointerCoordinates(event);
  }

  onPointerUp(event) {
    this.isPointerDown = false;
    if (this.onPointerUpEvent) this.onPointerUpEvent(event);
  }

  /**
   * Raycasts against registered interactive objects.
   * Finds the uppermost root InteractiveObject ancestor.
   */
  getIntersectedObject() {
    if (this.pointer.x < -1 || this.pointer.x > 1 || this.pointer.y < -1 || this.pointer.y > 1) {
      return null;
    }

    this.raycaster.setFromCamera(this.pointer, this.cameraInstance.camera);
    const candidateMeshes = this.objectManager.getRaycastMeshes();
    const hits = this.raycaster.intersectObjects(candidateMeshes, false);

    if (hits.length > 0) {
      for (const hit of hits) {
        let current = hit.object;
        while (current) {
          if (current.userData && current.userData.isInteractiveObject) {
            return {
              interactiveObject: current.userData.instance,
              hitPoint: hit.point,
              normal: hit.face ? hit.face.normal : new THREE.Vector3(0, 1, 0),
              distance: hit.distance
            };
          }
          current = current.parent;
        }
      }
    }
    return null;
  }

  /**
   * Casts ray against a horizontal plane at specified Y height to get 3D world target for dragging.
   */
  getFloorIntersection(planeY = 0) {
    this.raycaster.setFromCamera(this.pointer, this.cameraInstance.camera);
    const plane = new THREE.Plane(new THREE.Vector3(0, 1, 0), -planeY);
    const target = new THREE.Vector3();
    const hit = this.raycaster.ray.intersectPlane(plane, target);
    return hit ? target : null;
  }

  /**
   * Updates hover states smoothly when not dragging.
   */
  update() {
    if (!this.isPointerInside) return;

    const result = this.getIntersectedObject();
    const newHover = result ? result.interactiveObject : null;

    if (newHover !== this.hoveredObject) {
      if (this.hoveredObject) {
        this.hoveredObject.onHoverExit();
      }
      if (newHover) {
        newHover.onHoverEnter();
        this.domElement.style.cursor = 'pointer';
      } else {
        this.domElement.style.cursor = 'default';
      }

      this.hoveredObject = newHover;
      if (this.onHoverChange) {
        this.onHoverChange(newHover);
      }
    }
  }
}

