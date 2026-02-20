# SmoothScroll

A macOS menu bar app that adds smooth, animated scrolling to mice with mechanical scroll wheels.

## The Problem

Mechanical mouse wheels on macOS produce jarring, discrete scroll jumps. Unlike trackpads, they don't benefit from macOS's built-in momentum scrolling — each notch snaps the page instantly.

## How It Works

SmoothScroll intercepts raw scroll wheel events at the HID level (before the system processes them), suppresses the original event, and replaces it with a smooth animation driven by a `CVDisplayLink`. The result feels similar to trackpad scrolling.

- **Smooth interpolation** — scrolls ease toward the target position each frame
- **Momentum** — scroll continues briefly after you stop, then decays naturally
- **Horizontal scroll** — Shift+Scroll is correctly intercepted and animated as horizontal

## Features

- Scroll speed control
- Smoothness control (responsive ↔ smooth)
- Momentum / inertia toggle
- Menu bar icon for quick access
- Trackpad events are passed through unchanged

## Requirements

- macOS 13+
- Accessibility permission (required to intercept scroll events)

## Building

Open `SmoothScroll/SmoothScroll.xcodeproj` in Xcode and build, or:

```bash
cd SmoothScroll
xcodebuild -project SmoothScroll.xcodeproj -scheme SmoothScroll -configuration Release build
```
