/**
 * Nook 3D - FurnitureBuilder
 * Reconstructs all major furniture items from nook-room.jpeg as separate, independent Object3D instances:
 * - Workstation: Desk, Desk_Drawers
 * - Desk Objects: Monitor, Laptop, Keyboard, Mouse, Phone, Notebook, PenHolder, DeskLamp, Mug, SmallPlant, Headphones, Books
 * - Seating: OfficeChair
 * - Resting: Bed, Mattress, Blanket, Pillow_01, Pillow_02, Pillow_03, FlowerPillow
 * - Leisure: Ottoman, RecordPlayer, Vinyl, Skateboard, CatBed
 * - Floor Decor: DeskRug, MonsteraPlant, StepPlants
 */

import * as THREE from 'three';
import { PALETTE, MAIN_FLOOR_Y, LOWER_FLOOR_Y } from '../utils/Constants.js';
import { TextureGenerator } from '../utils/TextureGenerator.js';
import { MaterialSystem } from '../materials/MaterialSystem.js';

export class FurnitureBuilder {
  constructor(roomScene) {
    this.roomScene = roomScene;
    this.materials = this.createMaterials();
  }

  createMaterials() {
    const pbr = MaterialSystem.getMaterials();

    const monitorTexture = TextureGenerator.createMonitorHelloTexture(1024, 640);
    const rugTexture = TextureGenerator.createRugBotanicalTexture(1024, 1024);
    const notebookTexture = TextureGenerator.createNotebookTexture(512, 512);

    return {
      // Reusable PBR Materials from MaterialSystem:
      Wood_Warm: pbr.Wood_Warm,
      Wood_Light: pbr.Wood_Light,
      Wood_Dark: pbr.Wood_Dark,
      Wall_Cream: pbr.Wall_Cream,
      Fabric_Cream: pbr.Fabric_Cream,
      Fabric_Sage: pbr.Fabric_Sage,
      Metal_Warm: pbr.Metal_Warm,
      Ceramic_Cream: pbr.Ceramic_Cream,
      Glass_Warm: pbr.Glass_Warm,
      Paper: pbr.Paper,
      Plant_Green: pbr.Plant_Green,
      Vinyl_Black: pbr.Vinyl_Black,

      // Dedicated Furniture Wood Variations:
      woodHoney: pbr.Wood_Warm,
      woodDesk: pbr.Wood_Desk,
      woodBed: pbr.Wood_Bed,
      woodLight: pbr.Wood_Light,
      woodTrim: pbr.Wood_Dark,
      woodFloor: pbr.Wood_Floor,

      // PBR Fabrics:
      fabricCream: pbr.Fabric_Cream,
      fabricSage: pbr.Fabric_Sage,
      fabricBeige: new THREE.MeshStandardMaterial({
        color: 0xdecbb7,
        normalMap: pbr.Fabric_Cream.normalMap,
        normalScale: new THREE.Vector2(0.5, 0.5),
        roughness: 0.88,
        metalness: 0.01
      }),
      boucleCream: pbr.Fabric_Boucle,

      // Chair Fabric & Frame:
      fabricChairGray: new THREE.MeshStandardMaterial({
        color: 0x8a998e,
        normalMap: pbr.Fabric_Cream.normalMap,
        normalScale: new THREE.Vector2(0.4, 0.4),
        roughness: 0.82,
        metalness: 0.02
      }),
      chairFrameCream: new THREE.MeshStandardMaterial({
        color: 0xf5f0e6,
        roughness: 0.45,
        metalness: 0.04
      }),

      // Metals & Ceramics:
      metalChrome: pbr.Metal_Warm,
      plasticWhite: pbr.Ceramic_Cream,

      // Display Artwork:
      monitorScreen: new THREE.MeshBasicMaterial({
        map: monitorTexture
      }),

      // Dark Tech Surfaces:
      darkTech: new THREE.MeshStandardMaterial({
        color: 0x242428,
        roughness: 0.40,
        metalness: 0.15
      }),

      // Record Player & Vinyl:
      recordPlayerCase: new THREE.MeshStandardMaterial({
        color: PALETTE.recordPlayerDustyRose,
        normalMap: pbr.Fabric_Cream.normalMap,
        normalScale: new THREE.Vector2(0.25, 0.25),
        roughness: 0.65,
        metalness: 0.05
      }),
      vinylMaterial: pbr.Vinyl_Black,

      // Skateboard Grip Tape:
      gripTape: new THREE.MeshStandardMaterial({
        color: PALETTE.skateboardBlack,
        roughness: 0.95,
        metalness: 0.0
      }),

      // Daisy Pillow Components:
      petalWhite: new THREE.MeshStandardMaterial({
        color: 0xfefcf7,
        normalMap: pbr.Fabric_Cream.normalMap,
        normalScale: new THREE.Vector2(0.3, 0.3),
        roughness: 0.82,
        metalness: 0.0
      }),
      daisyYellow: new THREE.MeshStandardMaterial({
        color: PALETTE.pillowDaisyYellow,
        normalMap: pbr.Fabric_Cream.normalMap,
        normalScale: new THREE.Vector2(0.3, 0.3),
        roughness: 0.78,
        metalness: 0.0
      }),

      // Botanical Rug:
      rugMaterial: new THREE.MeshStandardMaterial({
        color: 0xffffff,
        map: rugTexture,
        normalMap: pbr.Fabric_Cream.normalMap,
        normalScale: new THREE.Vector2(0.7, 0.7),
        roughness: 0.92,
        metalness: 0.01
      }),

      // Plant Foliage Variations:
      foliageGreen: pbr.Plant_Green,
      foliageOlive: pbr.Plant_Olive,
      foliageDeep: pbr.Plant_Deep,
      foliageGoldenGreen: pbr.Plant_GoldenGreen,

      // Paper & Notebook:
      notebookMaterial: new THREE.MeshStandardMaterial({
        color: 0xffffff,
        map: notebookTexture,
        roughness: 0.92,
        metalness: 0.0
      }),
      paper: pbr.Paper
    };
  }

  /**
   * Builds and attaches all major furniture and decor to the scene.
   */
  buildAll() {
    const furnitureGroup = this.roomScene.furniture;
    furnitureGroup.clear();

    // 1. Workstation: Desk & Desk_Drawers
    const desk = this.buildDesk();
    const deskDrawers = this.buildDeskDrawers();
    furnitureGroup.add(desk);
    furnitureGroup.add(deskDrawers);

    // 2. Desk Objects
    const monitor = this.buildMonitor();
    const laptop = this.buildLaptop();
    const keyboard = this.buildKeyboard();
    const mouse = this.buildMouse();
    const phone = this.buildPhone();
    const notebook = this.buildNotebook();
    const penHolder = this.buildPenHolder();
    const deskLamp = this.buildDeskLamp();
    const mug = this.buildMug();
    const smallPlant = this.buildSmallPlant();
    const headphones = this.buildHeadphones();
    const books = this.buildDeskBooks();

    furnitureGroup.add(monitor);
    furnitureGroup.add(laptop);
    furnitureGroup.add(keyboard);
    furnitureGroup.add(mouse);
    furnitureGroup.add(phone);
    furnitureGroup.add(notebook);
    furnitureGroup.add(penHolder);
    furnitureGroup.add(deskLamp);
    furnitureGroup.add(mug);
    furnitureGroup.add(smallPlant);
    furnitureGroup.add(headphones);
    furnitureGroup.add(books);

    // 3. Office Chair & Desk Rug
    const chair = this.buildOfficeChair();
    const rug = this.buildDeskRug();
    furnitureGroup.add(chair);
    furnitureGroup.add(rug);

    // 4. Bed & Bedding
    const bed = this.buildBed();
    const mattress = this.buildMattress();
    const blanket = this.buildBlanket();
    const pillow1 = this.buildPillow01();
    const pillow2 = this.buildPillow02();
    const pillow3 = this.buildPillow03();
    const flowerPillow = this.buildFlowerPillow();

    furnitureGroup.add(bed);
    furnitureGroup.add(mattress);
    furnitureGroup.add(blanket);
    furnitureGroup.add(pillow1);
    furnitureGroup.add(pillow2);
    furnitureGroup.add(pillow3);
    furnitureGroup.add(flowerPillow);

    // 5. Ottoman & Record Player
    const ottoman = this.buildOttoman();
    const recordPlayer = this.buildRecordPlayer();
    furnitureGroup.add(ottoman);
    furnitureGroup.add(recordPlayer);

    // 6. Skateboard & Cat Bed
    const skateboard = this.buildSkateboard();
    const catBed = this.buildCatBed();
    furnitureGroup.add(skateboard);
    furnitureGroup.add(catBed);

    // 7. Floor Decorative Plants & Curb Books
    const monstera = this.buildMonsteraPlant();
    const curbBooks = this.buildCurbBooksAndPlant();
    const stepPlant = this.buildStepPlant();
    furnitureGroup.add(monstera);
    furnitureGroup.add(curbBooks);
    furnitureGroup.add(stepPlant);

    return {
      desk,
      deskDrawers,
      monitor,
      laptop,
      keyboard,
      mouse,
      phone,
      notebook,
      deskLamp,
      mug,
      smallPlant,
      headphones,
      chair,
      bed,
      mattress,
      blanket,
      pillow1,
      pillow2,
      pillow3,
      ottoman,
      recordPlayer,
      skateboard,
      catBed
    };
  }

  // MARK: - 1. Desk
  buildDesk() {
    const group = new THREE.Group();
    group.name = 'Desk';

    // Wide Wooden Desktop Plank (spans to left wall and connects naturally to right side)
    const topW = 4.15;
    const topD = 1.75;
    const topH = 0.10;
    const topGeo = new THREE.BoxGeometry(topW, topH, topD);
    const topMesh = new THREE.Mesh(topGeo, this.materials.woodDesk);
    topMesh.position.set(-2.85, 1.65, -2.52);
    topMesh.castShadow = true;
    topMesh.receiveShadow = true;
    group.add(topMesh);

    // Desktop Beveled Edge Lip
    const lipGeo = new THREE.BoxGeometry(topW + 0.04, 0.04, topD + 0.04);
    const lipMesh = new THREE.Mesh(lipGeo, this.materials.woodTrim);
    lipMesh.position.set(-2.85, 1.68, -2.52);
    lipMesh.castShadow = true;
    group.add(lipMesh);

    // Right Side Cabinet / Leg Unit (under desk)
    const rightLegGeo = new THREE.BoxGeometry(0.85, 1.32, 1.55);
    const rightLeg = new THREE.Mesh(rightLegGeo, this.materials.woodDesk);
    rightLeg.position.set(-1.15, MAIN_FLOOR_Y + 1.32 * 0.5, -2.52);
    rightLeg.castShadow = true;
    rightLeg.receiveShadow = true;
    group.add(rightLeg);

    // Right Cabinet Drawer Line Inset & Pull Handle
    const rightDrawerFrontGeo = new THREE.BoxGeometry(0.79, 0.38, 0.03);
    const rightDrawerFront = new THREE.Mesh(rightDrawerFrontGeo, this.materials.woodTrim);
    rightDrawerFront.position.set(-1.15, MAIN_FLOOR_Y + 0.66, -1.74);
    rightDrawerFront.castShadow = true;
    group.add(rightDrawerFront);

    const rightHandleGeo = new THREE.BoxGeometry(0.24, 0.035, 0.04);
    const rightHandle = new THREE.Mesh(rightHandleGeo, this.materials.woodDesk);
    rightHandle.position.set(-1.15, MAIN_FLOOR_Y + 0.66, -1.72);
    rightHandle.castShadow = true;
    group.add(rightHandle);

    // Recessed Modesty Back Panel
    const modestyGeo = new THREE.BoxGeometry(2.3, 0.85, 0.04);
    const modesty = new THREE.Mesh(modestyGeo, this.materials.woodDesk);
    modesty.position.set(-2.60, 1.15, -3.15);
    modesty.castShadow = true;
    group.add(modesty);

    // Bedside Nightstand Unit (Nestled between desk and bed as in reference image)
    const nsW = 0.72;
    const nsH = 1.05;
    const nsD = 1.25;
    const nsX = -0.32;
    const nsZ = -2.55;

    const nsBoxGeo = new THREE.BoxGeometry(nsW, nsH, nsD);
    const nsBox = new THREE.Mesh(nsBoxGeo, this.materials.woodDesk);
    nsBox.position.set(nsX, MAIN_FLOOR_Y + nsH * 0.5, nsZ);
    nsBox.castShadow = true;
    nsBox.receiveShadow = true;
    group.add(nsBox);

    const nsTopGeo = new THREE.BoxGeometry(nsW + 0.04, 0.04, nsD + 0.04);
    const nsTop = new THREE.Mesh(nsTopGeo, this.materials.woodTrim);
    nsTop.position.set(nsX, MAIN_FLOOR_Y + nsH + 0.02, nsZ);
    nsTop.castShadow = true;
    group.add(nsTop);

    const nsDrawerGeo = new THREE.BoxGeometry(nsW - 0.06, 0.32, 0.03);
    const nsDrawer = new THREE.Mesh(nsDrawerGeo, this.materials.woodTrim);
    nsDrawer.position.set(nsX, MAIN_FLOOR_Y + nsH - 0.22, nsZ + nsD * 0.5 + 0.015);
    nsDrawer.castShadow = true;
    group.add(nsDrawer);

    const knobGeo = new THREE.CylinderGeometry(0.025, 0.02, 0.03, 12);
    const knob = new THREE.Mesh(knobGeo, this.materials.woodDesk);
    knob.position.set(nsX, MAIN_FLOOR_Y + nsH - 0.22, nsZ + nsD * 0.5 + 0.035);
    knob.rotation.x = Math.PI * 0.5;
    group.add(knob);

    return group;
  }

  // MARK: - 2. Desk Drawers
  buildDeskDrawers() {
    const group = new THREE.Group();
    group.name = 'Desk_Drawers';

    const cabW = 1.15;
    const cabD = 1.55;
    const cabH = 1.32;

    // Cabinet Main Box
    const boxGeo = new THREE.BoxGeometry(cabW, cabH, cabD);
    const boxMesh = new THREE.Mesh(boxGeo, this.materials.woodDesk);
    boxMesh.position.set(-4.25, MAIN_FLOOR_Y + cabH * 0.5, -2.52);
    boxMesh.castShadow = true;
    boxMesh.receiveShadow = true;
    group.add(boxMesh);

    // Plinth Base Lip
    const plinthGeo = new THREE.BoxGeometry(cabW + 0.04, 0.08, cabD + 0.04);
    const plinth = new THREE.Mesh(plinthGeo, this.materials.woodTrim);
    plinth.position.set(-4.25, MAIN_FLOOR_Y + 0.04, -2.52);
    plinth.castShadow = true;
    group.add(plinth);

    // 3 Inset Drawer Fronts with Horizontal Cutout Pull Handles
    const drawerH = 0.36;
    for (let i = 0; i < 3; i++) {
      const dy = MAIN_FLOOR_Y + 0.12 + i * (drawerH + 0.05) + drawerH * 0.5;

      // Drawer Face Panel
      const faceGeo = new THREE.BoxGeometry(cabW - 0.06, drawerH, 0.035);
      const faceMesh = new THREE.Mesh(faceGeo, this.materials.woodTrim);
      faceMesh.position.set(-4.25, dy, -1.74);
      faceMesh.castShadow = true;
      group.add(faceMesh);

      // Recessed Horizontal Pull Handle
      const handleGeo = new THREE.BoxGeometry(0.35, 0.035, 0.04);
      const handle = new THREE.Mesh(handleGeo, this.materials.woodDesk);
      handle.position.set(-4.25, dy, -1.72);
      handle.castShadow = true;
      group.add(handle);
    }

    return group;
  }

  // MARK: - 3. Monitor
  buildMonitor() {
    const group = new THREE.Group();
    group.name = 'Monitor';

    const deskTopY = 1.70;
    const monX = -3.4;
    const monZ = -2.85;

    // Base Stand Plate
    const baseGeo = new THREE.BoxGeometry(0.65, 0.02, 0.42);
    const baseMesh = new THREE.Mesh(baseGeo, this.materials.metalChrome);
    baseMesh.position.set(monX, deskTopY + 0.01, monZ);
    baseMesh.castShadow = true;
    group.add(baseMesh);

    // Vertical Stand Neck
    const neckGeo = new THREE.BoxGeometry(0.08, 0.62, 0.06);
    const neck = new THREE.Mesh(neckGeo, this.materials.metalChrome);
    neck.position.set(monX, deskTopY + 0.32, monZ - 0.06);
    neck.rotation.x = 0.05;
    neck.castShadow = true;
    group.add(neck);

    // Screen Housing / Outer Bezel
    const screenW = 2.15;
    const screenH = 1.25;
    const screenD = 0.05;
    const bezelGeo = new THREE.BoxGeometry(screenW, screenH, screenD);
    const bezel = new THREE.Mesh(bezelGeo, this.materials.plasticWhite);
    bezel.position.set(monX, deskTopY + 0.88, monZ - 0.02);
    bezel.castShadow = true;
    group.add(bezel);

    // Active Display Screen Plane ("hello ♡" visual)
    const dispGeo = new THREE.PlaneGeometry(screenW - 0.08, screenH - 0.08);
    const display = new THREE.Mesh(dispGeo, this.materials.monitorScreen);
    display.position.set(monX, deskTopY + 0.88, monZ + screenD * 0.5 + 0.002);
    group.add(display);

    return group;
  }

  // MARK: - 4. Laptop
  buildLaptop() {
    const group = new THREE.Group();
    group.name = 'Laptop';

    const x = -1.95;
    const z = -2.62;
    const y = 1.70;

    // Rotated slightly toward the chair
    group.position.set(x, y, z);
    group.rotation.y = 0.32;

    // Base Chassis
    const baseGeo = new THREE.BoxGeometry(0.72, 0.022, 0.52);
    const base = new THREE.Mesh(baseGeo, this.materials.chairFrameCream);
    base.position.set(0, 0.011, 0);
    base.castShadow = true;
    group.add(base);

    // Keyboard Area & Trackpad
    const kbGeo = new THREE.BoxGeometry(0.64, 0.005, 0.28);
    const kb = new THREE.Mesh(kbGeo, this.materials.darkTech);
    kb.position.set(0, 0.023, -0.06);
    group.add(kb);

    const padGeo = new THREE.BoxGeometry(0.24, 0.002, 0.14);
    const pad = new THREE.Mesh(padGeo, this.materials.metalChrome);
    pad.position.set(0, 0.022, 0.15);
    group.add(pad);

    // Angled Display Lid (118 degrees open)
    const lidGroup = new THREE.Group();
    lidGroup.position.set(0, 0.02, -0.25);
    lidGroup.rotation.x = -0.42;

    const lidGeo = new THREE.BoxGeometry(0.72, 0.50, 0.018);
    const lid = new THREE.Mesh(lidGeo, this.materials.chairFrameCream);
    lid.position.set(0, 0.25, 0);
    lid.castShadow = true;
    lidGroup.add(lid);

    const screenGeo = new THREE.PlaneGeometry(0.66, 0.44);
    const screen = new THREE.Mesh(screenGeo, this.materials.darkTech);
    screen.position.set(0, 0.25, 0.01);
    lidGroup.add(screen);

    group.add(lidGroup);
    return group;
  }

  // MARK: - 5. Keyboard
  buildKeyboard() {
    const group = new THREE.Group();
    group.name = 'Keyboard';

    group.position.set(-3.25, 1.70, -2.05);

    // Keyboard Tray / Body
    const bodyGeo = new THREE.BoxGeometry(0.88, 0.024, 0.32);
    const body = new THREE.Mesh(bodyGeo, this.materials.plasticWhite);
    body.position.set(0, 0.012, 0);
    body.castShadow = true;
    group.add(body);

    // Sculpted Keycap Rows
    const keysGeo = new THREE.BoxGeometry(0.82, 0.018, 0.26);
    const keys = new THREE.Mesh(keysGeo, this.materials.fabricCream);
    keys.position.set(0, 0.026, 0);
    keys.castShadow = true;
    group.add(keys);

    return group;
  }

  // MARK: - 6. Mouse
  buildMouse() {
    const group = new THREE.Group();
    group.name = 'Mouse';

    group.position.set(-2.05, 1.70, -2.02);

    const mouseGeo = new THREE.CapsuleGeometry(0.045, 0.07, 8, 16);
    mouseGeo.scale(1.0, 0.55, 1.4);
    const mouseMesh = new THREE.Mesh(mouseGeo, this.materials.plasticWhite);
    mouseMesh.position.set(0, 0.02, 0);
    mouseMesh.castShadow = true;
    group.add(mouseMesh);

    return group;
  }

  // MARK: - 7. Phone
  buildPhone() {
    const group = new THREE.Group();
    group.name = 'Phone';

    group.position.set(-4.12, 1.70, -2.10);
    group.rotation.y = 0.15;

    // Small Wooden Easel Desk Stand
    const standGeo = new THREE.BoxGeometry(0.14, 0.18, 0.16);
    const stand = new THREE.Mesh(standGeo, this.materials.woodHoney);
    stand.position.set(0, 0.09, 0);
    stand.castShadow = true;
    group.add(stand);

    // Smartphone Body tilted back at 65°
    const phoneGeo = new THREE.BoxGeometry(0.12, 0.24, 0.014);
    const phoneMesh = new THREE.Mesh(phoneGeo, this.materials.darkTech);
    phoneMesh.position.set(0, 0.12, 0.04);
    phoneMesh.rotation.x = -0.35;
    phoneMesh.castShadow = true;
    group.add(phoneMesh);

    return group;
  }

  // MARK: - 8. Notebook
  buildNotebook() {
    const group = new THREE.Group();
    group.name = 'Notebook';

    group.position.set(-3.85, 1.70, -1.75);
    group.rotation.y = -0.18;

    // Open Notebook Pages
    const pagesGeo = new THREE.BoxGeometry(0.48, 0.018, 0.34);
    const pages = new THREE.Mesh(pagesGeo, this.materials.notebookMaterial);
    pages.position.set(0, 0.009, 0);
    pages.castShadow = true;
    group.add(pages);

    // Thin Pen resting in spine
    const penGeo = new THREE.CylinderGeometry(0.006, 0.006, 0.26, 8);
    const pen = new THREE.Mesh(penGeo, this.materials.metalChrome);
    pen.position.set(0.02, 0.02, 0);
    pen.rotation.x = Math.PI * 0.5;
    group.add(pen);

    return group;
  }

  // MARK: - 9. Pen Holder
  buildPenHolder() {
    const group = new THREE.Group();
    group.name = 'PenHolder';

    group.position.set(-4.42, 1.70, -2.45);

    // Ceramic Cup
    const cupGeo = new THREE.CylinderGeometry(0.07, 0.06, 0.18, 16);
    const cup = new THREE.Mesh(cupGeo, this.materials.plasticWhite);
    cup.position.set(0, 0.09, 0);
    cup.castShadow = true;
    group.add(cup);

    // Colorful Pencils / Pens inside
    const pencilColors = [0xd68945, 0x8ea889, 0xd8a49c, 0xf7d057];
    for (let i = 0; i < 4; i++) {
      const pGeo = new THREE.CylinderGeometry(0.007, 0.007, 0.24, 6);
      const pMat = new THREE.MeshStandardMaterial({ color: pencilColors[i] });
      const pencil = new THREE.Mesh(pGeo, pMat);
      pencil.position.set((i - 1.5) * 0.025, 0.15, (Math.random() - 0.5) * 0.04);
      pencil.rotation.z = (Math.random() - 0.5) * 0.25;
      pencil.castShadow = true;
      group.add(pencil);
    }

    return group;
  }

  // MARK: - 10. Desk Lamp
  buildDeskLamp() {
    const group = new THREE.Group();
    group.name = 'DeskLamp';

    group.position.set(-1.48, 1.70, -2.95);

    // Weighted Round Base
    const baseGeo = new THREE.CylinderGeometry(0.16, 0.18, 0.03, 24);
    const base = new THREE.Mesh(baseGeo, this.materials.chairFrameCream);
    base.position.set(0, 0.015, 0);
    base.castShadow = true;
    group.add(base);

    // Articulated Curved Stem
    const stemCurve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 0.02, 0),
      new THREE.Vector3(-0.06, 0.35, 0.04),
      new THREE.Vector3(-0.16, 0.62, 0.15),
      new THREE.Vector3(-0.25, 0.52, 0.28)
    ]);
    const stemGeo = new THREE.TubeGeometry(stemCurve, 20, 0.016, 8, false);
    const stem = new THREE.Mesh(stemGeo, this.materials.chairFrameCream);
    stem.castShadow = true;
    group.add(stem);

    // Conical Lamp Shade pointing down onto desk
    const shadeGeo = new THREE.ConeGeometry(0.18, 0.24, 20, 1, true);
    const shade = new THREE.Mesh(shadeGeo, this.materials.chairFrameCream);
    shade.position.set(-0.25, 0.52, 0.28);
    shade.rotation.x = Math.PI * 0.75;
    shade.rotation.y = -0.4;
    shade.castShadow = true;
    group.add(shade);

    // Soft Warm Task Light radiating from shade
    const lampLight = new THREE.PointLight(0xffecd0, 0.9, 4.0, 1.8);
    lampLight.position.set(-0.25, 0.44, 0.28);
    lampLight.castShadow = false; // Soft ambient desk light
    group.add(lampLight);

    return group;
  }

  // MARK: - 11. Mug
  buildMug() {
    const group = new THREE.Group();
    group.name = 'Mug';

    group.position.set(-1.62, 1.70, -2.25);

    // Cup Body
    const cupGeo = new THREE.CylinderGeometry(0.065, 0.06, 0.13, 16);
    const cup = new THREE.Mesh(cupGeo, this.materials.plasticWhite);
    cup.position.set(0, 0.065, 0);
    cup.castShadow = true;
    group.add(cup);

    // Handle
    const handleGeo = new THREE.TorusGeometry(0.04, 0.01, 8, 16, Math.PI);
    const handle = new THREE.Mesh(handleGeo, this.materials.plasticWhite);
    handle.position.set(0.065, 0.065, 0);
    handle.rotation.z = -Math.PI * 0.5;
    group.add(handle);

    return group;
  }

  // MARK: - 12. Small Plant
  buildSmallPlant() {
    const group = new THREE.Group();
    group.name = 'SmallPlant';

    // Sits atop the bedside nightstand between desk and bed (matching reference image)
    group.position.set(-0.32, MAIN_FLOOR_Y + 1.05 + 0.04, -2.55);

    // Ceramic Pot
    const potGeo = new THREE.CylinderGeometry(0.08, 0.065, 0.12, 16);
    const pot = new THREE.Mesh(potGeo, this.materials.plasticWhite);
    pot.position.set(0, 0.06, 0);
    pot.castShadow = true;
    group.add(pot);

    // Succulent Leaves
    for (let i = 0; i < 6; i++) {
      const leafGeo = new THREE.ConeGeometry(0.045, 0.11, 5);
      const leaf = new THREE.Mesh(leafGeo, this.materials.foliageGreen);
      const angle = (i / 6) * Math.PI * 2;
      leaf.position.set(Math.cos(angle) * 0.04, 0.12, Math.sin(angle) * 0.04);
      leaf.rotation.x = Math.sin(angle) * 0.45;
      leaf.rotation.z = -Math.cos(angle) * 0.45;
      leaf.castShadow = true;
      group.add(leaf);
    }

    return group;
  }

  // MARK: - 13. Headphones
  buildHeadphones() {
    const group = new THREE.Group();
    group.name = 'Headphones';

    // Hanging from pegboard behind desk
    group.position.set(-1.58, 3.25, -3.36);

    // Padded Headband
    const bandGeo = new THREE.TorusGeometry(0.14, 0.018, 8, 24, Math.PI);
    const band = new THREE.Mesh(bandGeo, this.materials.chairFrameCream);
    band.rotation.z = Math.PI;
    band.castShadow = true;
    group.add(band);

    // Earcups
    const cupGeo = new THREE.CylinderGeometry(0.065, 0.065, 0.04, 16);
    const cupL = new THREE.Mesh(cupGeo, this.materials.chairFrameCream);
    cupL.position.set(-0.14, 0.04, 0);
    cupL.rotation.z = Math.PI * 0.5;
    cupL.castShadow = true;
    group.add(cupL);

    const cupR = new THREE.Mesh(cupGeo, this.materials.chairFrameCream);
    cupR.position.set(0.14, 0.04, 0);
    cupR.rotation.z = Math.PI * 0.5;
    cupR.castShadow = true;
    group.add(cupR);

    return group;
  }

  // MARK: - 14. Desk Books
  buildDeskBooks() {
    const group = new THREE.Group();
    group.name = 'Books';

    group.position.set(-1.38, 1.70, -1.95);

    const bookColors = [0x8ea889, 0xd8a49c, 0xd69c5e];
    for (let i = 0; i < 3; i++) {
      const bGeo = new THREE.BoxGeometry(0.32, 0.045, 0.24);
      const bMat = new THREE.MeshStandardMaterial({ color: bookColors[i] });
      const book = new THREE.Mesh(bGeo, bMat);
      book.position.set(0, 0.022 + i * 0.046, 0);
      book.rotation.y = (i - 1) * 0.12;
      book.castShadow = true;
      group.add(book);
    }

    return group;
  }

  // MARK: - 15. Office Chair
  buildOfficeChair() {
    const group = new THREE.Group();
    group.name = 'OfficeChair';

    // In front of desk, rotated naturally toward desk/center
    group.position.set(-2.65, MAIN_FLOOR_Y, -0.68);
    group.rotation.y = -0.38;

    // 5-Point Star Wheeled Base
    const baseHubGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.06, 12);
    const baseHub = new THREE.Mesh(baseHubGeo, this.materials.metalChrome);
    baseHub.position.set(0, 0.08, 0);
    baseHub.castShadow = true;
    group.add(baseHub);

    // 5 Radiating Legs with Caster Wheels
    for (let i = 0; i < 5; i++) {
      const angle = (i / 5) * Math.PI * 2;
      const legGeo = new THREE.BoxGeometry(0.42, 0.028, 0.04);
      const leg = new THREE.Mesh(legGeo, this.materials.chairFrameCream);
      leg.position.set(Math.cos(angle) * 0.22, 0.07, Math.sin(angle) * 0.22);
      leg.rotation.y = -angle;
      leg.castShadow = true;
      group.add(leg);

      // Caster Wheel
      const wheelGeo = new THREE.CylinderGeometry(0.028, 0.028, 0.02, 10);
      const wheel = new THREE.Mesh(wheelGeo, this.materials.darkTech);
      wheel.position.set(Math.cos(angle) * 0.40, 0.03, Math.sin(angle) * 0.40);
      wheel.rotation.z = Math.PI * 0.5;
      group.add(wheel);
    }

    // Chrome Hydraulic Cylinder
    const cylinderGeo = new THREE.CylinderGeometry(0.045, 0.045, 0.44, 12);
    const cylinder = new THREE.Mesh(cylinderGeo, this.materials.metalChrome);
    cylinder.position.set(0, 0.32, 0);
    cylinder.castShadow = true;
    group.add(cylinder);

    // Ergonomic Contoured Seat Cushion
    const seatGeo = new THREE.BoxGeometry(0.78, 0.12, 0.72);
    const seat = new THREE.Mesh(seatGeo, this.materials.fabricChairGray);
    seat.position.set(0, 0.58, 0);
    seat.castShadow = true;
    group.add(seat);

    // Seat Outer White Shell
    const shellGeo = new THREE.BoxGeometry(0.82, 0.04, 0.76);
    const shell = new THREE.Mesh(shellGeo, this.materials.chairFrameCream);
    shell.position.set(0, 0.52, 0);
    shell.castShadow = true;
    group.add(shell);

    // Contoured Ergonomic Backrest with Cream Frame
    const backGroup = new THREE.Group();
    backGroup.position.set(0, 0.64, -0.34);
    backGroup.rotation.x = -0.12;

    const backSpineGeo = new THREE.BoxGeometry(0.08, 0.76, 0.06);
    const spine = new THREE.Mesh(backSpineGeo, this.materials.chairFrameCream);
    spine.position.set(0, 0.40, -0.04);
    backGroup.add(spine);

    const backGeo = new THREE.BoxGeometry(0.70, 0.74, 0.09);
    const backrest = new THREE.Mesh(backGeo, this.materials.fabricChairGray);
    backrest.position.set(0, 0.42, 0.02);
    backrest.castShadow = true;
    backGroup.add(backrest);

    // Back Outer White Frame Rim
    const backFrameGeo = new THREE.BoxGeometry(0.74, 0.78, 0.04);
    const backFrame = new THREE.Mesh(backFrameGeo, this.materials.chairFrameCream);
    backFrame.position.set(0, 0.42, -0.03);
    backGroup.add(backFrame);

    group.add(backGroup);

    // Left and Right Sweeping Armrests
    const armL = this.createArmrest(-0.41);
    const armR = this.createArmrest(0.41);
    group.add(armL);
    group.add(armR);

    return group;
  }

  createArmrest(xOffset) {
    const armGroup = new THREE.Group();
    armGroup.position.set(xOffset, 0.54, 0);

    // Vertical Support
    const postGeo = new THREE.BoxGeometry(0.04, 0.30, 0.06);
    const post = new THREE.Mesh(postGeo, this.materials.chairFrameCream);
    post.position.set(0, 0.15, 0.04);
    post.castShadow = true;
    armGroup.add(post);

    // Armrest Pad
    const padGeo = new THREE.BoxGeometry(0.09, 0.03, 0.38);
    const pad = new THREE.Mesh(padGeo, this.materials.chairFrameCream);
    pad.position.set(0, 0.30, 0.06);
    pad.castShadow = true;
    armGroup.add(pad);

    return armGroup;
  }

  // MARK: - 16. Desk Rug
  buildDeskRug() {
    const group = new THREE.Group();
    group.name = 'DeskRug';

    // Sits flat on the floor under the desk chair
    const rugW = 2.9;
    const rugD = 2.2;
    const rugGeo = new THREE.PlaneGeometry(rugW, rugD);
    const rugMesh = new THREE.Mesh(rugGeo, this.materials.rugMaterial);
    rugMesh.position.set(-2.7, MAIN_FLOOR_Y + 0.005, -0.7);
    rugMesh.rotation.x = -Math.PI * 0.5;
    rugMesh.receiveShadow = true;
    group.add(rugMesh);

    return group;
  }

  // MARK: - 17. Bed
  buildBed() {
    const group = new THREE.Group();
    group.name = 'Bed';

    const bedW = 3.25;
    const bedD = 3.75;
    const bedX = 1.85;
    const bedZ = -1.45;

    // Headboard (against built-in shelves)
    const headboardH = 1.45;
    const headboardGeo = new THREE.BoxGeometry(bedW, headboardH, 0.16);
    const headboard = new THREE.Mesh(headboardGeo, this.materials.woodBed);
    headboard.position.set(bedX, MAIN_FLOOR_Y + headboardH * 0.5, -3.32);
    headboard.castShadow = true;
    headboard.receiveShadow = true;
    group.add(headboard);

    // Footboard (facing front toward viewer)
    const footboardH = 0.95;
    const footboardGeo = new THREE.BoxGeometry(bedW, footboardH, 0.16);
    const footboard = new THREE.Mesh(footboardGeo, this.materials.woodBed);
    footboard.position.set(bedX, MAIN_FLOOR_Y + footboardH * 0.5, 0.42);
    footboard.castShadow = true;
    footboard.receiveShadow = true;
    group.add(footboard);

    // Left and Right Side Rails
    const railH = 0.44;
    const railGeo = new THREE.BoxGeometry(0.14, railH, bedD - 0.2);
    const railL = new THREE.Mesh(railGeo, this.materials.woodBed);
    railL.position.set(bedX - bedW * 0.5 + 0.07, MAIN_FLOOR_Y + railH * 0.5 + 0.22, -1.45);
    railL.castShadow = true;
    group.add(railL);

    const railR = new THREE.Mesh(railGeo, this.materials.woodBed);
    railR.position.set(bedX + bedW * 0.5 - 0.07, MAIN_FLOOR_Y + railH * 0.5 + 0.22, -1.45);
    railR.castShadow = true;
    group.add(railR);

    // 4 Sturdy Wooden Corner Legs
    const legGeo = new THREE.BoxGeometry(0.16, 0.48, 0.16);
    const legPositions = [
      [bedX - bedW * 0.5 + 0.08, -3.24],
      [bedX + bedW * 0.5 - 0.08, -3.24],
      [bedX - bedW * 0.5 + 0.08, 0.34],
      [bedX + bedW * 0.5 - 0.08, 0.34]
    ];
    for (const [lx, lz] of legPositions) {
      const leg = new THREE.Mesh(legGeo, this.materials.woodTrim);
      leg.position.set(lx, MAIN_FLOOR_Y + 0.24, lz);
      leg.castShadow = true;
      group.add(leg);
    }

    return group;
  }

  // MARK: - 18. Mattress
  buildMattress() {
    const group = new THREE.Group();
    group.name = 'Mattress';

    const matW = 2.95;
    const matD = 3.55;
    const matH = 0.46;

    const matGeo = new THREE.BoxGeometry(matW, matH, matD);
    const matMesh = new THREE.Mesh(matGeo, this.materials.fabricCream);
    matMesh.position.set(1.85, MAIN_FLOOR_Y + 0.44 + matH * 0.5, -1.45);
    matMesh.castShadow = true;
    matMesh.receiveShadow = true;
    group.add(matMesh);

    return group;
  }

  // MARK: - 19. Blanket
  buildBlanket() {
    const group = new THREE.Group();
    group.name = 'Blanket';

    // Folded sage green duvet across the lower half of the mattress
    const bW = 3.02;
    const bD = 2.15;
    const bH = 0.14;

    const bGeo = new THREE.BoxGeometry(bW, bH, bD);
    const bMesh = new THREE.Mesh(bGeo, this.materials.fabricSage);
    bMesh.position.set(1.85, MAIN_FLOOR_Y + 0.88 + bH * 0.5, -0.42);
    bMesh.castShadow = true;
    bMesh.receiveShadow = true;
    group.add(bMesh);

    // Turned-down Top Fold
    const foldGeo = new THREE.BoxGeometry(bW + 0.02, 0.09, 0.52);
    const fold = new THREE.Mesh(foldGeo, this.materials.fabricSage);
    fold.position.set(1.85, MAIN_FLOOR_Y + 0.94 + 0.045, -1.25);
    fold.castShadow = true;
    group.add(fold);

    // Delicate bottom hem / fringe bar
    const fringeGeo = new THREE.BoxGeometry(bW, 0.06, 0.08);
    const fringe = new THREE.Mesh(fringeGeo, this.materials.fabricCream);
    fringe.position.set(1.85, MAIN_FLOOR_Y + 0.88, 0.62);
    group.add(fringe);

    return group;
  }

  // MARK: - 20. Pillows
  buildPillow01() {
    const group = new THREE.Group();
    group.name = 'Pillow_01';

    // Cream Large Sleeping Pillow on left
    const geo = new THREE.BoxGeometry(0.95, 0.24, 0.58);
    const mesh = new THREE.Mesh(geo, this.materials.fabricCream);
    mesh.castShadow = true;
    group.add(mesh);

    group.position.set(1.05, MAIN_FLOOR_Y + 1.02, -2.75);
    group.rotation.x = 0.28;
    group.rotation.y = 0.08;

    return group;
  }

  buildPillow02() {
    const group = new THREE.Group();
    group.name = 'Pillow_02';

    // Muted Beige / Sand Pillow in center with tactile normal map
    const geo = new THREE.BoxGeometry(0.85, 0.22, 0.52);
    const mesh = new THREE.Mesh(geo, this.materials.fabricBeige);
    mesh.castShadow = true;
    group.add(mesh);

    group.position.set(1.85, MAIN_FLOOR_Y + 1.05, -2.62);
    group.rotation.x = 0.32;
    group.rotation.y = -0.12;

    return group;
  }

  buildPillow03() {
    const group = new THREE.Group();
    group.name = 'Pillow_03';

    // Sage Green Square Pillow on right
    const geo = new THREE.BoxGeometry(0.68, 0.22, 0.58);
    const mesh = new THREE.Mesh(geo, this.materials.fabricSage);
    mesh.castShadow = true;
    group.add(mesh);

    group.position.set(2.65, MAIN_FLOOR_Y + 1.08, -2.65);
    group.rotation.x = 0.25;
    group.rotation.y = 0.15;

    return group;
  }

  buildFlowerPillow() {
    const group = new THREE.Group();
    group.name = 'FlowerPillow';

    // Decorative White Daisy Flower Cushion with Yellow Center
    group.position.set(2.95, MAIN_FLOOR_Y + 0.95, -2.05);
    group.rotation.x = 0.30;
    group.rotation.y = -0.25;

    // Center Yellow Button
    const centerGeo = new THREE.CylinderGeometry(0.12, 0.12, 0.08, 16);
    const center = new THREE.Mesh(centerGeo, this.materials.daisyYellow);
    center.castShadow = true;
    group.add(center);

    // 6 White Rounded Petals
    for (let i = 0; i < 6; i++) {
      const angle = (i / 6) * Math.PI * 2;
      const petalGeo = new THREE.SphereGeometry(0.14, 12, 12);
      petalGeo.scale(1.0, 0.45, 1.4);
      const petal = new THREE.Mesh(petalGeo, this.materials.petalWhite);
      petal.position.set(Math.cos(angle) * 0.22, 0, Math.sin(angle) * 0.22);
      petal.rotation.y = -angle;
      petal.castShadow = true;
      group.add(petal);
    }

    return group;
  }

  // MARK: - 21. Ottoman
  buildOttoman() {
    const group = new THREE.Group();
    group.name = 'Ottoman';

    const ottW = 1.45;
    const ottD = 1.35;
    const ottX = 2.95;
    const ottZ = 1.15;

    // 4 Honey Oak Legs
    const legGeo = new THREE.BoxGeometry(0.10, 0.38, 0.10);
    const legOffsets = [
      [-ottW * 0.5 + 0.12, -ottD * 0.5 + 0.12],
      [ottW * 0.5 - 0.12, -ottD * 0.5 + 0.12],
      [-ottW * 0.5 + 0.12, ottD * 0.5 - 0.12],
      [ottW * 0.5 - 0.12, ottD * 0.5 - 0.12]
    ];
    for (const [ox, oz] of legOffsets) {
      const leg = new THREE.Mesh(legGeo, this.materials.woodTrim);
      leg.position.set(ottX + ox, MAIN_FLOOR_Y + 0.19, ottZ + oz);
      leg.castShadow = true;
      group.add(leg);
    }

    // Wooden Base Plinth
    const plinthGeo = new THREE.BoxGeometry(ottW, 0.08, ottD);
    const plinth = new THREE.Mesh(plinthGeo, this.materials.woodHoney);
    plinth.position.set(ottX, MAIN_FLOOR_Y + 0.38, ottZ);
    plinth.castShadow = true;
    group.add(plinth);

    // Thick Sage Fabric Cushion
    const cushionGeo = new THREE.BoxGeometry(ottW + 0.04, 0.36, ottD + 0.04);
    const cushion = new THREE.Mesh(cushionGeo, this.materials.fabricSage);
    cushion.position.set(ottX, MAIN_FLOOR_Y + 0.42 + 0.18, ottZ);
    cushion.castShadow = true;
    cushion.receiveShadow = true;
    group.add(cushion);

    return group;
  }

  // MARK: - 22. Record Player & Vinyl
  buildRecordPlayer() {
    const group = new THREE.Group();
    group.name = 'RecordPlayer';

    // Sits at the foot of the bed / ottoman ledge
    group.position.set(3.40, MAIN_FLOOR_Y + 0.78, 0.60);

    // Turntable Base Case (Vintage Dusty Rose Suitcase)
    const baseW = 0.72;
    const baseD = 0.62;
    const baseH = 0.14;
    const baseGeo = new THREE.BoxGeometry(baseW, baseH, baseD);
    const base = new THREE.Mesh(baseGeo, this.materials.recordPlayerCase);
    base.position.set(0, baseH * 0.5, 0);
    base.castShadow = true;
    group.add(base);

    // Turntable Platter
    const platterGeo = new THREE.CylinderGeometry(0.24, 0.24, 0.02, 24);
    const platter = new THREE.Mesh(platterGeo, this.materials.darkTech);
    platter.position.set(-0.06, baseH + 0.01, 0);
    group.add(platter);

    // Spindle
    const spindleGeo = new THREE.CylinderGeometry(0.01, 0.01, 0.04, 12);
    const spindle = new THREE.Mesh(spindleGeo, this.materials.metalChrome);
    spindle.position.set(-0.06, baseH + 0.03, 0);
    group.add(spindle);

    // Independent Vinyl Record Mesh (Can spin!)
    const vinylGeo = new THREE.CylinderGeometry(0.23, 0.23, 0.008, 32);
    const vinylMesh = new THREE.Mesh(vinylGeo, this.materials.vinylMaterial);
    vinylMesh.position.set(-0.06, baseH + 0.02, 0);
    vinylMesh.name = 'Vinyl';
    vinylMesh.castShadow = true;
    group.add(vinylMesh);

    // Tonearm with Cartridge and Pivot
    const pivotGeo = new THREE.CylinderGeometry(0.025, 0.025, 0.06, 12);
    const pivot = new THREE.Mesh(pivotGeo, this.materials.metalChrome);
    pivot.position.set(0.24, baseH + 0.04, -0.18);
    group.add(pivot);

    const armGeo = new THREE.CylinderGeometry(0.006, 0.006, 0.32, 8);
    const arm = new THREE.Mesh(armGeo, this.materials.metalChrome);
    arm.position.set(0.14, baseH + 0.06, -0.04);
    arm.rotation.x = Math.PI * 0.5;
    arm.rotation.z = 0.42;
    group.add(arm);

    // Open Hinged Lid (Angled back at 65 degrees)
    const lidGroup = new THREE.Group();
    lidGroup.position.set(0, baseH, -baseD * 0.5);
    lidGroup.rotation.x = -0.95;

    const lidGeo = new THREE.BoxGeometry(baseW, baseH * 0.8, baseD);
    const lid = new THREE.Mesh(lidGeo, this.materials.recordPlayerCase);
    lid.position.set(0, (baseH * 0.8) * 0.5, baseD * 0.5);
    lid.castShadow = true;
    lidGroup.add(lid);
    group.add(lidGroup);

    // Stack of Album Jackets beside the player
    const jacketGroup = new THREE.Group();
    jacketGroup.position.set(-0.55, 0, 0.12);
    const jacketColors = [0xdfab6f, 0x8ea889, 0xd8a49c];
    for (let i = 0; i < 3; i++) {
      const jGeo = new THREE.BoxGeometry(0.42, 0.015, 0.42);
      const jMat = new THREE.MeshStandardMaterial({ color: jacketColors[i] });
      const jacket = new THREE.Mesh(jGeo, jMat);
      jacket.position.set(0, 0.008 + i * 0.018, 0);
      jacket.rotation.y = (i - 1) * 0.15;
      jacket.castShadow = true;
      jacketGroup.add(jacket);
    }
    group.add(jacketGroup);

    return group;
  }

  // MARK: - 23. Skateboard
  buildSkateboard() {
    const group = new THREE.Group();
    group.name = 'Skateboard';

    // Resting on the raised platform step in the foreground
    group.position.set(1.15, 0.22, 2.05);
    group.rotation.y = -0.14;

    const deckL = 1.35;
    const deckW = 0.36;
    const deckH = 0.024;

    // Wooden Maple Deck Body
    const deckGeo = new THREE.BoxGeometry(deckL, deckH, deckW);
    const deck = new THREE.Mesh(deckGeo, this.materials.woodHoney);
    deck.position.set(0, 0.08, 0);
    deck.castShadow = true;
    group.add(deck);

    // Black Grip Tape on Top
    const gripGeo = new THREE.BoxGeometry(deckL - 0.04, 0.005, deckW - 0.04);
    const grip = new THREE.Mesh(gripGeo, this.materials.gripTape);
    grip.position.set(0, 0.08 + deckH * 0.5 + 0.003, 0);
    group.add(grip);

    // Front & Rear Aluminum Trucks & 4 Wheels
    const truckOffsets = [-deckL * 0.35, deckL * 0.35];
    for (const tx of truckOffsets) {
      // Truck Axle
      const axleGeo = new THREE.CylinderGeometry(0.015, 0.015, deckW + 0.04, 8);
      const axle = new THREE.Mesh(axleGeo, this.materials.metalChrome);
      axle.position.set(tx, 0.045, 0);
      axle.rotation.x = Math.PI * 0.5;
      group.add(axle);

      // Left & Right Wheels
      const wheelGeo = new THREE.CylinderGeometry(0.04, 0.04, 0.045, 16);
      const wheelL = new THREE.Mesh(wheelGeo, this.materials.darkTech);
      wheelL.position.set(tx, 0.04, -deckW * 0.5 - 0.02);
      wheelL.rotation.x = Math.PI * 0.5;
      wheelL.castShadow = true;
      group.add(wheelL);

      const wheelR = new THREE.Mesh(wheelGeo, this.materials.darkTech);
      wheelR.position.set(tx, 0.04, deckW * 0.5 + 0.02);
      wheelR.rotation.x = Math.PI * 0.5;
      wheelR.castShadow = true;
      group.add(wheelR);
    }

    return group;
  }

  // MARK: - 24. Cat Bed (Bouclé Pouf)
  buildCatBed() {
    const group = new THREE.Group();
    group.name = 'CatBed';

    // On lower front deck on the right
    group.position.set(3.45, LOWER_FLOOR_Y + 0.02, 3.25);

    // Large Round Bouclé Donut Pouf Cushion
    const radius = 0.85;
    const height = 0.44;

    const poufGeo = new THREE.CylinderGeometry(radius * 0.85, radius, height, 24);
    const pouf = new THREE.Mesh(poufGeo, this.materials.boucleCream);
    pouf.position.set(0, height * 0.5, 0);
    pouf.castShadow = true;
    pouf.receiveShadow = true;
    group.add(pouf);

    // Soft Recessed Center Concavity where Cookie can sleep
    const indentGeo = new THREE.CylinderGeometry(radius * 0.55, radius * 0.45, 0.12, 20);
    const indent = new THREE.Mesh(indentGeo, this.materials.boucleCream);
    indent.position.set(0, height - 0.04, 0);
    group.add(indent);

    // Mini Flower Pillow inside/atop Cat Bed
    const miniFlower = new THREE.Group();
    miniFlower.position.set(0, height + 0.04, 0);

    const centerGeo = new THREE.CylinderGeometry(0.09, 0.09, 0.06, 12);
    const center = new THREE.Mesh(centerGeo, this.materials.daisyYellow);
    miniFlower.add(center);

    for (let i = 0; i < 5; i++) {
      const angle = (i / 5) * Math.PI * 2;
      const petalGeo = new THREE.SphereGeometry(0.11, 10, 10);
      petalGeo.scale(1.0, 0.45, 1.3);
      const petal = new THREE.Mesh(petalGeo, this.materials.petalWhite);
      petal.position.set(Math.cos(angle) * 0.16, 0, Math.sin(angle) * 0.16);
      petal.rotation.y = -angle;
      miniFlower.add(petal);
    }
    group.add(miniFlower);

    return group;
  }

  // MARK: - 25. Floor Decor: Monstera Plant
  buildMonsteraPlant() {
    const group = new THREE.Group();
    group.name = 'MonsteraPlant';

    group.position.set(4.35, MAIN_FLOOR_Y, 1.45);

    // Ceramic White Planter
    const potGeo = new THREE.CylinderGeometry(0.24, 0.18, 0.42, 20);
    const pot = new THREE.Mesh(potGeo, this.materials.plasticWhite);
    pot.position.set(0, 0.21, 0);
    pot.castShadow = true;
    group.add(pot);

    // Soil
    const soilGeo = new THREE.CylinderGeometry(0.22, 0.22, 0.04, 16);
    const soilMat = new THREE.MeshStandardMaterial({ color: 0x3d2716 });
    const soil = new THREE.Mesh(soilGeo, soilMat);
    soil.position.set(0, 0.40, 0);
    group.add(soil);

    // Large Fan Monstera Leaves with natural color variations
    const leafAngles = [0.2, 1.4, 2.6, 3.8, 5.0];
    const leafMats = [
      this.materials.foliageGreen,
      this.materials.foliageOlive,
      this.materials.foliageDeep,
      this.materials.foliageGoldenGreen,
      this.materials.foliageGreen
    ];
    for (let i = 0; i < leafAngles.length; i++) {
      const a = leafAngles[i];
      const stemCurve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(0, 0.40, 0),
        new THREE.Vector3(Math.cos(a) * 0.18, 0.65, Math.sin(a) * 0.18),
        new THREE.Vector3(Math.cos(a) * 0.38, 0.88 + i * 0.08, Math.sin(a) * 0.38)
      ]);
      const stemGeo = new THREE.TubeGeometry(stemCurve, 10, 0.015, 6, false);
      const stem = new THREE.Mesh(stemGeo, leafMats[i % leafMats.length]);
      group.add(stem);

      // Broad Leaf
      const leafGeo = new THREE.PlaneGeometry(0.38, 0.52);
      const leaf = new THREE.Mesh(leafGeo, leafMats[i % leafMats.length]);
      leaf.position.set(Math.cos(a) * 0.38, 0.88 + i * 0.08, Math.sin(a) * 0.38);
      leaf.rotation.x = -Math.PI * 0.35;
      leaf.rotation.y = a;
      leaf.castShadow = true;
      group.add(leaf);
    }

    return group;
  }

  // MARK: - 26. Floor Decor: Curb Books & Plant
  buildCurbBooksAndPlant() {
    const group = new THREE.Group();
    group.name = 'CurbBooks';

    // On front-left raised platform curb
    group.position.set(-3.25, MAIN_FLOOR_Y + 0.14, 2.25);

    // Stack of 2 Hardcover Books with textured Paper finish
    const b1Geo = new THREE.BoxGeometry(0.38, 0.05, 0.28);
    const b1Mat = new THREE.MeshStandardMaterial({
      color: 0xc89658,
      roughness: 0.92,
      metalness: 0.0
    });
    const b1 = new THREE.Mesh(b1Geo, b1Mat);
    b1.position.set(0, 0.025, 0);
    b1.castShadow = true;
    group.add(b1);

    const b2Geo = new THREE.BoxGeometry(0.34, 0.045, 0.26);
    const b2Mat = new THREE.MeshStandardMaterial({
      color: 0x8ea889,
      roughness: 0.90,
      metalness: 0.0
    });
    const b2 = new THREE.Mesh(b2Geo, b2Mat);
    b2.position.set(0.01, 0.072, 0.01);
    b2.rotation.y = 0.14;
    b2.castShadow = true;
    group.add(b2);

    // Small Potted Plant on top of the books (Ceramic_Cream pot)
    const potGeo = new THREE.CylinderGeometry(0.065, 0.05, 0.10, 12);
    const pot = new THREE.Mesh(potGeo, this.materials.plasticWhite);
    pot.position.set(0, 0.145, 0);
    pot.castShadow = true;
    group.add(pot);

    const plantGeo = new THREE.SphereGeometry(0.07, 8, 8);
    const plant = new THREE.Mesh(plantGeo, this.materials.foliageOlive);
    plant.position.set(0, 0.21, 0);
    plant.castShadow = true;
    group.add(plant);

    return group;
  }

  // MARK: - 27. Step Plant
  buildStepPlant() {
    const group = new THREE.Group();
    group.name = 'StepPlant';

    // On corner of lower front step
    group.position.set(-0.85, LOWER_FLOOR_Y + 0.06, 2.92);

    const potGeo = new THREE.BoxGeometry(0.12, 0.12, 0.12);
    const pot = new THREE.Mesh(potGeo, this.materials.plasticWhite);
    pot.position.set(0, 0.06, 0);
    pot.castShadow = true;
    group.add(pot);

    const plantGeo = new THREE.DodecahedronGeometry(0.07, 1);
    const plant = new THREE.Mesh(plantGeo, this.materials.foliageGoldenGreen);
    plant.position.set(0, 0.15, 0);
    plant.castShadow = true;
    group.add(plant);

    return group;
  }
}
