# CHANGELOG

All notable changes to the Motorola Q11 Saver (`motoq11-saver`) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-21

### Added
- **Initial Migration from Android Native**:
  - Successfully migrated legacy Kotlin / Jetpack Compose codebase (`/home/carlos/Documents/apk-q11`) into cross-platform Flutter application.
- **State Management & Architecture**:
  - Implemented Riverpod 2.x with strict Unidirectional Data Flow (UDF).
  - Feature-First Clean Architecture structure (`core/`, `features/models/`, `features/patcher/`, `features/topology/`, `features/diagnostics/`, `features/guides/`, `features/scanner/`).
- **Low-Level Network Engine (`Q11PatchEngine`)**:
  - CGI trigger exploitation payload dispatch over HTTPS (`badCertificateCallback` bypass for self-signed router certs).
  - Pure-Dart SSH client (`dartssh2`) for provisioning script deployment and service configuration.
  - Multi-port socket verification on ports `22` (SSH), `80/8080` (LuCI HTTP), and `7681` (ttyd Web Terminal).
  - High-performance subnet port scanner (`1..254`) with device fingerprinting and RTT latency measurements.
  - ICMP Ping and Tracepath execution with real-time hop discovery and dark console visualization.
  - DHCP lease client polling via SSH `/tmp/dhcp.leases` inspection.
- **UI/UX & Design System**:
  - Tailored Material 3 theme with Swiss precision tokens: Slate 900 (`#0F172A`), Slate 800 (`#1E293B`), Sky 600 (`#0284C7`), Sky 400 (`#38BDF8`), Emerald 500 (`#10B981`), Amber 500 (`#F59E0B`), Red 500 (`#EF4444`).
  - Google Fonts Inter typography hierarchy.
  - Interactive Animated Mesh Canvas (`TopologyCanvasPainter`) featuring pulse waves, cubic Bezier backhaul lines, and moving packet flow effects.
  - Clean Material 3 NavigationBar with 3 primary screens: Setup Wizard, Mesh Topology, and Hardware Guides.
- **Storage & Backup**:
  - Local persistence via `SharedPreferences` with zero cloud lock-in.
  - Full JSON configuration export and import dialogs with clipboard and system share sheet integrations.
- **Internationalization (i18n)**:
  - English and Spanish (ES-MX) localized dictionaries with instant runtime language switching.
- **Hardware Guides & Diagnostics**:
  - Dedicated hardware documentation screen covering 15-second physical reset pinhole procedure, rear ports guide (WAN, LAN, USB-C), front LED status indicator matrix, and CGI exploit vector architecture.
- **Test Suite**:
  - 13 automated unit and widget tests covering QR parser formats, JSON configuration backup, network output parsers, and widget smoke tests (100% pass rate).
