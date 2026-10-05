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
export const BASE_PLATFORM_THICKNESS = 0.52;
export const UPPER_TRIM_WIDTH = 0.58;
export const UPPER_TRIM_HEIGHT = 0.38;

// Stepped Levels
export const LOWER_FLOOR_Y = 0.0;       // Sunken desk pit / lower floor
export const UPPER_FLOOR_Y = 0.42;      // Raised bed / entry platform
export const STEP_HEIGHT = 0.21;        // Intermediate step height

export const SURFACE_HEIGHTS = {
  FLOOR_UPPER: UPPER_FLOOR_Y,
  FLOOR_LOWER: LOWER_FLOOR_Y,
  DESK_TOP: 1.45,
  BED_MATTRESS: 0.95,
  BENCH_TOP: 0.65,
  WINDOW_SILL: 2.2,
  POUF_TOP: 0.42
};

// Window Architecture (Right Wall)
export const WINDOW_CONFIG = {
  centerZ: -0.2,
  width: 3.2,
  sillY: 2.2,
  height: 2.3,
  frameThickness: 0.14,
  mullionWidth: 0.08
};

// Built-in Shelving Structure (Back Wall)
export const SHELF_CONFIG = {
  leftX: -1.0,
  rightX: 3.2,
  bottomY: 2.2,
  topY: 5.2,
  depth: 0.55,
  plankThickness: 0.08
};

// Warm Ivory / Cream & Natural Honey Wood Palettes
export const PALETTE = {
  // Walls
  wallCream: 0xf5eedf,
  wallCreamLight: 0xf9f4ea,
  wallCreamShade: 0xede3d2,

  // Warm Natural Honey Wood (No dark mahogany, no neon orange)
  woodHoney: 0xd69c5e,
  woodHoneyLight: 0xdfab6f,
  woodHoneyDark: 0xb5783d,
  woodTrim: 0xa86c35,
  woodPlanks: 0xd09758,

  // Environment & Backing
  environmentBg: 0xede3d6,
  studioPedestal: 0xdfd4c4,
  glassWindow: 0xffffff,
  outdoorSky: 0x8cc4e8,
  outdoorTrees: 0x6e9f65,

  // Lighting
  sunlightGolden: 0xffe2b8,
  ambientSky: 0xfff7ed,
  ambientGround: 0xdfcbaf,
  accentGlow: 0xffb568
};

// NookMainCamera reference configuration
export const CAMERA_CONFIG = {
  name: 'NookMainCamera',
  fov: 32,
  near: 0.1,
  far: 80.0,
  defaultPosition: [-3.8, 10.6, 14.6],
  defaultTarget: [0.2, 1.8, -0.2],
  minDistance: 6.0,
  maxDistance: 24.0,
  minPolarAngle: Math.PI * 0.18,
  maxPolarAngle: Math.PI * 0.42,
  minAzimuthAngle: -Math.PI * 0.45,
  maxAzimuthAngle: Math.PI * 0.25
};

// Photometric lighting intensities
export const LIGHTING_CONFIG = {
  sunlightIntensity: 3.2,
  ambientSkyIntensity: 0.72,
  ambientGroundIntensity: 0.38,
  frontFillIntensity: 0.35,
  shelfAccentIntensity: 0.25,
  exposure: 1.02
};
