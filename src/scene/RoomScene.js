/**
 * Nook 3D - RoomScene
 * Manages the scene graph hierarchy, architecture, and diorama foundation
 * based on the nook-room.jpeg reference composition.
 *
 * Scene Root Hierarchy:
 * NookWorld
 *   ├── Architecture
 *   ├── Furniture
 *   ├── Decorations
 *   ├── InteractiveObjects
 *   ├── Cookie
 *   ├── Lighting
 *   └── Environment
 */

import * as THREE from 'three';
import {
  ROOM_WIDTH,
  ROOM_DEPTH,
  ROOM_HEIGHT,
  WALL_THICKNESS,
  FLOOR_THICKNESS,
  WOOD_TRIM_HEIGHT,
  WOOD_TRIM_DEPTH,
  UPPER_FLOOR_Y,
  LOWER_FLOOR_Y,
  PALETTE
} from '../utils/Constants.js';
import { Lighting } from './Lighting.js';
import { Environment } from './Environment.js';

export class RoomScene {
  constructor() {
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(PALETTE.environmentBg);

    // Root Group: NookWorld
    this.world = new THREE.Group();
    this.world.name = 'NookWorld';
    this.scene.add(this.world);

    // Primary Hierarchies
    this.architecture = new THREE.Group();
    this.architecture.name = 'Architecture';
    this.world.add(this.architecture);

    this.furniture = new THREE.Group();
    this.furniture.name = 'Furniture';
    this.world.add(this.furniture);

    this.decorations = new THREE.Group();
    this.decorations.name = 'Decorations';
    this.world.add(this.decorations);

    this.interactiveObjects = new THREE.Group();
    this.interactiveObjects.name = 'InteractiveObjects';
    this.world.add(this.interactiveObjects);

    this.cookieGroup = new THREE.Group();
    this.cookieGroup.name = 'Cookie';
    this.world.add(this.cookieGroup);

    // Subsystems
    this.lighting = new Lighting(this.world);
    this.environment = new Environment(this.world);

    // Materials Library
    this.materials = this.createMaterials();

    // Construct Architecture & Foundational Layout
    this.buildArchitecture();
    this.buildFoundationalFurniture();
    this.buildFoundationalDecorations();
  }

  createMaterials() {
    return {
      wallCream: new THREE.MeshStandardMaterial({
        color: PALETTE.wallCream,
        roughness: 0.85,
        metalness: 0.02
      }),
      woodHoney: new THREE.MeshStandardMaterial({
        color: PALETTE.woodHoney,
        roughness: 0.55,
        metalness: 0.05
      }),
      woodFloorLight: new THREE.MeshStandardMaterial({
        color: PALETTE.woodFloorLight,
        roughness: 0.45,
        metalness: 0.04
      }),
      woodTrim: new THREE.MeshStandardMaterial({
        color: PALETTE.woodTrim,
        roughness: 0.5,
        metalness: 0.05
      }),
      woodOakDark: new THREE.MeshStandardMaterial({
        color: PALETTE.woodOakDark,
        roughness: 0.6,
        metalness: 0.05
      }),
      bedSheets: new THREE.MeshStandardMaterial({
        color: PALETTE.bedSheets,
        roughness: 0.9,
        metalness: 0.0
      }),
      bedBlanket: new THREE.MeshStandardMaterial({
        color: PALETTE.bedBlanketSage,
        roughness: 0.85,
        metalness: 0.0
      }),
      pillowCream: new THREE.MeshStandardMaterial({
        color: PALETTE.bedPillowCream,
        roughness: 0.9
      }),
      pillowSage: new THREE.MeshStandardMaterial({
        color: PALETTE.bedPillowSage,
        roughness: 0.88
      }),
      poufBoucle: new THREE.MeshStandardMaterial({
        color: PALETTE.poufBoucle,
        roughness: 0.95
      }),
      rug: new THREE.MeshStandardMaterial({
        color: PALETTE.rugCream,
        roughness: 0.92
      }),
      glassWindow: new THREE.MeshPhysicalMaterial({
        color: 0xffffff,
        transparent: true,
        opacity: 0.25,
        roughness: 0.1,
        transmission: 0.85,
        ior: 1.5
      }),
      curtains: new THREE.MeshStandardMaterial({
        color: 0xfcfbfa,
        roughness: 0.9,
        transparent: true,
        opacity: 0.88
      }),
      leaves: new THREE.MeshStandardMaterial({
        color: PALETTE.plantGreen,
        roughness: 0.6
      }),
      ceramic: new THREE.MeshStandardMaterial({
        color: PALETTE.ceramicWhite,
        roughness: 0.25
      })
    };
  }

  buildArchitecture() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // 1. Solid Left Wall (-X)
    const leftWallGeo = new THREE.BoxGeometry(WALL_THICKNESS, ROOM_HEIGHT, ROOM_DEPTH);
    const leftWall = new THREE.Mesh(leftWallGeo, this.materials.wallCream);
    leftWall.position.set(-halfW - WALL_THICKNESS * 0.5, ROOM_HEIGHT * 0.5 + LOWER_FLOOR_Y, 0);
    leftWall.receiveShadow = true;
    leftWall.castShadow = true;
    leftWall.name = 'LeftWall';
    this.architecture.add(leftWall);

    // Left Wall Top Header Wood Trim
    const leftTrimGeo = new THREE.BoxGeometry(WOOD_TRIM_DEPTH, WOOD_TRIM_HEIGHT, ROOM_DEPTH + WOOD_TRIM_DEPTH);
    const leftTrim = new THREE.Mesh(leftTrimGeo, this.materials.woodTrim);
    leftTrim.position.set(-halfW - WALL_THICKNESS * 0.5, ROOM_HEIGHT + LOWER_FLOOR_Y + WOOD_TRIM_HEIGHT * 0.5, -WOOD_TRIM_DEPTH * 0.25);
    leftTrim.castShadow = true;
    leftTrim.receiveShadow = true;
    this.architecture.add(leftTrim);

    // 2. Solid Back Wall (-Z)
    const backWallGeo = new THREE.BoxGeometry(ROOM_WIDTH, ROOM_HEIGHT, WALL_THICKNESS);
    const backWall = new THREE.Mesh(backWallGeo, this.materials.wallCream);
    backWall.position.set(0, ROOM_HEIGHT * 0.5 + LOWER_FLOOR_Y, -halfD - WALL_THICKNESS * 0.5);
    backWall.receiveShadow = true;
    backWall.castShadow = true;
    backWall.name = 'BackWall';
    this.architecture.add(backWall);

    // Back Wall Top Header Wood Trim
    const backTrimGeo = new THREE.BoxGeometry(ROOM_WIDTH + WOOD_TRIM_DEPTH, WOOD_TRIM_HEIGHT, WOOD_TRIM_DEPTH);
    const backTrim = new THREE.Mesh(backTrimGeo, this.materials.woodTrim);
    backTrim.position.set(-WOOD_TRIM_DEPTH * 0.25, ROOM_HEIGHT + LOWER_FLOOR_Y + WOOD_TRIM_HEIGHT * 0.5, -halfD - WALL_THICKNESS * 0.5);
    backTrim.castShadow = true;
    backTrim.receiveShadow = true;
    this.architecture.add(backTrim);

    // 3. Right Wall (+X) with Window Cutaway Aperture
    // In reference: Back half of right wall has a large cozy window, front portion is cut open
    const windowWallWidth = ROOM_DEPTH * 0.55;
    const rightWallBottomGeo = new THREE.BoxGeometry(WALL_THICKNESS, 0.76, windowWallWidth);
    const rightWallBottom = new THREE.Mesh(rightWallBottomGeo, this.materials.wallCream);
    rightWallBottom.position.set(halfW + WALL_THICKNESS * 0.5, 0.38 + LOWER_FLOOR_Y, -halfD + windowWallWidth * 0.5);
    rightWallBottom.receiveShadow = true;
    rightWallBottom.castShadow = true;
    this.architecture.add(rightWallBottom);

    const rightWallTopGeo = new THREE.BoxGeometry(WALL_THICKNESS, 0.55, windowWallWidth);
    const rightWallTop = new THREE.Mesh(rightWallTopGeo, this.materials.wallCream);
    rightWallTop.position.set(halfW + WALL_THICKNESS * 0.5, ROOM_HEIGHT + LOWER_FLOOR_Y - 0.275, -halfD + windowWallWidth * 0.5);
    rightWallTop.castShadow = true;
    this.architecture.add(rightWallTop);

    // Window Wooden Frame & Sill
    const windowFrameGeo = new THREE.BoxGeometry(WALL_THICKNESS + 0.08, 1.35, 1.55);
    const windowFrameMat = this.materials.woodHoney;
    const windowFrame = new THREE.Mesh(windowFrameGeo, windowFrameMat);
    windowFrame.position.set(halfW + WALL_THICKNESS * 0.5, 1.42 + LOWER_FLOOR_Y, -0.9);
    windowFrame.castShadow = true;
    windowFrame.receiveShadow = true;
    this.architecture.add(windowFrame);

    // Window Sill Shelf (matching reference with small plants)
    const sillGeo = new THREE.BoxGeometry(WALL_THICKNESS + 0.22, 0.08, 1.75);
    const sill = new THREE.Mesh(sillGeo, this.materials.woodTrim);
    sill.position.set(halfW - 0.04, 0.76 + LOWER_FLOOR_Y, -0.9);
    sill.castShadow = true;
    sill.receiveShadow = true;
    this.architecture.add(sill);

    // Window Glass Pane
    const windowGlassGeo = new THREE.BoxGeometry(0.02, 1.25, 1.45);
    const windowGlass = new THREE.Mesh(windowGlassGeo, this.materials.glassWindow);
    windowGlass.position.set(halfW + WALL_THICKNESS * 0.5, 1.42 + LOWER_FLOOR_Y, -0.9);
    this.architecture.add(windowGlass);

    // Right Wall Top Header Trim
    const rightTrimGeo = new THREE.BoxGeometry(WOOD_TRIM_DEPTH, WOOD_TRIM_HEIGHT, windowWallWidth);
    const rightTrim = new THREE.Mesh(rightTrimGeo, this.materials.woodTrim);
    rightTrim.position.set(halfW + WALL_THICKNESS * 0.5, ROOM_HEIGHT + LOWER_FLOOR_Y + WOOD_TRIM_HEIGHT * 0.5, -halfD + windowWallWidth * 0.5);
    rightTrim.castShadow = true;
    this.architecture.add(rightTrim);

    // 4. Stepped Wood Floor Architecture
    // Base Plinth Slab
    const baseFloorGeo = new THREE.BoxGeometry(ROOM_WIDTH, FLOOR_THICKNESS, ROOM_DEPTH);
    const baseFloor = new THREE.Mesh(baseFloorGeo, this.materials.woodFloorLight);
    baseFloor.position.set(0, LOWER_FLOOR_Y - FLOOR_THICKNESS * 0.5, 0);
    baseFloor.receiveShadow = true;
    baseFloor.name = 'BaseFloorSlab';
    this.architecture.add(baseFloor);

    // Raised Upper Platform (Right & Rear of room where bed and nightstand rest)
    const upperW = ROOM_WIDTH * 0.52;
    const upperD = ROOM_DEPTH * 0.72;
    const upperPlatformGeo = new THREE.BoxGeometry(upperW, UPPER_FLOOR_Y - LOWER_FLOOR_Y, upperD);
    const upperPlatform = new THREE.Mesh(upperPlatformGeo, this.materials.woodFloorLight);
    upperPlatform.position.set(
      halfW - upperW * 0.5,
      (UPPER_FLOOR_Y + LOWER_FLOOR_Y) * 0.5,
      -halfD + upperD * 0.5
    );
    upperPlatform.receiveShadow = true;
    upperPlatform.castShadow = true;
    upperPlatform.name = 'RaisedUpperFloorPlatform';
    this.architecture.add(upperPlatform);

    // Connecting Wooden Steps (front edge of upper platform)
    const step1Geo = new THREE.BoxGeometry(upperW * 0.7, 0.075, 0.28);
    const step1 = new THREE.Mesh(step1Geo, this.materials.woodTrim);
    step1.position.set(halfW - upperW * 0.5 - 0.1, LOWER_FLOOR_Y + 0.0375, -halfD + upperD + 0.14);
    step1.receiveShadow = true;
    step1.castShadow = true;
    this.architecture.add(step1);

    // Diorama Cutaway Wooden Rim Borders (front and right outer edges)
    const frontRimGeo = new THREE.BoxGeometry(ROOM_WIDTH + WALL_THICKNESS, 0.18, 0.08);
    const frontRim = new THREE.Mesh(frontRimGeo, this.materials.woodTrim);
    frontRim.position.set(-WALL_THICKNESS * 0.5, LOWER_FLOOR_Y - 0.04, halfD + 0.04);
    frontRim.castShadow = true;
    this.architecture.add(frontRim);

    const rightRimGeo = new THREE.BoxGeometry(0.08, 0.18, ROOM_DEPTH * 0.45);
    const rightRim = new THREE.Mesh(rightRimGeo, this.materials.woodTrim);
    rightRim.position.set(halfW + 0.04, LOWER_FLOOR_Y - 0.04, halfD - (ROOM_DEPTH * 0.45) * 0.5);
    rightRim.castShadow = true;
    this.architecture.add(rightRim);
  }

  buildFoundationalFurniture() {
    // 1. Large Honey Oak Desk (Left Wall)
    const deskGroup = new THREE.Group();
    deskGroup.name = 'DeskArchitecture';

    // Desk Top Surface
    const topGeo = new THREE.BoxGeometry(1.6, 0.06, 0.75);
    const deskTop = new THREE.Mesh(topGeo, this.materials.woodHoney);
    deskTop.position.set(-1.15, 0.68, -0.65);
    deskTop.castShadow = true;
    deskTop.receiveShadow = true;
    deskGroup.add(deskTop);

    // Desk Left Drawer Unit
    const drawerGeo = new THREE.BoxGeometry(0.42, 0.65, 0.68);
    const deskDrawers = new THREE.Mesh(drawerGeo, this.materials.woodOakDark);
    deskDrawers.position.set(-1.65, 0.325 + LOWER_FLOOR_Y, -0.65);
    deskDrawers.castShadow = true;
    deskDrawers.receiveShadow = true;
    deskGroup.add(deskDrawers);

    // Desk Right Legs
    const legGeo = new THREE.CylinderGeometry(0.03, 0.03, 0.65, 16);
    const leg = new THREE.Mesh(legGeo, this.materials.woodTrim);
    leg.position.set(-0.42, 0.325 + LOWER_FLOOR_Y, -0.35);
    leg.castShadow = true;
    deskGroup.add(leg);

    this.furniture.add(deskGroup);

    // 2. Cozy Bed Platform (Rear-Right Corner)
    const bedGroup = new THREE.Group();
    bedGroup.name = 'BedArchitecture';

    // Wooden Frame Base
    const bedFrameGeo = new THREE.BoxGeometry(1.35, 0.30, 1.85);
    const bedFrame = new THREE.Mesh(bedFrameGeo, this.materials.woodHoney);
    bedFrame.position.set(0.95, UPPER_FLOOR_Y + 0.15, -0.75);
    bedFrame.castShadow = true;
    bedFrame.receiveShadow = true;
    bedGroup.add(bedFrame);

    // Bed Headboard
    const headboardGeo = new THREE.BoxGeometry(1.4, 0.65, 0.1);
    const headboard = new THREE.Mesh(headboardGeo, this.materials.woodTrim);
    headboard.position.set(0.95, UPPER_FLOOR_Y + 0.45, -1.65);
    headboard.castShadow = true;
    headboard.receiveShadow = true;
    bedGroup.add(headboard);

    // Mattress
    const mattressGeo = new THREE.BoxGeometry(1.25, 0.22, 1.75);
    const mattress = new THREE.Mesh(mattressGeo, this.materials.bedSheets);
    mattress.position.set(0.95, UPPER_FLOOR_Y + 0.38, -0.75);
    mattress.castShadow = true;
    mattress.receiveShadow = true;
    bedGroup.add(mattress);

    // Sage Green Duvet / Folded Quilt
    const duvetGeo = new THREE.BoxGeometry(1.28, 0.16, 1.15);
    const duvet = new THREE.Mesh(duvetGeo, this.materials.bedBlanket);
    duvet.position.set(0.95, UPPER_FLOOR_Y + 0.46, -0.45);
    duvet.castShadow = true;
    duvet.receiveShadow = true;
    bedGroup.add(duvet);

    // Pillows
    const p1Geo = new THREE.BoxGeometry(0.48, 0.12, 0.32);
    const p1 = new THREE.Mesh(p1Geo, this.materials.pillowCream);
    p1.position.set(0.68, UPPER_FLOOR_Y + 0.52, -1.35);
    p1.rotation.x = 0.15;
    p1.castShadow = true;
    bedGroup.add(p1);

    const p2Geo = new THREE.BoxGeometry(0.48, 0.12, 0.32);
    const p2 = new THREE.Mesh(p2Geo, this.materials.pillowSage);
    p2.position.set(1.22, UPPER_FLOOR_Y + 0.52, -1.35);
    p2.rotation.x = 0.15;
    p2.castShadow = true;
    bedGroup.add(p2);

    this.furniture.add(bedGroup);

    // 3. Low Ottoman / Turntable Bench (Foot of bed)
    const benchGroup = new THREE.Group();
    benchGroup.name = 'TurntableBench';
    const benchBaseGeo = new THREE.BoxGeometry(0.72, 0.16, 0.65);
    const benchBase = new THREE.Mesh(benchBaseGeo, this.materials.woodTrim);
    benchBase.position.set(1.15, UPPER_FLOOR_Y + 0.08, 0.65);
    benchBase.castShadow = true;
    benchGroup.add(benchBase);

    const benchCushionGeo = new THREE.BoxGeometry(0.68, 0.14, 0.62);
    const benchCushion = new THREE.Mesh(benchCushionGeo, this.materials.pillowSage);
    benchCushion.position.set(1.15, UPPER_FLOOR_Y + 0.22, 0.65);
    benchCushion.castShadow = true;
    benchGroup.add(benchCushion);
    this.furniture.add(benchGroup);

    // 4. Bouclé Pouf (Sunken front-right corner)
    const poufGeo = new THREE.CylinderGeometry(0.38, 0.44, 0.28, 24);
    const pouf = new THREE.Mesh(poufGeo, this.materials.poufBoucle);
    pouf.position.set(1.22, LOWER_FLOOR_Y + 0.14, 1.45);
    pouf.castShadow = true;
    pouf.receiveShadow = true;
    pouf.name = 'BouclePouf';
    this.furniture.add(pouf);
  }

  buildFoundationalDecorations() {
    // 1. Back Wall Bookshelf Structure (connecting desk to bed)
    const shelfGroup = new THREE.Group();
    shelfGroup.name = 'BackBookshelfArchitecture';

    const shelfBackGeo = new THREE.BoxGeometry(1.35, 1.45, 0.28);
    const shelfBack = new THREE.Mesh(shelfBackGeo, this.materials.woodHoney);
    shelfBack.position.set(0.15, 1.65 + LOWER_FLOOR_Y, -1.82);
    shelfBack.castShadow = true;
    shelfBack.receiveShadow = true;
    shelfGroup.add(shelfBack);

    // Individual horizontal shelves
    for (let y = 1.15; y <= 2.15; y += 0.42) {
      const plankGeo = new THREE.BoxGeometry(1.32, 0.04, 0.26);
      const plank = new THREE.Mesh(plankGeo, this.materials.woodTrim);
      plank.position.set(0.15, y + LOWER_FLOOR_Y, -1.82);
      plank.castShadow = true;
      shelfGroup.add(plank);
    }
    this.decorations.add(shelfGroup);

    // 2. Woven Rug in Sunken Desk Area
    const rugGeo = new THREE.PlaneGeometry(1.4, 1.1);
    const rug = new THREE.Mesh(rugGeo, this.materials.rug);
    rug.rotation.x = -Math.PI / 2;
    rug.position.set(-0.75, LOWER_FLOOR_Y + 0.005, 0.15);
    rug.receiveShadow = true;
    rug.name = 'DeskWovenRug';
    this.decorations.add(rug);

    // 3. Window Curtains
    const rodGeo = new THREE.CylinderGeometry(0.015, 0.015, 1.85, 16);
    const rod = new THREE.Mesh(rodGeo, this.materials.woodTrim);
    rod.rotation.z = Math.PI / 2;
    rod.position.set(ROOM_WIDTH * 0.5 - 0.08, 2.15 + LOWER_FLOOR_Y, -0.9);
    this.decorations.add(rod);

    const curtainLeftGeo = new THREE.BoxGeometry(0.04, 1.45, 0.28);
    const curtainLeft = new THREE.Mesh(curtainLeftGeo, this.materials.curtains);
    curtainLeft.position.set(ROOM_WIDTH * 0.5 - 0.1, 1.42 + LOWER_FLOOR_Y, -1.65);
    curtainLeft.castShadow = true;
    this.decorations.add(curtainLeft);

    const curtainRightGeo = new THREE.BoxGeometry(0.04, 1.45, 0.28);
    const curtainRight = new THREE.Mesh(curtainRightGeo, this.materials.curtains);
    curtainRight.position.set(ROOM_WIDTH * 0.5 - 0.1, 1.42 + LOWER_FLOOR_Y, -0.15);
    curtainRight.castShadow = true;
    this.decorations.add(curtainRight);
  }

  update(delta) {
    this.lighting.update(delta);
    this.environment.update(delta);
  }
}
