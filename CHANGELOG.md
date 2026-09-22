# CHANGELOG

All notable changes to the Motorola Q11 Saver (`motoq11-saver`) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.2] - 2026-09-21

### Added
- **Manual Device Credentials & Identification Entry**:
  - Full manual input fields on Setup Wizard cards for Friendly Name, IP address, default SSID, Wi-Fi password, MAC address, and Serial Number.
  - Form fields bind dynamic `ValueKey` instances ensuring instant updates without getting overwritten by background scans or provider refreshes.
- **Direct Friendly Name Editing on Mesh Topology Cards**:
  - Added dedicated edit icon buttons (`Icons.edit_note`) on both Master Node and Satellite Node cards in Mesh Topology.
  - Interactive rename dialog allows assigning or clearing friendly aliases (e.g. *"Living Room Gateway"*, *"Office Satellite"*).
  - Custom names synchronize across storage, `masterNodeProvider`, `satellitesProvider`, and subnet scan results.
- **Enhanced QR Code Label Scanning**:
  - Scanned QR label data (MAC, serial number, default SSID, and password) now maps to node models and preserves or auto-suggests the node's friendly name.
- **Subnet Scanner Relocation to Bottom of Mesh Topology**:
  - Relocated the Diagnostics & Subnet Scanner card to the bottom of the Mesh Topology screen, placing primary focus on the Mesh canvas, Master node, and Satellite nodes.
- **Prominent MAC Address Display for Discovered Devices**:
  - Subnet discovery results and topology views now showcase a dedicated, stylized badge with the resolved MAC address alongside port services.
  - Multi-source ARP resolution combining `/proc/net/arp`, `ip neigh show`, and `arp -n` to reliably identify hardware MACs across reachable and stale network cache entries.
- **Manual and QR Wi-Fi SSID & Password Editing on Topology Cards**:
  - Added direct credential edit buttons on both Master Node and Satellite Node cards in Mesh Topology.
  - Interactive credential edit dialogs allow changing default SSID and Wi-Fi password manually or scanning the device's QR code on the fly.
- **Automatic Satellite Slot Allocation for Selected Kit Size**:
  - Selecting kit size (1, 2, or 3 nodes) automatically generates satellite slots in state and local storage, enabling immediate configuration and manual/QR credential entry.

---

## [0.2.1] - 2026-09-21

### Fixed
- **Web Admin URL corrected to `/cgi-bin/admin.sh`**:
  - Master and Satellite node cards were pointing the "Open Admin" button to `http://<ip>:8080` which is the stock Motorola motosync download page.
  - Now correctly opens `http://<ip>/cgi-bin/admin.sh` — the actual OpenWrt router admin panel deployed by the patch script.
- **Device Stats now work without SSH credentials**:
  - `fetchDeviceStatistics` previously required a valid Dropbear SSH session (which fails when no password is known).
  - Replaced primary strategy with HTTP scraping of `/cgi-bin/admin.sh` (no auth required), parsing uptime, CPU load average, RAM usage, and configured SSIDs directly from the CGI page HTML.
  - SSH remains as a secondary fallback for when HTTP is unavailable.
- **DHCP Leases now loaded via HTTP fallback**:
  - `fetchDhcpClients` also scrapes the admin.sh DHCP Leases section as primary source (no SSH), SSH remains as fallback.
- **Backup/Restore SSH password prompt**:
  - When `wifiPassword` is empty (device adopted from network scan without explicit setup), backup and restore dialogs now display a password entry dialog before attempting SSH.
  - Users can leave it empty to try passwordless SSH, or enter their router's root password.
  - All three bug areas: Web Admin, Stats, Backup — now work correctly against unpatched and patched Q11 routers.

---

## [0.2.0] - 2026-09-21

### Added
- **Direct Connected Mesh Node Identification**:
  - Automatically identifies which specific Motorola Q11 unit (Master or Satellite) the host device is directly associated with via Linux `iw dev <iface> link` BSSID matching and default gateway route fallback.
  - Highlights the directly connected node with a golden amber badge `Connected (You)` on node cards and a golden identification ring on the interactive topology canvas.
- **Physical Device LED Flash Identification (15 Seconds)**:
  - Added 15-second physical LED blink toggle via SSH to locate specific hardware nodes in the premises (`/sys/class/leds/*`).
  - Integrated animated cyan pulse wave rings on the canvas and countdown indicators on the UI cards while flashing.
- **Device Telemetry & Real-Time Statistics**:
  - Live SSH telemetry querying system uptime, CPU load average (`/proc/loadavg`), RAM usage with dynamic visual progress indicator (`/proc/meminfo`), hardware board name, and kernel version.
- **Configured Broadcast SSID Inspection**:
  - Added live query of all configured and transmitting wireless network SSIDs across radios using `uci show wireless` and `iwinfo`.
- **Integrated Network Speedtest**:
  - Implemented multi-stage network speed test measuring ICMP latency, jitter, download throughput (Mbps), and upload throughput (Mbps) against CDN endpoints with real-time status messaging.
- **Web Admin & Web Terminal Shortcuts**:
  - Added direct external launch buttons on Master and Satellite cards for Web Admin (`:8080`) and Web Terminal (`:7681`).
- **Device Configuration Backup & Remote Restore**:
  - Added remote backup of router `/etc/config` over SSH into portable Base64 `tar.gz` archives.
  - Interactive restore dialog to paste Base64 tarballs and push them to the router with automated network service reload.

---

## [0.1.0] - 2026-09-21

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
  - **Smart Motorola Device Detection & Discrimination**:
    - Automatic physical LAN subnet detection (`LocalNetworkDetector`) filtering out virtual interfaces (Docker bridges, VPNs, WireGuard, Tailscale).
    - Host ARP table integration (`ArpHelper`) matching Motorola OUI prefixes (`c8:c7:50`, etc.).
    - Characteristic multi-port probing (`22 Dropbear SSH`, `53 DNS`, `80 Motosync Web UI`, `443 HTTPS`, `8080 HTTP Alt`, `7681 ttyd Web Terminal`) to reliably discriminate Motorola Q11 Master Gateway from Mesh Satellites and other non-Motorola LAN hosts.
    - Default gateway and routing correlation to automatically assign Master Gateway vs. numbered Mesh Satellite roles.
    - Custom friendly device naming & alias persistence (`Q11LocalStorage`) remembering user-assigned labels (e.g., "Living Room Gateway", "Office Satellite") indexed by IP and MAC address.
  - High-performance subnet port scanner (`1..254`) with device fingerprinting, role tagging, and RTT latency measurements.
  - ICMP Ping and Tracepath execution with real-time hop discovery and dark console visualization.
  - DHCP lease client polling via SSH `/tmp/dhcp.leases` inspection.
- **UI/UX & Design System**:
  - Tailored Material 3 theme with Swiss precision tokens: Slate 900 (`#0F172A`), Slate 800 (`#1E293B`), Sky 600 (`#0284C7`), Sky 400 (`#38BDF8`), Emerald 500 (`#10B981`), Amber 500 (`#F59E0B`), Red 500 (`#EF4444`).
  - Google Fonts Inter typography hierarchy.
  - Interactive Animated Mesh Canvas (`TopologyCanvasPainter`) featuring pulse waves, cubic Bezier backhaul lines, and moving packet flow effects.
  - Clean Material 3 NavigationBar with 3 primary screens: Setup Wizard, Mesh Topology, and Hardware Guides.
  - Interactive device renaming dialog in network diagnostics with quick clear and instant state updates.
- **Storage & Backup**:
  - Local persistence via `SharedPreferences` with zero cloud lock-in.
  - Full JSON configuration export and import dialogs with clipboard and system share sheet integrations, including remembered custom device names.
- **Mesh Topology Flow & Device Discovery**:
  - Automatic unconfigured network detection prompting user to auto-detect and scan their physical LAN.
  - Interactive device adoption allowing single-click assignment of discovered Motorola Q11 devices as Master Gateway or Satellite Node.
  - Full network re-scan capability at any time from both the app bar and overview banner with live progress indicators.
- **Internationalization (i18n)**:
  - English and Spanish (ES-MX) localized dictionaries with instant runtime language switching.
- **Hardware Guides & Diagnostics**:
  - Dedicated hardware documentation screen covering 15-second physical reset pinhole procedure, rear ports guide (WAN, LAN, USB-C), front LED status indicator matrix, and CGI exploit vector architecture.
- **Test Suite**:
  - 18 automated unit and widget tests covering QR parser formats, JSON configuration backup, custom device naming persistence, network output parsers, and widget smoke tests (100% pass rate).

