# Project: Gemini Floating Assistant & Nothing OS Island Desktop Customization Suite

## Architecture
A modular desktop customization suite for KDE Plasma 6 (Wayland) integrating an Android Gemini-style floating overlay with the Nothing OS Dynamic Island topbar aesthetic.

### Subsystems:
1. **Plasmoid (`plasmoid/org.omar.nothingisland/`)**:
   - KDE Plasma 6 declarative applet (QML, JS, fonts).
   - Polls local daemon at `http://127.0.0.1:8765/active` every 300ms.
   - Renders 40 FPS Electric Blue (`#4DA3FF`) undulating wave animation on Canvas when assistant is active.
   - Integrates media controls, system monitors, and Gemini quick-launch button.
2. **Brave Extension (`extension/`)**:
   - Manifest V3 extension injected into `https://gemini.google.com/*`.
   - Floating "Attach Screen" action pill with 3-tier fallback image injection (file input, drag-and-drop, clipboard paste).
   - Glassmorphic borderless window controls (Maximize, Close) and Escape dismissal.
   - Real-time focus/visibility reporting to daemon.
3. **Daemon Service (`daemon/`)**:
   - Python HTTP microservice on `127.0.0.1:8765`.
   - Coordinates Spectacle desktop capture with KWin 6 DBus window minimization/restoration.
   - Tracks `/active` state via `/tmp/gemini_active` and monitors browser process lifecycle.
   - Systemd user service units (`systemd/gemini-screenshot.service`, `systemd/gemini-assistant.service`).
4. **KWin & Shortcut Integration (`kwin/`, `bin/`, `desktop/`)**:
   - KWin 6 window rule for `brave-gemini.google.com__app-Default` (above=3, noborder=3, skiptaskbar=3, skipswitcher=3, 410x710 at bottom-right).
   - Toggle launcher script (`gemini-toggle.sh`) with KWin scripting D-Bus toggle and web-app invocation.
   - Desktop entry (`gemini-overlay.desktop`) with global shortcuts: HP Omen key (`Launch (2)`), auxiliary keys, and `Meta+Space`.
5. **Universal Packaging & Lifecycle (`install.sh`, `uninstall.sh`)**:
   - Non-destructive installer with `--dry-run` and `--check` modes.
   - Dynamic `$HOME` resolution (zero hardcoded paths).
   - Safe KWin rule injection with DBus reload (`qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure`).
   - Clean uninstaller with complete state rollback.

## Code Layout
```
gemini-nothing-desktop/
├── .agents/                    # Multi-agent coordination metadata
├── .gitignore                  # Git exclusions
├── ORIGINAL_REQUEST.md         # Authoritative requirements
├── PROJECT.md                  # Master architecture & feature inventory
├── README.md                   # Enterprise-grade documentation
├── install.sh                  # Universal installer (with --dry-run)
├── uninstall.sh                # Clean uninstaller
├── bin/
│   └── gemini-toggle.sh        # Overlay toggle and launcher
├── daemon/
│   ├── server.py               # Screenshot & state microservice
│   └── systemd/
│       ├── gemini-screenshot.service # Systemd user service
│       └── gemini-assistant.service  # Systemd user service
├── desktop/
│   └── gemini-overlay.desktop  # XDG desktop entry & shortcut definitions
├── extension/
│   ├── manifest.json           # Manifest V3 definition
│   ├── content.js              # DOM injection & screenshot attachment
│   └── style.css               # Styling & glassmorphism controls
├── kwin/
│   └── gemini-kwinrules.conf   # KWin 6 window rules template
├── plasmoid/
│   └── org.omar.nothingisland/ # Full Plasma 6 applet tree (47 files)
└── tests/
    ├── e2e_test_runner.sh      # Comprehensive test runner
    └── test_cases/             # Tiers 1-4 test suites
```

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Plasmoid Tree Assembly | Complete 47-file tree of `org.omar.nothingisland` | M1 | Survey 1 |
| 2 | Electric Blue Wave Engine | Sinusoidal Canvas wave reacting to `/active` state | M1 | Survey 1 |
| 3 | Plasmoid Path Parameterization | Replace hardcoded path in `CompactPill.qml:266` | M1 | Survey 1 |
| 4 | Brave Extension Assembly | Manifest V3 (`manifest.json`, `content.js`, `style.css`) | M1 | Survey 2 |
| 5 | Screen Attacher Action Pill | Floating pill with 3-tier image injection | M1 | Survey 2 |
| 6 | Borderless Window Controls | Glassmorphic maximize/close buttons & Escape handler | M1 | Survey 2 |
| 7 | Daemon Microservice | `server.py` Spectacle capture & state coordination | M1 | Survey 2 |
| 8 | Systemd Units | Parameterized user services (`gemini-screenshot.service`) | M1 | Survey 2 |
| 9 | KWin 6 Window Rules | Template for floating borderless overlay rules | M1 | Survey 3 |
| 10 | Overlay Toggle Script | `gemini-toggle.sh` with KWin D-Bus scripting | M1 | Survey 3 |
| 11 | Desktop Entry & Shortcuts | `gemini-overlay.desktop` with HP Omen & Meta+Space keys | M1 | Survey 3 |
| 12 | Universal Installer | `install.sh` with `--dry-run` and check mode | M2 | Request R2 |
| 13 | Dynamic Path Resolution | Parameterize all paths to `$HOME` / `%h` | M2 | Request R2 |
| 14 | Safe KWin Rules Merging | Non-destructive config update & DBus reconfigure | M2 | Request R2 |
| 15 | KDE Shortcut Registration | `kbuildsycoca6` and `kwriteconfig6` integration | M2 | Request R2 |
| 16 | Universal Uninstaller | `uninstall.sh` with complete rollback | M2 | Request R2 |
| 17 | Git Initialization | Clean git repo on branch `main` with proper history | M3 | Request R3 |
| 18 | Production .gitignore | Ignore temporary files, browser profiles, tokens, logs | M3 | Request R3 |
| 19 | Enterprise Documentation | Visual architecture, installation, shortcuts, troubleshooting | M3 | Request R3 |
| 20 | Git Remote Setup | Remote configuration for GitHub publication | M3 | Request R3 |
| 21 | E2E Testing Suite | Tier 1-4 comprehensive automated test suite | M4 | Dual Track |
| 22 | Forensic Integrity Audit | Independent verification of zero hardcoding & clean logic | M4 | Dual Track |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Component Assembly & Modular Consolidation | Extract, assemble, and parameterize plasmoid, extension, daemon, kwin, bin, desktop | none | IN_PROGRESS |
| 2 | Universal Installer & Uninstaller | Build `install.sh` (with `--dry-run`) and `uninstall.sh` with dynamic paths & DBus hooks | M1 | PLANNED |
| 3 | Git Repository & Enterprise Documentation | Initialize git on `main`, `.gitignore`, comprehensive `README.md`, git remote | M1, M2 | PLANNED |
| 4 | E2E Verification & Forensic Integrity Audit | Requirement-driven test suite (Tiers 1-4), adversarial stress tests, forensic audit | M1, M2, M3 | PLANNED |

## Interface Contracts
### Daemon (`server.py`) ↔ Plasmoid (`CompactPill.qml`)
- Protocol: HTTP GET `http://127.0.0.1:8765/active`
- Response: Status 200, Body: `"1"` (active) or `"0"` (inactive), Content-Type: `text/plain`
- CORS: `Access-Control-Allow-Origin: *`

### Daemon (`server.py`) ↔ Brave Extension (`content.js`)
- Protocol: HTTP GET `http://127.0.0.1:8765/screenshot`
- Response: Status 200, Body: PNG binary data, Content-Type: `image/png`
- Protocol: HTTP GET `http://127.0.0.1:8765/active?val=1` or `val=0`
- Response: Status 200, Body: `"OK"`
- Protocol: HTTP GET `http://127.0.0.1:8765/close` and `/maximize`
- Response: Status 200, Body: `"OK"`

### Toggle Script (`gemini-toggle.sh`) ↔ KWin 6
- Protocol: D-Bus call `org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript` or D-Bus run script
- Target: Minimizes/restores window with `caption` matching Gemini or `wmclass` matching `brave-gemini.google.com__app-Default`
- Fallback: Launches `brave --app=https://gemini.google.com/app --user-data-dir=...` if process not running
