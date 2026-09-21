# Motorola Q11 Saver — AGENTS.MD

## Project Overview
**Moto Q11 Saver** (`motoq11_saver`) is an open-source, engineering-grade Flutter application built to rescue, patch, configure, and monitor Motorola Q11 mesh Wi-Fi units (models MH7601, MH7602, MH7603) using local OpenWrt firmware workflows without cloud dependencies.

---

## Technical Stack & Architecture

- **Framework**: Flutter (Dart 3.x) targeting Linux desktop, Android, iOS, macOS, and Web.
- **State Management**: Riverpod 2.x (`AsyncNotifier`, `StateNotifier`, `StateProvider`) enforcing Unidirectional Data Flow (UDF).
- **Design System**: Material 3 with Swiss precision tokens (`ui-ux-pro-max`):
  - Primary: Sky 600 (`#0284C7`), Sky 400 (`#38BDF8`)
  - Background & Surface: Slate 900 (`#0F172A`), Slate 800 (`#1E293B`)
  - Status Accents: Emerald (`#10B981`), Amber (`#F59E0B`), Red (`#EF4444`)
  - Typography: Google Fonts Inter
- **Networking & Scripting**:
  - `dartssh2`: Pure Dart SSH client to execute provisioning scripts on Dropbear daemon.
  - `dart:io`: HTTPS CGI trigger payload delivery with self-signed SSL tolerance (`badCertificateCallback`).
  - Raw socket probing across TCP ports `22, 80, 8080, 7681`.
  - Subnet scanner across `1..254` range with latency measurement.
  - ICMP Ping and Tracepath via cross-platform system CLI execution (`Process.run`).
- **Storage**:
  - `shared_preferences` with JSON schema backup export and import (`exportFullConfigJson` / `importFullConfigJson`).

---

## Directory Structure

```
lib/
├── app.dart                                # MaterialApp, NavigationBar shell, & language toggle
├── main.dart                               # Entry point, SharedPreferences & ProviderScope setup
├── core/
│   ├── constants/app_strings.dart          # EN and ES-MX localization dictionaries
│   ├── errors/failure.dart                 # Network and SSH domain failures
│   ├── providers/app_providers.dart        # Global Riverpod state notifiers
│   ├── storage/                            # On-device JSON storage & backup dialogs
│   └── theme/                              # AppColors and AppTheme tokens
└── features/
    ├── diagnostics/                        # Subnet scanner, Ping, Tracepath, & DHCP poll
    ├── guides/                             # Hardware rescue, pinhole reset, & LED guides
    ├── models/                             # Q11Device, WifiMeshConfig, DhcpClient, etc.
    ├── patcher/                            # Q11PatchEngine, patch controllers, & 5-step wizard
    ├── scanner/                            # QR barcode parser & scanner dialog
    └── topology/                           # Animated mesh topology canvas & node cards
```

---

## Development Guidelines for Agents

1. **Unidirectional Data Flow**: UI widgets must only consume providers; business and networking logic lives exclusively inside controllers (`PatchController`, `DiagnosticsController`) and domain engines (`Q11PatchEngine`, `Q11LocalStorage`).
2. **Design Tokens**: Never hardcode generic hex values or use browser defaults. Reference `AppColors.*` tokens and `AppTheme.darkTheme`.
3. **No Text Emojis as UI Icons**: Always use vector `Icons.*` from Flutter Material Icons.
4. **Self-Signed SSL Compliance**: Motorola routers in stock firmware serve CGI backdoors over HTTPS with self-signed certificates; always configure `HttpClient.badCertificateCallback = (cert, host, port) => true`.
5. **Quality Gate**: Always ensure `flutter analyze` reports `No issues found!` and `flutter test` achieves 100% test pass rate.
