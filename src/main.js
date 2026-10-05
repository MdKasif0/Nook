/**
 * Nook 3D - Main Application Entry Point
 * Initializes high-fidelity Three.js WebGLRenderer, isometric-leaning Camera,
 * Lighting, Architecture, Interactive Objects, and Gesture/Pointer systems.
 */

import * as THREE from 'three';
import { LIGHTING_CONFIG, PALETTE } from './utils/Constants.js';
import { Camera } from './scene/Camera.js';
import { RoomScene } from './scene/RoomScene.js';
import { PlacementManager } from './objects/PlacementManager.js';
import { ObjectManager } from './objects/ObjectManager.js';
import { CookieController } from './cookie/CookieController.js';
import { COOKIE_LOCATIONS } from './cookie/CookieNavigation.js';
import { RaycastManager } from './interaction/RaycastManager.js';
import { DragManager } from './interaction/DragManager.js';
import { SelectionManager } from './interaction/SelectionManager.js';
import { RoomState } from './persistence/RoomState.js';
import { ContextMenu } from './ui/ContextMenu.js';
import { ObjectInspector } from './ui/ObjectInspector.js';

class NookApplication {
  constructor() {
    this.canvas = document.getElementById('nook-canvas');
    this.uiContainer = document.getElementById('nook-ui');
    this.clock = new THREE.Clock();

    this.initRenderer();
    this.initScene();
    this.initSubsystems();
    this.initUI();
    this.initNativeBridge();

    this.onResize();
    window.addEventListener('resize', this.onResize.bind(this));

    // Start render loop
    this.animate = this.animate.bind(this);
    requestAnimationFrame(this.animate);

    console.log('🌿 Nook 3D Interactive Miniature Room Initialized');
  }

  initRenderer() {
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: true,
      powerPreference: 'high-performance',
      stencil: false,
      depth: true
    });

    // Retina crispness clamped to 2 for optimal thermals on Apple Silicon
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.setSize(window.innerWidth, window.innerHeight);

    // Warm, filmic tone mapping & color space suitable for warm miniature reference
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = LIGHTING_CONFIG.exposure;

    // Soft PCF Shadow Maps
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  }

  initScene() {
    // 1. Camera System
    this.cameraInstance = new Camera(this.canvas);

    // 2. Room Scene & Architecture
    this.roomScene = new RoomScene();

    // 3. Placement Manager (Droppable / Walkable surfaces)
    this.placementManager = new PlacementManager(this.roomScene);

    // 4. Object Manager (Tactile interactive thoughts and room props)
    this.objectManager = new ObjectManager(this.roomScene, this.placementManager);

    // 5. Cookie the Calico Companion Cat
    this.cookie = new CookieController(this.roomScene);
    this.objectManager.registerObject(this.cookie);
  }

  initSubsystems() {
    // 1. Raycast Manager
    this.raycastManager = new RaycastManager(this.canvas, this.cameraInstance, this.objectManager);

    // 2. Drag Manager
    this.dragManager = new DragManager(
      this.canvas,
      this.cameraInstance,
      this.raycastManager,
      this.placementManager
    );

    // 3. Selection Manager
    this.selectionManager = new SelectionManager(
      this.canvas,
      this.cameraInstance,
      this.raycastManager,
      this.dragManager,
      this.objectManager
    );

    // 4. Room State Persistence
    this.roomState = new RoomState(this.objectManager, this.roomScene.lighting, this.cookie);

    // Auto-save on drag completion
    this.dragManager.onDragEndCallback = () => {
      this.roomState.saveState();
    };
  }

  initUI() {
    // 1. Object Inspector
    this.inspector = new ObjectInspector(this.uiContainer, {
      onDeselect: () => this.selectionManager.deselect(),
      onFocus: obj => this.cameraInstance.focusOn(obj.position),
      onPet: () => this.cookie.behavior.pet()
    });

    this.selectionManager.onSelectionChange = obj => {
      this.inspector.show(obj);
    };

    // 2. Context Menu
    this.contextMenu = new ContextMenu(this.uiContainer);

    this.canvas.addEventListener('contextmenu', e => {
      e.preventDefault();
      const hit = this.raycastManager.getIntersectedObject();

      if (hit && hit.interactiveObject) {
        const obj = hit.interactiveObject;
        if (obj.id === 'prop_cookie') {
          // Cookie Specific Context Actions
          this.contextMenu.show(e.clientX, e.clientY, [
            {
              label: 'Pet Cookie 🐾',
              icon: '❤️',
              action: () => this.cookie.behavior.pet()
            },
            { separator: true },
            {
              label: 'Call to Bed (Sun Spot)',
              icon: '🛏️',
              action: () => {
                this.cookie.position.copy(COOKIE_LOCATIONS.BED_SUN_SPOT);
                this.cookie.behavior.setMood('sleeping');
              }
            },
            {
              label: 'Call to Desk',
              icon: '🖥️',
              action: () => {
                this.cookie.position.copy(COOKIE_LOCATIONS.DESK_COMPANION);
                this.cookie.behavior.setMood('idle');
              }
            },
            {
              label: 'Call to Pouf',
              icon: '🛋️',
              action: () => {
                this.cookie.position.copy(COOKIE_LOCATIONS.POUF_LOUNGE);
                this.cookie.behavior.setMood('idle');
              }
            }
          ]);
        } else {
          // General Object Context Actions
          this.contextMenu.show(e.clientX, e.clientY, [
            {
              label: `Focus "${obj.name}"`,
              icon: '🔍',
              action: () => {
                this.selectionManager.select(obj);
                this.cameraInstance.focusOn(obj.position);
              }
            },
            {
              label: 'Inspect Details',
              icon: '📄',
              action: () => {
                this.selectionManager.select(obj);
              }
            },
            { separator: true },
            {
              label: 'Move to Desk Center',
              icon: '📥',
              action: () => {
                obj.position.set(-1.0, 0.73, -0.6);
                this.roomState.saveState();
              }
            },
            {
              label: 'Move to Bed',
              icon: '🛏️',
              action: () => {
                obj.position.set(0.65, 0.52, -0.5);
                this.roomState.saveState();
              }
            }
          ]);
        }
      } else {
        // Room Context Menu (Empty Space)
        this.contextMenu.show(e.clientX, e.clientY, [
          {
            label: 'Toggle Desk Lamp',
            icon: '💡',
            action: () => {
              this.roomScene.lighting.toggleDeskLamp();
              this.roomState.saveState();
            }
          },
          {
            label: 'Toggle Accent Lights',
            icon: '✨',
            action: () => this.roomScene.lighting.toggleAccentLights()
          },
          { separator: true },
          {
            label: 'Reset Camera Framing',
            icon: '🎥',
            action: () => {
              this.selectionManager.deselect();
              this.cameraInstance.resetToDefault();
            }
          }
        ]);
      }
    });

    // 3. Subtle Floating Ambient Pill Bar at top
    this.initAmbientControls();
  }

  initAmbientControls() {
    const pill = document.createElement('div');
    pill.className = 'nook-ambient-bar';
    pill.innerHTML = `
      <div class="nook-brand">
        <span class="nook-brand-icon">🌱</span>
        <span class="nook-brand-name">Nook</span>
      </div>
      <div class="nook-pill-divider"></div>
      <button class="nook-pill-btn" id="btn-lamp" title="Toggle Desk Lamp">💡 Lamp</button>
      <button class="nook-pill-btn" id="btn-cookie" title="Pet Cookie">🐾 Pet Cookie</button>
      <button class="nook-pill-btn" id="btn-reset" title="Reset View (Esc)">🎥 Reset View</button>
    `;
    this.uiContainer.appendChild(pill);

    pill.querySelector('#btn-lamp').addEventListener('click', () => {
      const isOn = this.roomScene.lighting.toggleDeskLamp();
      this.roomState.saveState();
      pill.querySelector('#btn-lamp').classList.toggle('active', isOn);
    });

    pill.querySelector('#btn-cookie').addEventListener('click', () => {
      this.cookie.behavior.pet();
    });

    pill.querySelector('#btn-reset').addEventListener('click', () => {
      this.selectionManager.deselect();
      this.cameraInstance.resetToDefault();
    });
  }

  initNativeBridge() {
    // Expose clean JavaScript API for macOS WKWebView
    window.NookBridge = {
      petCookie: () => this.cookie.behavior.pet(),
      toggleLamp: () => this.roomScene.lighting.toggleDeskLamp(),
      resetCamera: () => this.cameraInstance.resetToDefault(),
      selectObject: id => {
        const obj = this.objectManager.getObjectById(id);
        if (obj) {
          this.selectionManager.select(obj);
          this.cameraInstance.focusOn(obj.position);
        }
      },
      exportState: () => this.roomState.state
    };
  }

  onResize() {
    const width = window.innerWidth;
    const height = window.innerHeight;

    this.cameraInstance.resize(width, height);
    this.renderer.setSize(width, height);
  }

  animate() {
    requestAnimationFrame(this.animate);

    const delta = this.clock.getDelta();

    // 1. Raycast Hover Updates
    if (!this.dragManager.isDragging) {
      this.raycastManager.update();
    }

    // 2. Camera Controls & Interpolations
    this.cameraInstance.update(delta);

    // 3. Room Scene & Lighting
    this.roomScene.update(delta);

    // 4. Interactive Objects
    this.objectManager.update(delta);

    // 5. Render Scene
    this.renderer.render(this.roomScene.scene, this.cameraInstance.camera);
  }
}

// Bootstrap on DOM readiness
window.addEventListener('DOMContentLoaded', () => {
  window.nookApp = new NookApplication();
});
