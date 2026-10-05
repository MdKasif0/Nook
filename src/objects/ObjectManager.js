/**
 * Nook 3D - ObjectManager
 * Manages the registry, spawning, queries, and updates of all interactive 3D objects
 * inside the diorama room (matching objects visible in nook-room.jpeg).
 */

import * as THREE from 'three';
import { InteractiveObject } from './InteractiveObject.js';
import { PALETTE, UPPER_FLOOR_Y, LOWER_FLOOR_Y } from '../utils/Constants.js';
import { TextureGenerator } from '../utils/TextureGenerator.js';

export class ObjectManager {
  constructor(roomScene, placementManager) {
    this.roomScene = roomScene;
    this.placementManager = placementManager;
    this.objects = new Map();

    this.spawnFoundationalObjects();
  }

  /**
   * Spawns initial tactile interactive thoughts.
   */
  spawnFoundationalObjects() {
    // 1. Smooth River Pebble (Tactile Thought) on Desk
    const pebble = this.createPebble({
      id: 'prop_welcome_pebble',
      name: 'Welcome Pebble',
      title: 'Welcome to your Nook',
      content: 'Capture a thought anytime. Every thought exists here as a small tactile physical object.',
      position: new THREE.Vector3(-2.4, 1.72, -1.9)
    });
    this.registerObject(pebble);

    // 2. Sticky Note on Desk
    const sticky = this.createStickyNote({
      id: 'prop_sticky_note',
      name: 'Sticky Note',
      title: 'Gentle Reminder',
      content: 'breathe deeply, you are home 🌱',
      position: new THREE.Vector3(-1.25, 1.72, -2.1),
      rotation: new THREE.Euler(0, 0.18, 0)
    });
    this.registerObject(sticky);

    // 3. Instant Polaroid Photo on Desk
    const polaroid = this.createPolaroid({
      id: 'prop_polaroid_thought',
      name: 'Polaroid Photo',
      title: 'Sunday Morning',
      content: 'Sunlight filtering through the curtains.',
      position: new THREE.Vector3(-3.85, 1.72, -2.0),
      rotation: new THREE.Euler(0, -0.15, 0)
    });
    this.registerObject(polaroid);

    // 4. Woven Ribbon Bookmark resting on Bed Duvet
    const bookmark = this.createBookmark({
      id: 'prop_bookmark_thought',
      name: 'Ribbon Bookmark',
      title: 'Current Chapter',
      content: 'Page 142 — "Where the light settles."',
      position: new THREE.Vector3(1.25, 1.32, -0.75),
      rotation: new THREE.Euler(0, 0.35, 0)
    });
    this.registerObject(bookmark);

    // 5. Paper Note beside keyboard
    const paperNote = this.createPaperNote({
      id: 'prop_paper_note',
      name: 'Paper Note',
      title: 'Morning Notes',
      content: 'A quiet morning with coffee and Cookie purring.',
      position: new THREE.Vector3(-1.42, 1.72, -2.55),
      rotation: new THREE.Euler(0, -0.22, 0)
    });
    this.registerObject(paperNote);
  }

  initMovableProps(propsList) {
    if (!propsList) return;
    for (const prop of propsList) {
      this.registerObject(prop);
    }
  }

  registerObject(obj) {
    if (!obj) return;
    this.objects.set(obj.itemId, obj);
    this.roomScene.interactiveObjects.add(obj);
  }

  removeObject(id) {
    const obj = this.objects.get(id);
    if (obj) {
      this.roomScene.interactiveObjects.remove(obj);
      this.objects.delete(id);
      return obj;
    }
    return null;
  }

  duplicateObject(id) {
    const original = this.objects.get(id);
    if (!original || !original.isDuplicatable) return null;

    const duplicate = new InteractiveObject({
      name: `${original.name} Copy`,
      accessibilityLabel: `${original.accessibilityLabel} (Copy)`,
      category: original.category,
      objectType: original.objectType,
      collisionRadius: original.collisionRadius,
      isMovable: original.isMovable,
      isDraggable: original.isDraggable,
      isSelectable: original.isSelectable,
      isRotatable: original.isRotatable,
      isDeletable: true,
      isDuplicatable: true,
      specialAction: original.specialAction
    });

    // Clone visual meshes
    for (const child of original.visualRoot.children) {
      const cloned = child.clone(true);
      duplicate.visualRoot.add(cloned);
    }

    // Offset position slightly on the surface
    const offsetPos = original.position.clone();
    offsetPos.x += 0.22;
    offsetPos.z += 0.15;
    duplicate.setDefaultTransform(offsetPos, original.rotation.clone());
    duplicate.cacheMaterials();

    this.registerObject(duplicate);
    return duplicate;
  }

  getObjectById(id) {
    return this.objects.get(id);
  }

  getAllObjects() {
    return Array.from(this.objects.values());
  }

  /**
   * Collects all mesh children suitable for raycaster intersections.
   */
  getRaycastMeshes() {
    const meshes = [];
    for (const obj of this.objects.values()) {
      obj.traverse(child => {
        if (child.isMesh) {
          meshes.push(child);
        }
      });
    }
    return meshes;
  }

  update(delta) {
    for (const obj of this.objects.values()) {
      obj.update(delta);
    }
  }

  // MARK: - Object Factories

  createPebble(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'pebble',
      category: 'thought'
    });

    const geo = new THREE.DodecahedronGeometry(0.045, 2);
    // Squash slightly along Y to give natural pebble curvature
    geo.scale(1.2, 0.65, 1.0);
    const mat = new THREE.MeshStandardMaterial({
      color: 0x98a2a8,
      roughness: 0.35,
      metalness: 0.05
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);
    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    return obj;
  }

  createPaperNote(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'paper_note',
      category: 'thought',
      collisionRadius: 0.16
    });

    const noteTex = TextureGenerator.createPaperNoteTexture(512, 512);
    const geo = new THREE.BoxGeometry(0.24, 0.005, 0.28);
    const mat = new THREE.MeshStandardMaterial({
      map: noteTex,
      roughness: 0.88,
      color: 0xffffff
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    return obj;
  }

  createPolaroid(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'polaroid',
      category: 'thought',
      collisionRadius: 0.16
    });

    const polTex = TextureGenerator.createPolaroidTexture(512, 600);
    const geo = new THREE.BoxGeometry(0.22, 0.006, 0.26);
    const mat = new THREE.MeshPhysicalMaterial({
      map: polTex,
      roughness: 0.45,
      clearcoat: 0.25,
      clearcoatRoughness: 0.15
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    return obj;
  }

  createBookmark(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'bookmark',
      category: 'thought',
      collisionRadius: 0.12
    });

    const bmTex = TextureGenerator.createBookmarkTexture(256, 512);
    const geo = new THREE.BoxGeometry(0.08, 0.004, 0.28);
    const mat = new THREE.MeshStandardMaterial({
      map: bmTex,
      roughness: 0.82
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    // Tiny brass charm ring at top
    const charmGeo = new THREE.TorusGeometry(0.016, 0.004, 8, 16);
    const charmMat = new THREE.MeshStandardMaterial({
      color: 0xd9b362,
      metalness: 0.8,
      roughness: 0.25
    });
    const charm = new THREE.Mesh(charmGeo, charmMat);
    charm.position.set(0, 0.003, -0.15);
    charm.rotation.x = Math.PI * 0.5;
    obj.visualRoot.add(charm);

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    return obj;
  }

  createStickyNote(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'sticky_note',
      category: 'thought',
      collisionRadius: 0.14
    });

    const stickyTex = TextureGenerator.createStickyNoteTexture(512, 512);
    const geo = new THREE.BoxGeometry(0.20, 0.004, 0.20);
    const mat = new THREE.MeshStandardMaterial({
      map: stickyTex,
      roughness: 0.85
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    return obj;
  }

  createThoughtObject(type, options) {
    switch (type) {
      case 'pebble':
        return this.createPebble(options);
      case 'paper_note':
        return this.createPaperNote(options);
      case 'polaroid':
        return this.createPolaroid(options);
      case 'bookmark':
        return this.createBookmark(options);
      case 'sticky_note':
        return this.createStickyNote(options);
      default:
        return this.createPebble(options);
    }
  }

  createJournal(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'journal',
      category: 'thought'
    });

    const coverGeo = new THREE.BoxGeometry(0.18, 0.024, 0.24);
    const coverMat = new THREE.MeshStandardMaterial({
      color: PALETTE.bedBlanketSage,
      roughness: 0.75
    });
    const cover = new THREE.Mesh(coverGeo, coverMat);
    cover.castShadow = true;
    cover.receiveShadow = true;
    obj.visualRoot.add(cover);

    const pagesGeo = new THREE.BoxGeometry(0.17, 0.02, 0.23);
    const pagesMat = new THREE.MeshStandardMaterial({
      color: 0xfffcf5,
      roughness: 0.9
    });
    const pages = new THREE.Mesh(pagesGeo, pagesMat);
    pages.position.set(0.005, 0, 0);
    obj.visualRoot.add(pages);

    obj.position.copy(options.position);
    obj.rotation.y = 0.2;
    return obj;
  }

  createMug(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'mug',
      category: 'prop'
    });

    const bodyGeo = new THREE.CylinderGeometry(0.038, 0.035, 0.075, 20);
    const mat = new THREE.MeshStandardMaterial({
      color: PALETTE.ceramicWhite,
      roughness: 0.25,
      metalness: 0.05
    });
    const body = new THREE.Mesh(bodyGeo, mat);
    body.castShadow = true;
    body.receiveShadow = true;
    obj.visualRoot.add(body);

    // Handle
    const handleGeo = new THREE.TorusGeometry(0.022, 0.007, 10, 20, Math.PI);
    const handle = new THREE.Mesh(handleGeo, mat);
    handle.rotation.z = -Math.PI / 2;
    handle.position.set(0.042, 0, 0);
    handle.castShadow = true;
    obj.visualRoot.add(handle);

    obj.position.copy(options.position);
    return obj;
  }

  createRecordPlayer(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'record_player',
      category: 'prop'
    });

    // Suitcase Box Base (dusty rose from reference)
    const baseGeo = new THREE.BoxGeometry(0.32, 0.065, 0.28);
    const baseMat = new THREE.MeshStandardMaterial({
      color: PALETTE.recordPlayerDustyRose,
      roughness: 0.65
    });
    const base = new THREE.Mesh(baseGeo, baseMat);
    base.castShadow = true;
    base.receiveShadow = true;
    obj.visualRoot.add(base);

    // Vinyl Record Platter
    const platterGeo = new THREE.CylinderGeometry(0.09, 0.09, 0.008, 32);
    const platterMat = new THREE.MeshStandardMaterial({
      color: PALETTE.recordVinyl,
      roughness: 0.25,
      metalness: 0.4
    });
    this.vinylMesh = new THREE.Mesh(platterGeo, platterMat);
    this.vinylMesh.position.set(-0.04, 0.038, 0);
    this.vinylMesh.castShadow = true;
    obj.visualRoot.add(this.vinylMesh);

    // Center Label
    const labelGeo = new THREE.CylinderGeometry(0.03, 0.03, 0.01, 20);
    const labelMat = new THREE.MeshStandardMaterial({
      color: 0xdb6848,
      roughness: 0.5
    });
    const label = new THREE.Mesh(labelGeo, labelMat);
    label.position.set(-0.04, 0.042, 0);
    obj.visualRoot.add(label);

    // Tonearm
    const armGeo = new THREE.BoxGeometry(0.01, 0.008, 0.12);
    const armMat = new THREE.MeshStandardMaterial({
      color: 0xd9b362,
      metalness: 0.7,
      roughness: 0.3
    });
    const arm = new THREE.Mesh(armGeo, armMat);
    arm.position.set(0.08, 0.045, 0.02);
    arm.rotation.y = -0.3;
    obj.visualRoot.add(arm);

    obj.position.copy(options.position);
    obj.rotation.y = -0.25;

    // Interactive spin state
    obj.isSpinning = true;
    const oldUpdate = obj.update.bind(obj);
    obj.update = delta => {
      oldUpdate(delta);
      if (obj.isSpinning && this.vinylMesh) {
        this.vinylMesh.rotation.y += delta * 2.8;
      }
    };

    return obj;
  }

  createSkateboard(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'skateboard',
      category: 'prop'
    });

    // Deck with curved kicktail
    const deckGeo = new THREE.BoxGeometry(0.48, 0.014, 0.12);
    const deckMat = new THREE.MeshStandardMaterial({
      color: PALETTE.skateboardBlack,
      roughness: 0.95
    });
    const deck = new THREE.Mesh(deckGeo, deckMat);
    deck.castShadow = true;
    deck.receiveShadow = true;
    obj.visualRoot.add(deck);

    // Wheels
    const wheelGeo = new THREE.CylinderGeometry(0.02, 0.02, 0.018, 16);
    const wheelMat = new THREE.MeshStandardMaterial({
      color: 0xd8873d,
      roughness: 0.4
    });
    const wheelPositions = [
      [-0.17, -0.015, -0.055],
      [-0.17, -0.015, 0.055],
      [0.17, -0.015, -0.055],
      [0.17, -0.015, 0.055]
    ];
    for (const pos of wheelPositions) {
      const wheel = new THREE.Mesh(wheelGeo, wheelMat);
      wheel.rotation.x = Math.PI / 2;
      wheel.position.set(...pos);
      wheel.castShadow = true;
      obj.visualRoot.add(wheel);
    }

    obj.position.copy(options.position);
    obj.rotation.y = -0.35;
    return obj;
  }

  createDaisyPillow(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'daisy_pillow',
      category: 'prop'
    });

    // Yellow Center
    const centerGeo = new THREE.CylinderGeometry(0.05, 0.05, 0.04, 20);
    const centerMat = new THREE.MeshStandardMaterial({
      color: PALETTE.pillowDaisyYellow,
      roughness: 0.9
    });
    const center = new THREE.Mesh(centerGeo, centerMat);
    center.castShadow = true;
    obj.visualRoot.add(center);

    // 6 White Petals
    const petalGeo = new THREE.SphereGeometry(0.04, 16, 12);
    petalGeo.scale(1.0, 0.45, 1.4);
    const petalMat = new THREE.MeshStandardMaterial({
      color: PALETTE.bedSheets,
      roughness: 0.85
    });
    for (let i = 0; i < 6; i++) {
      const angle = (i / 6) * Math.PI * 2;
      const petal = new THREE.Mesh(petalGeo, petalMat);
      petal.position.set(Math.cos(angle) * 0.075, 0, Math.sin(angle) * 0.075);
      petal.rotation.y = -angle;
      petal.castShadow = true;
      obj.visualRoot.add(petal);
    }

    obj.position.copy(options.position);
    return obj;
  }

  createPlant(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'plant',
      category: 'prop'
    });

    // Ceramic Pot
    const potGeo = new THREE.CylinderGeometry(0.08, 0.065, 0.16, 20);
    const potMat = new THREE.MeshStandardMaterial({
      color: PALETTE.ceramicWhite,
      roughness: 0.3
    });
    const pot = new THREE.Mesh(potGeo, potMat);
    pot.castShadow = true;
    pot.receiveShadow = true;
    obj.visualRoot.add(pot);

    // Plant Stems and Monstera Leaves
    const leafGeo = new THREE.CircleGeometry(0.07, 12);
    const leafMat = new THREE.MeshStandardMaterial({
      color: PALETTE.plantGreen,
      roughness: 0.5,
      side: THREE.DoubleSide
    });
    for (let i = 0; i < 5; i++) {
      const angle = (i / 5) * Math.PI * 2;
      const leaf = new THREE.Mesh(leafGeo, leafMat);
      leaf.position.set(Math.cos(angle) * 0.09, 0.12 + (i % 2) * 0.05, Math.sin(angle) * 0.09);
      leaf.rotation.x = -Math.PI / 4;
      leaf.rotation.y = angle;
      leaf.castShadow = true;
      obj.visualRoot.add(leaf);
    }

    obj.position.copy(options.position);
    return obj;
  }
}
