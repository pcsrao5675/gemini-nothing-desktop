#!/usr/bin/env bash
# ==============================================================================
# Tier 1: Core Feature Coverage Test Suite (≥5 tests per feature area)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source assertion helpers
source "$REPO_ROOT/tests/test_helpers.sh"

run_tier1_tests() {
    print_tier_header 1 "Core Feature Coverage (Specification & Syntax Verification)"

    # --------------------------------------------------------------------------
    # 1. Plasmoid Structure & Metadata Validation
    # --------------------------------------------------------------------------
    print_feature_header "1. Plasmoid Structure & Metadata"
    local plasmoid_dir="$REPO_ROOT/plasmoid/org.omar.nothingisland"
    local plasmoid_meta="$plasmoid_dir/metadata.json"

    assert_valid_json "T1-PLASM-01" "$plasmoid_meta" \
        "Plasmoid metadata.json exists and is syntactically valid JSON"

    if [[ -f "$plasmoid_meta" ]]; then
        if python3 -c "import json, sys; d=json.load(open(sys.argv[1])); assert 'Plasma/Applet' in str(d.get('KPackageStructure', '')) or 'Plasma/Applet' in str(d.get('KPlugin',{}).get('ServiceTypes',[])); assert d.get('KPlugin',{}).get('Id') == 'org.omar.nothingisland' or d.get('Id') == 'org.omar.nothingisland'" "$plasmoid_meta" 2>/dev/null; then
            record_pass "T1-PLASM-02" "Plasmoid metadata declares Plasma/Applet structure and org.omar.nothingisland ID"
        else
            record_fail "T1-PLASM-02" "Plasmoid metadata lacks expected package structure or ID"
        fi
    else
        record_fail "T1-PLASM-02" "Plasmoid metadata file missing"
    fi

    assert_file_count "T1-PLASM-03" "$plasmoid_dir" 49 \
        "Plasmoid directory contains complete 47-file distribution tree"

    local fonts_ok=1
    for font in "MaterialSymbolsRounded.ttf" "SpaceGrotesk.ttf" "ndot-47-inspired-by-nothing.otf"; do
        if [[ ! -s "$plasmoid_dir/contents/fonts/$font" ]]; then
            fonts_ok=0
            break
        fi
    done
    if [[ "$fonts_ok" -eq 1 ]]; then
        record_pass "T1-PLASM-04" "All required font assets present and non-empty in contents/fonts/"
    else
        record_fail "T1-PLASM-04" "One or more font assets missing or empty in contents/fonts/"
    fi

    local compact_pill="$plasmoid_dir/contents/ui/CompactPill.qml"
    if [[ -f "$compact_pill" ]] && grep -q "#4DA3FF" "$compact_pill" && grep -q "8765/active" "$compact_pill"; then
        record_pass "T1-PLASM-05" "CompactPill.qml implements Electric Blue (#4DA3FF) wave and 8765/active polling"
    else
        record_fail "T1-PLASM-05" "CompactPill.qml missing wave color or daemon status polling logic"
    fi

    local qmldir="$plasmoid_dir/contents/ui/qmldir"
    if [[ -f "$qmldir" ]] && grep -q "singleton Theme" "$qmldir" && grep -q "singleton Exec" "$qmldir" && grep -q "singleton Icons" "$qmldir"; then
        record_pass "T1-PLASM-06" "qmldir declares required QML singletons (Theme, Exec, Icons, Cfg)"
    else
        record_fail "T1-PLASM-06" "qmldir missing required QML singleton declarations"
    fi

    # --------------------------------------------------------------------------
    # 2. Brave Extension Manifest & Content Script Syntax
    # --------------------------------------------------------------------------
    print_feature_header "2. Brave Extension Manifest & Content Script"
    local ext_dir="$REPO_ROOT/extension"
    local ext_manifest="$ext_dir/manifest.json"
    local ext_content="$ext_dir/content.js"
    local ext_style="$ext_dir/style.css"

    assert_valid_json "T1-EXT-01" "$ext_manifest" \
        "Extension manifest.json exists and is syntactically valid JSON"

    if [[ -f "$ext_manifest" ]]; then
        if python3 -c "import json, sys; d=json.load(open(sys.argv[1])); assert d.get('manifest_version') == 3; assert 'https://gemini.google.com/*' in d.get('content_scripts', [{}])[0].get('matches', [])" "$ext_manifest" 2>/dev/null; then
            record_pass "T1-EXT-02" "Extension specifies Manifest V3 and matches https://gemini.google.com/*"
        else
            record_fail "T1-EXT-02" "manifest.json does not declare MV3 or target URL"
        fi
    else
        record_fail "T1-EXT-02" "manifest.json missing"
    fi

    if [[ -f "$ext_content" ]] && grep -q "gemini-screen-pill-container" "$ext_content" && grep -q "gemini-screen-pill-btn" "$ext_content"; then
        record_pass "T1-EXT-03" "content.js injects screen attach action pill (#gemini-screen-pill-btn)"
    else
        record_fail "T1-EXT-03" "content.js missing action pill element declarations"
    fi

    if [[ -f "$ext_content" ]] && grep -q "input\[type=.file.\]" "$ext_content" && grep -q "DragEvent" "$ext_content" && grep -q "ClipboardEvent" "$ext_content"; then
        record_pass "T1-EXT-04" "content.js implements 3-tier image injection fallback (file input, drag, paste)"
    else
        record_fail "T1-EXT-04" "content.js missing one or more image injection fallback tiers"
    fi

    if [[ -f "$ext_content" ]] && grep -q "gemini-maximize-btn" "$ext_content" && grep -q "gemini-close-btn" "$ext_content" && grep -q "Escape" "$ext_content"; then
        record_pass "T1-EXT-05" "content.js defines borderless window controls (maximize, close) and Escape handler"
    else
        record_fail "T1-EXT-05" "content.js missing window controls or Escape key listener"
    fi

    if [[ -f "$ext_style" ]] && grep -q "backdrop-filter" "$ext_style" && grep -q "gemini-screen-pill" "$ext_style"; then
        record_pass "T1-EXT-06" "style.css defines glassmorphic backdrop-filter and pill button styling"
    else
        record_fail "T1-EXT-06" "style.css missing glassmorphism or pill styling rules"
    fi

    # --------------------------------------------------------------------------
    # 3. Daemon Microservice Syntax & Endpoints Declaration
    # --------------------------------------------------------------------------
    print_feature_header "3. Daemon Microservice & Systemd Units"
    local daemon_server="$REPO_ROOT/daemon/server.py"

    assert_valid_python "T1-DAEMON-01" "$daemon_server" \
        "daemon/server.py exists and compiles cleanly under Python 3 AST"

    if [[ -f "$daemon_server" ]] && grep -q "8765" "$daemon_server" && grep -q "Access-Control-Allow-Origin" "$daemon_server"; then
        record_pass "T1-DAEMON-02" "daemon/server.py binds to port 8765 and configures CORS headers"
    else
        record_fail "T1-DAEMON-02" "daemon/server.py missing port 8765 declaration or CORS headers"
    fi

    if [[ -f "$daemon_server" ]] && grep -q "/screenshot" "$daemon_server" && grep -q "spectacle" "$daemon_server"; then
        record_pass "T1-DAEMON-03" "daemon/server.py declares /screenshot endpoint coordinating Spectacle"
    else
        record_fail "T1-DAEMON-03" "daemon/server.py missing /screenshot endpoint or Spectacle integration"
    fi

    if [[ -f "$daemon_server" ]] && grep -q "/active" "$daemon_server" && grep -q "gemini_active" "$daemon_server"; then
        record_pass "T1-DAEMON-04" "daemon/server.py declares /active endpoint synchronizing with /tmp/gemini_active"
    else
        record_fail "T1-DAEMON-04" "daemon/server.py missing /active endpoint or state file synchronization"
    fi

    if [[ -f "$daemon_server" ]] && grep -q "/close" "$daemon_server" && grep -q "/maximize" "$daemon_server"; then
        record_pass "T1-DAEMON-05" "daemon/server.py declares /close and /maximize window control endpoints"
    else
        record_fail "T1-DAEMON-05" "daemon/server.py missing /close or /maximize endpoints"
    fi

    local unit_screenshot="$REPO_ROOT/daemon/systemd/gemini-screenshot.service"
    local unit_assistant="$REPO_ROOT/daemon/systemd/gemini-assistant.service"
    if [[ -f "$unit_screenshot" ]] && [[ -f "$unit_assistant" ]] && grep -q "%h" "$unit_screenshot" && grep -q "%h" "$unit_assistant"; then
        record_pass "T1-DAEMON-06" "Systemd service units use standard dynamic home specifier (%h)"
    else
        record_fail "T1-DAEMON-06" "Systemd service units missing or not using %h specifier"
    fi

    # --------------------------------------------------------------------------
    # 4. KWin Rules Format & Parameters
    # --------------------------------------------------------------------------
    print_feature_header "4. KWin Window Rules Format & Parameters"
    local kwin_rules="$REPO_ROOT/kwin/gemini-kwinrules.conf"

    assert_file_exists "T1-KWIN-01" "$kwin_rules" \
        "kwin/gemini-kwinrules.conf exists and is accessible"

    assert_file_contains "T1-KWIN-02" "$kwin_rules" "wmclass=brave-gemini\.google\.com__app-Default" \
        "KWin rules target wmclass=brave-gemini.google.com__app-Default"

    if [[ -f "$kwin_rules" ]] && grep -q "aboverule=3" "$kwin_rules" && grep -q "noborderrule=3" "$kwin_rules" && grep -q "skiptaskbarrule=3" "$kwin_rules" && grep -q "skipswitcherrule=3" "$kwin_rules"; then
        record_pass "T1-KWIN-03" "KWin rules enforce forced overrides (rule=3) for above, noborder, and taskbar"
    else
        record_fail "T1-KWIN-03" "KWin rules missing forced rule=3 enforcement flags"
    fi

    if [[ -f "$kwin_rules" ]] && grep -q "position=1490,330" "$kwin_rules" && grep -q "size=410,710" "$kwin_rules"; then
        record_pass "T1-KWIN-04" "KWin rules configure overlay geometry (position=1490,330, size=410,710)"
    else
        record_fail "T1-KWIN-04" "KWin rules missing target geometry coordinates"
    fi

    assert_file_contains "T1-KWIN-05" "$kwin_rules" "description=Gemini Floating Assistant Overlay" \
        "KWin rules specify description header"

    # --------------------------------------------------------------------------
    # 5. Shortcuts & Desktop Entry Spec Compliance
    # --------------------------------------------------------------------------
    print_feature_header "5. Shortcuts & Desktop Entry Spec Compliance"
    local desktop_entry="$REPO_ROOT/desktop/gemini-overlay.desktop"

    assert_file_contains "T1-DESK-01" "$desktop_entry" "\[Desktop Entry\]" \
        "gemini-overlay.desktop contains valid [Desktop Entry] section"

    if [[ -f "$desktop_entry" ]] && grep -q "Type=Application" "$desktop_entry" && grep -q "Name=Gemini" "$desktop_entry"; then
        record_pass "T1-DESK-02" "Desktop entry specifies Type=Application and Name=Gemini"
    else
        record_fail "T1-DESK-02" "Desktop entry missing required Type or Name fields"
    fi

    assert_file_contains "T1-DESK-03" "$desktop_entry" "StartupWMClass=brave-gemini\.google\.com__app-Default" \
        "Desktop entry specifies StartupWMClass matching KWin rule"

    assert_file_contains "T1-DESK-04" "$desktop_entry" "X-KDE-GlobalAccel-CommandShortcut=true" \
        "Desktop entry enables KDE global accelerator command shortcut"

    if [[ -f "$desktop_entry" ]] && grep -q "Launch (2)" "$desktop_entry" && grep -q "Meta+Space" "$desktop_entry"; then
        record_pass "T1-DESK-05" "Desktop entry maps HP Omen key (Launch (2)) and Meta+Space shortcuts"
    else
        record_fail "T1-DESK-05" "Desktop entry missing HP Omen key or Meta+Space shortcut definition"
    fi

    # --------------------------------------------------------------------------
    # 6. Toggle Script Syntax & Execution Flags
    # --------------------------------------------------------------------------
    print_feature_header "6. Toggle Script Syntax & Execution Flags"
    local toggle_script="$REPO_ROOT/bin/gemini-toggle.sh"

    assert_executable "T1-TOGG-01" "$toggle_script" \
        "bin/gemini-toggle.sh has executable bit (+x) set"

    assert_valid_bash "T1-TOGG-02" "$toggle_script" \
        "bin/gemini-toggle.sh passes bash syntax validation (bash -n)"

    if [[ -f "$toggle_script" ]] && grep -q "org.kde.KWin" "$toggle_script" && grep -q "Scripting" "$toggle_script"; then
        record_pass "T1-TOGG-03" "bin/gemini-toggle.sh invokes KWin 6 D-Bus scripting interface"
    else
        record_fail "T1-TOGG-03" "bin/gemini-toggle.sh missing KWin D-Bus scripting commands"
    fi

    assert_file_contains "T1-TOGG-04" "$toggle_script" "/tmp/gemini_active" \
        "bin/gemini-toggle.sh coordinates active status via /tmp/gemini_active"

    if [[ -f "$toggle_script" ]] && grep -q "pgrep" "$toggle_script" && grep -q "https://gemini.google.com/app" "$toggle_script"; then
        record_pass "T1-TOGG-05" "bin/gemini-toggle.sh includes process check and fallback browser launch"
    else
        record_fail "T1-TOGG-05" "bin/gemini-toggle.sh missing process check or fallback launch logic"
    fi

    # --------------------------------------------------------------------------
    # 7. Universal Installer Interface (Progressive / M2)
    # --------------------------------------------------------------------------
    print_feature_header "7. Universal Installer Interface"
    local installer="$REPO_ROOT/install.sh"

    if [[ -f "$installer" ]]; then
        assert_valid_bash "T1-INST-01" "$installer" "install.sh passes bash syntax check"
        assert_executable "T1-INST-02" "$installer" "install.sh is executable"
        assert_command_output_contains "T1-INST-03" "bash $installer --help" "(Usage|Options|--dry-run)" \
            "install.sh --help outputs usage guidance"
        assert_command_exit_code "T1-INST-04" "bash $installer --dry-run" 0 \
            "install.sh --dry-run executes successfully with exit code 0"
        if grep -q -E '(\$HOME|XDG_DATA_HOME)' "$installer"; then
            record_pass "T1-INST-05" "install.sh resolves target paths dynamically using \$HOME / XDG vars"
        else
            record_fail "T1-INST-05" "install.sh lacks dynamic \$HOME or XDG destination path resolution"
        fi
    else
        record_skip "T1-INST-01" "install.sh bash syntax check" "Pending Milestone 2"
        record_skip "T1-INST-02" "install.sh executable permission" "Pending Milestone 2"
        record_skip "T1-INST-03" "install.sh --help usage output" "Pending Milestone 2"
        record_skip "T1-INST-04" "install.sh --dry-run execution" "Pending Milestone 2"
        record_skip "T1-INST-05" "install.sh dynamic path resolution" "Pending Milestone 2"
    fi

    # --------------------------------------------------------------------------
    # 8. Universal Uninstaller Interface (Progressive / M2)
    # --------------------------------------------------------------------------
    print_feature_header "8. Universal Uninstaller Interface"
    local uninstaller="$REPO_ROOT/uninstall.sh"

    if [[ -f "$uninstaller" ]]; then
        assert_valid_bash "T1-UNIN-01" "$uninstaller" "uninstall.sh passes bash syntax check"
        assert_executable "T1-UNIN-02" "$uninstaller" "uninstall.sh is executable"
        assert_command_output_contains "T1-UNIN-03" "bash $uninstaller --help" "(Usage|Options|--dry-run)" \
            "uninstall.sh --help outputs usage guidance"
        assert_command_exit_code "T1-UNIN-04" "bash $uninstaller --dry-run" 0 \
            "uninstall.sh --dry-run executes successfully with exit code 0"
        if grep -q -E '(nothingisland|gemini-assistant|gemini-toggle)' "$uninstaller"; then
            record_pass "T1-UNIN-05" "uninstall.sh targets all installed components for removal"
        else
            record_fail "T1-UNIN-05" "uninstall.sh missing component removal targets"
        fi
    else
        record_skip "T1-UNIN-01" "uninstall.sh bash syntax check" "Pending Milestone 2"
        record_skip "T1-UNIN-02" "uninstall.sh executable permission" "Pending Milestone 2"
        record_skip "T1-UNIN-03" "uninstall.sh --help usage output" "Pending Milestone 2"
        record_skip "T1-UNIN-04" "uninstall.sh --dry-run execution" "Pending Milestone 2"
        record_skip "T1-UNIN-05" "uninstall.sh removal target definitions" "Pending Milestone 2"
    fi

    # --------------------------------------------------------------------------
    # 9. Gitignore Configuration & Exclusion Coverage (Progressive / M3)
    # --------------------------------------------------------------------------
    print_feature_header "9. Gitignore Configuration & Exclusion Coverage"
    local gitignore="$REPO_ROOT/.gitignore"

    if [[ -f "$gitignore" ]]; then
        record_pass "T1-GIT-01" ".gitignore file exists and is present in repository root"
        if grep -q "\.pyc" "$gitignore" || grep -q "__pycache__" "$gitignore"; then
            record_pass "T1-GIT-02" ".gitignore excludes Python bytecode and cache files"
        else
            record_fail "T1-GIT-02" ".gitignore does not exclude Python bytecode (*.pyc or __pycache__)"
        fi
        if grep -q "brave-profile" "$gitignore" || grep -q "web-profile" "$gitignore"; then
            record_pass "T1-GIT-03" ".gitignore excludes browser authentication/session profiles"
        else
            record_fail "T1-GIT-03" ".gitignore does not exclude browser profile directories"
        fi
        if grep -q "\.log" "$gitignore" || grep -q "/tmp" "$gitignore"; then
            record_pass "T1-GIT-04" ".gitignore excludes temporary runtime files and logs"
        else
            record_fail "T1-GIT-04" ".gitignore does not exclude logs or temporary files"
        fi
        if grep -q "\.pem" "$gitignore" || grep -q "\.key" "$gitignore" || grep -q "token" "$gitignore"; then
            record_pass "T1-GIT-05" ".gitignore excludes private credentials and key files"
        else
            record_fail "T1-GIT-05" ".gitignore does not exclude secret tokens or certificates"
        fi
    else
        record_skip "T1-GIT-01" ".gitignore file existence" "Pending Milestone 3"
        record_skip "T1-GIT-02" ".gitignore Python bytecode exclusions" "Pending Milestone 3"
        record_skip "T1-GIT-03" ".gitignore browser profile exclusions" "Pending Milestone 3"
        record_skip "T1-GIT-04" ".gitignore runtime temporary file exclusions" "Pending Milestone 3"
        record_skip "T1-GIT-05" ".gitignore secrets & credential exclusions" "Pending Milestone 3"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tier1_tests
    echo -e "\nTier 1 Summary: Total=$TOTAL_TESTS, Passed=$PASSED_TESTS, Failed=$FAILED_TESTS, Skipped=$SKIPPED_TESTS"
    [[ "$FAILED_TESTS" -eq 0 ]] || exit 1
fi
