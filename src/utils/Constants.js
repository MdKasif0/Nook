/**
 * Nook 3D - Global Dimensions, Coordinates, Palettes, and Architectural Constants
 * Carefully calibrated to match the reference composition (nook-room.jpeg).
 *
 * Coordinate System:
 *   Y = Vertical (Up / Down)
 *   X = Horizontal (Left / Right)
 *   Z = Depth (Front / Back)
 * Room is centered around world origin (0, 0, 0).
 */

export const ROOM_WIDTH = 4.0;
export const ROOM_DEPTH = 4.0;
export const ROOM_HEIGHT = 2.6;
export const WALL_THICKNESS = 0.16;
export const FLOOR_THICKNESS = 0.18;
export const WOOD_TRIM_HEIGHT = 0.14;
export const WOOD_TRIM_DEPTH = 0.22;

// Stepped floor architecture (matching reference: sunken desk pit + raised bed platform)
export const UPPER_FLOOR_Y = 0.0;
export const LOWER_FLOOR_Y = -0.15;
export const STEP_HEIGHT = 0.075;

// Placement / Droppable surface elevations
export const SURFACE_HEIGHTS = {
  FLOOR_UPPER: UPPER_FLOOR_Y,
  FLOOR_LOWER: LOWER_FLOOR_Y,
  DESK_TOP: 0.62,
  BED_MATTRESS: 0.44,
  BENCH_TOP: 0.28,
  SHELF_LOW: 1.15,
  SHELF_MID: 1.55,
  SHELF_HIGH: 1.95,
  WINDOW_SILL: 0.76,
  POUF_TOP: 0.18
};

// Warm miniature palette directly matching nook-room.jpeg
export const PALETTE = {
  // Wood finishes
  woodHoney: 0xd49b5c,
  woodOakDark: 0x9b612e,
  woodOakBevel: 0xb5783d,
  woodFloorLight: 0xddaa6f,
  woodFloorDark: 0xc89052,
  woodTrim: 0x8a5426,

  // Architecture & walls
  wallCream: 0xf6f0e4,
  wallCreamShade: 0xede3d2,
  baseboard: 0x915c2d,

  // Textiles & Comfort
  bedSheets: 0xf9f7f2,
  bedBlanketSage: 0x6e8a72,
  bedPillowCream: 0xf4eee4,
  bedPillowSage: 0x879f8b,
  pillowDaisyYellow: 0xefa744,
  rugCream: 0xeee7db,
  rugPatternGreen: 0x647e68,
  poufBoucle: 0xede5db,

  // Accents & Props
  ceramicWhite: 0xf7f5f0,
  plantGreen: 0x3d6e40,
  plantGreenLight: 0x5a915e,
  terracotta: 0xc66946,
  recordPlayerDustyRose: 0xd69d9d,
  recordVinyl: 0x222022,
  skateboardBlack: 0x232326,
  chairFabric: 0xc8d7cb,
  chairPlastic: 0xf2f0ea,
  lampWarmBrass: 0xd8b273,
  lampShade: 0xf8f5ee,

  // Cat (Cookie)
  cookieWhite: 0xfcfaf5,
  cookieGinger: 0xcc7b38,
  cookieDarkBrown: 0x3d322b,
  cookieBlush: 0xf8a6a6,
  cookieEarsPink: 0xf3bfbf,

  // Environment & Lighting
  sunlightWarm: 0xffebd0,
  ambientSky: 0xfff6ec,
  ambientGround: 0xdfcbb4,
  lampGlow: 0xffaf58,
  environmentBg: 0xebdccf,
  tabletopShadow: 0xd4c2b0
};

// Camera framing (isometric-leaning miniature perspective)
export const CAMERA_CONFIG = {
  fov: 34,
  near: 0.1,
  far: 50.0,
  defaultPosition: [5.6, 4.6, 5.6],
  defaultTarget: [0.0, 0.35, 0.0],
  minDistance: 3.2,
  maxDistance: 11.0,
  minPolarAngle: Math.PI * 0.16, // ~28 degrees from top
  maxPolarAngle: Math.PI * 0.44, // ~79 degrees
  minAzimuthAngle: -Math.PI * 0.15, // Clamped exploration around the cutaway
  maxAzimuthAngle: Math.PI * 0.65
};

// Lighting intensities (photometrically balanced, non-overexposing)
export const LIGHTING_CONFIG = {
  sunlightIntensity: 2.2,
  ambientSkyIntensity: 0.6,
  deskLampIntensity: 1.4,
  accentShelfIntensity: 0.8,
  windowRimIntensity: 0.4,
  exposure: 1.05
};

// Interactive Object Categories
export const OBJECT_CATEGORIES = {
  THOUGHT: 'thought',
  FURNITURE: 'furniture',
  PROP: 'prop',
  CHARACTER: 'character',
  LIGHTING: 'lighting'
};
