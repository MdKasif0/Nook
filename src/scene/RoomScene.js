/**
 * Nook 3D - RoomScene Architecture
 * Reconstructs the exact architectural structure of nook-room.jpeg as true 3D geometry:
 * 1. Left Wall (solid cream + upper trim)
 * 2. Back Wall (solid cream + upper trim)
 * 3. Right Wall (cutaway + window opening + wainscot)
 * 4. Wooden Floor (sunken lower pit)
 * 5. Raised Wooden Platform (elevated level)
 * 6. Front Steps (intermediate wooden steps connecting levels)
 * 7. Thick Wooden Upper Wall Trim (solid beveled honey oak headers)
 * 8. Window Opening (large aperture pouring morning light)
 * 9. Window Frame (casing, sill shelf, center mullion, glass, outdoor sky view)
 * 10. Built-in Shelf Structure (back wall integrated bookshelves & uprights)
 */

import * as THREE from 'three';
import {
  ROOM_WIDTH,
  ROOM_DEPTH,
  ROOM_HEIGHT,
  WALL_THICKNESS,
  BASE_PLATFORM_THICKNESS,
  UPPER_TRIM_WIDTH,
  UPPER_TRIM_HEIGHT,
  LOWER_FLOOR_Y,
  UPPER_FLOOR_Y,
  STEP_HEIGHT,
  WINDOW_CONFIG,
  SHELF_CONFIG,
  PALETTE
} from '../utils/Constants.js';
import { TextureGenerator } from '../utils/TextureGenerator.js';
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

    // Lighting & Environment
    this.lighting = new Lighting(this.world);
    this.environment = new Environment(this.world);

    // Procedural PBR Materials Library
    this.materials = this.createMaterials();

    // Construct Architecture
    this.buildBasePlatform();
    this.buildSteppedFloorsAndSteps();
    this.buildLeftWall();
    this.buildBackWall();
    this.buildRightWallAndWindow();
    this.buildThickUpperWallTrim();
    this.buildBuiltInShelfStructure();
  }

  createMaterials() {
    // 1. Procedural PBR Textures
    const woodTexture = TextureGenerator.createHoneyWoodTexture(1024, 1024);
    woodTexture.repeat.set(2, 2);

    const floorPlanksTexture = TextureGenerator.createFloorPlanksTexture(1024, 1024, 14);
    floorPlanksTexture.repeat.set(2, 2);

    const wallTexture = TextureGenerator.createWallCreamTexture(512, 512);
    wallTexture.repeat.set(4, 4);

    return {
      // Warm Ivory / Cream Plaster
      wallCream: new THREE.MeshStandardMaterial({
        color: PALETTE.wallCream,
        map: wallTexture,
        roughness: 0.88,
        metalness: 0.02
      }),

      // Warm Natural Honey Wood (Semi-matte finish, visible subtle grain)
      woodHoney: new THREE.MeshStandardMaterial({
        color: PALETTE.woodHoney,
        map: woodTexture,
        roughness: 0.52,
        metalness: 0.04
      }),

      // Slightly darker honey wood for bevels and structural trims
      woodTrim: new THREE.MeshStandardMaterial({
        color: PALETTE.woodTrim,
        map: woodTexture,
        roughness: 0.48,
        metalness: 0.05
      }),

      // Floor Planks (Warm wood with board grooves)
      floorPlanks: new THREE.MeshStandardMaterial({
        color: PALETTE.woodPlanks,
        map: floorPlanksTexture,
        roughness: 0.45,
        metalness: 0.04
      }),

      // Window Glass
      windowGlass: new THREE.MeshPhysicalMaterial({
        color: 0xffffff,
        transparent: true,
        opacity: 0.22,
        roughness: 0.08,
        transmission: 0.88,
        ior: 1.52
      }),

      // Outdoor Sunny Sky Backdrop
      outdoorSky: new THREE.MeshBasicMaterial({
        color: PALETTE.outdoorSky
      }),

      // Base Platform Plinth
      pedestal: new THREE.MeshStandardMaterial({
        color: PALETTE.studioPedestal,
        roughness: 0.9,
        metalness: 0.04
      })
    };
  }

  // MARK: - 1. Base Platform
  buildBasePlatform() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // Outer thick wooden miniature diorama platform
    const platformW = ROOM_WIDTH + WALL_THICKNESS * 2 + 0.3;
    const platformD = ROOM_DEPTH + WALL_THICKNESS * 2 + 0.3;
    const platformGeo = new THREE.BoxGeometry(platformW, BASE_PLATFORM_THICKNESS, platformD);
    const platformMesh = new THREE.Mesh(platformGeo, this.materials.woodTrim);
    platformMesh.position.set(0, -BASE_PLATFORM_THICKNESS * 0.5, 0);
    platformMesh.receiveShadow = true;
    platformMesh.castShadow = true;
    platformMesh.name = 'DioramaBasePlatform';
    this.architecture.add(platformMesh);

    // Front lower outer stepped rim
    const frontStepGeo = new THREE.BoxGeometry(platformW + 0.2, 0.16, 0.45);
    const frontStepMesh = new THREE.Mesh(frontStepGeo, this.materials.woodHoney);
    frontStepMesh.position.set(0, -BASE_PLATFORM_THICKNESS + 0.08, halfD + WALL_THICKNESS + 0.35);
    frontStepMesh.receiveShadow = true;
    frontStepMesh.castShadow = true;
    this.architecture.add(frontStepMesh);
  }

  // MARK: - 2. Stepped Floors & Front Steps
  buildSteppedFloorsAndSteps() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // A. Sunken Lower Floor (Desk Pit on Left)
    // From X = -halfW (-5.0) to X = 0.2 (width 5.2), Z = -3.5 to +3.5 (depth 7.0)
    const lowerW = 5.2;
    const lowerFloorGeo = new THREE.BoxGeometry(lowerW, 0.14, ROOM_DEPTH);
    const lowerFloor = new THREE.Mesh(lowerFloorGeo, this.materials.floorPlanks);
    lowerFloor.position.set(-halfW + lowerW * 0.5, LOWER_FLOOR_Y - 0.07, 0);
    lowerFloor.receiveShadow = true;
    lowerFloor.name = 'SunkenLowerFloor';
    this.architecture.add(lowerFloor);

    // B. Raised Upper Platform (Bed & Lounge on Right)
    // From X = 0.2 to X = +halfW (+5.0) (width 4.8), Z = -3.5 to +3.5 (depth 7.0)
    const upperW = ROOM_WIDTH - lowerW;
    const upperFloorHeight = UPPER_FLOOR_Y - LOWER_FLOOR_Y;
    const upperFloorGeo = new THREE.BoxGeometry(upperW, upperFloorHeight, ROOM_DEPTH);
    const upperFloor = new THREE.Mesh(upperFloorGeo, this.materials.floorPlanks);
    upperFloor.position.set(halfW - upperW * 0.5, LOWER_FLOOR_Y + upperFloorHeight * 0.5, 0);
    upperFloor.receiveShadow = true;
    upperFloor.castShadow = true;
    upperFloor.name = 'RaisedUpperFloorPlatform';
    this.architecture.add(upperFloor);

    // Wood Riser dividing lower floor and upper platform (along X = 0.2)
    const riserGeo = new THREE.BoxGeometry(0.06, upperFloorHeight, ROOM_DEPTH);
    const riser = new THREE.Mesh(riserGeo, this.materials.woodTrim);
    riser.position.set(0.2 - 0.03, LOWER_FLOOR_Y + upperFloorHeight * 0.5, 0);
    riser.receiveShadow = true;
    riser.castShadow = true;
    this.architecture.add(riser);

    // C. Front Steps (Connecting Sunken Pit to Upper Platform)
    // Two distinct wooden steps in front of the platform divider
    const stepWidth = 1.8;
    const stepDepth = 0.52;

    // Step 1: Intermediate Step (Y = 0.21)
    const step1Geo = new THREE.BoxGeometry(stepWidth, STEP_HEIGHT, stepDepth);
    const step1 = new THREE.Mesh(step1Geo, this.materials.woodTrim);
    step1.position.set(0.2 + stepWidth * 0.5 - 0.4, LOWER_FLOOR_Y + STEP_HEIGHT * 0.5, 1.4);
    step1.receiveShadow = true;
    step1.castShadow = true;
    this.architecture.add(step1);

    // Step 1 Tread Plank
    const step1TreadGeo = new THREE.BoxGeometry(stepWidth + 0.04, 0.04, stepDepth + 0.04);
    const step1Tread = new THREE.Mesh(step1TreadGeo, this.materials.woodHoney);
    step1Tread.position.set(0.2 + stepWidth * 0.5 - 0.4, LOWER_FLOOR_Y + STEP_HEIGHT + 0.02, 1.4);
    step1Tread.receiveShadow = true;
    step1Tread.castShadow = true;
    this.architecture.add(step1Tread);

    // Step 2: Top Step Edge / Nose
    const step2Geo = new THREE.BoxGeometry(stepWidth, STEP_HEIGHT, stepDepth * 0.8);
    const step2 = new THREE.Mesh(step2Geo, this.materials.woodTrim);
    step2.position.set(0.2 + stepWidth * 0.5 - 0.4, LOWER_FLOOR_Y + STEP_HEIGHT * 1.5, 1.4 - stepDepth * 0.9);
    step2.receiveShadow = true;
    step2.castShadow = true;
    this.architecture.add(step2);

    // Step 2 Tread Plank
    const step2TreadGeo = new THREE.BoxGeometry(stepWidth + 0.04, 0.04, stepDepth * 0.8 + 0.04);
    const step2Tread = new THREE.Mesh(step2TreadGeo, this.materials.woodHoney);
    step2Tread.position.set(0.2 + stepWidth * 0.5 - 0.4, UPPER_FLOOR_Y + 0.02, 1.4 - stepDepth * 0.9);
    step2Tread.receiveShadow = true;
    step2Tread.castShadow = true;
    this.architecture.add(step2Tread);
  }

  // MARK: - 3. Left Wall
  buildLeftWall() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // Solid cream left wall
    const wallGeo = new THREE.BoxGeometry(WALL_THICKNESS, ROOM_HEIGHT, ROOM_DEPTH);
    const wall = new THREE.Mesh(wallGeo, this.materials.wallCream);
    wall.position.set(-halfW - WALL_THICKNESS * 0.5, ROOM_HEIGHT * 0.5 + LOWER_FLOOR_Y, 0);
    wall.receiveShadow = true;
    wall.castShadow = true;
    wall.name = 'LeftWall';
    this.architecture.add(wall);

    // Left wall baseboard
    const baseboardGeo = new THREE.BoxGeometry(0.04, 0.22, ROOM_DEPTH);
    const baseboard = new THREE.Mesh(baseboardGeo, this.materials.woodTrim);
    baseboard.position.set(-halfW + 0.02, LOWER_FLOOR_Y + 0.11, 0);
    baseboard.receiveShadow = true;
    this.architecture.add(baseboard);

    // Front return column (corner frame)
    const columnGeo = new THREE.BoxGeometry(WALL_THICKNESS + 0.06, ROOM_HEIGHT, 0.45);
    const column = new THREE.Mesh(columnGeo, this.materials.wallCream);
    column.position.set(-halfW - WALL_THICKNESS * 0.5, ROOM_HEIGHT * 0.5 + LOWER_FLOOR_Y, halfD - 0.225);
    column.castShadow = true;
    column.receiveShadow = true;
    this.architecture.add(column);
  }

  // MARK: - 4. Back Wall
  buildBackWall() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // Solid cream back wall
    const wallGeo = new THREE.BoxGeometry(ROOM_WIDTH + WALL_THICKNESS * 2, ROOM_HEIGHT, WALL_THICKNESS);
    const wall = new THREE.Mesh(wallGeo, this.materials.wallCream);
    wall.position.set(0, ROOM_HEIGHT * 0.5 + LOWER_FLOOR_Y, -halfD - WALL_THICKNESS * 0.5);
    wall.receiveShadow = true;
    wall.castShadow = true;
    wall.name = 'BackWall';
    this.architecture.add(wall);

    // Back wall baseboard
    const baseboardGeo = new THREE.BoxGeometry(ROOM_WIDTH, 0.22, 0.04);
    const baseboard = new THREE.Mesh(baseboardGeo, this.materials.woodTrim);
    baseboard.position.set(0, LOWER_FLOOR_Y + 0.11, -halfD + 0.02);
    baseboard.receiveShadow = true;
    this.architecture.add(baseboard);
  }

  // MARK: - 5. Right Wall & Window
  buildRightWallAndWindow() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    const wallX = halfW + WALL_THICKNESS * 0.5;
    const winConfig = WINDOW_CONFIG;

    // A. Back Solid Section of Right Wall (from Z = -halfD to window start)
    const backSectionDepth = 1.7;
    const backSectionGeo = new THREE.BoxGeometry(WALL_THICKNESS, ROOM_HEIGHT, backSectionDepth);
    const backSection = new THREE.Mesh(backSectionGeo, this.materials.wallCream);
    backSection.position.set(wallX, ROOM_HEIGHT * 0.5 + LOWER_FLOOR_Y, -halfD + backSectionDepth * 0.5);
    backSection.receiveShadow = true;
    backSection.castShadow = true;
    this.architecture.add(backSection);

    // B. Lower Wall section below window with wood wainscot paneling
    const lowerWallGeo = new THREE.BoxGeometry(WALL_THICKNESS, winConfig.sillY, winConfig.width);
    const lowerWall = new THREE.Mesh(lowerWallGeo, this.materials.wallCream);
    lowerWall.position.set(wallX, winConfig.sillY * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ);
    lowerWall.receiveShadow = true;
    lowerWall.castShadow = true;
    this.architecture.add(lowerWall);

    // Lower Wainscot Honey Wood Paneling (under window as in nook-room.jpeg)
    const wainscotGeo = new THREE.BoxGeometry(0.05, winConfig.sillY - 0.1, winConfig.width);
    const wainscot = new THREE.Mesh(wainscotGeo, this.materials.woodHoney);
    wainscot.position.set(halfW - 0.025, (winConfig.sillY - 0.1) * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ);
    wainscot.castShadow = true;
    wainscot.receiveShadow = true;
    this.architecture.add(wainscot);

    // C. Top Wall Header above window
    const topWallHeight = ROOM_HEIGHT - (winConfig.sillY + winConfig.height);
    const topWallGeo = new THREE.BoxGeometry(WALL_THICKNESS, topWallHeight, winConfig.width);
    const topWall = new THREE.Mesh(topWallGeo, this.materials.wallCream);
    topWall.position.set(wallX, ROOM_HEIGHT + LOWER_FLOOR_Y - topWallHeight * 0.5, winConfig.centerZ);
    topWall.castShadow = true;
    this.architecture.add(topWall);

    // D. Front Cutaway Column of Right Wall
    const frontColDepth = 1.1;
    const frontColGeo = new THREE.BoxGeometry(WALL_THICKNESS, ROOM_HEIGHT * 0.68, frontColDepth);
    const frontCol = new THREE.Mesh(frontColGeo, this.materials.wallCream);
    frontCol.position.set(wallX, (ROOM_HEIGHT * 0.68) * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ + winConfig.width * 0.5 + frontColDepth * 0.5);
    frontCol.receiveShadow = true;
    frontCol.castShadow = true;
    this.architecture.add(frontCol);

    // E. Window Frame & Sash Assembly
    const frameGroup = new THREE.Group();
    frameGroup.name = 'WindowFrameAssembly';

    const frameDepth = WALL_THICKNESS + 0.12;
    const frameThick = winConfig.frameThickness;

    // Window Sill Shelf (Prominent honey wood shelf with potted plants in reference)
    const sillGeo = new THREE.BoxGeometry(frameDepth + 0.28, 0.12, winConfig.width + 0.38);
    const sill = new THREE.Mesh(sillGeo, this.materials.woodTrim);
    sill.position.set(halfW - 0.06, winConfig.sillY + LOWER_FLOOR_Y + 0.06, winConfig.centerZ);
    sill.castShadow = true;
    sill.receiveShadow = true;
    frameGroup.add(sill);

    // Top Frame Rail
    const topRailGeo = new THREE.BoxGeometry(frameDepth, frameThick, winConfig.width);
    const topRail = new THREE.Mesh(topRailGeo, this.materials.woodHoney);
    topRail.position.set(wallX, winConfig.sillY + winConfig.height + LOWER_FLOOR_Y - frameThick * 0.5, winConfig.centerZ);
    topRail.castShadow = true;
    frameGroup.add(topRail);

    // Left & Right Vertical Jambs
    const jambGeo = new THREE.BoxGeometry(frameDepth, winConfig.height - frameThick, frameThick);
    const leftJamb = new THREE.Mesh(jambGeo, this.materials.woodHoney);
    leftJamb.position.set(wallX, winConfig.sillY + winConfig.height * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ - winConfig.width * 0.5 + frameThick * 0.5);
    leftJamb.castShadow = true;
    frameGroup.add(leftJamb);

    const rightJamb = new THREE.Mesh(jambGeo, this.materials.woodHoney);
    rightJamb.position.set(wallX, winConfig.sillY + winConfig.height * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ + winConfig.width * 0.5 - frameThick * 0.5);
    rightJamb.castShadow = true;
    frameGroup.add(rightJamb);

    // Center Vertical Mullion (Dividing into two classic panes)
    const mullionGeo = new THREE.BoxGeometry(frameDepth * 0.7, winConfig.height - frameThick * 2, winConfig.mullionWidth);
    const centerMullion = new THREE.Mesh(mullionGeo, this.materials.woodHoney);
    centerMullion.position.set(wallX, winConfig.sillY + winConfig.height * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ);
    centerMullion.castShadow = true;
    frameGroup.add(centerMullion);

    // Window Glass Panes (Light streaming through)
    const glassGeo = new THREE.BoxGeometry(0.015, winConfig.height - frameThick * 2, winConfig.width - frameThick * 2);
    const glass = new THREE.Mesh(glassGeo, this.materials.windowGlass);
    glass.position.set(wallX, winConfig.sillY + winConfig.height * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ);
    frameGroup.add(glass);

    // Sunny Outdoor Backdrop Plane (Blue sky & warm green foliage outside the window)
    const outdoorGeo = new THREE.PlaneGeometry(5.2, 4.0);
    const outdoorBackdrop = new THREE.Mesh(outdoorGeo, this.materials.outdoorSky);
    outdoorBackdrop.position.set(wallX + 1.2, winConfig.sillY + winConfig.height * 0.5 + LOWER_FLOOR_Y, winConfig.centerZ);
    outdoorBackdrop.rotation.y = -Math.PI / 2;
    frameGroup.add(outdoorBackdrop);

    this.architecture.add(frameGroup);
  }

  // MARK: - 6. Thick Wooden Upper Wall Trim
  buildThickUpperWallTrim() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    const trimW = UPPER_TRIM_WIDTH;
    const trimH = UPPER_TRIM_HEIGHT;
    const trimY = ROOM_HEIGHT + LOWER_FLOOR_Y + trimH * 0.5;

    // A. Left Wall Top Header Trim
    const leftTrimGeo = new THREE.BoxGeometry(trimW, trimH, ROOM_DEPTH + trimW);
    const leftTrim = new THREE.Mesh(leftTrimGeo, this.materials.woodTrim);
    leftTrim.position.set(-halfW - WALL_THICKNESS * 0.5, trimY, 0);
    leftTrim.castShadow = true;
    leftTrim.receiveShadow = true;
    this.architecture.add(leftTrim);

    // B. Back Wall Top Header Trim
    const backTrimGeo = new THREE.BoxGeometry(ROOM_WIDTH + WALL_THICKNESS * 2 + trimW, trimH, trimW);
    const backTrim = new THREE.Mesh(backTrimGeo, this.materials.woodTrim);
    backTrim.position.set(0, trimY, -halfD - WALL_THICKNESS * 0.5);
    backTrim.castShadow = true;
    backTrim.receiveShadow = true;
    this.architecture.add(backTrim);

    // C. Right Wall Top Header Trim (Covering the back solid section of right wall)
    const rightTrimGeo = new THREE.BoxGeometry(trimW, trimH, 2.5);
    const rightTrim = new THREE.Mesh(rightTrimGeo, this.materials.woodTrim);
    rightTrim.position.set(halfW + WALL_THICKNESS * 0.5, trimY, -halfD + 1.25);
    rightTrim.castShadow = true;
    rightTrim.receiveShadow = true;
    this.architecture.add(rightTrim);
  }

  // MARK: - 7. Built-in Shelf Structure (Back Wall)
  buildBuiltInShelfStructure() {
    const halfD = ROOM_DEPTH * 0.5;
    const shelfGroup = new THREE.Group();
    shelfGroup.name = 'BackWallBuiltInShelving';

    const woodMat = this.materials.woodHoney;
    const trimMat = this.materials.woodTrim;
    const backZ = -halfD + 0.05;

    // A. Tall Shelving Unit (Center-Right behind bed)
    // Vertical Side Uprights
    const uprightH = 3.6;
    const uprightW = 0.08;
    const uprightD = 0.48;

    const uprightGeo = new THREE.BoxGeometry(uprightW, uprightH, uprightD);

    const leftUpright = new THREE.Mesh(uprightGeo, trimMat);
    leftUpright.position.set(0.2, 1.8 + uprightH * 0.5 + LOWER_FLOOR_Y, backZ + uprightD * 0.5);
    leftUpright.castShadow = true;
    shelfGroup.add(leftUpright);

    const rightUpright = new THREE.Mesh(uprightGeo, trimMat);
    rightUpright.position.set(2.8, 1.8 + uprightH * 0.5 + LOWER_FLOOR_Y, backZ + uprightD * 0.5);
    rightUpright.castShadow = true;
    shelfGroup.add(rightUpright);

    // Top Storage Box Ledge (Crown beam)
    const topLedgeGeo = new THREE.BoxGeometry(2.8 - 0.2 + uprightW * 2, 0.12, uprightD + 0.08);
    const topLedge = new THREE.Mesh(topLedgeGeo, trimMat);
    topLedge.position.set(1.5, 1.8 + uprightH + LOWER_FLOOR_Y + 0.06, backZ + uprightD * 0.5);
    topLedge.castShadow = true;
    shelfGroup.add(topLedge);

    // Horizontal Shelves
    const shelfWidth = 2.8 - 0.2;
    const shelfPlankGeo = new THREE.BoxGeometry(shelfWidth, 0.06, uprightD);

    const shelfHeights = [2.2, 3.0, 3.8, 4.6];
    for (const y of shelfHeights) {
      const plank = new THREE.Mesh(shelfPlankGeo, woodMat);
      plank.position.set(1.5, y + LOWER_FLOOR_Y, backZ + uprightD * 0.5);
      plank.castShadow = true;
      plank.receiveShadow = true;
      shelfGroup.add(plank);
    }

    // Flush Warm Wood Backing Panel for the Bookshelf
    const backPanelGeo = new THREE.BoxGeometry(shelfWidth, uprightH, 0.03);
    const backPanel = new THREE.Mesh(backPanelGeo, woodMat);
    backPanel.position.set(1.5, 1.8 + uprightH * 0.5 + LOWER_FLOOR_Y, backZ + 0.015);
    backPanel.receiveShadow = true;
    shelfGroup.add(backPanel);

    // B. Upper Floating Bookshelf (Left side, above desk workstation)
    const deskShelfWidth = 3.6;
    const deskShelfPlankGeo = new THREE.BoxGeometry(deskShelfWidth, 0.06, 0.42);

    const deskShelfHeights = [3.6, 4.4];
    for (const y of deskShelfHeights) {
      const plank = new THREE.Mesh(deskShelfPlankGeo, woodMat);
      plank.position.set(-2.8, y + LOWER_FLOOR_Y, backZ + 0.21);
      plank.castShadow = true;
      plank.receiveShadow = true;
      shelfGroup.add(plank);
    }

    // Vertical dividers between desk shelves
    const dividerGeo = new THREE.BoxGeometry(0.06, 0.74, 0.40);
    const div1 = new THREE.Mesh(dividerGeo, trimMat);
    div1.position.set(-2.8, 4.0 + LOWER_FLOOR_Y, backZ + 0.21);
    div1.castShadow = true;
    shelfGroup.add(div1);

    const div2 = new THREE.Mesh(dividerGeo, trimMat);
    div2.position.set(-4.2, 4.0 + LOWER_FLOOR_Y, backZ + 0.21);
    div2.castShadow = true;
    shelfGroup.add(div2);

    this.architecture.add(shelfGroup);
  }

  update(delta) {
    this.lighting.update(delta);
    this.environment.update(delta);
  }
}
