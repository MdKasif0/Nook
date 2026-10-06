# Nook 🛋️

A calm, native macOS application where your thoughts, notes, ideas, and memories live as tactile physical objects inside a realistic miniature 3D diorama room on your Mac.

[![Platform](https://img.shields.io/badge/Platform-macOS%2015+-F4F0EA?style=flat-square&logo=apple&logoColor=3A3835)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-F4F0EA?style=flat-square&logo=swift&logoColor=F05138)](https://swift.org)
[![Three.js](https://img.shields.io/badge/Three.js-0.186-F4F0EA?style=flat-square&logo=threedotjs&logoColor=000000)](https://threejs.org/)
[![Storage](https://img.shields.io/badge/Storage-Local--First-F4F0EA?style=flat-square)](https://developer.apple.com/documentation/swiftdata)
[![License](https://img.shields.io/badge/License-MIT-F4F0EA?style=flat-square)](LICENSE)

---

## What Nook Is

Nook is not a conventional productivity app. It rejects infinite databases, nested folder hierarchies, and noisy SaaS dashboards. Instead, it feels like opening a quiet, tactile miniature room on your desk:

* **Thoughts Become Physical Objects**: A thought can manifest as a smooth grounding river stone, a folded cream paper note, a buttery sticky note, a linen index card, a vintage Polaroid print, or a ribbon bookmark.
* **Warm, Miniature Diorama Aesthetic**: Warm neutrals, cream plaster, honey wood, muted sage, soft terracotta, and warm gray. Zero purple, blue, cyan, neon, or cold futuristic gradients.
* **Cookie the Companion Cat**: An articulated 3D calico companion cat who lives in your room, curling up in sunspots on the bed, perking up when you leave thoughts, and purring softly when pet.
* **100% Local-First & Offline**: Zero network requests, zero telemetry, zero CDNs, and zero cloud dependencies. Works completely offline.
* **macOS Citizen**: Packaged as a native Mac app through `SwiftUI -> WKWebView -> Nook Three.js World` with bidirectional JavaScript bridge (`window.nookBridge`).

---

## Developer Guide: 3D Miniature Room

### 1. Running the Three.js Room Locally

The web diorama is built with modern ES modules, Vite, and Three.js:

```bash
# Install dependencies
npm install

# Start local development server with Hot Module Reloading (HMR)
npm run dev

# Run automated validation test suite
npm test

# Build production bundle for macOS WKWebView bundling (outputs to dist-web/ & dist/)
npm run build
```

The application runs at `http://localhost:3000` with high-DPI retina clamping (`devicePixelRatio <= 2`), warm PCF soft shadows, and ACES Filmic tone mapping.

---

### 2. How to Add GLB / GLTF 3D Assets

All external models are bundled locally in `models/` or generated procedurally to guarantee offline operation:

```javascript
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

export class AssetLoader {
  static loadGLB(path, onLoad, onError) {
    const loader = new GLTFLoader();
    loader.load(
      path,
      gltf => {
        gltf.scene.traverse(child => {
          if (child.isMesh) {
            child.castShadow = true;
            child.receiveShadow = true;
          }
        });
        onLoad(gltf.scene);
      },
      undefined,
      error => {
        // Robust Fallback: Never crash the entire room on a failed asset
        console.warn(`[Nook] Failed to load ${path}, deploying procedural fallback:`, error);
        if (onError) onError(error);
      }
    );
  }
}
```

---

### 3. How to Add Interactive Objects

Interactive physical props subclass `InteractiveObject` in `src/objects/InteractiveObject.js`:

```javascript
import { InteractiveObject } from './InteractiveObject.js';
import * as THREE from 'three';

export class CustomDeskLamp extends InteractiveObject {
  constructor() {
    super({
      id: 'prop_desk_lamp',
      name: 'Anglepoise Lamp',
      category: 'lighting',
      objectType: 'lamp',
      isMovable: true,
      isDraggable: true,
      isRotatable: true,
      collisionRadius: 0.24,
      accessibilityLabel: 'Warm brass desk lamp'
    });

    // Build physical meshes and attach to visualRoot
    const mesh = new THREE.Mesh(geometry, material);
    mesh.castShadow = true;
    this.visualRoot.add(mesh);
  }

  // Override triggerSpecialAction for contextual interaction
  triggerSpecialAction() {
    this.toggleGlow();
  }
}
```

Interactive objects automatically participate in raycast hovering, elevation on drag, surface snapping, shadow casting, and undo/redo stacks.

---

### 4. How to Add Cookie Cat Animations

Cookie's articulated skeleton is driven by a single central `THREE.AnimationMixer` inside `src/cookie/CookieAnimationController.js`:

```javascript
// Register a new animation clip
registerCustomClip(name, duration, keyframes) {
  const tracks = [
    new THREE.VectorKeyframeTrack('.bones[Head].rotation', [0, duration * 0.5, duration], [...]),
    new THREE.VectorKeyframeTrack('.bones[Tail].rotation', [0, duration], [...])
  ];
  const clip = new THREE.AnimationClip(name, duration, tracks);
  this.clips.set(name, clip);
  this.actions.set(name, this.mixer.clipAction(clip));
}

// Play clip with cross-fading
playAnimation(name, crossFadeDuration = 0.3) {
  const currentAction = this.currentAction;
  const nextAction = this.actions.get(name);
  if (nextAction && currentAction !== nextAction) {
    nextAction.reset().fadeIn(crossFadeDuration).play();
    currentAction.fadeOut(crossFadeDuration);
    this.currentAction = nextAction;
  }
}
```

Cookie supports 17 expressive procedural animations including `SLEEP_LOAF`, `WALK`, `JUMP_UP`, `POUNCE`, `STRETCH`, `HEAD_TILT`, and `PURR`.

---

### 5. How to Create New Thought Object Types

Nook maps 7 thought types to distinct physical 3D geometry via `src/objects/ThoughtEntityBuilder.js`:

| Type | Physical Representation | Default Surface |
| :--- | :--- | :--- |
| **Thought** | Smooth rounded river stone / pebble | Desk |
| **Idea** | Folded cream origami paper object | Desk / Shelf |
| **Reminder** | Tactile butter-yellow sticky note | Desk |
| **Quote** | Linen card with brass stand | Shelf / Wall |
| **Photo** | Miniature Polaroid photo print | Shelf / Wall |
| **Link** | Ribbon bookmark | Bookshelf |
| **Note** | Hardcover notebook with ribbon | Desk |

To add a new thought representation:
1. Add type definition to `PALETTE` and `ThoughtEntityBuilder.createGeometry(type)`.
2. Add preferred surface mapping in `PlacementManager.preferredSurfaces`.
3. Register the type icon and display name in `ObjectInspector.js` and `ThoughtCreatorModal.js`.

---

### 6. Swift / WKWebView Bidirectional Bridge

Nook prepares a clean JavaScript bridge interface for native macOS embedding via `window.nookBridge`:

```swift
// Swift side: Calling Nook JavaScript API
webView.evaluateJavaScript("window.nookBridge.createThought({ title: 'Idea', type: 'idea' })")
webView.evaluateJavaScript("window.nookBridge.resetCamera()")
webView.evaluateJavaScript("window.nookBridge.setReducedMotion(true)")
```

```javascript
// JavaScript side: Sending events to macOS Swift host
if (window.webkit?.messageHandlers?.nookHost) {
  window.webkit.messageHandlers.nookHost.postMessage({
    type: 'thoughtCreated',
    payload: { id: 'thought_123', title: 'Idea', type: 'idea' }
  });
}
```

#### Supported `window.nookBridge` Methods:
* `createThought(data)`: Spawns new 3D thought object with placement finding and Cookie notification.
* `updateThought(id, updates)`: Updates metadata, pin state, or geometric type.
* `deleteThought(id)`: Removes thought with undo support.
* `getThoughts()`: Returns all stored thoughts.
* `loadRoomState(state)`: Restores room furniture, lighting, and camera transforms.
* `saveRoomState()`: Persists current room transforms to `localStorage` and returns state.
* `resetCamera()`: Restores elevated isometric reference composition.
* `openQuickCapture()`: Opens the thought capture modal.
* `openSettings()`: Opens the settings menu.
* `setSoundEnabled(bool)` / `setAmbientSoundEnabled(bool)` / `setSoundEffectsEnabled(bool)`: Independent audio toggles.
* `setReducedMotion(bool)`: Toggles accessibility motion damping.

---

### 7. Room State & Thought Persistence

Persistence is 100% local-first:
* **Thoughts**: Managed by `ThoughtStore.js`, stored in browser `localStorage` (`nook_thoughts_v2`) and synchronized bidirectionally with macOS SwiftData SQLite.
* **Room Layout & Furniture**: Managed by `RoomState.js`, storing object positions, rotations, lamp state, time of day, and Cookie's position.
* **Audio Settings**: Managed by `SoundManager.js`, storing master mute, SFX enabled, and ambient sound enabled in `nook_audio_settings`.
* **Zero Telemetry / Offline**: No remote servers, analytics, or external CDNs are required.

---

## Architectural Overview

```
Nook
├── Web 3D Diorama (Three.js)
│   ├── src/main.js                  # Central render loop, subsystems & window.nookBridge
│   ├── src/scene/
│   │   ├── RoomScene.js             # Room diorama box, window, walls, plaster materials
│   │   ├── Camera.js                # NookMainCamera isometric rig & resetCamera()
│   │   └── Lighting.js              # Photometric sunlight, ambient fill, and desk lamp
│   ├── src/objects/
│   │   ├── ObjectManager.js         # Interactive object registry, selection & raycast
│   │   ├── PlacementManager.js      # Surface-aware thought placement finder
│   │   └── ThoughtEntityBuilder.js  # 3D procedural meshes (pebbles, notes, polaroids)
│   ├── src/cookie/
│   │   ├── CookieController.js      # Articulated calico companion cat controller
│   │   ├── CookieAnimationController.js # THREE.AnimationMixer with 17 feline clips
│   │   └── CookieNavigationController.js # Surface pathfinding & waypoint locomotion
│   ├── src/audio/SoundManager.js    # Procedural Web Audio synthesizer (lamp clicks, purr, vinyl)
│   ├── src/persistence/
│   │   ├── ThoughtStore.js          # Local thought persistence & SwiftData sync
│   │   └── RoomState.js             # 3D layout, undo/redo history & transforms
│   └── src/style.css                # Apple-inspired warm diorama styling & reduced motion
├── macOS Native Host (SwiftUI / Swift 6)
│   ├── NookApp.swift                # App lifecycle & menu bar extras
│   ├── ContentView.swift            # WKWebView host container & bridge coordinator
│   └── Persistence/                 # SwiftData container & schema definitions
└── scripts/
    ├── test_validation.js           # Automated 36-point validation suite
    └── package_dmg.sh               # macOS DMG release builder
```

---

## How to Build & Run

### 1. Development Build via Xcode

1. Open `Nook.xcodeproj` in Xcode 16 or later:
   ```bash
   open Nook.xcodeproj
   ```
2. Select the `Nook` scheme and target **My Mac**.
3. Press **⌘R** to build and run.

### 2. Command-Line Development Build

To build the debug application bundle from Terminal:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Nook.xcodeproj \
  -scheme Nook \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  build
```

### 3. Running Data Reliability Tests

Nook includes a built-in automated test suite that tests the complete lifecycle: item creation, coordinates, editing, deletion, archiving, SwiftData restarts, local search, and malformed input sanitization:
```bash
./DerivedData/Build/Products/Debug/Nook.app/Contents/MacOS/Nook --run-tests
```

---

## Creating a Release Build & Packaging the DMG

The project provides an automated release script: [`scripts/package_dmg.sh`](scripts/package_dmg.sh).

### Generating the Distribution DMG:
```bash
./scripts/package_dmg.sh
```

This script performs the following:
1. Compiles `Nook.app` under the optimized `Release` configuration.
2. Applies code signing (ad-hoc by default).
3. Prepares a clean staging presentation containing `Nook.app`, a symlink to `/Applications`, and volume icons.
4. Generates a compressed read-only disk image: `dist/Nook-1.0.0-Universal.dmg`.
5. Automatically syncs the generated DMG to the marketing website downloads directory (`web/downloads/`).

---

## Distribution & Code Signing Details

Nook is distributed directly from its website as a standalone `.dmg` file.

### 1. Unsigned / Ad-hoc Distribution (Current Status)

If distributed without an Apple Developer ID membership:
* The build script signs the binary with an ad-hoc signature (`codesign --force --deep -s -`).
* When users download and open Nook for the first time, macOS Gatekeeper will recognize that the app was downloaded directly from the internet and may display:
  > *"Apple could not verify the developer of Nook"* or *"Nook was downloaded from the internet"*.

#### Recommended Safe User Opening Instructions:
1. In Finder, locate **Nook.app** in the Applications folder.
2. **Control-click** (or right-click) the Nook icon and select **Open** from the menu.
3. Click **Open** in the confirmation dialog. (This only needs to be performed once.)
4. Alternatively: Open **System Settings**  > **Privacy & Security**, scroll to *Security*, and click **Open Anyway**.

> **Note:** Never advise users to globally disable Gatekeeper (`spctl --master-disable`). The Control-click method provides safe, per-app authorization without weakening macOS system security.

### 2. Future Developer ID Signing Process

Once an Apple Developer Program membership is active:
1. Install your **Developer ID Application** certificate into your macOS Keychain.
2. Identify your certificate:
   ```bash
   security find-identity -v -p codesigning
   ```
3. Run the packaging script with your Developer ID identity:
   ```bash
   ./scripts/package_dmg.sh --sign "Developer ID Application: Your Name (TEAM_ID)"
   ```
   The script automatically signs all binaries with the **Hardened Runtime** (`--options runtime`), entitlements, and secure Apple timestamps.

### 3. Future Apple Notarization Process

To notarize the packaged DMG so that Gatekeeper opens it without warnings:
1. Create an App Store Connect API key or app-specific password.
2. Store your credentials in the Apple notary keychain:
   ```bash
   xcrun notarytool store-credentials "AC_NOTARY" \
     --apple-id "developer@example.com" \
     --team-id "TEAM_ID" \
     --password "your-app-specific-password"
   ```
3. Submit and staple the disk image:
   ```bash
   xcrun notarytool submit dist/Nook-1.0.0-Universal.dmg --keychain-profile "AC_NOTARY" --wait
   xcrun stapler staple dist/Nook-1.0.0-Universal.dmg
   ```

---

## Hosting the Marketing Website on Netlify

The Nook website is built with pure, lightweight Vanilla HTML5, CSS3, and JavaScript, designed to be deployed directly to Netlify without needing Node.js build pipelines or external dependencies.

The repository includes a ready-to-use [`netlify.toml`](netlify.toml) configuration that configures:
* **Publish Directory**: `web`
* **Clean Redirects**: `/download` → `/downloads/` and `/dmg` → direct DMG binary
* **Edge Caching & Security**: High-performance HTTP headers and automatic MIME typing for `.dmg` disk image downloads

### Deployment Options:

#### Option 1: Git Integration (Recommended)
1. Push your repository to GitHub.
2. In the [Netlify Dashboard](https://app.netlify.com/), click **Add new site** > **Import an existing project**.
3. Select your repository (`MdKasif0/Nook`). Netlify will automatically detect `netlify.toml`.
4. Click **Deploy Nook**. Every `git push` to `main` will instantly trigger a fresh deployment to the global edge network.

#### Option 2: Netlify CLI
Deploy directly from your terminal:
```bash
# Preview deployment
npx netlify-cli deploy --dir=web

# Production deployment
npx netlify-cli deploy --dir=web --prod
```

#### Option 3: Manual Drag & Drop
Drag and drop the [`web/`](web/) folder into [app.netlify.com/drop](https://app.netlify.com/drop) for instant deployment.

---

## Privacy Architecture

Privacy is foundational to Nook:
* **Zero Telemetry**: No analytics libraries, crash trackers, or behavioral telemetry.
* **No Cloud Infrastructure**: No user accounts, logins, or remote servers.
* **Zero-Cloud Local Storage**: All your thoughts, notes, and room coordinates remain exclusively on your Mac in local SwiftData SQLite storage.
* **Strictly Scoped Network Access**: Outbound HTTPS network access (`com.apple.security.network.client`) is strictly restricted to fetching the signed AppCast feed (`appcast.xml`) and downloading verified DMG updates. Zero user data, thoughts, or metadata are ever transmitted.

---

## Sparkle 2 Auto-Update System

Nook features a 100% Sparkle 2 compliant update distribution and verification architecture:

* **Cryptographic Verification**: Every release archive is signed with **Ed25519 (RFC 8032)** digital signatures generated via Apple's native `CryptoKit`.
* **Standard AppCast Feed**: Releases are cataloged in [`web/appcast.xml`](web/appcast.xml) using RSS 2.0 with the `sparkle:` namespace, providing version metadata, system version compatibility (`macOS 15.0+`), and release highlights.
* **Native In-App Updater**: Built into Nook using pure Swift and SwiftUI (`NookUpdateManager`), allowing users to check for updates from the application menu (<kbd>Nook > Check for Updates…</kbd>) or Settings, with live download progress and automatic DMG disk image mounting.
* **Multi-Release History**: The update generator preserves historical release notes while prioritizing the latest compatible build.

### Release & Update Workflow

To package and deploy a new release:

```bash
# 1. Package the Release DMG (builds, signs, stages, and creates dist/Nook-X.Y.Z-Universal.dmg)
./scripts/package_dmg.sh

# 2. Or generate/update the Sparkle AppCast feed for an existing DMG:
VERSION="1.0.1" BUILD_NUMBER="2" ./scripts/generate_appcast.sh dist/Nook-1.0.1-Universal.dmg

# 3. Validate the feed and signature:
./scripts/validate_appcast.sh web/appcast.xml dist/Nook-1.0.1-Universal.dmg
```

---

## Future Local AI Architecture

When intelligent capabilities (such as automatic object suggestions, semantic grouping, or thoughtful summaries) are introduced in future releases:
* **On-Device Exclusively**: AI will execute strictly on-device utilizing Apple Foundation Models, CoreML, or local MLX frameworks on Apple Silicon Neural Engines.
* **No External LLM APIs**: No user thoughts will ever be transmitted to external cloud APIs (OpenAI, Anthropic, or remote inference servers).
* **Zero Account Requirement**: AI features will run without user accounts or subscription tokens.
* **Opt-In Controls**: Users will retain full toggle controls over any local model indexing.

---

## License & Credits

* **Author**: Nook Team
* **Platform**: macOS 15+ Native
* **Design Philosophy**: Warm natural materials, Apple San Francisco typography, local-first architecture.
