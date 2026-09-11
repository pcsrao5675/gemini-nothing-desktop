# Original User Request

## Initial Request — 2026-09-11T08:10:58Z

Package the complete Gemini Floating Assistant and Nothing OS Island KDE desktop customization suite into a standalone, modular, open-source Git repository ready for GitHub publication.

Working directory: /home/harsha/gemini-nothing-desktop
Integrity mode: development

## Requirements

### R1. Repository Assembly & Modular Structure
Extract and consolidate all active components from user directories into a clean, self-contained project structure:
- **Plasmoid**: Nothing OS Island topbar widget (`org.omar.nothingisland`) including the Electric Blue wave animation, dynamic pill layout, media controls, and Gemini status indicator.
- **Brave Extension**: In-page UI injector (`content.js`, `style.css`, `manifest.json`) providing the floating "Attach Screen" action pill, fullscreen toggle, and custom close controls.
- **Daemon**: Local helper service (`server.py`) managing Spectacle desktop capture, active status reporting on port 8765, and user systemd service definitions (`gemini-screenshot.service`).
- **KWin & Shortcut Integration**: KWin 6 window rules configuration (`kwinrulesrc`), standalone toggle script (`gemini-toggle.sh`), desktop entry (`gemini-overlay.desktop`), and global shortcut mapping for both HP Omen key (`Launch (2)`) and `Meta+Space`.

### R2. Universal Installer & Uninstaller
Provide an automated installation script (`install.sh`) and uninstallation script (`uninstall.sh`) that:
- Automatically replaces any hardcoded user paths (`/home/harsha/...`) with dynamic user home paths (`$HOME`).
- Copies or symlinks components into standard XDG locations (`~/.local/share/plasma/plasmoids/`, `~/.local/share/gemini-assistant/`, `~/.local/bin/`, `~/.config/systemd/user/`).
- Registers and applies KWin 6 window rules via DBus.
- Registers global shortcuts with KDE's `kglobalaccel` and `kbuildsycoca6`.

### R3. Repository Initialization & Documentation
- Initialize a local git repository on branch `main` with clean commit history.
- Add a `.gitignore` excluding temporary files, browser profiles, tokens, and build artifacts.
- Write an enterprise-grade `README.md` with visual architecture diagrams, installation instructions, keyboard shortcut mappings, and troubleshooting steps.
- Configure git remote for GitHub deployment.

## Acceptance Criteria

### Component Integrity
- [ ] All required files from `~/.local/share/plasma/plasmoids/org.omar.nothingisland/`, `~/.local/share/gemini-assistant/`, `~/.local/bin/gemini-toggle.sh`, and systemd units are captured without missing dependencies.
- [ ] Zero static absolute paths to `/home/harsha` remaining in shipped repository files (all parameterized or dynamically resolved via environment variables).

### Installation & Operations
- [ ] An automated `install.sh` script executes successfully with `--dry-run` or check mode, verifying destination paths, systemd unit files, and KWin rule templates.
- [ ] `uninstall.sh` cleanly removes all installed files, systemd units, and KWin rules without affecting other system configurations.

### Documentation & Git Quality
- [ ] Git repository is initialized with a clean initial commit on branch `main` and a proper `.gitignore`.
- [ ] `README.md` includes clear feature breakdown, architecture overview, installation instructions, and Omen/Meta+Space key configuration guide.
- [ ] Git remote is staged and ready for push to GitHub (`git remote add origin ...`).
