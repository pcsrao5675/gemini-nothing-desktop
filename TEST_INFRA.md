# TEST_INFRA: Automated Test Infrastructure Specification
## Gemini Floating Assistant & Nothing OS Island Desktop Customization Suite

---

## 1. Test Philosophy & Principles

### 1.1 Opaque-Box & Requirement-Driven Testing
The testing infrastructure is built upon an **opaque-box, requirement-driven philosophy**. Tests validate external behaviors, file system structures, syntax integrity, configuration specifications, and inter-process communication contracts against the formal requirements defined in `ORIGINAL_REQUEST.md` (R1, R2, R3) and `PROJECT.md` (Features 1–22). Tests do not rely on transient internal implementation quirks or mocked assertions that guarantee artificial passage.

### 1.2 Zero Dependency on Implementation Internals
Tests treat all components as independent, modular artifacts:
- **Plasmoid Applet**: Validated against the KDE Plasma 6 Applet Package specification, standard `qmldir` definitions, and required QML/canvas properties.
- **Brave Extension**: Validated against Chrome/Chromium Manifest V3 schema and ECMAScript syntactic standards.
- **Daemon Microservice**: Validated via Python AST syntax verification and HTTP/1.1 endpoint declaration contract checks.
- **KWin Window Rules**: Validated against KDE KWin 6 window rule format specifications and property enforcement levels (`rule=3`).
- **Desktop Entry & Shortcuts**: Validated against freedesktop.org Desktop Entry Specification v1.5 and KDE GlobalAccel key syntax.
- **Scripts & Packaging**: Validated through static shell analysis (`bash -n`), executable permission flags, dynamic path resolutions, and non-destructive dry-run executions.

### 1.3 Strict Test Integrity & Non-Facade Verification
In accordance with team integrity standards:
- **No Facade Testing**: No test may return `true` unconditionally or check trivial tautologies. Every assertion evaluates a verifiable property of target files or commands.
- **Adversarial & Negative Testing**: Includes malicious input handling, missing environment variables, nonexistent target directories, and corrupted configurations.
- **Zero Static Path Tolerance**: Absolute prohibition of hardcoded `/home/harsha` in shipped repository files (validated by Tier 2 forensic audits).

---

## 2. Testing Methodology

The test suite employs four industry-standard testing methodologies:

### 2.1 Category-Partition Testing
Input domains and environment states are systematically partitioned into discrete equivalence classes:
- **CLI Options**: Valid flags (`--dry-run`, `--check`, `--help`, `-h`), invalid flags (`--unknown`, `--fake-arg`), and empty argument sets.
- **Environment Contexts**: Standard desktop sessions (`XDG_DATA_HOME`, `XDG_CONFIG_HOME`), headless environments, and missing/empty environment variables.
- **System Service States**: Installed units, uninstalled states, running daemons, and inactive daemons.

### 2.2 Boundary Value Analysis (BVA)
Boundary values are probed to prevent edge-case regressions:
- Empty strings for path environment variables (`HOME=""`, `XDG_DATA_HOME=""`).
- Minimal vs. maximal command-line arguments.
- Trailing slash permutations in destination paths (`~/.local/share/` vs `~/.local/share`).
- Permission boundary checks (`0755` executable vs `0644` non-executable).

### 2.3 Pairwise & Cross-Feature Integration Testing
Verifies interface contracts across distinct subsystem boundaries:
- **Plasmoid ↔ Toggle Script**: `CompactPill.qml` dynamic execution contract with `gemini-toggle.sh`.
- **Extension ↔ Daemon Microservice**: Endpoints declared in `content.js` (`/screenshot`, `/active`, `/close`, `/maximize`) matching route declarations in `server.py`.
- **Toggle Script ↔ Daemon & KWin**: Toggle script state updates to `/tmp/gemini_active` and KWin D-Bus interface invocation (`org.kde.KWin /Scripting`).
- **KWin Rules ↔ Desktop Entry**: `StartupWMClass` in `gemini-overlay.desktop` matching `wmclass` in `gemini-kwinrules.conf`.

### 2.4 Workload & Real-World Application Scenarios
Full lifecycle simulation under realistic operational workloads:
- Non-destructive installer execution in dry-run mode (`./install.sh --dry-run`).
- Verification of simulated XDG target destinations without host pollution.
- Idempotency verification: multiple consecutive dry-run runs produce identical results.
- Simulated uninstaller verification verifying clean removal plan.

---

## 3. Four-Tier Test Suite Architecture

The automated test framework is divided into four sequential execution tiers:

```
tests/
├── e2e_test_runner.sh         # Master test orchestrator and reporter
├── tier1_feature_coverage.sh  # Tier 1: Core Feature Verification (≥45 tests)
├── tier2_boundary_corner.sh   # Tier 2: Boundary & Corner Cases (≥10 tests)
├── tier3_cross_feature.sh     # Tier 3: Cross-Feature Integration (≥8 tests)
└── tier4_real_world.sh        # Tier 4: Real-World Scenarios (≥6 tests)
```

### 3.1 Tier 1: Feature Coverage (≥5 tests per feature area, ≥45 tests total)
Focuses on individual component structure, syntax, and specification compliance:
1. **Plasmoid Structure & Metadata**: `metadata.json` valid JSON, `Plasma/Applet` structure, required QML files, `qmldir` singletons, font assets presence.
2. **Brave Extension**: `manifest.json` Manifest V3 compliance, valid JSON syntax, content script declarations, `style.css` presence, CSS valid selectors.
3. **Daemon Microservice**: `server.py` Python AST syntax check, HTTP port 8765 declaration, CORS header handling, route declarations, systemd unit syntax.
4. **KWin Rules Format**: `gemini-kwinrules.conf` INI syntax, `wmclass` definition, forced properties (`rule=3`), geometry definitions, window state flags.
5. **Shortcuts & Desktop Entry**: `gemini-overlay.desktop` XDG spec compliance, `X-KDE-Shortcuts` mapping (HP Omen + Meta+Space), `StartupWMClass`, `Icon` definition, `Type=Application`.
6. **Toggle Script**: Bash syntax (`bash -n`), executable permission, KWin D-Bus call logic, fallback browser launch logic, process check logic.
7. **Installer Interface**: `install.sh` syntax, `--help` output, `--dry-run` flag handling, dynamic path substitution, prerequisite checking.
8. **Uninstaller Interface**: `uninstall.sh` syntax, `--help` output, `--dry-run` flag handling, removal targets matching install targets, non-destructive confirmation.
9. **Gitignore & Exclusions**: `.gitignore` exists, excludes temporary files (`/tmp`), excludes browser profiles (`brave-profile`), excludes `.pyc`, excludes credentials/tokens.

### 3.2 Tier 2: Boundary & Corner Cases (≥10 tests)
Stress tests boundary conditions, environmental deviations, and security hygiene:
1. **Hardcoded Path Audit (Zero Tolerance)**: Recursively searches all tracked files outside `.agents` and `.git` for `/home/harsha`. Any match fails the test.
2. **File Permission Verification**: Confirms executable bit (`+x`) on `gemini-toggle.sh`, `install.sh`, `uninstall.sh`, and internal helper scripts.
3. **Missing Directory Resilience**: Evaluates installer behavior when destination directories do not yet exist.
4. **Empty Environment Variables**: Evaluates script behavior when `XDG_DATA_HOME` or `XDG_CONFIG_HOME` are unset or empty.
5. **Idempotency**: Verifies multiple consecutive invocations of `--dry-run` or check commands produce identical, non-destructive outputs.

### 3.3 Tier 3: Cross-Feature Combinations (≥8 tests)
Verifies inter-component integration and contract consistency:
1. **Desktop Entry ↔ Toggle Script**: `Exec` command in `desktop/gemini-overlay.desktop` resolves to `bin/gemini-toggle.sh`.
2. **Plasmoid ↔ Toggle Script**: `CompactPill.qml` triggers `gemini-toggle.sh` via dynamic execution rather than hardcoded path.
3. **Extension ↔ Daemon Routes**: All 4 REST endpoints called by `content.js` (`/screenshot`, `/active`, `/close`, `/maximize`) are explicitly serviced in `server.py`.
4. **Toggle Script ↔ Daemon Active State**: `gemini-toggle.sh` coordinates state changes via `/tmp/gemini_active` read by daemon and plasmoid.
5. **Toggle Script ↔ KWin D-Bus Contract**: `gemini-toggle.sh` utilizes standard `org.kde.KWin /Scripting` D-Bus calls.
6. **KWin Rules ↔ Desktop WMClass**: Window class `brave-gemini.google.com__app-Default` exactly aligns across KWin rules and desktop entry.

### 3.4 Tier 4: Real-World Application Scenarios (≥6 tests)
Validates end-to-end user workflows and non-destructive deployments:
1. **End-to-End Dry-Run Install**: Executes `./install.sh --dry-run` with complete output capture, asserting exit code 0 and planned target paths.
2. **XDG Destination Compliance**: Asserts planned installation paths match standard XDG specifications (`~/.local/share/plasma/plasmoids/`, `~/.local/share/gemini-assistant/`, `~/.local/bin/`, `~/.config/systemd/user/`).
3. **Component Manifest Verification**: Asserts all 47 plasmoid files and auxiliary assets are accounted for in the deployment plan.
4. **End-to-End Simulated Uninstall**: Executes `./uninstall.sh --dry-run` or simulated removal, verifying that all installed artifacts have corresponding cleanup actions without collateral deletion.

---

## 4. Feature Inventory Mapping

| Feature # | Feature Description | Milestone | Primary Test Tier | Specific Test Function / Check |
|---|---|---|---|---|
| 1 | Plasmoid Tree Assembly | M1 | Tier 1, Tier 4 | `test_plasmoid_file_count`, `test_plasmoid_manifest_integrity` |
| 2 | Electric Blue Wave Engine | M1 | Tier 1 | `test_plasmoid_wave_properties`, `test_plasmoid_gemini_blue` |
| 3 | Plasmoid Path Parameterization | M1 | Tier 2, Tier 3 | `test_hardcoded_path_audit`, `test_plasmoid_dynamic_toggle_call` |
| 4 | Brave Extension Assembly | M1 | Tier 1 | `test_extension_manifest_validity`, `test_extension_file_set` |
| 5 | Screen Attacher Action Pill | M1 | Tier 1, Tier 3 | `test_extension_pill_elements`, `test_extension_endpoint_screenshot` |
| 6 | Borderless Window Controls | M1 | Tier 1, Tier 3 | `test_extension_window_controls`, `test_extension_endpoint_close_max` |
| 7 | Daemon Microservice | M1 | Tier 1, Tier 3 | `test_daemon_python_syntax`, `test_daemon_routes_declaration` |
| 8 | Systemd Units | M1 | Tier 1 | `test_systemd_unit_syntax`, `test_systemd_home_specifiers` |
| 9 | KWin 6 Window Rules | M1 | Tier 1, Tier 3 | `test_kwin_rules_syntax`, `test_kwin_rules_forced_properties` |
| 10 | Overlay Toggle Script | M1 | Tier 1, Tier 3 | `test_toggle_script_syntax`, `test_toggle_script_kwin_dbus` |
| 11 | Desktop Entry & Shortcuts | M1 | Tier 1, Tier 3 | `test_desktop_entry_spec`, `test_desktop_entry_shortcut_mapping` |
| 12 | Universal Installer | M2 | Tier 1, Tier 4 | `test_installer_syntax`, `test_e2e_dry_run_install` |
| 13 | Dynamic Path Resolution | M2 | Tier 2 | `test_hardcoded_path_audit`, `test_installer_dynamic_paths` |
| 14 | Safe KWin Rules Merging | M2 | Tier 1, Tier 4 | `test_installer_kwin_merge_logic`, `test_kwin_reconfigure_call` |
| 15 | KDE Shortcut Registration | M2 | Tier 1, Tier 4 | `test_installer_shortcut_registration_logic` |
| 16 | Universal Uninstaller | M2 | Tier 1, Tier 4 | `test_uninstaller_syntax`, `test_simulated_uninstall` |
| 17 | Git Initialization | M3 | Tier 1, Tier 2 | `test_git_initialization`, `test_git_branch_main` |
| 18 | Production .gitignore | M3 | Tier 1 | `test_gitignore_existence`, `test_gitignore_exclusions` |
| 19 | Enterprise Documentation | M3 | Tier 1 | `test_readme_existence_and_sections` |
| 20 | Git Remote Setup | M3 | Tier 1 | `test_git_remote_configured` |
| 21 | E2E Testing Suite | M4 | All Tiers | `test_e2e_runner_execution_and_reporting` |
| 22 | Forensic Integrity Audit | M4 | Tier 2 | `test_hardcoded_path_audit`, `test_facade_check` |

---

## 5. Test Execution & Coverage Thresholds

### 5.1 Test Runner Interface
The test suite is driven by a single top-level command:
```bash
bash tests/e2e_test_runner.sh
```

The runner supports the following invocation modes:
- `bash tests/e2e_test_runner.sh`: Executes all tiers sequentially.
- `bash tests/e2e_test_runner.sh --tier 1`: Executes only Tier 1.
- `bash tests/e2e_test_runner.sh --tier 2`: Executes only Tier 2.
- `bash tests/e2e_test_runner.sh --tier 3`: Executes only Tier 3.
- `bash tests/e2e_test_runner.sh --tier 4`: Executes only Tier 4.
- `bash tests/e2e_test_runner.sh --verbose`: Outputs detailed test execution traces.

### 5.2 Quality Gates & Coverage Thresholds
To achieve certification in `TEST_READY.md`:
1. **Tier 1 Pass Rate**: 100% (≥45 tests passed).
2. **Tier 2 Pass Rate**: 100% (≥10 tests passed). Zero occurrences of `/home/harsha` in shipped files.
3. **Tier 3 Pass Rate**: 100% (≥8 tests passed). All cross-subsystem interface contracts verified.
4. **Tier 4 Pass Rate**: 100% (≥6 tests passed). Non-destructive dry-run workflows verified.
5. **Exit Code**: Returns strictly `0` if all required tests pass; returns non-zero (`1`) on any failure.
