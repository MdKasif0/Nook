/**
 * Nook 3D - ObjectManager
 * Manages the registry, spawning, queries, and updates of all interactive 3D objects
 * inside the diorama room (matching objects visible in nook-room.jpeg).
 */

import * as THREE from 'three';
import { InteractiveObject } from './InteractiveObject.js';
import { PALETTE, UPPER_FLOOR_Y, LOWER_FLOOR_Y } from '../utils/Constants.js';
import { TextureGenerator } from '../utils/TextureGenerator.js';
import { thoughtStore } from '../persistence/ThoughtStore.js';
import { soundManager } from '../audio/SoundManager.js';

export class ObjectManager {
  constructor(roomScene, placementManager) {
    this.roomScene = roomScene;
    this.placementManager = placementManager;
    this.objects = new Map();

    this.spawnFoundationalObjects();
  }

  /**
   * Spawns or restores tactile interactive thoughts from persistent store.
   * If store has saved thoughts, restore them exactly where left.
   * Otherwise, seed the room with beautiful foundational thoughts.
   */
  spawnFoundationalObjects() {
    const savedThoughts = thoughtStore.getAll();

    if (savedThoughts && savedThoughts.length > 0) {
      // Restore existing thoughts from room memory
      for (const item of savedThoughts) {
        const obj = this.createThoughtObject(item.type, {
          id: item.id,
          title: item.title,
          content: item.content,
          type: item.type,
          position: new THREE.Vector3(item.position.x, item.position.y, item.position.z),
          rotation: new THREE.Euler(item.rotation.x, item.rotation.y, item.rotation.z),
          scale: new THREE.Vector3(item.scale?.x ?? 1, item.scale?.y ?? 1, item.scale?.z ?? 1),
          surface: item.surface,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt
        });
        if (item.isPinned) {
          this.setThoughtPinnedVisual(obj, true);
        }
        this.registerObject(obj);
      }
    } else {
      // First-time seed of initial thoughts
      const defaults = [
        {
          id: 'thought_welcome_pebble',
          title: 'Welcome to your Nook',
          content: 'Capture a thought anytime. Every thought exists here as a small tactile physical object.',
          type: 'thought',
          position: { x: -2.4, y: 1.70, z: -1.95 },
          rotation: { x: 0, y: 0.15, z: 0 },
          surface: 'desk'
        },
        {
          id: 'thought_gentle_reminder',
          title: 'Gentle Reminder',
          content: 'breathe deeply, you are home 🌱',
          type: 'reminder',
          position: { x: -1.35, y: 1.70, z: -2.15 },
          rotation: { x: 0, y: 0.22, z: 0 },
          surface: 'desk'
        },
        {
          id: 'thought_polaroid_photo',
          title: 'Sunday Morning',
          content: 'Sunlight filtering through the curtains.',
          type: 'photo',
          position: { x: -3.85, y: 1.70, z: -2.0 },
          rotation: { x: 0, y: -0.15, z: 0 },
          surface: 'desk'
        },
        {
          id: 'thought_bookmark_link',
          title: 'Current Chapter',
          content: 'Page 142 — "Where the light settles."',
          type: 'link',
          position: { x: 1.25, y: 1.30, z: -0.75 },
          rotation: { x: 0, y: 0.35, z: 0 },
          surface: 'bed'
        },
        {
          id: 'thought_origami_idea',
          title: 'Origami Idea',
          content: 'Folding paper thoughts into gentle sculptures.',
          type: 'idea',
          position: { x: -1.65, y: 1.70, z: -2.55 },
          rotation: { x: 0, y: -0.28, z: 0 },
          surface: 'desk'
        },
        {
          id: 'thought_field_notes',
          title: 'Field Notes',
          content: 'Observing morning shadows shift across the honey wood.',
          type: 'note',
          position: { x: -2.95, y: 1.70, z: -2.05 },
          rotation: { x: 0, y: 0.08, z: 0 },
          surface: 'desk'
        },
        {
          id: 'thought_quote_card',
          title: 'Invincible Summer',
          content: '“In the middle of winter, I found there was within me an invincible summer.” — Albert Camus',
          type: 'quote',
          position: { x: 1.50, y: 2.22, z: -3.12 },
          rotation: { x: 0, y: 0, z: 0 },
          surface: 'shelf_bed_1'
        }
      ];

      for (const d of defaults) {
        thoughtStore.saveThought(d);
        const obj = this.createThoughtObject(d.type, {
          id: d.id,
          title: d.title,
          content: d.content,
          type: d.type,
          position: new THREE.Vector3(d.position.x, d.position.y, d.position.z),
          rotation: new THREE.Euler(d.rotation.x, d.rotation.y, d.rotation.z),
          surface: d.surface
        });
        this.registerObject(obj);
      }
    }
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

  // MARK: - Thought Object Factories (7 Core Physical Representations)

  /**
   * 1. Thought: Small rounded tactile river pebble
   */
  createPebble(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'thought',
      category: 'thought',
      collisionRadius: 0.14
    });

    const geo = new THREE.DodecahedronGeometry(0.048, 2);
    geo.scale(1.22, 0.65, 1.05); // Natural smooth river stone flattening
    const mat = new THREE.MeshStandardMaterial({
      color: 0x929ba0,
      roughness: 0.38,
      metalness: 0.04
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    if (options.scale) obj.scale.copy(options.scale);
    return obj;
  }

  /**
   * 2. Idea: Small folded origami paper object
   */
  createFoldedPaperIdea(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'idea',
      category: 'thought',
      collisionRadius: 0.15
    });

    const group = new THREE.Group();

    // Folded Origami Paper Geometry (Angled facets with sharp paper creases)
    const paperMat = new THREE.MeshStandardMaterial({
      color: 0xfcfbf8,
      roughness: 0.82,
      side: THREE.DoubleSide
    });

    // Keel / Body fold (front & back facets)
    const keelGeo = new THREE.ConeGeometry(0.065, 0.055, 4);
    keelGeo.scale(1.4, 1.0, 0.7);
    keelGeo.rotateX(Math.PI);
    const keelMesh = new THREE.Mesh(keelGeo, paperMat);
    keelMesh.position.set(0, 0.028, 0);
    keelMesh.castShadow = true;
    keelMesh.receiveShadow = true;
    group.add(keelMesh);

    // Left and Right Origami Wing folds
    const wingGeo = new THREE.ConeGeometry(0.052, 0.048, 3);
    wingGeo.scale(0.8, 1.0, 1.2);

    const wingL = new THREE.Mesh(wingGeo, paperMat);
    wingL.position.set(-0.042, 0.035, 0);
    wingL.rotation.z = -0.35;
    wingL.castShadow = true;
    group.add(wingL);

    const wingR = new THREE.Mesh(wingGeo, paperMat);
    wingR.position.set(0.042, 0.035, 0);
    wingR.rotation.z = 0.35;
    wingR.castShadow = true;
    group.add(wingR);

    obj.visualRoot.add(group);
    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    if (options.scale) obj.scale.copy(options.scale);
    return obj;
  }

  /**
   * 3. Reminder: Small sticky note with realistic curved corner peel
   */
  createStickyNote(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'reminder',
      category: 'thought',
      collisionRadius: 0.14
    });

    const stickyTex = TextureGenerator.createStickyNoteTexture(512, 512);

    // 3D paper plane with curled corner
    const w = 0.18;
    const h = 0.18;
    const geo = new THREE.PlaneGeometry(w, h, 8, 8);
    const posAttr = geo.attributes.position;

    // Curl bottom corner upwards
    for (let i = 0; i < posAttr.count; i++) {
      const px = posAttr.getX(i);
      const py = posAttr.getY(i);
      if (px > 0.02 && py < -0.02) {
        const factor = Math.hypot(px - 0.02, py + 0.02);
        posAttr.setZ(i, Math.pow(factor * 1.5, 2) * 0.035);
      }
    }
    geo.computeVertexNormals();

    const mat = new THREE.MeshStandardMaterial({
      map: stickyTex,
      roughness: 0.85,
      side: THREE.DoubleSide
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.rotation.x = -Math.PI * 0.5;
    mesh.position.y = 0.003;
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    if (options.scale) obj.scale.copy(options.scale);
    return obj;
  }

  /**
   * 4. Quote: Small cardstock with debossed gold line border and letterpress lines
   */
  createQuoteCard(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'quote',
      category: 'thought',
      collisionRadius: 0.15
    });

    const cardTex = TextureGenerator.createQuoteCardTexture(512, 360);
    const geo = new THREE.BoxGeometry(0.22, 0.005, 0.15);
    const mat = new THREE.MeshStandardMaterial({
      map: cardTex,
      roughness: 0.78,
      metalness: 0.05
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    // If attached to wall, add delicate brass clip at top
    if (options.surface === 'wall_pegboard' || Math.abs(options.position?.z - (-3.31)) < 0.08) {
      const clipGeo = new THREE.BoxGeometry(0.024, 0.015, 0.008);
      const clipMat = new THREE.MeshStandardMaterial({
        color: 0xd4af37,
        metalness: 0.85,
        roughness: 0.2
      });
      const clip = new THREE.Mesh(clipGeo, clipMat);
      clip.position.set(0, 0.08, 0.005);
      obj.visualRoot.add(clip);
      mesh.rotation.x = Math.PI * 0.5; // Mount upright against wall
    }

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    if (options.scale) obj.scale.copy(options.scale);
    return obj;
  }

  /**
   * 5. Photo: Miniature Polaroid print
   */
  createPolaroid(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'photo',
      category: 'thought',
      collisionRadius: 0.16
    });

    const polTex = TextureGenerator.createPolaroidTexture(0, 512, 600);
    const geo = new THREE.BoxGeometry(0.20, 0.005, 0.24);
    const mat = new THREE.MeshPhysicalMaterial({
      map: polTex,
      roughness: 0.45,
      clearcoat: 0.4,
      clearcoatRoughness: 0.12
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    // Wall mounting pin if on pegboard
    if (options.surface === 'wall_pegboard' || Math.abs(options.position?.z - (-3.31)) < 0.08) {
      const pinGeo = new THREE.CylinderGeometry(0.008, 0.008, 0.012, 12);
      const pinMat = new THREE.MeshStandardMaterial({
        color: 0xc89848,
        metalness: 0.85,
        roughness: 0.25
      });
      const pin = new THREE.Mesh(pinGeo, pinMat);
      pin.position.set(0, 0.11, 0.006);
      pin.rotation.x = Math.PI * 0.5;
      obj.visualRoot.add(pin);
      mesh.rotation.x = Math.PI * 0.5;
    }

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    if (options.scale) obj.scale.copy(options.scale);
    return obj;
  }

  /**
   * 6. Link: Woven bookmark with brass charm loop
   */
  createBookmark(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'link',
      category: 'thought',
      collisionRadius: 0.12
    });

    const bmTex = TextureGenerator.createBookmarkTexture(256, 512);
    const geo = new THREE.BoxGeometry(0.075, 0.004, 0.26);
    const mat = new THREE.MeshStandardMaterial({
      map: bmTex,
      roughness: 0.82
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    obj.visualRoot.add(mesh);

    // Tiny brass charm ring at top
    const charmGeo = new THREE.TorusGeometry(0.015, 0.0035, 8, 16);
    const charmMat = new THREE.MeshStandardMaterial({
      color: 0xd9b362,
      metalness: 0.85,
      roughness: 0.25
    });
    const charm = new THREE.Mesh(charmGeo, charmMat);
    charm.position.set(0, 0.003, -0.14);
    charm.rotation.x = Math.PI * 0.5;
    obj.visualRoot.add(charm);

    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    if (options.scale) obj.scale.copy(options.scale);
    return obj;
  }

  /**
   * 7. Note: Small pocket notebook
   */
  createNotebook(options) {
    const obj = new InteractiveObject({
      ...options,
      objectType: 'note',
      category: 'thought',
      collisionRadius: 0.16
    });

    const group = new THREE.Group();

    // Notebook Hardcover (Forest Sage or Warm Cognac)
    const coverGeo = new THREE.BoxGeometry(0.16, 0.022, 0.22);
    const coverMat = new THREE.MeshStandardMaterial({
      color: 0x3d4e41, // Elegant muted moss green
      roughness: 0.72
    });
    const cover = new THREE.Mesh(coverGeo, coverMat);
    cover.castShadow = true;
    cover.receiveShadow = true;
    group.add(cover);

    // Paper Pages Block inside
    const pagesGeo = new THREE.BoxGeometry(0.15, 0.018, 0.21);
    const pagesMat = new THREE.MeshStandardMaterial({
      color: 0xfffcf2,
      roughness: 0.92
    });
    const pages = new THREE.Mesh(pagesGeo, pagesMat);
    pages.position.set(0.004, 0, 0);
    group.add(pages);

    // Elastic band closure
    const bandGeo = new THREE.BoxGeometry(0.012, 0.024, 0.225);
    const bandMat = new THREE.MeshStandardMaterial({
      color: 0x222623,
      roughness: 0.8
    });
    const band = new THREE.Mesh(bandGeo, bandMat);
    band.position.set(0.05, 0, 0);
    group.add(band);

    // Satin ribbon marker tail
    const ribbonGeo = new THREE.BoxGeometry(0.008, 0.003, 0.06);
    const ribbonMat = new THREE.MeshStandardMaterial({
      color: 0xd98845,
      roughness: 0.6
    });
    const ribbon = new THREE.Mesh(ribbonGeo, ribbonMat);
    ribbon.position.set(-0.02, -0.009, 0.13);
    group.add(ribbon);

    obj.visualRoot.add(group);
    obj.position.copy(options.position);
    if (options.rotation) obj.rotation.copy(options.rotation);
    if (options.scale) obj.scale.copy(options.scale);
    return obj;
  }

  // MARK: - Factory Dispatcher

  createThoughtObject(type, options) {
    const norm = (type || 'thought').toLowerCase();
    switch (norm) {
      case 'thought':
      case 'pebble':
        return this.createPebble(options);
      case 'idea':
      case 'folded_paper':
        return this.createFoldedPaperIdea(options);
      case 'reminder':
      case 'sticky_note':
        return this.createStickyNote(options);
      case 'quote':
      case 'card':
        return this.createQuoteCard(options);
      case 'photo':
      case 'polaroid':
        return this.createPolaroid(options);
      case 'link':
      case 'bookmark':
        return this.createBookmark(options);
      case 'note':
      case 'notebook':
      case 'journal':
      case 'paper_note':
        return this.createNotebook(options);
      default:
        return this.createPebble(options);
    }
  }

  /**
   * Spawns a new thought into the diorama room with physical appear animation.
   */
  spawnThought(data, animate = true) {
    const saved = thoughtStore.saveThought(data);
    const obj = this.createThoughtObject(saved.type, {
      id: saved.id,
      title: saved.title,
      content: saved.content,
      type: saved.type,
      position: new THREE.Vector3(saved.position.x, saved.position.y, saved.position.z),
      rotation: new THREE.Euler(saved.rotation.x, saved.rotation.y, saved.rotation.z),
      scale: new THREE.Vector3(saved.scale?.x ?? 1, saved.scale?.y ?? 1, saved.scale?.z ?? 1),
      surface: saved.surface,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt
    });

    if (saved.isPinned) {
      this.setThoughtPinnedVisual(obj, true);
    }

    this.registerObject(obj);

    if (animate) {
      this.animateAppear(obj);
    }

    return obj;
  }

  /**
   * Attaches or removes a physical 3D indicator (polished brass pin with warm amber pearl cap & glowing micro-light).
   */
  setThoughtPinnedVisual(obj, isPinned) {
    if (!obj || !obj.visualRoot) return;

    obj.isPinned = isPinned;

    // Remove existing pin if present
    const existingPin = obj.visualRoot.getObjectByName('pinIndicator');
    if (existingPin) {
      obj.visualRoot.remove(existingPin);
    }

    if (isPinned) {
      const pinGroup = new THREE.Group();
      pinGroup.name = 'pinIndicator';

      // 1. Polished Brass Pin Needle
      const needleGeo = new THREE.CylinderGeometry(0.003, 0.001, 0.038, 8);
      const needleMat = new THREE.MeshStandardMaterial({
        color: 0xd4af37,
        metalness: 0.92,
        roughness: 0.18
      });
      const needle = new THREE.Mesh(needleGeo, needleMat);
      needle.position.y = 0.016;
      needle.castShadow = true;
      pinGroup.add(needle);

      // 2. Warm Amber Jewel / Pearl Cap
      const capGeo = new THREE.SphereGeometry(0.014, 12, 10);
      const capMat = new THREE.MeshStandardMaterial({
        color: 0xffa726,
        emissive: 0xff9800,
        emissiveIntensity: 0.85,
        roughness: 0.15,
        metalness: 0.25
      });
      const cap = new THREE.Mesh(capGeo, capMat);
      cap.position.y = 0.034;
      cap.castShadow = true;
      pinGroup.add(cap);

      // 3. Subtle Warm Radiant Micro PointLight (illuminates the thought object)
      const pinGlow = new THREE.PointLight(0xffb347, 0.45, 0.6, 2.0);
      pinGlow.position.y = 0.038;
      pinGroup.add(pinGlow);

      // Slight natural angle
      pinGroup.rotation.z = 0.20;
      pinGroup.rotation.x = -0.14;

      // Position relative to object size (top right corner)
      pinGroup.position.set(0.04, 0.035, -0.04);
      obj.visualRoot.add(pinGroup);
    }
  }

  /**
   * Toggles the pinned/favorite status of a thought.
   */
  togglePinThought(id) {
    const obj = this.getObjectById(id);
    const data = thoughtStore.getById(id);
    if (!obj || !data) return false;

    const newPinned = !Boolean(data.isPinned);
    thoughtStore.updateThought(id, { isPinned: newPinned });
    this.setThoughtPinnedVisual(obj, newPinned);
    soundManager.playPinSound(newPinned);
    return newPinned;
  }

  /**
   * Transforms a thought object into a different 3D representation while preserving content.
   */
  changeThoughtType(id, newType) {
    const oldObj = this.getObjectById(id);
    if (!oldObj) return null;

    const data = thoughtStore.getById(id);
    if (!data) return null;

    data.type = newType.toLowerCase();
    thoughtStore.updateThought(id, { type: data.type });

    // Clear old visual meshes
    while (oldObj.visualRoot.children.length > 0) {
      oldObj.visualRoot.remove(oldObj.visualRoot.children[0]);
    }

    // Generate new visual geometry
    const tempObj = this.createThoughtObject(data.type, {
      id: data.id,
      title: data.title,
      content: data.content,
      position: oldObj.position,
      rotation: oldObj.rotation,
      surface: data.surface
    });

    for (const child of tempObj.visualRoot.children) {
      oldObj.visualRoot.add(child.clone(true));
    }

    oldObj.name = `${data.type.charAt(0).toUpperCase() + data.type.slice(1)}: ${data.title}`;
    oldObj.objectType = data.type;
    oldObj.metadata.type = data.type;
    oldObj.cacheMaterials();

    // Reattach pin if pinned
    if (data.isPinned) {
      this.setThoughtPinnedVisual(oldObj, true);
    }

    this.animateAppear(oldObj);
    return oldObj;
  }

  /**
   * Physical appear animation:
   * 1. Small scale
   * 2. Slight elevation
   * 3. Gentle movement downward
   * 4. Settles on surface with soft bounce
   * 5. Shadow appears
   */
  animateAppear(obj, onComplete = null) {
    const targetY = obj.position.y;
    const startY = targetY + 0.22;
    obj.position.y = startY;
    obj.scale.set(0.05, 0.05, 0.05);

    let elapsed = 0;
    const duration = 0.52;

    const animStep = () => {
      elapsed += 0.016;
      const t = Math.min(elapsed / duration, 1.0);

      // Overshoot scale spring: 0.05 -> 1.06 -> 1.0
      const scaleEase = 1.0 + Math.sin(t * Math.PI) * 0.12 * (1.0 - t) - (1.0 - t) * 0.95;
      obj.scale.setScalar(Math.max(0.05, Math.min(scaleEase, 1.1)));

      // Height downward drop with soft bounce
      const dropEase = 1.0 - Math.pow(1.0 - t, 2.5);
      const bounce = Math.sin(t * Math.PI * 2) * 0.012 * Math.exp(-t * 4);
      obj.position.y = THREE.MathUtils.lerp(startY, targetY, dropEase) + bounce;

      if (t < 1.0) {
        requestAnimationFrame(animStep);
      } else {
        obj.position.y = targetY;
        obj.scale.set(1, 1, 1);
        soundManager.playPlacementSound(obj.objectType);
        if (onComplete) onComplete();
      }
    };

    requestAnimationFrame(animStep);
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
