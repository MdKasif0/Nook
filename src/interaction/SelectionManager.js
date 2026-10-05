/**
 * Nook 3D - SelectionManager
 * Manages active object selection, keyboard navigation, focus framing, and deselection.
 */

export class SelectionManager {
  constructor(domElement, cameraInstance, raycastManager, dragManager, objectManager) {
    this.domElement = domElement;
    this.cameraInstance = cameraInstance;
    this.raycastManager = raycastManager;
    this.dragManager = dragManager;
    this.objectManager = objectManager;

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
    if (this.dragManager.isDragging) return;

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
      this.cameraInstance.resetToDefault();
    }
  }

  onKeyDown(event) {
    if (event.key === 'Escape') {
      this.deselect();
      this.cameraInstance.resetToDefault();
    } else if (event.key === 'Tab') {
      event.preventDefault();
      this.cycleSelection(event.shiftKey ? -1 : 1);
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
