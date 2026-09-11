# Oblivion - Unofficial Warp Client

"Internet, for all or none!"

Oblivion provides secure, optimized internet access through a user-friendly app
using Cloudflare Warp technology.

It is built on [Aether](https://github.com/CluvexStudio/Aether), a user-space
Warp core written in Rust that speaks MASQUE and WireGuard, and runs on Android,
Windows and Linux from one codebase.

> **مستندات فارسی:** نسخهٔ کامل فارسی این سند در [README_FA.md](README_FA.md) در دسترس است.

![oblivion3.jpg](media/oblivion3.jpg)

## Features

- **Two transports**: MASQUE over QUIC/HTTP-3 or HTTP/2, and classic WireGuard.
- **Zero Trust**: connect as a managed device on your organization's Cloudflare
  account, signing in with an emailed code, a service token, or a token you hold.
- **Traffic rules**: block a destination outright, or send it straight out and
  bypass the tunnel, which is what banking apps and domestic sites need.
- **Split tunnelling**: choose which Android apps stay off the tunnel.
- **Obfuscation**: profiles that reshape the handshake for networks that
  fingerprint it.
- **User-Friendly**: simple, intuitive interface in Persian and English, with a
  right-to-left layout wherever Persian is selected.
- **Native desktop**: a first-class Windows desktop client with the same design
  language as the mobile app - system tray integration, a compact window, dark
  and light themes, and a bundled privileged helper for full-tunnel mode.

## Quick Start

1. **Download**: Grab the build for your platform from our
   [Releases](https://github.com/bepass-org/oblivion/releases) page and install it.

2. **Connect**: Launch Oblivion and hit the switch button.

On Android the app runs as a VPN service and needs no root. On Windows and Linux
it exposes a local SOCKS5 proxy, and full device routing needs administrator
rights.

## Windows Desktop

The Windows client is a native desktop application built from the same Flutter
codebase and the same design language as the mobile app: the amber wordmark, the
rounded card lists, the single connect switch, and the Vazirmatn typeface are all
shared, so the desktop app feels like an official sibling of the phone app.

### What ships in the Windows package

Everything the app needs is bundled next to `oblivion.exe`; no runtime,
library or developer tool has to be installed separately:

| Component | Purpose |
| --- | --- |
| `oblivion.exe` | The desktop application itself |
| `oblivion_core.dll` | The FFI bridge that supervises the tunnel engines |
| `aether.exe` | The Aether Warp core (MASQUE / WireGuard / gool) |
| `psiphon.exe` | The Psiphon engine, used by the Psiphon and chain cores |
| `oblivion-helper.exe` | Privileged helper that configures full-tunnel routing |
| `hev-socks5-tunnel.exe`, `wintun.dll` | The tun device used by full-tunnel mode |
| `flutter_windows.dll`, `data\` | The Flutter engine and the app assets |

### Getting it

- **Installer** - run `Oblivion-Setup-x64.exe`, accept the prompts, and Oblivion
  appears in the Start menu (and optionally on the desktop). The installer
  silently adds the Microsoft Visual C++ runtime if the machine does not have
  it already.
- **Portable** - unpack `Oblivion-Windows-x64.zip` anywhere and run
  `oblivion.exe` straight from the folder; the archive carries an app-local copy
  of the C runtime, so it also works on machines without any redistributable.

### Desktop behaviour

- The window opens centred at the phone-like frame the design is drawn for, and
  can be resized down to a compact panel; closing the window hides the app to
  the system tray instead of quitting it.
- The tray icon reports the tunnel stage (idle, connecting, connected) with a
  distinct icon per stage, and its menu - show, hide, quit - is translated in
  the active language.
- **Language**: Settings › Language switches between English and Persian
  (فارسی). Persian renders fully right-to-left: every row, header, picker and
  dialog mirrors, while addresses, endpoints and IPs stay left-to-right.
- **Theme**: Settings › Theme follows the system, or forces dark or light.
- **Routing**: Settings › Routing mode offers *Local proxy only*, *System
  proxy* and *Full tunnel*. Full tunnel drives all device traffic through
  wintun and asks for administrator rights when it starts; without them the app
  stays on the proxy and says so on the home screen.

### Building the Windows app yourself

On a Windows machine with Flutter 3.44+, Rust and Go installed:

```sh
git clone --recursive https://github.com/bepass-org/oblivion.git
cd oblivion
flutter pub get
flutter build windows --release
```

The release bundle lands in `build\windows\x64\runner\Release`. To wrap it in
the single-file installer, install [Inno Setup](https://jrsoftware.org/isinfo.php)
and compile the bundled script:

```sh
iscc windows\installer\oblivion.iss
```

The script reads the release bundle, embeds the icon and version information,
and writes `dist\Oblivion-Setup-x64.exe`.

## Building the Project

### Prerequisites

- Flutter 3.44 or newer
- Rust (stable) for the Aether core and the FFI bridge
- Go, for the Psiphon engine
- Android NDK r27 or newer, and JDK 17, for Android builds
- CMake, Ninja, Clang and `libgtk-3-dev` for Linux builds
- A Windows host, NASM and MSYS2 for Windows builds (NASM builds BoringSSL,
  MSYS2 builds the hev-socks5-tunnel helper)

### Clone with the submodules

The Aether core and hev-socks5-tunnel live in their own repositories and are
linked here as submodules, so clone recursively:

```sh
git clone --recursive https://github.com/bepass-org/oblivion.git
```

If you already cloned without `--recursive`:

```sh
git submodule update --init --recursive
```

### Build

```sh
flutter pub get

flutter build apk --release --split-per-abi
flutter build apk --release
flutter build linux --release
flutter build windows --release
```

The Android build cross compiles the Aether core for each ABI on the fly, so the
first build takes a while. Add `--target-platform android-arm64` to build for one
ABI only.

Release APKs are signed when `android/key.properties` exists, and fall back to
the debug key when it does not.

## Get Involved

We're a community-driven project, aiming to make the internet accessible for all. Whether you want to contribute code, suggest features, or need some help, we'd love to hear from you! Check out our [GitHub Issues](https://github.com/bepass-org/oblivion/issues) or submit a pull request.

## Acknowledgements and Credits

This project makes use of several open-source tools and libraries, and we are grateful to the developers and communities behind these projects. In particular, we would like to acknowledge:

### Cloudflare Warp

- **Project**: Cloudflare Warp
- **Website**: [Cloudflare Warp](https://www.cloudflare.com/products/warp/)
- **License**: [License information](https://www.cloudflare.com/application/terms/)
- **Description**: Cloudflare Warp is a technology that enhances the security and performance of Internet applications. We use it in our project for its efficient and secure network traffic routing capabilities.

### Aether

- **Project**: Aether
- **GitHub Repository**: [Aether on GitHub](https://github.com/CluvexStudio/Aether)
- **License**: [GNU Affero General Public License v3.0](https://github.com/CluvexStudio/Aether/blob/main/LICENSE)
- **Description**: Aether is the Warp core this app is built on. It implements MASQUE over QUIC and HTTP/2, WireGuard, endpoint discovery, obfuscation and Cloudflare Zero Trust enrolment, and exposes the tunnel as a local proxy.

### quiche

- **Project**: quiche
- **GitHub Repository**: [quiche on GitHub](https://github.com/cloudflare/quiche)
- **License**: [BSD 2-Clause](https://github.com/cloudflare/quiche/blob/master/COPYING)
- **Description**: Cloudflare's QUIC and HTTP/3 implementation. Aether uses it to carry the MASQUE tunnel.

### hev-socks5-tunnel

- **Project**: hev-socks5-tunnel
- **GitHub Repository**: [hev-socks5-tunnel on GitHub](https://github.com/heiher/hev-socks5-tunnel)
- **License**: [MIT](https://github.com/heiher/hev-socks5-tunnel/blob/master/LICENSE)
- **Description**: A tun to socks5 forwarder. On Android it turns the packets from the VPN interface into proxy connections that the core carries. On Windows it feeds the wintun interface into the local proxy.

### BoringTun

- **Project**: BoringTun
- **GitHub Repository**: [BoringTun on GitHub](https://github.com/cloudflare/boringtun)
- **License**: [BSD 3-Clause](https://github.com/cloudflare/boringtun/blob/master/LICENSE)
- **Description**: A user-space WireGuard implementation in Rust, used for the WireGuard transport.

Please note that the use of these tools is governed by their respective licenses, and you should consult those licenses for terms and conditions of use.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License - see the [CC BY-NC-SA 4.0 License](https://creativecommons.org/licenses/by-nc-sa/4.0/) for details.

### Summary of License

The CC BY-NC-SA 4.0 License is a free, copyleft license suitable for non-commercial use. Here's what it means for using this project:

- **Attribution (BY)**: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

- **NonCommercial (NC)**: You may not use the material for commercial purposes.

- **ShareAlike (SA)**: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

This summary is only a brief overview. For the full legal text, please visit the provided link.
