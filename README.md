# Nook 🛋️

A calm, native macOS application where your thoughts, notes, ideas, and memories live as tactile physical objects inside a realistic miniature 3D diorama room on your Mac.

[![Platform](https://img.shields.io/badge/Platform-macOS%2015+-F4F0EA?style=flat-square&logo=apple&logoColor=3A3835)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-F4F0EA?style=flat-square&logo=swift&logoColor=F05138)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20SceneKit-F4F0EA?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/Storage-SwiftData-F4F0EA?style=flat-square)](https://developer.apple.com/documentation/swiftdata)
[![License](https://img.shields.io/badge/License-MIT-F4F0EA?style=flat-square)](LICENSE)

---

## What Nook Is

Nook is not a conventional productivity app. It rejects infinite databases, nested folder hierarchies, and noisy SaaS dashboards. Instead, it feels like opening a quiet, tactile miniature room on your desk:

* **Thoughts Become Physical Objects**: A thought can manifest as a smooth grounding river stone, a folded cream paper note, a buttery sticky note, a linen index card, a vintage Polaroid print, or a ribbon bookmark.
* **Warm, Apple-Inspired Aesthetic**: Natural materials, oak wood, linen textiles, matte ceramics, muted sage, and warm terracotta. Zero blue, zero purple, and zero artificial neon gradients.
* **Cookie the Cat Companion**: A tiny companion cat who lives in your room, taking peaceful naps on the linen bed, perking up when you capture an idea, and purring softly when pet.
* **100% Local-First & Private**: Powered purely by native SwiftData (SQLite) on your Mac. Zero accounts, zero cloud databases, and zero network calls.
* **True macOS Citizen**: Native keyboard shortcuts (<kbd>⌘⇧Space</kbd> for Quick Thought, <kbd>⌘K</kbd> for instant in-memory search), menu bar companion utility, and SceneKit Metal rendering throttled to preserve battery life.

---

## System Requirements

* **Operating System**: macOS 15.0 Sequoia or later
* **Development Toolchain**: Xcode 16.0+ (Swift 6.0)
* **Hardware Architecture**: Universal binary supporting Apple Silicon (M1/M2/M3/M4) and Intel Macs

---

## Architectural Overview

```
Nook
├── App Entry & Windowing
│   ├── NookApp.swift                # App lifecycle, multi-window scenes, menu bar extra
│   ├── ContentView.swift            # Primary split layout & room host
│   └── Info.plist                   # App metadata, bundle display name, categories
├── Room & 3D SceneKit Engine
│   ├── RoomSceneView.swift          # NSViewRepresentable with 60 FPS cap & occlusion throttling
│   ├── RoomSceneController.swift    # Scene graph state, camera orbit, lighting modes
│   ├── RoomDioramaBuilder.swift     # Procedural physical geometry & PBR materials
│   └── RoomItemNode.swift           # Physical representations of thoughts (pebbles, notes, etc.)
├── Companion (Cookie)
│   ├── CookieNode.swift             # Procedural 3D cat character (fur, paws, tail, ears)
│   └── CookieBehaviorController.swift # State machine: sleeping, curious, happy, resting
├── Data & Persistence (Local-First)
│   ├── PersistenceController.swift  # SwiftData ModelContainer initialization & error handling
│   ├── Models/                      # NookItem, RoomState, NookObjectType models
│   └── NookDataReliabilityTests.swift # 10-point test suite validating persistence & recovery
├── Quick Capture & Search
│   ├── QuickCaptureView.swift       # Floating paper window (⌘⇧Space)
│   └── Search/                      # Inverted index, tokenization, spotlight command palette
└── Distribution & Marketing
    ├── scripts/package_dmg.sh       # Automated, clean DMG packaging script
    └── web/                         # Official marketing & download website
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

## Privacy Architecture

Privacy is foundational to Nook:
* **Zero Telemetry**: No analytics libraries, crash trackers, or behavioral telemetry.
* **No Cloud Infrastructure**: No user accounts, logins, or remote servers.
* **Network Sandbox Restrictions**: The app entitlements ([`Nook.entitlements`](Nook/Nook.entitlements)) omit all network client and server privileges (`com.apple.security.network.client` is disabled). Even if third-party code attempted a network connection, the macOS kernel would physically reject the socket.
* **On-Disk SQLite Storage**: All content remains inside your user Application Support sandbox.

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
