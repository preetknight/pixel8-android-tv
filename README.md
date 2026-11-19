# Pixel 8 → Complete 4K HDR Android TV

Turn a rooted **Google Pixel 8 (`shiba`, Tensor G3)** into a dedicated **4K 60Hz 10-bit HDR Android TV box**—complete with a **4-lane USB-C to HDMI 4K cable**, a **real Google TV Bluetooth remote**, a **4K Android TV launcher**, streaming apps (**Nuvio**, **TizenTube**), **automatic SDR ↔ HLG HDR** switching, and full Magisk boot automation.

---

## Hardware & Peripherals

- **Phone:** Rooted **Google Pixel 8 (`shiba`, Tensor G3)** with Magisk.
- **Cable:** Direct **4-lane USB-C to HDMI (4K 60Hz HDR)** cable supporting DisplayPort 1.4 Alt Mode.
  - *Why 4-lane matters:* Standard 2-lane USB-C hubs/dongles (with USB 3.0 data ports) halve DisplayPort lanes and cap bandwidth; a direct 4-lane Type-C to HDMI cable negotiates `4 lanes @ 8100 Mbps (HBR3)` for `3840x2160 @ 60Hz` at **10-bit color (`bpc = 10`)**.
- **Remote:** **Real Google TV Bluetooth Remote** paired over Bluetooth for D-Pad navigation, Home/Back, and full couch control without touching the phone.

---

## What This Project Does (A to Z)

### 1. Complete Android TV Shell & Power Setup (`scripts/03_android_tv.sh`, `scripts/disable_touch.sh`, `scripts/enable_tcpip.sh`)
- **TV Launcher & Clean UI:** Disables Pixel Launcher (`com.google.android.apps.nexuslauncher`), sets **GlassTV** (`com.techgenius.tvoslauncher/.MainActivity`) as the home launcher, disables lockscreen/keyguard, hides navigation bars/cutout (`noCutout` overlay + `immersive.status=*`), and switches the on-screen keyboard to **LeanKeyboard** (`org.liskovsoft.androidtv.rukeyboard`).
- **4K Landscape Lock:** Permanently locks orientation to landscape (`user_rotation 1`, `set-ignore-orientation-request -d 0 true`) and sets `wm size 2160x3840 -d 0` + `wm density 640 -d 0` (native `3840x2160` render buffer at `960x540 dp` TV layout scaling).
- **24/7 TV Box Power & Ghost-Touch Prevention:** Caps charging at 80% (`charge_optimization_mode 1`), sets internal screen brightness to `0`, keeps the device awake (`svc power stayon true`), unbinds the internal touchscreen driver (`goodix_ts.0` / `goodix_brl_touch`), and enables persistent wireless ADB (`service.adb.tcp.port 5555`).

### 2. Universal 4K 60Hz Mode Lock (`java/Set4KHDR.java`, `java/Keep4KHDR.java`)
- Bypasses Android `DisplayModeDirector`'s `3440x1600` (`PRIORITY_LIMIT_MODE`) cap via `DisplayControl.overrideHdrTypes` and `SurfaceControl.setDesiredDisplayModeSpecs`.
- `Keep4KHDR` inspects `supportedDisplayModes` on **any** connected external TV (not tied to a single TV ID) and locks the best **`3840x2160 @ ~60Hz`** mode, resetting state automatically on cable unplug/replug.

### 3. 10-bit DisplayPort & Hardware Auto-HDR (`kernel/dp_hdr_hlg.c`, `kernel/dp_hdr_sdr.c`, `scripts/auto_hdr.sh`)
- Enables `dp_rate=3` (HBR3 8100 Mbps) and `dp_bpc=10` (10-bit) before DisplayPort link training.
- **KASLR-independent** out-of-tree `.ko` modules map the Tensor G3 DisplayPort MMIO page (`0x110f5000`) via `ioremap_prot`:
  - `dp_hdr_hlg.ko`: Programs register `0x5c10` to CEA-861 DRM InfoFrame **`0x87`** with **`EOTF = 3` (HLG)** and standard AVI colorimetry, triggering hardware HDR on the TV without crushing gamma-2.2 shadows.
  - `dp_hdr_sdr.ko`: Sends **`0x87` (`EOTF = 0`, Traditional Gamma SDR)** so the TV cleanly exits HDR mode back to SDR.
- `scripts/auto_hdr.sh` streams `logcat` (`CCodecBuffers` / `CCodec` / `MediaCodec`) with near-zero idle CPU and switches automatically between **HLG HDR** and **SDR** for both **Nuvio** (`10-bit P010`) and **TizenTube Cobalt** (`AV1`/`VP9`).

> **Note on HLG vs HDR10 PQ:** Pixel 8's `/vendor/lib64/libexynosdisplay.so` (`ExynosDisplayDrmInterface::updateHdrCapabilities()`) and `displaycolor` only expose `NATIVE`, `SRGB`, and `DISPLAY_P3` on external DisplayPort (no `BT2100_PQ`), so `SurfaceFlinger` always tone-maps to gamma-2.2 `sRGB`/`DISPLAY_P3`. Using **HLG (`EOTF = 3`)** preserves gamma-2.2 shadow/midtone brightness while enabling TV HDR highlights; `EOTF = 2` (PQ) + `BT.2020` crushes shadows and oversaturates colors.

---

## Repository Layout

```text
├── build.sh                    # Builds .dex helpers and .ko kernel modules into ./build/
├── java/
│   ├── Set4KHDR.java           # One-shot 4K 60Hz + HDR capability override
│   └── Keep4KHDR.java          # Universal background 4K 60Hz mode lock for any TV
├── kernel/
│   ├── dp_hdr_hlg.c            # KASLR-independent .ko: sends CEA-861 DRM 0x87 (EOTF=3 HLG)
│   └── dp_hdr_sdr.c            # KASLR-independent .ko: sends CEA-861 DRM 0x87 (EOTF=0 SDR)
└── scripts/
    ├── 03_android_tv.sh        # TV launcher, landscape lock, 4K UI, power & touch unbind
    ├── 4k_hdr_dp.sh            # DisplayPort 10-bit HBR3 link + Set4KHDR/Keep4KHDR + Auto-HDR
    ├── auto_hdr.sh             # Event-driven MediaCodec SDR ↔ HLG HDR switcher
    ├── disable_touch.sh        # Early post-fs-data/service.d goodix_ts unbind
    └── enable_tcpip.sh         # Persistent wireless ADB on port 5555
```

---

## Build & Install

### Prerequisites
- Build tools (macOS/Linux): `clang`, `javac`, Android SDK `d8`, `adb`.
- **Kernel note:** `kernel/dp_hdr_hlg.c` and `kernel/dp_hdr_sdr.c` embed `vermagic`, kCFI hashes, and `__versions` CRCs for `6.1.162-android14-11-gd7a0a08e0e15-ab16261946` (Android 17 `CP3A.261005.005`). For other kernel builds, extract matching values from your device's `exynos-drm.ko`.

### Build
```bash
chmod +x build.sh
./build.sh
```

### Deploy to Pixel 8
```bash
adb push build/set_4k_hdr.dex build/keep_4k_hdr.dex build/dp_hdr_hlg.ko build/dp_hdr_sdr.ko scripts/auto_hdr.sh /data/local/tmp/
adb push scripts/03_android_tv.sh scripts/4k_hdr_dp.sh scripts/disable_touch.sh scripts/enable_tcpip.sh /data/local/tmp/
adb shell "su -c '
  chmod +x /data/local/tmp/auto_hdr.sh
  mkdir -p /data/adb/service.d /data/adb/post-fs-data.d
  mv /data/local/tmp/03_android_tv.sh /data/local/tmp/4k_hdr_dp.sh /data/local/tmp/disable_touch.sh /data/local/tmp/enable_tcpip.sh /data/adb/service.d/
  cp /data/adb/service.d/disable_touch.sh /data/adb/post-fs-data.d/disable_touch.sh
  chmod 0755 /data/adb/service.d/*.sh /data/adb/post-fs-data.d/disable_touch.sh
  chown 0:0 /data/adb/service.d/*.sh /data/adb/post-fs-data.d/disable_touch.sh
'"
```

Reboot the Pixel 8 to bring up the complete 4K HDR Android TV automatically.
