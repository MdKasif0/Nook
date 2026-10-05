/**
 * Nook 3D - SelectionManager
 * Manages active object selection, keyboard navigation, focus framing, deselection,
 * and keyboard transformations:
 * - Arrow keys: small movement (0.05)
 * - Shift + Arrow: larger movement (0.20)
 * - R: rotate 45 degrees
 * - Escape: deselect
 * - Cmd/Ctrl + Z: undo
 * - Delete / Backspace: delete if allowed
 */

import * as THREE from 'three';

export class SelectionManager {
  constructor(domElement, cameraInstance, raycastManager, dragManager, objectManager, surfaceManager = null, roomState = null) {
    this.domElement = domElement;
    this.cameraInstance = cameraInstance;
    this.raycastManager = raycastManager;
    this.dragManager = dragManager;
    this.objectManager = objectManager;
    this.surfaceManager = surfaceManager;
    this.roomState = roomState;

    this.selectedObject = null;
    this.onSelectionChange = null;

    this.initListeners();
  }

  initListeners() {
    this.domElement.addEventListener('click', this.onClick.bind(this));
    this.domElement.addEventListener('dblclick', this.onDoubleClick.bind(this));
    window.addEventListener('keydown', this.onKeyDown.bind(this));
  }

  onClick(event) {
    // If user just finished dragging, ignore click selection
    if (this.dragManager && this.dragManager.isDragging) return;

    const hit = this.raycastManager.getIntersectedObject();
    if (hit && hit.interactiveObject) {
      this.select(hit.interactiveObject);
    } else {
      this.deselect();
    }
  }

  onDoubleClick(event) {
    const hit = this.raycastManager.getIntersectedObject();
    if (hit && hit.interactiveObject) {
      // Focus camera on selected object
      this.select(hit.interactiveObject);
      this.cameraInstance.focusOn(hit.interactiveObject.position);
    } else {
      // Double click empty space resets camera framing
      this.deselect();
      this.cameraInstance.resetCamera ? this.cameraInstance.resetCamera() : this.cameraInstance.resetToDefault();
    }
  }

  onKeyDown(event) {
    // Ignore input if user is typing in a textarea or text input
    if (event.target.tagName === 'INPUT' || event.target.tagName === 'TEXTAREA') return;

    // 1. Undo (Cmd+Z or Ctrl+Z)
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'z') {
      event.preventDefault();
      if (this.roomState) {
        const undone = this.roomState.undo();
        if (undone && undone.object) {
          this.select(undone.object);
        }
      }
      return;
    }

    // 2. Escape: Deselect and reset camera focus
    if (event.key === 'Escape') {
      this.deselect();
      return;
    }

    // 3. Tab: Cycle through interactive objects
    if (event.key === 'Tab') {
      event.preventDefault();
      this.cycleSelection(event.shiftKey ? -1 : 1);
      return;
    }

    if (!this.selectedObject) return;

    // 4. Rotation (R key)
    if (event.key === 'r' || event.key === 'R') {
      if (this.selectedObject.isRotatable) {
        event.preventDefault();
        const prevRot = this.selectedObject.rotation.clone();

        this.selectedObject.rotateBy(Math.PI * 0.25); // 45 degrees

        if (this.roomState) {
          this.roomState.pushUndo({
            type: 'rotate',
            objectId: this.selectedObject.itemId,
            previousRotation: prevRot,
            newRotation: this.selectedObject.rotation.clone()
          });
          this.roomState.saveState();
        }
      }
      return;
    }

    // 5. Delete (Delete or Backspace)
    if (event.key === 'Delete' || event.key === 'Backspace') {
      if (this.selectedObject.isDeletable) {
        event.preventDefault();
        const toDelete = this.selectedObject;

        if (this.roomState) {
          this.roomState.pushUndo({
            type: 'delete',
            objectId: toDelete.itemId,
            objectInstance: toDelete,
            previousPosition: toDelete.position.clone(),
            previousRotation: toDelete.rotation.clone()
          });
        }

        this.deselect();
        this.objectManager.removeObject(toDelete.itemId);
        if (this.roomState) {
          this.roomState.saveState();
        }
      }
      return;
    }

    // 6. Arrow Keys (Nudge movement: small = 0.05, Shift = 0.20)
    if (['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown'].includes(event.key)) {
      if (!this.selectedObject.isMovable) return;
      event.preventDefault();

      const step = event.shiftKey ? 0.20 : 0.05;
      let dx = 0;
      let dz = 0;

      if (event.key === 'ArrowLeft') dx = -step;
      if (event.key === 'ArrowRight') dx = step;
      if (event.key === 'ArrowUp') dz = -step;
      if (event.key === 'ArrowDown') dz = step;

      const prevPos = this.selectedObject.position.clone();
      const prevRot = this.selectedObject.rotation.clone();
      const targetPos = prevPos.clone();
      targetPos.x += dx;
      targetPos.z += dz;

      if (this.surfaceManager) {
        const radius = this.selectedObject.collisionRadius || 0.15;
        const clamped = this.surfaceManager.clampToRoom(targetPos, radius);
        const surfaceResult = this.surfaceManager.findSurface(
          clamped.x,
          clamped.y,
          clamped.z,
          this.selectedObject.objectType
        );

        const allObjects = this.objectManager.getAllObjects();
        const collision = this.surfaceManager.checkCollision(
          this.selectedObject,
          surfaceResult.position,
          allObjects,
          Math.max(0.18, radius)
        );

        if (surfaceResult.isValid && !collision.hasCollision) {
          this.selectedObject.position.copy(surfaceResult.position);
          this.selectedObject.previousValidPosition.copy(surfaceResult.position);

          if (this.roomState) {
            this.roomState.pushUndo({
              type: 'move',
              objectId: this.selectedObject.itemId,
              previousPosition: prevPos,
              previousRotation: prevRot,
              newPosition: surfaceResult.position.clone(),
              newRotation: this.selectedObject.rotation.clone()
            });
            this.roomState.saveState();
          }
        } else {
          // Play subtle collision / invalid nudge feedback
          this.selectedObject.playInvalidRebound();
        }
      } else {
        this.selectedObject.position.copy(targetPos);
      }
    }
  }

  select(object) {
    if (this.selectedObject === object) return;

    if (this.selectedObject) {
      this.selectedObject.onDeselect();
    }

    this.selectedObject = object;
    if (this.selectedObject) {
      this.selectedObject.onSelect();
    }

    if (this.onSelectionChange) {
      this.onSelectionChange(this.selectedObject);
    }
  }

  deselect() {
    if (!this.selectedObject) return;
    this.selectedObject.onDeselect();
    this.selectedObject = null;

    if (this.onSelectionChange) {
      this.onSelectionChange(null);
    }
  }

  cycleSelection(direction = 1) {
    const all = this.objectManager.getAllObjects().filter(o => o.isSelectable);
    if (all.length === 0) return;

    let index = all.indexOf(this.selectedObject);
    if (index === -1) {
      index = direction > 0 ? 0 : all.length - 1;
    } else {
      index = (index + direction + all.length) % all.length;
    }

    this.select(all[index]);
    this.cameraInstance.focusOn(all[index].position);
  }
}

