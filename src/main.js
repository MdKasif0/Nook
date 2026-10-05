/**
 * Nook 3D - Main Application Entry Point
 * Initializes high-fidelity Three.js WebGLRenderer, isometric-leaning Camera,
 * Lighting, Architecture, Interactive Objects, and Gesture/Pointer systems.
 */

import * as THREE from 'three';
import { LIGHTING_CONFIG, PALETTE } from './utils/Constants.js';
import { Camera } from './scene/Camera.js';
import { RoomScene } from './scene/RoomScene.js';
import { SurfaceManager } from './interaction/SurfaceManager.js';
import { ObjectManager } from './objects/ObjectManager.js';
import { CookieController } from './cookie/CookieController.js';
import { COOKIE_LOCATIONS } from './cookie/CookieNavigation.js';
import { RaycastManager } from './interaction/RaycastManager.js';
import { DragManager } from './interaction/DragManager.js';
import { SelectionManager } from './interaction/SelectionManager.js';
import { RoomState } from './persistence/RoomState.js';
import { ContextMenu } from './ui/ContextMenu.js';
import { ObjectInspector } from './ui/ObjectInspector.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { VerticalTiltShiftShader } from 'three/addons/shaders/VerticalTiltShiftShader.js';
import { soundManager } from './audio/SoundManager.js';

class NookApplication {
  constructor() {
    this.canvas = document.getElementById('nook-canvas');
    this.uiContainer = document.getElementById('nook-ui');
    this.lastTime = performance.now();

    this.initRenderer();
    this.initScene();
    this.initSubsystems();
    this.initPostProcessing();
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

    // High quality soft PCF shadow maps
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  }

  initPostProcessing() {
    const width = window.innerWidth;
    const height = window.innerHeight;

    this.composer = new EffectComposer(this.renderer);

    // 1. Base Scene Render
    const renderPass = new RenderPass(this.roomScene.scene, this.cameraInstance.camera);
    this.composer.addPass(renderPass);

    // 2. Subtle Miniature Tilt-Shift / Shallow Depth of Field
    // Keeps main room interior (focus line r ~ 0.48) crisp and readable,
    // while softly blurring extreme foreground and distant ceiling beam
    this.tiltShiftPass = new ShaderPass(VerticalTiltShiftShader);
    this.tiltShiftPass.uniforms.r.value = 0.48;
    this.tiltShiftPass.uniforms.v.value = (1.0 / height) * 1.5;
    this.composer.addPass(this.tiltShiftPass);

    // 3. Filmic Color Grading Output Pass
    const outputPass = new OutputPass();
    this.composer.addPass(outputPass);
  }

  initScene() {
    // 1. Camera System
    this.cameraInstance = new Camera(this.canvas);

    // 2. Room Scene & Architecture
    this.roomScene = new RoomScene();

    // 3. Surface Manager (Physical surface bounds, snap heights, allowed object types)
    this.surfaceManager = new SurfaceManager(this.roomScene);

    // 4. Object Manager (Tactile interactive props and miniature thoughts)
    this.objectManager = new ObjectManager(this.roomScene, this.surfaceManager);

    // Register all movable and special props created by FurnitureBuilder
    if (this.roomScene.furnitureBuilder && this.roomScene.furnitureBuilder.movableProps) {
      this.objectManager.initMovableProps(this.roomScene.furnitureBuilder.movableProps);
    }

    // 5. Cookie the Calico Companion Cat
    this.cookie = new CookieController(this.roomScene);
    this.objectManager.registerObject(this.cookie);

    // Initial state: Full room with major furniture visible
    this.isArchOnly = false;
    this.roomScene.interactiveObjects.visible = true;
    this.roomScene.furniture.visible = true;
    this.roomScene.decorations.visible = true;
    this.roomScene.cookieGroup.visible = true;
  }

  initSubsystems() {
    // 1. Raycast Manager
    this.raycastManager = new RaycastManager(this.canvas, this.cameraInstance, this.objectManager);

    // 2. Room State Persistence & Undo History
    this.roomState = new RoomState(this.objectManager, this.roomScene.lighting, this.cookie);

    // 3. Drag Manager (Tactile 3D direct-manipulation controller)
    this.dragManager = new DragManager(
      this.canvas,
      this.cameraInstance,
      this.raycastManager,
      this.surfaceManager,
      this.objectManager,
      this.roomState
    );

    // 4. Selection Manager (Active focus, keyboard navigation, nudging & rotation)
    this.selectionManager = new SelectionManager(
      this.canvas,
      this.cameraInstance,
      this.raycastManager,
      this.dragManager,
      this.objectManager,
      this.surfaceManager,
      this.roomState
    );

    // Auto-save on drag completion
    this.dragManager.onDragEndCallback = (draggedObj, surfaceResult, isValid) => {
      if (isValid) {
        this.roomState.saveState();
      }
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
        this.selectionManager.select(obj);

        const menuItems = [];

        // Special Actions first if available
        if (obj.itemId === 'prop_cookie') {
          menuItems.push({
            label: 'Pet Cookie 🐾',
            icon: '❤️',
            action: () => this.cookie.behavior.pet()
          });
        } else if (obj.objectType === 'lamp') {
          const isLampOn = this.roomScene.lighting && this.roomScene.lighting.isDeskLampOn;
          menuItems.push({
            label: isLampOn ? 'Turn Off Lamp' : 'Turn On Lamp',
            icon: '💡',
            action: () => {
              if (this.roomScene && this.roomScene.lighting) {
                this.roomScene.lighting.toggleDeskLamp();
                this.roomState.saveState();
              }
            }
          });
        } else if (obj.objectType === 'record_player') {
          menuItems.push({
            label: obj.isSpinning ? 'Pause Record' : 'Play Vinyl 🎵',
            icon: '💿',
            action: () => {
              obj.triggerSpecialAction();
            }
          });
        }

        if (menuItems.length > 0) {
          menuItems.push({ separator: true });
        }

        // Standard Actions for movable objects:
        // Move
        if (obj.isMovable) {
          menuItems.push({
            label: 'Move',
            icon: '✥',
            action: () => {
              this.selectionManager.select(obj);
              obj.targetElevation = 0.12;
              setTimeout(() => { obj.targetElevation = 0.075; }, 300);
            }
          });
        }

        // Rotate
        if (obj.isRotatable) {
          menuItems.push({
            label: 'Rotate 45° (R)',
            icon: '↻',
            action: () => {
              const prevRot = obj.rotation.clone();
              obj.rotateBy(Math.PI * 0.25);
              this.roomState.pushUndo({
                type: 'rotate',
                objectId: obj.itemId,
                previousRotation: prevRot,
                newRotation: obj.rotation.clone()
              });
              this.roomState.saveState();
            }
          });
        }

        // Reset Position
        if (obj.isMovable) {
          menuItems.push({
            label: 'Reset Position',
            icon: '↺',
            action: () => {
              const prevPos = obj.position.clone();
              const prevRot = obj.rotation.clone();
              obj.resetToDefault();
              this.roomState.pushUndo({
                type: 'move',
                objectId: obj.itemId,
                previousPosition: prevPos,
                previousRotation: prevRot,
                newPosition: obj.defaultPosition.clone(),
                newRotation: obj.defaultRotation.clone()
              });
              this.roomState.saveState();
            }
          });
        }

        // Duplicate
        if (obj.isDuplicatable) {
          menuItems.push({
            label: 'Duplicate',
            icon: '⧉',
            action: () => {
              const dup = this.objectManager.duplicateObject(obj.itemId);
              if (dup) {
                this.selectionManager.select(dup);
                this.roomState.pushUndo({
                  type: 'delete',
                  objectId: dup.itemId,
                  objectInstance: dup,
                  previousPosition: dup.position.clone(),
                  previousRotation: dup.rotation.clone()
                });
                this.roomState.saveState();
              }
            }
          });
        }

        // Delete
        if (obj.isDeletable) {
          menuItems.push({ separator: true });
          menuItems.push({
            label: 'Delete',
            icon: '🗑️',
            danger: true,
            action: () => {
              this.roomState.pushUndo({
                type: 'delete',
                objectId: obj.itemId,
                objectInstance: obj,
                previousPosition: obj.position.clone(),
                previousRotation: obj.rotation.clone()
              });
              this.selectionManager.deselect();
              this.objectManager.removeObject(obj.itemId);
              this.roomState.saveState();
            }
          });
        }

        this.contextMenu.show(e.clientX, e.clientY, menuItems);
      } else {
        // Room Context Menu (Empty Space)
        const emptyItems = [
          {
            label: 'Reset Reference Camera (Esc)',
            icon: '🎥',
            action: () => {
              this.selectionManager.deselect();
              this.cameraInstance.resetCamera();
            }
          }
        ];

        if (this.roomState && this.roomState.undoStack.length > 0) {
          emptyItems.push({
            label: 'Undo (Cmd+Z)',
            icon: '↶',
            action: () => {
              const undone = this.roomState.undo();
              if (undone && undone.object) {
                this.selectionManager.select(undone.object);
              }
            }
          });
        }

        this.contextMenu.show(e.clientX, e.clientY, emptyItems);
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
      <button class="nook-pill-btn" id="btn-time" title="Cycle Daylight: Morning / Evening / Night">☀️ Morning</button>
      <button class="nook-pill-btn active" id="btn-lamp" title="Toggle Desk Lamp Warm Glow">💡 Lamp: On</button>
      <button class="nook-pill-btn" id="btn-sound" title="Toggle Procedural Audio Immersion">🔊 Sound</button>
      <div class="nook-pill-divider"></div>
      <button class="nook-pill-btn active" id="btn-arch" title="Toggle Furniture / Architecture Mode">🛋️ Room</button>
      <button class="nook-pill-btn" id="btn-reset" title="Reset Reference Camera (Esc)">🎥 Camera</button>
    `;
    this.uiContainer.appendChild(pill);

    // 1. Time of Day Cycle (Morning -> Evening -> Night -> Morning)
    const timeBtn = pill.querySelector('#btn-time');
    timeBtn.addEventListener('click', () => {
      const newTime = this.roomScene.lighting.cycleTimeOfDay();
      const labels = {
        morning: '☀️ Morning',
        evening: '🌇 Evening',
        night: '🌙 Night'
      };
      timeBtn.textContent = labels[newTime] || '☀️ Morning';
      updateLampBtn();
    });

    // 2. Desk Lamp Toggle
    const lampBtn = pill.querySelector('#btn-lamp');
    const updateLampBtn = () => {
      const isOn = this.roomScene.lighting && this.roomScene.lighting.isDeskLampOn;
      lampBtn.classList.toggle('active', isOn);
      lampBtn.textContent = isOn ? '💡 Lamp: On' : '💡 Lamp: Off';
    };

    lampBtn.addEventListener('click', () => {
      if (this.roomScene && this.roomScene.lighting) {
        soundManager.playLampClick();
        const isOn = this.roomScene.lighting.toggleDeskLamp();
        const lampObj = this.objectManager.getObjectById('prop_desk_lamp');
        if (lampObj) {
          lampObj.isLampOn = isOn;
          lampObj.traverse(child => {
            if (child.isPointLight) child.visible = isOn;
            if (child.isMesh && child.material && child.material.emissive) {
              child.material.emissiveIntensity = isOn ? 1.6 : 0.0;
            }
          });
        }
        updateLampBtn();
        this.roomState.saveState();
      }
    });

    // 3. Procedural Sound Toggle
    const soundBtn = pill.querySelector('#btn-sound');
    soundBtn.addEventListener('click', () => {
      const isMuted = soundManager.toggleMute();
      soundBtn.textContent = isMuted ? '🔇 Muted' : '🔊 Sound';
      soundBtn.classList.toggle('active', !isMuted);
    });

    // 4. Architecture / Furniture Toggle
    const archBtn = pill.querySelector('#btn-arch');
    const updateVisibility = () => {
      this.roomScene.interactiveObjects.visible = !this.isArchOnly;
      this.roomScene.furniture.visible = !this.isArchOnly;
      this.roomScene.decorations.visible = !this.isArchOnly;
      this.roomScene.cookieGroup.visible = !this.isArchOnly;
      archBtn.classList.toggle('active', !this.isArchOnly);
      archBtn.textContent = this.isArchOnly ? '🏛️ Arch' : '🛋️ Room';
    };

    archBtn.addEventListener('click', () => {
      this.isArchOnly = !this.isArchOnly;
      updateVisibility();
    });

    // 5. Reset Camera
    pill.querySelector('#btn-reset').addEventListener('click', () => {
      this.selectionManager.deselect();
      this.cameraInstance.resetCamera();
    });
  }

  initNativeBridge() {
    // Expose clean JavaScript API for macOS WKWebView
    window.NookBridge = {
      resetCamera: () => this.cameraInstance.resetCamera(),
      setArchitectureOnly: enable => {
        this.isArchOnly = enable;
        this.roomScene.interactiveObjects.visible = !enable;
        this.roomScene.furniture.visible = !enable;
        this.roomScene.decorations.visible = !enable;
        this.roomScene.cookieGroup.visible = !enable;
      },
      exportState: () => this.roomState.state
    };
  }

  onResize() {
    const width = window.innerWidth;
    const height = window.innerHeight;

    this.cameraInstance.resize(width, height);
    this.renderer.setSize(width, height);
    if (this.composer) {
      this.composer.setSize(width, height);
      if (this.tiltShiftPass) {
        this.tiltShiftPass.uniforms.v.value = (1.0 / height) * 1.5;
      }
    }
  }

  animate() {
    requestAnimationFrame(this.animate);

    const currentTime = performance.now();
    const delta = Math.min((currentTime - this.lastTime) * 0.001, 0.1);
    this.lastTime = currentTime;

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

    // 5. Render Scene with Post-Processing Miniature Effect
    if (this.composer) {
      this.composer.render();
    } else {
      this.renderer.render(this.roomScene.scene, this.cameraInstance.camera);
    }
  }
}

// Bootstrap on DOM readiness
window.addEventListener('DOMContentLoaded', () => {
  window.nookApp = new NookApplication();
});
