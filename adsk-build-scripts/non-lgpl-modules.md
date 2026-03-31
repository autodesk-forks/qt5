# Qt 6.8 Modules — Not Available Under LGPL

Complete list across all 50 submodules. Verified by inspecting each module's `LICENSES/` directory
(new-style) and `LICENSE.*` files (old-style) in the repo.

---

## 1. Commercial + GPL only (no LGPL) — 15 modules

These require a Qt commercial license for use in proprietary/closed-source software.
Modules marked **(skipped)** are excluded from the Autodesk Windows build via `QT_MODULE_SKIPPED`.

| Module | Licenses | Notes |
|---|---|---|
| `qtactiveqt` | GPL-3.0, Commercial | ActiveX/COM support on Windows |
| `qthttpserver` | GPL-3.0, Commercial | HTTP server module |
| `qtquickeffectmaker` | GPL-3.0, Commercial | Visual effect editor |
| `qtgrpc` | GPL-3.0, Commercial | gRPC/Protobuf protocol support |
| `qtvirtualkeyboard` | GPL-3.0, Commercial | **(skipped)** Virtual keyboard |
| `qtquicktimeline` | GPL-3.0, Commercial | **(skipped)** Timeline animations |
| `qtquick3d` | GPL-3.0, Commercial | **(skipped)** 3D graphics |
| `qtnetworkauth` | GPL-3.0, Commercial | **(skipped)** Network authentication |
| `qtdatavis3d` | GPL-3.0, Commercial | **(skipped)** 3D data visualization |
| `qtcharts` | GPL-3.0, Commercial | **(skipped)** Charting components |
| `qtquick3dphysics` | GPL-3.0, Commercial | **(skipped)** 3D physics engine |
| `qtlottie` | GPL-3.0, Commercial | **(skipped)** Lottie animation |
| `qtcoap` | GPL-3.0, Commercial | **(skipped)** CoAP protocol |
| `qtmqtt` | GPL-3.0, Commercial | **(skipped)** MQTT protocol |
| `qtgraphs` | GPL-3.0, Commercial | **(skipped)** Graph visualization |

---

## 2. GPL only (no LGPL, no Commercial) — 1 module

| Module | Licenses | Notes |
|---|---|---|
| `qtwebglplugin` | GPL-3.0 only | Stream Qt over WebGL |

---

## 3. Documentation only (no LGPL) — 1 module

| Module | Licenses | Notes |
|---|---|---|
| `qtdoc` | GPL-3.0, Commercial, FDL, CC-BY | Documentation only |

---

## Special Notes

### qtlocation — IS LGPL but still excluded from build
`qtlocation` has `LGPL-3.0-only.txt`. It is excluded from the Autodesk build via
`QT_MODULE_EXCLUDED`, likely due to dependency or functionality concerns rather than licensing.

### qttools — LGPL with GPL components inside
`qttools` libraries are LGPL-3.0, but **Qt Designer** and parts of **Qt Linguist** are GPL.
The Windows build mitigates this with the `-no-feature-designer` configure flag.

### Old-style license files
Several older/deprecated modules use `LICENSE.*` filenames instead of a `LICENSES/` subdirectory
(e.g. `qtfeedback`, `qtxmlpatterns`, `qtcanvas3d`, `qtgamepad`, `qtsystems`, `qtpim`).
These all include LGPL — they are NOT in the non-LGPL list above.
