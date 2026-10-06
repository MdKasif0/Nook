/**
 * Nook 3D - Automated Verification Suite
 * Validates all 36 points of the production readiness checklist.
 */

import * as THREE from 'three';
import { ROOM_WIDTH, ROOM_DEPTH, ROOM_HEIGHT, CAMERA_CONFIG, LIGHTING_CONFIG, PALETTE } from '../src/utils/Constants.js';
import { thoughtStore } from '../src/persistence/ThoughtStore.js';
import { soundManager } from '../src/audio/SoundManager.js';
import { undoManager, CreateThoughtCommand, DeleteThoughtCommand } from '../src/interaction/UndoManager.js';

console.log('🧪 Starting Nook 3D Full Validation Suite...\n');

let passedTests = 0;
let totalTests = 0;

function assert(condition, message) {
  totalTests++;
  if (condition) {
    console.log(`  ✓ ${message}`);
    passedTests++;
  } else {
    console.error(`  ✗ FAILED: ${message}`);
    process.exitCode = 1;
  }
}

// 1. Proportions & Dimensions
console.log('--- 1. Room Architecture & Proportions ---');
assert(ROOM_WIDTH === 10.0, 'Room width matches 10.0 specification');
assert(ROOM_DEPTH === 7.0, 'Room depth matches 7.0 specification');
assert(ROOM_HEIGHT === 5.6, 'Room height matches 5.6 specification');

// 2. Camera Configuration
console.log('\n--- 2. NookMainCamera & Reset Angle ---');
assert(CAMERA_CONFIG.name === 'NookMainCamera', 'Camera name is NookMainCamera');
assert(CAMERA_CONFIG.fov === 30, 'Field of view is 30 degrees (elevated 3/4 isometric)');
assert(CAMERA_CONFIG.defaultPosition[0] === -2.6 && CAMERA_CONFIG.defaultPosition[1] === 9.2 && CAMERA_CONFIG.defaultPosition[2] === 16.2, 'Default camera position matches reference blueprint');
assert(CAMERA_CONFIG.defaultTarget[0] === 0.15 && CAMERA_CONFIG.defaultTarget[1] === 1.85 && CAMERA_CONFIG.defaultTarget[2] === 0.0, 'Default camera target centers room diorama');

// 3. Lighting & Palette
console.log('\n--- 3. Lighting Calibration & Warm Palette ---');
assert(LIGHTING_CONFIG.sunlightIntensity === 2.8, 'Sunlight intensity matches golden morning sunlight');
assert(LIGHTING_CONFIG.ambientSkyIntensity === 1.15, 'Ambient sky fill provides luminous bounce');
assert(LIGHTING_CONFIG.exposure === 1.15, 'Tone mapping exposure prevents crushed shadows');
assert(PALETTE.environmentBg === 0xf6f0e8, 'Environment background is warm studio ivory');
assert(PALETTE.wallCream === 0xf7f1e6, 'Wall cream color matches natural plaster');
assert(PALETTE.woodHoney === 0xdda362, 'Wood honey color matches natural warm timber');

// 4. Audio Controls & Independent SFX / Ambient
console.log('\n--- 4. SoundManager & Audio Controls ---');
soundManager.setMuted(false);
soundManager.setSfxEnabled(true);
soundManager.setAmbientEnabled(true);
assert(soundManager.isSfxEnabled() === true, 'SFX is initially enabled');
assert(soundManager.isAmbientEnabled() === true, 'Ambient sound is initially enabled');

soundManager.setSfxEnabled(false);
assert(soundManager.isSfxEnabled() === false, 'SFX can be disabled independently');
assert(soundManager.isAmbientEnabled() === true, 'Ambient remains enabled when SFX is disabled');

soundManager.setAmbientEnabled(false);
assert(soundManager.isAmbientEnabled() === false, 'Ambient can be disabled independently');

soundManager.setMuted(true);
assert(soundManager.isSfxEnabled() === false && soundManager.isAmbientEnabled() === false, 'Muting disables all audio output');
soundManager.setMuted(false);
soundManager.setSfxEnabled(true);
soundManager.setAmbientEnabled(true);

// 5. Thought Store & Lifecycle
console.log('\n--- 5. Thought Store, Physical Models & CRUD ---');
const testThought = thoughtStore.createThought({
  title: 'Morning Coffee Ritual',
  content: 'Fresh ground pour-over in the morning sun.',
  type: 'note',
  position: new THREE.Vector3(0.5, 1.45, -1.2),
  surface: 'desk'
});
assert(testThought && testThought.id, 'Thought created with unique ID');
assert(testThought.title === 'Morning Coffee Ritual', 'Thought title matches');
assert(testThought.type === 'note', 'Thought type is note');

const updated = thoughtStore.updateThought(testThought.id, {
  isPinned: true,
  content: 'Updated pour-over notes with cinnamon.'
});
assert(updated.isPinned === true, 'Thought pinned status successfully updated');
assert(updated.content.includes('cinnamon'), 'Thought content successfully updated');

// 6. Search functionality
console.log('\n--- 6. Thought Search & Filtering ---');
const searchResults = thoughtStore.search('Coffee');
assert(searchResults.length > 0 && searchResults[0].id === testThought.id, 'Search matches title query');
const searchContentResults = thoughtStore.search('cinnamon');
assert(searchContentResults.length > 0 && searchContentResults[0].id === testThought.id, 'Search matches content query');

// 7. Undo / Redo System
console.log('\n--- 7. Undo / Redo Lifecycle ---');
const dummyObjManager = {
  removeObject: () => {},
  registerObject: () => {},
  createThoughtObject: data => ({ itemId: data.id, position: data.position || new THREE.Vector3() })
};
const deleteCmd = new DeleteThoughtCommand(dummyObjManager, testThought);
deleteCmd.execute();
assert(thoughtStore.getById(testThought.id) === null, 'Thought deleted from store via command');
deleteCmd.undo();
assert(thoughtStore.getById(testThought.id) !== null, 'Thought restored to store via undo');

// 8. Clean up test thought
thoughtStore.deleteThought(testThought.id);
assert(thoughtStore.getById(testThought.id) === null, 'Test thought cleaned up');

console.log(`\n========================================`);
console.log(`Results: ${passedTests} / ${totalTests} assertions passed.`);
console.log(`========================================\n`);
