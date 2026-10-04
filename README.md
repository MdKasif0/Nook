# Nook 🛋️

A cozy, native macOS application where your thoughts, notes, ideas, and memories live as tactile physical objects inside a realistic miniature 3D room.

[![Platform](https://img.shields.io/badge/Platform-macOS%2015+-F4F0EA?style=flat-square&logo=apple&logoColor=3A3835)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-F4F0EA?style=flat-square&logo=swift&logoColor=F05138)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20SceneKit-F4F0EA?style=flat-square)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/Storage-SwiftData-F4F0EA?style=flat-square)](https://developer.apple.com/documentation/swiftdata)

---

## Philosophy

Nook is not a conventional productivity app. It rejects infinite kanban boards, sprawling databases, and harsh neon dashboards. Instead, it feels like opening a tiny, peaceful miniature dollhouse sitting quietly on your Mac:

- **Tactile Objects**: Thoughts, ideas, reminders, quotes, and links exist as small 3D objects resting naturally on your desk.
- **Warm Aesthetics**: Natural materials, warm daylight, soft shadows, walnut woods, matte ceramics, and calm sage accents.
- **Local-First & Private**: Powered purely by SwiftData with zero analytics, zero external servers, and zero cloud lock-in.
- **Zero Web Bloat**: Built 100% natively with Swift, SwiftUI, and SceneKit. No Electron, no web wrappers.

---

## Features

### 🪴 The 3D Miniature Room Diorama
- **Warm Interior Architecture**: Cream ivory walls with baseboard trim, warm honey oak hardwood floors, and open dollhouse three-quarter cutaway.
- **The Focal Wooden Desk**: Rich beveled tabletop with slender tapered legs, brushed brass caps, side drawer cabinet, sage leather blotter, and ceramic pencil cup.
- **Dynamic Window & Outdoors**: Natural morning, afternoon, golden hour, and cozy night lighting streaming through a multi-pane window with rolling hills outside.
- **Interactive Desk Lamp**: Articulated brass/cream desk lamp that casts a soft, warm pool of light over your workspace.
- **Bookshelf**: Three-tier bookshelf populated with colorful miniature books in muted sage, terracotta, and linen.
- **Cookie the Companion Cat**: A curled ginger cat resting on a braided circular woven rug with gentle breathing animations and interactive petting feedback.

### 💡 Thoughts as Physical Objects
Every captured item is rendered as a distinct physical 3D object:
- **Thoughts**: Buttery pastel sticky notes with curled corners.
- **Ideas**: Miniature warm brass Edison bulbs with luminous filaments.
- **Notes**: Folded textured linen parchment with pencils.
- **Reminders**: Vintage brass desk clocks on walnut stands.
- **Quotes**: Miniature open books with bookmark ribbons.
- **Links**: Sealed envelopes with terracotta wax stamps.
- **Photos**: Tiny framed photographs on tabletop easels.

### 🪄 Native macOS Integration
- **Quick Capture Window**: Dedicated floating mini-window (`⌘N`) for rapid keyboard-first thought entry.
- **System Menu Bar Extra**: One-click quick glance and capture right from the macOS status bar.
- **Multi-Scene macOS Architecture**: Native `NavigationSplitView` with sidebar filtering and SwiftData persistence.

---

## System Requirements

- **macOS**: 15.0 (Sequoia) or later
- **Xcode**: 16.0 or later
- **Architecture**: Apple Silicon (M1/M2/M3/M4) or Intel Mac

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/MdKasif0/Nook.git
   ```
2. Open `Nook.xcodeproj` in Xcode 16+:
   ```bash
   open Nook.xcodeproj
   ```
3. Select the `Nook` target and press **⌘R** to run.
