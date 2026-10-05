/**
 * Nook 3D - RoomState Persistence
 * Local-first persistence engine saving object transforms, lamp states, and Cookie interactions.
 * Bridges seamlessly with localStorage and native macOS Swift WKWebView handlers.
 */

const STORAGE_KEY = 'nook_room_state_v1';

export class RoomState {
  constructor(objectManager, lighting, cookieController) {
    this.objectManager = objectManager;
    this.lighting = lighting;
    this.cookieController = cookieController;

    this.state = {
      version: 1,
      objects: {},
      isDeskLampOn: true,
      cookiePetCount: 0,
      updatedAt: new Date().toISOString()
    };

    this.loadState();
  }

  loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        this.state = { ...this.state, ...parsed };
        this.applyState();
      }
    } catch (e) {
      console.warn('Failed to load room state from localStorage:', e);
    }
  }

  applyState() {
    // 1. Apply lamp state
    if (this.state.isDeskLampOn !== undefined && this.lighting) {
      if (this.lighting.isDeskLampOn !== this.state.isDeskLampOn) {
        this.lighting.toggleDeskLamp();
      }
    }

    // 2. Restore object positions
    if (this.state.objects && this.objectManager) {
      for (const [id, record] of Object.entries(this.state.objects)) {
        const obj = this.objectManager.getObjectById(id);
        if (obj && record.position) {
          obj.position.set(record.position.x, record.position.y, record.position.z);
          if (record.rotationY !== undefined) {
            obj.rotation.y = record.rotationY;
          }
        }
      }
    }
  }

  saveState() {
    try {
      // Collect object transforms
      const objectsRecord = {};
      for (const obj of this.objectManager.getAllObjects()) {
        objectsRecord[obj.id] = {
          position: {
            x: Number(obj.position.x.toFixed(3)),
            y: Number(obj.position.y.toFixed(3)),
            z: Number(obj.position.z.toFixed(3))
          },
          rotationY: Number(obj.rotation.y.toFixed(3))
        };
      }

      this.state.objects = objectsRecord;
      this.state.isDeskLampOn = this.lighting ? this.lighting.isDeskLampOn : true;
      this.state.updatedAt = new Date().toISOString();

      localStorage.setItem(STORAGE_KEY, JSON.stringify(this.state));

      // Notify native macOS wrapper if running inside WKWebView
      this.notifyNativeWrapper('roomStateSaved', this.state);
    } catch (e) {
      console.warn('Failed to save room state:', e);
    }
  }

  notifyNativeWrapper(action, payload) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.nookBridge) {
      window.webkit.messageHandlers.nookBridge.postMessage({
        action,
        payload
      });
    }
  }
}
