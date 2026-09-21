# Motorola Q11 Saver (`motoq11-saver`)

Cross-platform network engineering utility and OpenWrt provisioning tool for **Motorola Q11 Wi-Fi 6 Mesh Routers**.

Migrated and re-architected into clean Flutter & Dart 3 with Riverpod 2.x UDF, low-level CGI exploit dispatch, Dropbear SSH provisioning, interactive mesh topology visualization, and smart physical LAN Motorola device discrimination.

---

## Prerequisites

- **Flutter SDK**: `>= 3.13.4` (Dart 3.x)
- **Linux Prerequisites** (for desktop builds):
  ```bash
  sudo apt-get update && sudo apt-get install -y \
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
  ```
- **Android Prerequisites**:
  - Android SDK (API 34+ recommended)
  - `adb` (Android Debug Bridge)
  - USB Debugging enabled on physical Android device or active Android emulator
- **Windows Prerequisites**:
  - Visual Studio 2022 with "Desktop development with C++" workload
  - Windows 10/11 64-bit

---

## Running in Development Mode (with Hot Reload 🔥)

First, ensure dependencies are installed:
```bash
flutter pub get
```

### 1. Linux Desktop
To run directly on Linux with native windowing and interactive DevTools:
```bash
flutter run -d linux
```
* **Hot Reload**: Press `r` in the terminal.
* **Hot Restart**: Press `R` in the terminal.
* **Inspect Widget Tree / DevTools**: Open the displayed DevTools URL in your browser.

### 2. Android via ADB
Verify your Android device or emulator is detected:
```bash
adb devices
flutter devices
```

Run on the connected device:
```bash
# If a single Android device is connected:
flutter run -d android

# Or target by specific ADB Device ID:
flutter run -d <DEVICE_SERIAL_ID>
```
* Supports Camera / QR Code label scanner (`mobile_scanner`).
* Full live hot-reload enabled over ADB.

### 3. Windows Desktop
On a Windows host with Developer Mode enabled:
```bash
flutter run -d windows
```

### 4. Web Browser (Optional Testing)
```bash
flutter run -d chrome
```

---

## Compiling for Production Release

Before building production artifacts, verify that all automated unit and widget tests pass and analysis is clean:
```bash
flutter test
flutter analyze
```

---

### 1. Production Linux Binary & Bundle

Build an optimized 64-bit native ELF release bundle:
```bash
flutter build linux --release
```

#### Production Artifact Location:
```text
build/linux/x64/release/bundle/
├── motoq11_saver (executable binary)
├── data/
└── lib/
```

To run the release bundle directly:
```bash
./build/linux/x64/release/bundle/motoq11_saver
```

*(Optional) Create a standalone `.tar.gz` distribution archive:*
```bash
tar -czvf motoq11-saver-linux-x64.tar.gz -C build/linux/x64/release/bundle .
```

---

### 2. Production Android (APK & App Bundle)

#### A. Standalone Release APK (Sideloading / Direct Install)
```bash
flutter build apk --release
```
* **Production APK Path**: `build/app/outputs/flutter-apk/app-release.apk`

*To split by target ABI (`armeabi-v7a`, `arm64-v8a`, `x86_64`) for smaller download sizes:*
```bash
flutter build apk --release --split-per-abi
```
* **Splits Output**: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`, etc.

#### B. Google Play App Bundle (AAB)
```bash
flutter build appbundle --release
```
* **Production Bundle Path**: `build/app/outputs/bundle/release/app-release.aab`

#### Installing Release APK directly via ADB:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

### 3. Production Windows Executable

Build a self-contained release folder for 64-bit Windows:
```bash
flutter build windows --release
```

#### Production Artifact Location:
```text
build/windows/x64/runner/Release/
├── motoq11_saver.exe
├── data/
└── flutter_windows.dll
```

*(Optional) Package into a ZIP distribution:*
```powershell
Compress-Archive -Path build\windows\x64\runner\Release\* -DestinationPath motoq11-saver-windows-x64.zip
```

---

## Key Feature Capabilities

- **Automatic Physical LAN Detection**: Identifies local subnet (`10.10.11.0/24`, `192.168.1.0/24`, etc.) excluding Docker virtual interfaces and VPNs.
- **Smart Motorola Q11 Discrimination**: Probes characteristic OpenWrt ports (`22 Dropbear`, `53 DNS`, `80 Motosync UI`, `443 HTTPS`, `8080 HTTP Alt`, `7681 ttyd`) and checks system ARP cache against Motorola OUI (`c8:c7:50`).
- **Master vs. Satellite Determination**: Uses system default gateway routing to automatically designate the Master Router vs. Mesh Satellite Nodes.
- **Persistent Friendly Device Naming**: Lets users assign and remember custom names (e.g., *"Living Room Gateway"*, *"Office Satellite"*) indexed by IP and hardware MAC address.
- **Interactive Animated Mesh Topology**: Visualizes mesh backhaul links, signal strength (dBm), and real-time packet transit.
- **Pure-Dart SSH & CGI Exploit Engine**: Direct firmware deployment without requiring external SSH or curl binaries.
