/**
 * Nook 3D - RoomScene Architecture
 * Reconstructs the exact architectural structure of nook-room.jpeg as true 3D geometry:
 * 1. Left Wall (solid cream + thick honey oak upper trim)
 * 2. Back Wall (solid cream + thick honey oak upper trim)
 * 3. Right Wall (solid cream + large window aperture + wood wainscot + upper trim)
 * 4. Wooden Floor (main room floor planks)
 * 5. Raised Wooden Platform (staggered front-right platform)
 * 6. Front Steps (warm wooden steps connecting main floor to lower front deck)
 * 7. Thick Wooden Upper Wall Trim (solid beveled honey oak headers across wall tops)
 * 8. Window Opening (large right-wall sun aperture)
 * 9. Window Frame (honey oak casing, deep sill shelf, center mullion, glass, outdoor foliage)
 * 10. Built-in Shelf Structure (center-right vertical bookcase + left workstation shelves)
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
  MAIN_FLOOR_Y,
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

    // Construct Architecture matching nook-room.jpeg blueprint
    this.buildBasePlatform();
    this.buildFloorsAndSteps();
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

    const floorPlanksTexture = TextureGenerator.createFloorPlanksTexture(1024, 1024, 12);
    floorPlanksTexture.repeat.set(2, 2);

    const wallTexture = TextureGenerator.createWallCreamTexture(512, 512);
    wallTexture.repeat.set(4, 4);

    return {
      // Warm Ivory / Cream Plaster (#F7F1E6 / #F4EBDD)
      wallCream: new THREE.MeshStandardMaterial({
        color: PALETTE.wallCream,
        map: wallTexture,
        roughness: 0.88,
        metalness: 0.01
      }),

      // Warm Natural Honey Wood (Semi-matte finish, subtle grain)
      woodHoney: new THREE.MeshStandardMaterial({
        color: PALETTE.woodHoney,
        map: woodTexture,
        roughness: 0.52,
        metalness: 0.03
      }),

      // Slightly deeper honey oak for structural trims, beams, and bevels
      woodTrim: new THREE.MeshStandardMaterial({
        color: PALETTE.woodTrim,
        map: woodTexture,
        roughness: 0.48,
        metalness: 0.04
      }),

      // Floor Planks (Warm honey oak with board grooves)
      floorPlanks: new THREE.MeshStandardMaterial({
        color: PALETTE.woodPlanks,
        map: floorPlanksTexture,
        roughness: 0.46,
        metalness: 0.03
      }),

      // Window Glass
      windowGlass: new THREE.MeshPhysicalMaterial({
        color: 0xffffff,
        transparent: true,
        opacity: 0.2,
        roughness: 0.06,
        transmission: 0.88,
        ior: 1.5
      }),

      // Outdoor Sky & Foliage Backdrop
      outdoorSky: new THREE.MeshBasicMaterial({
        color: PALETTE.outdoorSky
      }),

      // Studio Pedestal / Table surface underneath diorama
      pedestal: new THREE.MeshStandardMaterial({
        color: PALETTE.studioPedestal,
        roughness: 0.92,
        metalness: 0.02
      })
    };
  }

  // MARK: - 1. Base Platform
  buildBasePlatform() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // Outer thick wooden miniature diorama foundation platform
    const platformW = ROOM_WIDTH + WALL_THICKNESS * 2 + 0.6;
    const platformD = ROOM_DEPTH + WALL_THICKNESS * 2 + 1.2;
    const platformGeo = new THREE.BoxGeometry(platformW, BASE_PLATFORM_THICKNESS, platformD);
    const platformMesh = new THREE.Mesh(platformGeo, this.materials.woodTrim);
    // Sit immediately below the lowest deck (Y = 0)
    platformMesh.position.set(0, -BASE_PLATFORM_THICKNESS * 0.5, 0.4);
    platformMesh.receiveShadow = true;
    platformMesh.castShadow = true;
    platformMesh.name = 'DioramaBasePlatform';
    this.architecture.add(platformMesh);

    // Front-most lower outer stepped rim / plinth lip
    const plinthLipGeo = new THREE.BoxGeometry(platformW + 0.25, 0.12, 0.4);
    const plinthLip = new THREE.Mesh(plinthLipGeo, this.materials.woodHoney);
    plinthLip.position.set(0, -0.06, halfD + WALL_THICKNESS + 0.9);
    plinthLip.receiveShadow = true;
    plinthLip.castShadow = true;
    this.architecture.add(plinthLip);
  }

  // MARK: - 2. Stepped Floors & Front Steps
  buildFloorsAndSteps() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // Floor Group
    const floorGroup = new THREE.Group();
    floorGroup.name = 'FlooringAndSteps';

    // A. Main Room Living Floor (Desk workstation on left, Bed & Lounge on right)
    // Continuous floor level (Y = MAIN_FLOOR_Y = 0.28) where both desk chair and bed live
    const mainFloorThickness = 0.28;

    // 1. Rear Room Floor (spans full width from X = -5.0 to +5.0, from Z = -3.5 to Z = 1.4)
    const rearDepth = 4.9;
    const rearFloorGeo = new THREE.BoxGeometry(ROOM_WIDTH, mainFloorThickness, rearDepth);
    const rearFloor = new THREE.Mesh(rearFloorGeo, this.materials.floorPlanks);
    rearFloor.position.set(0, MAIN_FLOOR_Y - mainFloorThickness * 0.5, -halfD + rearDepth * 0.5);
    rearFloor.receiveShadow = true;
    floorGroup.add(rearFloor);

    // 2. Left Desk Area Floor Extension (from X = -5.0 to X = -1.2, from Z = 1.4 to Z = 2.4)
    const leftDeskExtW = 3.8;
    const leftDeskExtD = 1.0;
    const leftDeskFloorGeo = new THREE.BoxGeometry(leftDeskExtW, mainFloorThickness, leftDeskExtD);
    const leftDeskFloor = new THREE.Mesh(leftDeskFloorGeo, this.materials.floorPlanks);
    leftDeskFloor.position.set(-halfW + leftDeskExtW * 0.5, MAIN_FLOOR_Y - mainFloorThickness * 0.5, 1.4 + leftDeskExtD * 0.5);
    leftDeskFloor.receiveShadow = true;
    floorGroup.add(leftDeskFloor);

    // Left Front Raised Corner Curb / Ledge (where book stack and plant sit in reference)
    const curbGeo = new THREE.BoxGeometry(leftDeskExtW + 0.08, 0.14, 0.24);
    const curbMesh = new THREE.Mesh(curbGeo, this.materials.woodTrim);
    curbMesh.position.set(-halfW + leftDeskExtW * 0.5, MAIN_FLOOR_Y + 0.07, 2.4 - 0.12);
    curbMesh.receiveShadow = true;
    curbMesh.castShadow = true;
    floorGroup.add(curbMesh);

    // B. Intermediate Front-Right Platform (Where skateboard sits in reference)
    // Extends forward in front of the bed from X = 0.8 to X = 5.0, from Z = 1.4 to Z = 2.8
    const rightPlatformW = 4.2;
    const rightPlatformD = 1.4;
    const rightPlatformHeight = 0.22;
    const rightPlatformGeo = new THREE.BoxGeometry(rightPlatformW, rightPlatformHeight, rightPlatformD);
    const rightPlatform = new THREE.Mesh(rightPlatformGeo, this.materials.floorPlanks);
    rightPlatform.position.set(halfW - rightPlatformW * 0.5, rightPlatformHeight * 0.5, 1.4 + rightPlatformD * 0.5);
    rightPlatform.receiveShadow = true;
    rightPlatform.castShadow = true;
    floorGroup.add(rightPlatform);

    // Front Bullnose Edge for Skateboard Platform
    const bullnoseGeo = new THREE.BoxGeometry(rightPlatformW + 0.04, 0.06, 0.08);
    const bullnose = new THREE.Mesh(bullnoseGeo, this.materials.woodTrim);
    bullnose.position.set(halfW - rightPlatformW * 0.5, rightPlatformHeight - 0.03, 1.4 + rightPlatformD + 0.04);
    bullnose.receiveShadow = true;
    bullnose.castShadow = true;
    floorGroup.add(bullnose);

    // Left Side Riser for Skateboard Platform (facing steps)
    const sideRiserGeo = new THREE.BoxGeometry(0.06, rightPlatformHeight, rightPlatformD);
    const sideRiser = new THREE.Mesh(sideRiserGeo, this.materials.woodTrim);
    sideRiser.position.set(halfW - rightPlatformW - 0.03, rightPlatformHeight * 0.5, 1.4 + rightPlatformD * 0.5);
    sideRiser.receiveShadow = true;
    floorGroup.add(sideRiser);

    // C. Front Steps (Connecting Main Living Floor down to the Lower Front Deck)
    // In front of the center passage between X = -1.2 and X = 0.8 (width = 2.0)
    const stepW = 2.0;
    const stepDepth = 0.44;

    // Step 1: Intermediate Step (Y = 0.14)
    const step1RiserGeo = new THREE.BoxGeometry(stepW, STEP_HEIGHT, stepDepth);
    const step1Riser = new THREE.Mesh(step1RiserGeo, this.materials.woodTrim);
    step1Riser.position.set(-0.2, STEP_HEIGHT * 0.5, 1.6 + stepDepth * 0.5);
    step1Riser.receiveShadow = true;
    step1Riser.castShadow = true;
    floorGroup.add(step1Riser);

    // Step 1 Tread Plank with gentle overhang
    const step1TreadGeo = new THREE.BoxGeometry(stepW + 0.04, 0.035, stepDepth + 0.04);
    const step1Tread = new THREE.Mesh(step1TreadGeo, this.materials.woodHoney);
    step1Tread.position.set(-0.2, STEP_HEIGHT + 0.0175, 1.6 + stepDepth * 0.5);
    step1Tread.receiveShadow = true;
    step1Tread.castShadow = true;
    floorGroup.add(step1Tread);

    // Step 2: Lower Step (Y = 0.06)
    const step2RiserGeo = new THREE.BoxGeometry(stepW + 0.2, 0.07, stepDepth);
    const step2Riser = new THREE.Mesh(step2RiserGeo, this.materials.woodTrim);
    step2Riser.position.set(-0.1, 0.035, 1.6 + stepDepth * 1.5);
    step2Riser.receiveShadow = true;
    step2Riser.castShadow = true;
    floorGroup.add(step2Riser);

    const step2TreadGeo = new THREE.BoxGeometry(stepW + 0.24, 0.03, stepDepth + 0.04);
    const step2Tread = new THREE.Mesh(step2TreadGeo, this.materials.woodHoney);
    step2Tread.position.set(-0.1, 0.07 + 0.015, 1.6 + stepDepth * 1.5);
    step2Tread.receiveShadow = true;
    step2Tread.castShadow = true;
    floorGroup.add(step2Tread);

    // D. Lower Front Deck (Entryway / Lounge Deck in front where pouf cushion sits)
    // Spans across the front from Z = 2.8 to Z = 4.2
    const frontDeckW = ROOM_WIDTH + 0.2;
    const frontDeckD = 1.5;
    const frontDeckGeo = new THREE.BoxGeometry(frontDeckW, 0.1, frontDeckD);
    const frontDeck = new THREE.Mesh(frontDeckGeo, this.materials.floorPlanks);
    frontDeck.position.set(0, -0.05, 2.7 + frontDeckD * 0.5);
    frontDeck.receiveShadow = true;
    floorGroup.add(frontDeck);

    this.architecture.add(floorGroup);
  }

  // MARK: - 3. Left Wall
  buildLeftWall() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // Solid cream left wall
    const wallGeo = new THREE.BoxGeometry(WALL_THICKNESS, ROOM_HEIGHT, ROOM_DEPTH);
    const wall = new THREE.Mesh(wallGeo, this.materials.wallCream);
    wall.position.set(-halfW - WALL_THICKNESS * 0.5, ROOM_HEIGHT * 0.5, 0);
    wall.receiveShadow = true;
    wall.castShadow = true;
    wall.name = 'LeftWall';
    this.architecture.add(wall);

    // Left wall honey wood baseboard
    const baseboardGeo = new THREE.BoxGeometry(0.04, 0.20, ROOM_DEPTH);
    const baseboard = new THREE.Mesh(baseboardGeo, this.materials.woodTrim);
    baseboard.position.set(-halfW + 0.02, MAIN_FLOOR_Y + 0.10, 0);
    baseboard.receiveShadow = true;
    this.architecture.add(baseboard);

    // Front edge corner profile
    const cornerProfileGeo = new THREE.BoxGeometry(WALL_THICKNESS + 0.04, ROOM_HEIGHT, 0.35);
    const cornerProfile = new THREE.Mesh(cornerProfileGeo, this.materials.wallCream);
    cornerProfile.position.set(-halfW - WALL_THICKNESS * 0.5, ROOM_HEIGHT * 0.5, halfD - 0.175);
    cornerProfile.castShadow = true;
    cornerProfile.receiveShadow = true;
    this.architecture.add(cornerProfile);
  }

  // MARK: - 4. Back Wall
  buildBackWall() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    // Solid cream back wall
    const wallGeo = new THREE.BoxGeometry(ROOM_WIDTH + WALL_THICKNESS * 2, ROOM_HEIGHT, WALL_THICKNESS);
    const wall = new THREE.Mesh(wallGeo, this.materials.wallCream);
    wall.position.set(0, ROOM_HEIGHT * 0.5, -halfD - WALL_THICKNESS * 0.5);
    wall.receiveShadow = true;
    wall.castShadow = true;
    wall.name = 'BackWall';
    this.architecture.add(wall);

    // Back wall baseboard
    const baseboardGeo = new THREE.BoxGeometry(ROOM_WIDTH, 0.20, 0.04);
    const baseboard = new THREE.Mesh(baseboardGeo, this.materials.woodTrim);
    baseboard.position.set(0, MAIN_FLOOR_Y + 0.10, -halfD + 0.02);
    baseboard.receiveShadow = true;
    this.architecture.add(baseboard);
  }

  // MARK: - 5. Right Wall & Window
  buildRightWallAndWindow() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;
    const wallX = halfW + WALL_THICKNESS * 0.5;
    const winConfig = WINDOW_CONFIG;

    const rightWallGroup = new THREE.Group();
    rightWallGroup.name = 'RightWallAndWindowGroup';

    // A. Back Section of Right Wall (from back-right corner Z = -3.5 to window start Z = -1.8)
    const backSectionDepth = 1.7;
    const backSectionGeo = new THREE.BoxGeometry(WALL_THICKNESS, ROOM_HEIGHT, backSectionDepth);
    const backSection = new THREE.Mesh(backSectionGeo, this.materials.wallCream);
    backSection.position.set(wallX, ROOM_HEIGHT * 0.5, -halfD + backSectionDepth * 0.5);
    backSection.receiveShadow = true;
    backSection.castShadow = true;
    rightWallGroup.add(backSection);

    // Baseboard on back section of right wall
    const backBaseboardGeo = new THREE.BoxGeometry(0.04, 0.20, backSectionDepth);
    const backBaseboard = new THREE.Mesh(backBaseboardGeo, this.materials.woodTrim);
    backBaseboard.position.set(halfW - 0.02, MAIN_FLOOR_Y + 0.10, -halfD + backSectionDepth * 0.5);
    backBaseboard.receiveShadow = true;
    rightWallGroup.add(backBaseboard);

    // B. Wall Below Window with Vertical Honey Oak Wainscoting Paneling
    const lowerWallGeo = new THREE.BoxGeometry(WALL_THICKNESS, winConfig.sillY, winConfig.width);
    const lowerWall = new THREE.Mesh(lowerWallGeo, this.materials.wallCream);
    lowerWall.position.set(wallX, winConfig.sillY * 0.5, winConfig.centerZ);
    lowerWall.receiveShadow = true;
    lowerWall.castShadow = true;
    rightWallGroup.add(lowerWall);

    // Warm Vertical Honey Oak Wainscot Paneling below window (as in nook-room.jpeg)
    const wainscotGeo = new THREE.BoxGeometry(0.05, winConfig.sillY - MAIN_FLOOR_Y, winConfig.width);
    const wainscot = new THREE.Mesh(wainscotGeo, this.materials.woodHoney);
    wainscot.position.set(halfW - 0.025, (winConfig.sillY + MAIN_FLOOR_Y) * 0.5, winConfig.centerZ);
    wainscot.castShadow = true;
    wainscot.receiveShadow = true;
    rightWallGroup.add(wainscot);

    // Wainscot Top Rail / Skirt Trim
    const skirtGeo = new THREE.BoxGeometry(0.08, 0.08, winConfig.width + 0.1);
    const skirt = new THREE.Mesh(skirtGeo, this.materials.woodTrim);
    skirt.position.set(halfW - 0.04, winConfig.sillY - 0.04, winConfig.centerZ);
    skirt.castShadow = true;
    rightWallGroup.add(skirt);

    // C. Top Header Wall Section Above Window
    const topWallHeight = ROOM_HEIGHT - (winConfig.sillY + winConfig.height);
    const topWallGeo = new THREE.BoxGeometry(WALL_THICKNESS, topWallHeight, winConfig.width);
    const topWall = new THREE.Mesh(topWallGeo, this.materials.wallCream);
    topWall.position.set(wallX, ROOM_HEIGHT - topWallHeight * 0.5, winConfig.centerZ);
    topWall.castShadow = true;
    rightWallGroup.add(topWall);

    // D. Front Section of Right Wall (from window end Z = 1.6 to front edge Z = 3.5)
    // Solid cream wall section where pictures and wall lamp hang in reference
    const frontSectionDepth = 1.9;
    const frontSectionGeo = new THREE.BoxGeometry(WALL_THICKNESS, ROOM_HEIGHT, frontSectionDepth);
    const frontSection = new THREE.Mesh(frontSectionGeo, this.materials.wallCream);
    frontSection.position.set(wallX, ROOM_HEIGHT * 0.5, winConfig.centerZ + winConfig.width * 0.5 + frontSectionDepth * 0.5);
    frontSection.receiveShadow = true;
    frontSection.castShadow = true;
    rightWallGroup.add(frontSection);

    // Front section baseboard
    const frontBaseboardGeo = new THREE.BoxGeometry(0.04, 0.20, frontSectionDepth);
    const frontBaseboard = new THREE.Mesh(frontBaseboardGeo, this.materials.woodTrim);
    frontBaseboard.position.set(halfW - 0.02, MAIN_FLOOR_Y + 0.10, winConfig.centerZ + winConfig.width * 0.5 + frontSectionDepth * 0.5);
    frontBaseboard.receiveShadow = true;
    rightWallGroup.add(frontBaseboard);

    // E. Window Frame & Glass Assembly
    const frameDepth = WALL_THICKNESS + 0.14;
    const frameThick = winConfig.frameThickness;

    // Window Sill Shelf (Deep honey wood shelf where plants & cat sit)
    const sillDepth = frameDepth + 0.35;
    const sillGeo = new THREE.BoxGeometry(sillDepth, 0.12, winConfig.width + 0.4);
    const sill = new THREE.Mesh(sillGeo, this.materials.woodTrim);
    sill.position.set(halfW - 0.08, winConfig.sillY + 0.06, winConfig.centerZ);
    sill.castShadow = true;
    sill.receiveShadow = true;
    rightWallGroup.add(sill);

    // Top Frame Rail
    const topRailGeo = new THREE.BoxGeometry(frameDepth, frameThick, winConfig.width);
    const topRail = new THREE.Mesh(topRailGeo, this.materials.woodHoney);
    topRail.position.set(wallX, winConfig.sillY + winConfig.height - frameThick * 0.5, winConfig.centerZ);
    topRail.castShadow = true;
    rightWallGroup.add(topRail);

    // Left & Right Vertical Jambs
    const jambGeo = new THREE.BoxGeometry(frameDepth, winConfig.height - frameThick, frameThick);
    const leftJamb = new THREE.Mesh(jambGeo, this.materials.woodHoney);
    leftJamb.position.set(wallX, winConfig.sillY + winConfig.height * 0.5, winConfig.centerZ - winConfig.width * 0.5 + frameThick * 0.5);
    leftJamb.castShadow = true;
    rightWallGroup.add(leftJamb);

    const rightJamb = new THREE.Mesh(jambGeo, this.materials.woodHoney);
    rightJamb.position.set(wallX, winConfig.sillY + winConfig.height * 0.5, winConfig.centerZ + winConfig.width * 0.5 - frameThick * 0.5);
    rightJamb.castShadow = true;
    rightWallGroup.add(rightJamb);

    // Center Vertical Mullion (Dividing into two classic sunny panes)
    const mullionGeo = new THREE.BoxGeometry(frameDepth * 0.75, winConfig.height - frameThick * 2, winConfig.mullionWidth);
    const centerMullion = new THREE.Mesh(mullionGeo, this.materials.woodHoney);
    centerMullion.position.set(wallX, winConfig.sillY + winConfig.height * 0.5, winConfig.centerZ);
    centerMullion.castShadow = true;
    rightWallGroup.add(centerMullion);

    // Window Glass Panes (Warm sunlight pours through)
    const glassGeo = new THREE.BoxGeometry(0.015, winConfig.height - frameThick * 2, winConfig.width - frameThick * 2);
    const glass = new THREE.Mesh(glassGeo, this.materials.windowGlass);
    glass.position.set(wallX, winConfig.sillY + winConfig.height * 0.5, winConfig.centerZ);
    rightWallGroup.add(glass);

    // Outdoor Sunny Sky & Foliage View Plane (Placed just outside the window aperture)
    const outdoorGeo = new THREE.PlaneGeometry(5.0, 3.8);
    const outdoorBackdrop = new THREE.Mesh(outdoorGeo, this.materials.outdoorSky);
    outdoorBackdrop.position.set(wallX + 1.2, winConfig.sillY + winConfig.height * 0.5, winConfig.centerZ);
    outdoorBackdrop.rotation.y = -Math.PI / 2;
    rightWallGroup.add(outdoorBackdrop);

    this.architecture.add(rightWallGroup);
  }

  // MARK: - 6. Thick Wooden Upper Wall Trim
  buildThickUpperWallTrim() {
    const halfW = ROOM_WIDTH * 0.5;
    const halfD = ROOM_DEPTH * 0.5;

    const trimW = UPPER_TRIM_WIDTH;
    const trimH = UPPER_TRIM_HEIGHT;
    const trimY = ROOM_HEIGHT + trimH * 0.5;

    // A. Left Wall Top Header Trim
    const leftTrimGeo = new THREE.BoxGeometry(trimW, trimH, ROOM_DEPTH + trimW);
    const leftTrim = new THREE.Mesh(leftTrimGeo, this.materials.woodTrim);
    leftTrim.position.set(-halfW - WALL_THICKNESS * 0.5, trimY, 0);
    leftTrim.castShadow = true;
    leftTrim.receiveShadow = true;
    this.architecture.add(leftTrim);

    // B. Back Wall Top Header Trim
    const backTrimGeo = new THREE.BoxGeometry(ROOM_WIDTH + WALL_THICKNESS * 2 + trimW * 2, trimH, trimW);
    const backTrim = new THREE.Mesh(backTrimGeo, this.materials.woodTrim);
    backTrim.position.set(0, trimY, -halfD - WALL_THICKNESS * 0.5);
    backTrim.castShadow = true;
    backTrim.receiveShadow = true;
    this.architecture.add(backTrim);

    // C. Right Wall Top Header Trim (Continuous across the entire right wall top)
    const rightTrimGeo = new THREE.BoxGeometry(trimW, trimH, ROOM_DEPTH + trimW);
    const rightTrim = new THREE.Mesh(rightTrimGeo, this.materials.woodTrim);
    rightTrim.position.set(halfW + WALL_THICKNESS * 0.5, trimY, 0);
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

    // A. Center-Right Vertical Bookshelf (recessed into nook behind bed)
    const uprightH = 3.6;
    const uprightW = 0.08;
    const uprightD = 0.48;

    const uprightGeo = new THREE.BoxGeometry(uprightW, uprightH, uprightD);

    // Left Upright
    const leftUpright = new THREE.Mesh(uprightGeo, trimMat);
    leftUpright.position.set(0.2, 1.8 + uprightH * 0.5, backZ + uprightD * 0.5);
    leftUpright.castShadow = true;
    shelfGroup.add(leftUpright);

    // Right Upright
    const rightUpright = new THREE.Mesh(uprightGeo, trimMat);
    rightUpright.position.set(2.8, 1.8 + uprightH * 0.5, backZ + uprightD * 0.5);
    rightUpright.castShadow = true;
    shelfGroup.add(rightUpright);

    // Top Storage Ledge / Crown Header Beam
    const topLedgeGeo = new THREE.BoxGeometry(2.8 - 0.2 + uprightW * 2, 0.12, uprightD + 0.08);
    const topLedge = new THREE.Mesh(topLedgeGeo, trimMat);
    topLedge.position.set(1.5, 1.8 + uprightH + 0.06, backZ + uprightD * 0.5);
    topLedge.castShadow = true;
    shelfGroup.add(topLedge);

    // Horizontal Shelves
    const shelfWidth = 2.8 - 0.2;
    const shelfPlankGeo = new THREE.BoxGeometry(shelfWidth, 0.06, uprightD);

    const shelfHeights = [2.2, 3.0, 3.8, 4.6];
    for (const y of shelfHeights) {
      const plank = new THREE.Mesh(shelfPlankGeo, woodMat);
      plank.position.set(1.5, y, backZ + uprightD * 0.5);
      plank.castShadow = true;
      plank.receiveShadow = true;
      shelfGroup.add(plank);
    }

    // Warm Honey Wood Backing Panel for the Bookshelf
    const backPanelGeo = new THREE.BoxGeometry(shelfWidth, uprightH, 0.03);
    const backPanel = new THREE.Mesh(backPanelGeo, woodMat);
    backPanel.position.set(1.5, 1.8 + uprightH * 0.5, backZ + 0.015);
    backPanel.receiveShadow = true;
    shelfGroup.add(backPanel);

    // B. Left Upper Shelving Unit (above workstation desk)
    const deskShelfWidth = 3.6;
    const deskShelfPlankGeo = new THREE.BoxGeometry(deskShelfWidth, 0.06, 0.42);

    const deskShelfHeights = [4.0, 4.8];
    for (const y of deskShelfHeights) {
      const plank = new THREE.Mesh(deskShelfPlankGeo, woodMat);
      plank.position.set(-2.8, y, backZ + 0.21);
      plank.castShadow = true;
      plank.receiveShadow = true;
      shelfGroup.add(plank);
    }

    // Vertical Divider Brackets between desk shelves
    const dividerGeo = new THREE.BoxGeometry(0.06, 0.74, 0.40);
    const div1 = new THREE.Mesh(dividerGeo, trimMat);
    div1.position.set(-2.8, 4.4, backZ + 0.21);
    div1.castShadow = true;
    shelfGroup.add(div1);

    const div2 = new THREE.Mesh(dividerGeo, trimMat);
    div2.position.set(-4.2, 4.4, backZ + 0.21);
    div2.castShadow = true;
    shelfGroup.add(div2);

    // Horizontal Pegboard / Pinboard Backing Slat below the shelf
    const pinboardGeo = new THREE.BoxGeometry(deskShelfWidth, 1.1, 0.03);
    const pinboard = new THREE.Mesh(pinboardGeo, woodMat);
    pinboard.position.set(-2.8, 3.2, backZ + 0.015);
    pinboard.receiveShadow = true;
    shelfGroup.add(pinboard);

    this.architecture.add(shelfGroup);
  }

  update(delta) {
    this.lighting.update(delta);
    this.environment.update(delta);
  }
}
