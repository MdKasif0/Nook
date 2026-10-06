/**
 * Nook 3D - Architectural Dimensions, Proportions, Palettes, and Camera Setup
 * Calibrated specifically to match the 10 × 7 × 5.6 diorama proportions of nook-room.jpeg.
 *
 * Coordinate System:
 *   Y = Vertical (Up / Down)
 *   X = Horizontal (Left / Right, Left Wall = -X, Right Wall = +X)
 *   Z = Depth (Front / Back, Back Wall = -Z, Open Front = +Z)
 * Centered around origin (0, 0, 0).
 */

// Room Proportions specified by user
export const ROOM_WIDTH = 10.0;
export const ROOM_DEPTH = 7.0;
export const ROOM_HEIGHT = 5.6;

// Structural Architecture
export const WALL_THICKNESS = 0.38;
export const BASE_PLATFORM_THICKNESS = 0.48;
export const UPPER_TRIM_WIDTH = 0.56;
export const UPPER_TRIM_HEIGHT = 0.36;

// Stepped Levels
export const LOWER_FLOOR_Y = 0.0;       // Lower front deck
export const STEP_HEIGHT = 0.14;        // Subtle riser height
export const MAIN_FLOOR_Y = 0.28;       // Main room floor (desk & bed level)
export const UPPER_FLOOR_Y = MAIN_FLOOR_Y;

export const SURFACE_HEIGHTS = {
  FLOOR_UPPER: MAIN_FLOOR_Y,
  FLOOR_LOWER: LOWER_FLOOR_Y,
  DESK_TOP: MAIN_FLOOR_Y + 1.45,
  BED_MATTRESS: MAIN_FLOOR_Y + 0.95,
  BENCH_TOP: MAIN_FLOOR_Y + 0.65,
  WINDOW_SILL: 2.1,
  POUF_TOP: LOWER_FLOOR_Y + 0.42
};

// Window Architecture (Right Wall)
export const WINDOW_CONFIG = {
  centerZ: -0.1,
  width: 3.4,
  sillY: 2.05,
  height: 2.35,
  frameThickness: 0.14,
  mullionWidth: 0.08
};

// Built-in Shelving Structure (Back Wall)
export const SHELF_CONFIG = {
  leftX: 0.2,
  rightX: 2.8,
  bottomY: 1.8,
  topY: 5.2,
  depth: 0.52,
  plankThickness: 0.07
};

// Warm Ivory / Cream & Natural Honey Wood Palettes
export const PALETTE = {
  // Walls
  wallCream: 0xf7f1e6,
  wallCreamLight: 0xfbf6ed,
  wallCreamShade: 0xeee4d3,

  // Warm Natural Honey Wood (No dark mahogany, no neon orange, no glossy plastic)
  woodHoney: 0xdda362,
  woodHoneyLight: 0xe6b477,
  woodHoneyDark: 0xc28642,
  woodTrim: 0xb97a38,
  woodPlanks: 0xd89d5a,

  // Environment & Backing (Clean warm studio ivory)
  environmentBg: 0xf6f0e8,
  studioPedestal: 0xedd8c0,
  glassWindow: 0xffffff,
  outdoorSky: 0x93cbef,
  outdoorTrees: 0x76a86c,

  // Lighting (Warm golden morning sunlight & luminous ambient bounce)
  sunlightGolden: 0xffe6c2,
  ambientSky: 0xfff8ee,
  ambientGround: 0xf0d6b5,
  accentGlow: 0xffbf75,

  // Object & Prop Colors (Used by ObjectManager and CookieController)
  bedBlanketSage: 0x8ea889,
  bedSheets: 0xfaf5ec,
  pillowDaisyYellow: 0xf7d057,
  ceramicWhite: 0xfbf9f5,
  recordPlayerDustyRose: 0xd8a49c,
  recordVinyl: 0x222224,
  skateboardBlack: 0x2c2c2e,
  plantGreen: 0x487a42,

  // Cookie Calico Colors
  cookieWhite: 0xfaf7f2,
  cookieGinger: 0xd68945,
  cookieDarkBrown: 0x3d2817,
  cookieEarsPink: 0xf2aeb5,
  cookieBlush: 0xf9bcc3
};

// NookMainCamera reference configuration (Subtle elevated 3/4 isometric perspective)
export const CAMERA_CONFIG = {
  name: 'NookMainCamera',
  fov: 30,
  near: 0.1,
  far: 80.0,
  defaultPosition: [-2.6, 9.2, 16.2],
  defaultTarget: [0.15, 1.85, 0.0],
  minDistance: 7.0,
  maxDistance: 22.0,
  minPolarAngle: Math.PI * 0.22,
  maxPolarAngle: Math.PI * 0.38,
  minAzimuthAngle: -Math.PI * 0.30,
  maxAzimuthAngle: Math.PI * 0.18
};

// Photometric lighting intensities matching soft morning sunlight in nook-room.jpeg
export const LIGHTING_CONFIG = {
  sunlightIntensity: 2.8,
  ambientSkyIntensity: 1.15,
  ambientGroundIntensity: 0.72,
  frontFillIntensity: 0.85,
  shelfAccentIntensity: 0.35,
  exposure: 1.15
};
