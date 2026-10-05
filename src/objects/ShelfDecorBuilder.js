/**
 * Nook 3D - ShelfDecorBuilder
 * Recreates the rich, cozy shelf styling, wall art, analog clock, kraft boxes,
 * 3D curtains, and decorative ceramics matching nook-room.jpeg.
 */

import * as THREE from 'three';
import { TextureGenerator } from '../utils/TextureGenerator.js';
import { PALETTE } from '../utils/Constants.js';
import { MaterialSystem } from '../materials/MaterialSystem.js';

export class ShelfDecorBuilder {
  constructor() {
    this.materials = this.createMaterials();
  }

  createMaterials() {
    const pbr = MaterialSystem.getMaterials();

    const clockTexture = TextureGenerator.createClockFaceTexture(512);
    const botPrint1 = TextureGenerator.createBotanicalArtTexture(0, 512, 640);
    const botPrint2 = TextureGenerator.createBotanicalArtTexture(1, 512, 640);
    const botPrint3 = TextureGenerator.createBotanicalArtTexture(2, 512, 640);
    const botPrint4 = TextureGenerator.createBotanicalArtTexture(3, 512, 640);
    const curtainTexture = TextureGenerator.createCurtainFabricTexture(512, 1024);

    return {
      clockFace: new THREE.MeshBasicMaterial({ map: clockTexture }),
      brassGold: pbr.Metal_Warm,
      clockBodyWood: pbr.Wood_Warm,
      botArt1: new THREE.MeshStandardMaterial({
        map: botPrint1,
        roughness: 0.94,
        metalness: 0.0
      }),
      botArt2: new THREE.MeshStandardMaterial({
        map: botPrint2,
        roughness: 0.94,
        metalness: 0.0
      }),
      botArt3: new THREE.MeshStandardMaterial({
        map: botPrint3,
        roughness: 0.94,
        metalness: 0.0
      }),
      botArt4: new THREE.MeshStandardMaterial({
        map: botPrint4,
        roughness: 0.94,
        metalness: 0.0
      }),
      curtainFabric: new THREE.MeshStandardMaterial({
        color: 0xfbf8f1,
        map: curtainTexture,
        normalMap: pbr.Fabric_Cream.normalMap,
        normalScale: new THREE.Vector2(0.5, 0.5),
        roughness: 0.88,
        metalness: 0.01,
        side: THREE.DoubleSide
      }),
      curtainRodWood: pbr.Wood_Dark,
      kraftBox: new THREE.MeshStandardMaterial({
        color: 0xcaa375,
        roughness: 0.92,
        metalness: 0.0
      }),
      kraftLid: new THREE.MeshStandardMaterial({
        color: 0xbe9767,
        roughness: 0.90,
        metalness: 0.0
      }),
      ceramicWhite: pbr.Ceramic_Cream,
      ceramicTerracotta: new THREE.MeshStandardMaterial({
        color: 0xc77651,
        roughness: 0.76,
        metalness: 0.02
      }),
      ceramicSage: new THREE.MeshPhysicalMaterial({
        color: 0x8ea889,
        roughness: 0.35,
        clearcoat: 0.25,
        clearcoatRoughness: 0.20
      }),
      frameOak: pbr.Wood_Light,
      catFigurineWhite: new THREE.MeshStandardMaterial({
        color: 0xffffff,
        roughness: 0.55,
        metalness: 0.02
      }),
      catEarsPink: new THREE.MeshStandardMaterial({
        color: 0xf5bfbe,
        roughness: 0.65
      }),
      washiTape: new THREE.MeshStandardMaterial({
        color: 0xe8dfc8,
        roughness: 0.85,
        transparent: true,
        opacity: 0.92
      }),
      sconceShade: new THREE.MeshStandardMaterial({
        color: 0xdfcaa0,
        roughness: 0.45,
        metalness: 0.15
      }),
      sconceArm: new THREE.MeshStandardMaterial({
        color: 0x6e563d,
        roughness: 0.38,
        metalness: 0.65
      })
    };
  }

  /**
   * Generates a realistic row of books with varied height, width, tilt, and muted palette.
   */
  buildBookRow(startX, y, z, count = 8, spacing = 0.075, options = {}) {
    const group = new THREE.Group();
    group.name = 'BookRow';

    const bookColors = [
      0xf5efe3, // cream
      0xdfcfb7, // beige
      0x8ea889, // sage
      0xc97a5e, // muted terracotta
      0x8a5d3b, // warm brown
      0x6a7d57, // muted olive
      0xd9ab73, // golden ochre
      0x7f9486  // soft forest
    ];

    let curX = startX;
    for (let i = 0; i < count; i++) {
      const bW = 0.045 + (i % 3) * 0.018;
      const bH = 0.32 + (Math.sin(i * 1.7) * 0.08);
      const bD = 0.24 + (i % 2) * 0.04;

      const color = bookColors[(i * 3 + (options.seed || 0)) % bookColors.length];
      const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.78, metalness: 0.02 });

      // Book cover / pages
      const bookGeo = new THREE.BoxGeometry(bW, bH, bD);
      const book = new THREE.Mesh(bookGeo, mat);

      // Leaning book at end of row
      let rotZ = 0;
      if (options.leanLast && i === count - 1) {
        rotZ = 0.24;
        book.position.set(curX + bW * 0.5 + 0.04, y + bH * 0.48, z);
      } else if (options.leanFirst && i === 0) {
        rotZ = -0.22;
        book.position.set(curX + bW * 0.5 - 0.03, y + bH * 0.48, z);
      } else {
        book.position.set(curX + bW * 0.5, y + bH * 0.5, z);
      }

      book.rotation.z = rotZ;
      book.castShadow = true;
      book.receiveShadow = true;
      group.add(book);

      curX += bW + 0.015;
    }

    return group;
  }

  /**
   * Generates a horizontal stack of 2-3 books with a ceramic object or succulent on top.
   */
  buildBookStack(x, y, z, count = 3, topObject = null) {
    const group = new THREE.Group();
    group.name = 'BookStack';

    const colors = [0xdfcfb7, 0x8ea889, 0xc97a5e, 0x8a5d3b];
    let curY = y;

    for (let i = 0; i < count; i++) {
      const bW = 0.32 - i * 0.025;
      const bH = 0.055;
      const bD = 0.26 - i * 0.02;

      const mat = new THREE.MeshStandardMaterial({
        color: colors[i % colors.length],
        roughness: 0.78
      });
      const geo = new THREE.BoxGeometry(bW, bH, bD);
      const book = new THREE.Mesh(geo, mat);
      book.position.set(x, curY + bH * 0.5, z);
      book.rotation.y = (i - 1) * 0.12;
      book.castShadow = true;
      book.receiveShadow = true;
      group.add(book);

      curY += bH;
    }

    // Optional ceramic cup on top
    if (topObject === 'cup') {
      const cupGeo = new THREE.CylinderGeometry(0.055, 0.045, 0.09, 16);
      const cup = new THREE.Mesh(cupGeo, this.materials.ceramicTerracotta);
      cup.position.set(x + 0.02, curY + 0.045, z);
      cup.castShadow = true;
      group.add(cup);
    }

    return group;
  }

  /**
   * Builds the physical 3D analog shelf clock (round face, brass housing, bells/feet).
   */
  buildAnalogClock(x, y, z) {
    const group = new THREE.Group();
    group.name = 'AnalogClock';
    group.position.set(x, y, z);
    group.rotation.y = -0.15;

    const radius = 0.16;
    const depth = 0.08;

    // Clock Housing Barrel
    const barrelGeo = new THREE.CylinderGeometry(radius, radius, depth, 24);
    barrelGeo.rotateX(Math.PI * 0.5);
    const barrel = new THREE.Mesh(barrelGeo, this.materials.clockBodyWood);
    barrel.position.set(0, radius + 0.04, 0);
    barrel.castShadow = true;
    group.add(barrel);

    // Front Brass Bezel Ring
    const bezelGeo = new THREE.TorusGeometry(radius, 0.015, 12, 32);
    const bezel = new THREE.Mesh(bezelGeo, this.materials.brassGold);
    bezel.position.set(0, radius + 0.04, depth * 0.5 + 0.005);
    bezel.castShadow = true;
    group.add(bezel);

    // Clock Face Dial (with procedural numerals & hands)
    const faceGeo = new THREE.PlaneGeometry(radius * 1.95, radius * 1.95);
    const face = new THREE.Mesh(faceGeo, this.materials.clockFace);
    face.position.set(0, radius + 0.04, depth * 0.5 + 0.008);
    group.add(face);

    // Top Twin Bells / Hammer detail
    const bellGeo = new THREE.SphereGeometry(0.045, 12, 10, 0, Math.PI * 2, 0, Math.PI * 0.65);
    const bellL = new THREE.Mesh(bellGeo, this.materials.brassGold);
    bellL.position.set(-radius * 0.55, radius * 2 + 0.02, 0);
    bellL.rotation.z = -0.4;
    group.add(bellL);

    const bellR = new THREE.Mesh(bellGeo, this.materials.brassGold);
    bellR.position.set(radius * 0.55, radius * 2 + 0.02, 0);
    bellR.rotation.z = 0.4;
    group.add(bellR);

    // Top Handle Loop
    const handleGeo = new THREE.TorusGeometry(0.035, 0.007, 8, 16, Math.PI);
    const topHandle = new THREE.Mesh(handleGeo, this.materials.brassGold);
    topHandle.position.set(0, radius * 2 + 0.035, 0);
    group.add(topHandle);

    // 2 Angled Peg Feet
    const footGeo = new THREE.CylinderGeometry(0.012, 0.008, 0.06, 8);
    const footL = new THREE.Mesh(footGeo, this.materials.brassGold);
    footL.position.set(-radius * 0.5, 0.03, 0);
    footL.rotation.z = 0.35;
    group.add(footL);

    const footR = new THREE.Mesh(footGeo, this.materials.brassGold);
    footR.position.set(radius * 0.5, 0.03, 0);
    footR.rotation.z = -0.35;
    group.add(footR);

    return group;
  }

  /**
   * Large kraft storage box with cutout handles and lid (on top shelf).
   */
  buildKraftStorageBox(x, y, z, w = 0.65, h = 0.42, d = 0.48) {
    const group = new THREE.Group();
    group.name = 'KraftStorageBox';
    group.position.set(x, y, z);

    // Main Box
    const boxGeo = new THREE.BoxGeometry(w, h, d);
    const box = new THREE.Mesh(boxGeo, this.materials.kraftBox);
    box.position.set(0, h * 0.5, 0);
    box.castShadow = true;
    box.receiveShadow = true;
    group.add(box);

    // Overlapping Top Lid
    const lidGeo = new THREE.BoxGeometry(w + 0.03, 0.08, d + 0.03);
    const lid = new THREE.Mesh(lidGeo, this.materials.kraftLid);
    lid.position.set(0, h + 0.035, 0);
    lid.castShadow = true;
    group.add(lid);

    // Front Oval Cutout Handle
    const handleGeo = new THREE.CylinderGeometry(0.045, 0.045, 0.01, 16);
    handleGeo.rotateX(Math.PI * 0.5);
    handleGeo.scale(1.8, 0.7, 1.0);
    const handleMat = new THREE.MeshStandardMaterial({ color: 0x4a3622 });
    const handleHole = new THREE.Mesh(handleGeo, handleMat);
    handleHole.position.set(0, h * 0.75, d * 0.5 + 0.002);
    group.add(handleHole);

    return group;
  }

  /**
   * Adorable white cat figurine sitting on the top shelf next to kraft box.
   */
  buildWhiteCatFigurine(x, y, z) {
    const group = new THREE.Group();
    group.name = 'CatFigurine';
    group.position.set(x, y, z);
    group.rotation.y = 0.25;

    // Body Loaf
    const bodyGeo = new THREE.SphereGeometry(0.09, 16, 14);
    bodyGeo.scale(1.0, 0.9, 1.15);
    const body = new THREE.Mesh(bodyGeo, this.materials.catFigurineWhite);
    body.position.set(0, 0.08, 0);
    body.castShadow = true;
    group.add(body);

    // Chibi Head
    const headGeo = new THREE.SphereGeometry(0.075, 16, 14);
    const head = new THREE.Mesh(headGeo, this.materials.catFigurineWhite);
    head.position.set(0, 0.18, 0.04);
    head.castShadow = true;
    group.add(head);

    // Pointed Ears
    const earGeo = new THREE.ConeGeometry(0.026, 0.05, 4);
    const earL = new THREE.Mesh(earGeo, this.materials.catFigurineWhite);
    earL.position.set(-0.04, 0.24, 0.03);
    earL.rotation.set(-0.15, 0, 0.35);
    group.add(earL);

    const earR = new THREE.Mesh(earGeo, this.materials.catFigurineWhite);
    earR.position.set(0.04, 0.24, 0.03);
    earR.rotation.set(-0.15, 0, -0.35);
    group.add(earR);

    // Pink ear inner details
    const earInGeo = new THREE.ConeGeometry(0.016, 0.035, 4);
    const earInL = new THREE.Mesh(earInGeo, this.materials.catEarsPink);
    earInL.position.set(-0.038, 0.24, 0.04);
    earInL.rotation.set(-0.15, 0, 0.35);
    group.add(earInL);

    const earInR = new THREE.Mesh(earInGeo, this.materials.catEarsPink);
    earInR.position.set(0.038, 0.24, 0.04);
    earInR.rotation.set(-0.15, 0, -0.35);
    group.add(earInR);

    // Curled Tail
    const tailCurve = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 0.04, -0.09),
      new THREE.Vector3(0.06, 0.06, -0.06),
      new THREE.Vector3(0.09, 0.08, 0.02)
    ]);
    const tailGeo = new THREE.TubeGeometry(tailCurve, 12, 0.014, 6, false);
    const tail = new THREE.Mesh(tailGeo, this.materials.catFigurineWhite);
    group.add(tail);

    return group;
  }

  /**
   * Framed picture in wooden honey-oak frame with glass/print.
   */
  buildFramedArt(w, h, artMaterial, frameThickness = 0.03) {
    const group = new THREE.Group();
    group.name = 'FramedArt';

    // 4 Oak frame molding pieces
    // Top & Bottom
    const tbGeo = new THREE.BoxGeometry(w + frameThickness * 2, frameThickness, 0.035);
    const topBar = new THREE.Mesh(tbGeo, this.materials.frameOak);
    topBar.position.set(0, h * 0.5 + frameThickness * 0.5, 0);
    topBar.castShadow = true;
    group.add(topBar);

    const botBar = new THREE.Mesh(tbGeo, this.materials.frameOak);
    botBar.position.set(0, -h * 0.5 - frameThickness * 0.5, 0);
    botBar.castShadow = true;
    group.add(botBar);

    // Left & Right
    const lrGeo = new THREE.BoxGeometry(frameThickness, h, 0.035);
    const leftBar = new THREE.Mesh(lrGeo, this.materials.frameOak);
    leftBar.position.set(-w * 0.5 - frameThickness * 0.5, 0, 0);
    leftBar.castShadow = true;
    group.add(leftBar);

    const rightBar = new THREE.Mesh(lrGeo, this.materials.frameOak);
    rightBar.position.set(w * 0.5 + frameThickness * 0.5, 0, 0);
    rightBar.castShadow = true;
    group.add(rightBar);

    // Art print plane
    const artGeo = new THREE.PlaneGeometry(w, h);
    const artMesh = new THREE.Mesh(artGeo, artMaterial);
    artMesh.position.set(0, 0, 0.01);
    group.add(artMesh);

    return group;
  }

  /**
   * Polaroid photo with top washi tape strip.
   */
  buildPolaroidWithTape(variant = 0, scale = 1.0) {
    const group = new THREE.Group();
    group.name = `Polaroid_${variant}`;

    const pW = 0.22 * scale;
    const pH = 0.27 * scale;

    const texture = TextureGenerator.createPolaroidTexture(variant, 360, 440);
    const mat = new THREE.MeshStandardMaterial({
      map: texture,
      roughness: 0.82,
      metalness: 0.01
    });

    const photoGeo = new THREE.PlaneGeometry(pW, pH);
    const photo = new THREE.Mesh(photoGeo, mat);
    photo.castShadow = true;
    group.add(photo);

    // Washi Tape strip across top edge
    const tapeGeo = new THREE.PlaneGeometry(pW * 0.45, 0.035 * scale);
    const tape = new THREE.Mesh(tapeGeo, this.materials.washiTape);
    tape.position.set(0, pH * 0.5 - 0.005, 0.003);
    tape.rotation.z = (Math.random() - 0.5) * 0.15;
    group.add(tape);

    return group;
  }

  /**
   * Wall sconce reading lamp mounted on the right wall near window/bed.
   */
  buildWallSconce(x, y, z) {
    const group = new THREE.Group();
    group.name = 'WallSconce';
    group.position.set(x, y, z);

    // Wooden circular mounting backplate on wall
    const plateGeo = new THREE.CylinderGeometry(0.08, 0.08, 0.025, 16);
    plateGeo.rotateZ(Math.PI * 0.5);
    const plate = new THREE.Mesh(plateGeo, this.materials.frameOak);
    plate.castShadow = true;
    group.add(plate);

    // Articulated Brass Arm extending out
    const armGeo = new THREE.CylinderGeometry(0.008, 0.008, 0.18, 8);
    armGeo.rotateZ(Math.PI * 0.5);
    const arm = new THREE.Mesh(armGeo, this.materials.sconceArm);
    arm.position.set(-0.09, 0, 0);
    group.add(arm);

    // Downward angled conical shade
    const shadeGeo = new THREE.ConeGeometry(0.095, 0.14, 16, 1, true);
    const shade = new THREE.Mesh(shadeGeo, this.materials.sconceShade);
    shade.position.set(-0.18, -0.05, 0);
    shade.rotation.z = Math.PI * 0.25;
    shade.castShadow = true;
    group.add(shade);

    // Warm Ambient Light from Sconce
    const sconceLight = new THREE.PointLight(0xffdfa8, 0.85, 3.5, 2.0);
    sconceLight.position.set(-0.20, -0.10, 0);
    group.add(sconceLight);

    return group;
  }

  /**
   * Builds the 3D gathered cream curtains with wooden rod, rings, and tiebacks.
   */
  build3DCurtainsAndRod(winConfig, halfW) {
    const group = new THREE.Group();
    group.name = 'CurtainsAndRod';

    const rodY = winConfig.sillY + winConfig.height + 0.18;
    const rodX = halfW - 0.16;
    const winZ = winConfig.centerZ;
    const winW = winConfig.width;

    // 1. Honey Oak Curtain Rod
    const rodLen = winW + 0.75;
    const rodGeo = new THREE.CylinderGeometry(0.022, 0.022, rodLen, 16);
    rodGeo.rotateX(Math.PI * 0.5);
    const rod = new THREE.Mesh(rodGeo, this.materials.curtainRodWood);
    rod.position.set(rodX, rodY, winZ);
    rod.castShadow = true;
    group.add(rod);

    // Rod Finial Knobs (spherical honey oak ends)
    const finialGeo = new THREE.SphereGeometry(0.045, 12, 10);
    const finialL = new THREE.Mesh(finialGeo, this.materials.curtainRodWood);
    finialL.position.set(rodX, rodY, winZ - rodLen * 0.5 - 0.03);
    group.add(finialL);

    const finialR = new THREE.Mesh(finialGeo, this.materials.curtainRodWood);
    finialR.position.set(rodX, rodY, winZ + rodLen * 0.5 + 0.03);
    group.add(finialR);

    // Wall mounting brackets
    const bracketGeo = new THREE.BoxGeometry(0.16, 0.03, 0.03);
    const brL = new THREE.Mesh(bracketGeo, this.materials.curtainRodWood);
    brL.position.set(rodX + 0.07, rodY, winZ - winW * 0.5 - 0.12);
    group.add(brL);

    const brR = new THREE.Mesh(bracketGeo, this.materials.curtainRodWood);
    brR.position.set(rodX + 0.07, rodY, winZ + winW * 0.5 + 0.12);
    group.add(brR);

    // 2. 3D Gathered Fabric Curtains (Left and Right panels with true depth and folds)
    const curtainH = winConfig.height + 0.12;

    const buildCurtainPanel = (panelZ, isLeft) => {
      const panelGroup = new THREE.Group();
      panelGroup.position.set(rodX - 0.02, rodY, panelZ);

      // Wooden Curtain Rings along the top
      for (let r = 0; r < 5; r++) {
        const ringGeo = new THREE.TorusGeometry(0.03, 0.006, 8, 16);
        ringGeo.rotateY(Math.PI * 0.5);
        const ring = new THREE.Mesh(ringGeo, this.materials.curtainRodWood);
        const rz = (r - 2) * 0.07;
        ring.position.set(0, 0, rz);
        panelGroup.add(ring);
      }

      // 5 Fluted Vertical 3D Pleat Tubes forming gathered folds
      for (let p = 0; p < 5; p++) {
        const pz = (p - 2) * 0.065;
        // Wavy spline curving gently toward wall at waist for tieback
        const pinchZ = isLeft ? -0.06 : 0.06;
        const curve = new THREE.CatmullRomCurve3([
          new THREE.Vector3(0, -0.02, pz),
          new THREE.Vector3(0.02, -curtainH * 0.35, pz * 0.8 + pinchZ * 0.4),
          new THREE.Vector3(0.03, -curtainH * 0.55, pz * 0.5 + pinchZ),
          new THREE.Vector3(0.01, -curtainH * 0.80, pz * 0.9 + pinchZ * 0.6),
          new THREE.Vector3(0, -curtainH, pz * 1.25)
        ]);

        const pleatGeo = new THREE.TubeGeometry(curve, 20, 0.035, 8, false);
        const pleat = new THREE.Mesh(pleatGeo, this.materials.curtainFabric);
        pleat.castShadow = true;
        pleat.receiveShadow = true;
        panelGroup.add(pleat);
      }

      // Tie-Back Strap Ribbon (wrapping around waist)
      const strapGeo = new THREE.TorusGeometry(0.12, 0.014, 8, 16, Math.PI * 1.4);
      strapGeo.rotateX(Math.PI * 0.5);
      const strap = new THREE.Mesh(strapGeo, this.materials.curtainFabric);
      strap.position.set(0.02, -curtainH * 0.55, isLeft ? -0.04 : 0.04);
      panelGroup.add(strap);

      return panelGroup;
    };

    // Left gathered curtain
    const leftCurtain = buildCurtainPanel(winZ - winW * 0.5 + 0.16, true);
    group.add(leftCurtain);

    // Right gathered curtain
    const rightCurtain = buildCurtainPanel(winZ + winW * 0.5 - 0.16, false);
    group.add(rightCurtain);

    group.userData.leftCurtain = leftCurtain;
    group.userData.rightCurtain = rightCurtain;

    return group;
  }

  /**
   * 3D Soft Outdoor Environment visible through window.
   */
  buildOutdoorGarden(winConfig, wallX) {
    const group = new THREE.Group();
    group.name = 'OutdoorGarden';

    const outX = wallX + 0.85;
    const cy = winConfig.sillY + winConfig.height * 0.5;
    const cz = winConfig.centerZ;

    // Layered Soft Foliage Canopies (sunlit morning trees)
    const foliageColors = [0x789c56, 0x8cb564, 0x658546, 0x9fbf6f];
    for (let i = 0; i < 9; i++) {
      const angle = (i / 9) * Math.PI * 2;
      const r = 0.55 + (i % 3) * 0.15;
      const geo = new THREE.IcosahedronGeometry(r, 1);
      const mat = new THREE.MeshStandardMaterial({
        color: foliageColors[i % foliageColors.length],
        roughness: 0.72,
        metalness: 0.0
      });
      const canopy = new THREE.Mesh(geo, mat);
      const oy = cy + (Math.sin(i * 1.8) * 0.55) - 0.1;
      const oz = cz + (Math.cos(i * 1.4) * 0.95);
      canopy.position.set(outX + (i % 2) * 0.25, oy, oz);
      group.add(canopy);
    }

    // Warm terracotta rooftop accent in distance
    const roofGeo = new THREE.ConeGeometry(0.7, 0.45, 4);
    roofGeo.rotateY(Math.PI * 0.25);
    const roofMat = new THREE.MeshStandardMaterial({ color: 0xc87452, roughness: 0.85 });
    const roof = new THREE.Mesh(roofGeo, roofMat);
    roof.position.set(outX + 0.5, cy - 0.25, cz + 0.85);
    group.add(roof);

    return group;
  }
}
