#!/usr/bin/env bash
# ==============================================================================
# Tier 3: Cross-Feature Integration Test Suite
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source assertion helpers
source "$REPO_ROOT/tests/test_helpers.sh"

run_tier3_tests() {
    print_tier_header 3 "Cross-Feature Integration (Subsystem Contracts & Pairwise Compatibility)"

    # --------------------------------------------------------------------------
    # 1. Desktop Entry ↔ Toggle Script Integration
    # --------------------------------------------------------------------------
    print_feature_header "1. Desktop Entry ↔ Toggle Script Contract"
    local desktop_file="$REPO_ROOT/desktop/gemini-overlay.desktop"
    local toggle_file="$REPO_ROOT/bin/gemini-toggle.sh"

    if [[ -f "$desktop_file" ]] && [[ -f "$toggle_file" ]]; then
        local exec_line
        exec_line=$(grep "^Exec=" "$desktop_file" | head -n 1)
        if [[ "$exec_line" == *"gemini-toggle.sh"* ]]; then
            record_pass "T3-CROSS-01" "desktop/gemini-overlay.desktop Exec command maps to gemini-toggle.sh"
        else
            record_fail "T3-CROSS-01" "desktop Exec command does not reference gemini-toggle.sh ($exec_line)"
        fi
    else
        record_fail "T3-CROSS-01" "desktop/gemini-overlay.desktop or bin/gemini-toggle.sh missing"
    fi

    # --------------------------------------------------------------------------
    # 2. Plasmoid CompactPill ↔ Toggle Script Invocation Contract
    # --------------------------------------------------------------------------
    print_feature_header "2. Plasmoid ↔ Toggle Script Contract"
    local compact_pill="$REPO_ROOT/plasmoid/org.omar.nothingisland/contents/ui/CompactPill.qml"

    if [[ -f "$compact_pill" ]]; then
        if grep -q "gemini-toggle\.sh" "$compact_pill" && ! grep -q "/home/harsha" "$compact_pill"; then
            record_pass "T3-CROSS-02" "CompactPill.qml invokes gemini-toggle.sh dynamically without hardcoded path"
        else
            record_fail "T3-CROSS-02" "CompactPill.qml missing dynamic gemini-toggle.sh execution or contains hardcoded path"
        fi
    else
        record_fail "T3-CROSS-02" "CompactPill.qml missing"
    fi

    # --------------------------------------------------------------------------
    # 3. Extension Endpoints ↔ Daemon Routes Contract
    # --------------------------------------------------------------------------
    print_feature_header "3. Extension ↔ Daemon REST Contract"
    local ext_content="$REPO_ROOT/extension/content.js"
    local daemon_server="$REPO_ROOT/daemon/server.py"

    if [[ -f "$ext_content" ]] && [[ -f "$daemon_server" ]]; then
        # Check /screenshot endpoint contract
        if grep -q "127\.0\.0\.1:8765/screenshot" "$ext_content" && grep -q '"/screenshot"' "$daemon_server"; then
            record_pass "T3-CROSS-03" "Extension screenshot request contracts with daemon /screenshot route"
        else
            record_fail "T3-CROSS-03" "Mismatch between extension screenshot request and daemon /screenshot route"
        fi

        # Check /active endpoint contract
        if grep -q "127\.0\.0\.1:8765/active" "$ext_content" && grep -q '"/active"' "$daemon_server"; then
            record_pass "T3-CROSS-04" "Extension /active status reporting contracts with daemon /active route"
        else
            record_fail "T3-CROSS-04" "Mismatch between extension /active reporting and daemon /active route"
        fi

        # Check /close and /maximize endpoints contract
        if grep -q "127\.0\.0\.1:8765/close" "$ext_content" && grep -q '"/close"' "$daemon_server" && \
           grep -q "127\.0\.0\.1:8765/maximize" "$ext_content" && grep -q '"/maximize"' "$daemon_server"; then
            record_pass "T3-CROSS-05" "Extension window controls contract with daemon /close and /maximize routes"
        else
            record_fail "T3-CROSS-05" "Mismatch between extension window controls and daemon window routes"
        fi
    else
        record_fail "T3-CROSS-03" "content.js or daemon/server.py missing"
        record_fail "T3-CROSS-04" "content.js or daemon/server.py missing"
        record_fail "T3-CROSS-05" "content.js or daemon/server.py missing"
    fi

    # --------------------------------------------------------------------------
    # 4. Toggle Script ↔ Daemon Active State Synchronization
    # --------------------------------------------------------------------------
    print_feature_header "4. Toggle Script ↔ Daemon Active State Contract"
    if [[ -f "$toggle_file" ]] && [[ -f "$daemon_server" ]]; then
        if grep -q "/tmp/gemini_active" "$toggle_file" && grep -q "/tmp/gemini_active" "$daemon_server"; then
            record_pass "T3-CROSS-06" "Toggle script and daemon share identical state contract via /tmp/gemini_active"
        else
            record_fail "T3-CROSS-06" "State file contract mismatch between toggle script and daemon"
        fi
    else
        record_fail "T3-CROSS-06" "Toggle script or daemon missing"
    fi

    # --------------------------------------------------------------------------
    # 5. Toggle Script ↔ KWin 6 D-Bus Interface Contract
    # --------------------------------------------------------------------------
    print_feature_header "5. Toggle Script ↔ KWin 6 D-Bus Contract"
    if [[ -f "$toggle_file" ]] && [[ -f "$daemon_server" ]]; then
        if grep -q "org\.kde\.KWin" "$toggle_file" && grep -q "org\.kde\.kwin\.Scripting" "$toggle_file" && \
           grep -q "org\.kde\.KWin" "$daemon_server" && grep -q "org\.kde\.kwin\.Scripting" "$daemon_server"; then
            record_pass "T3-CROSS-07" "Toggle script and daemon employ consistent KWin 6 Scripting D-Bus contracts"
        else
            record_fail "T3-CROSS-07" "Inconsistent KWin D-Bus interface invocation across toggle script and daemon"
        fi
    else
        record_fail "T3-CROSS-07" "Toggle script or daemon missing"
    fi

    # --------------------------------------------------------------------------
    # 6. KWin Rules ↔ Desktop WMClass Contract
    # --------------------------------------------------------------------------
    print_feature_header "6. KWin Rules ↔ Desktop WMClass Contract"
    local kwin_rules="$REPO_ROOT/kwin/gemini-kwinrules.conf"
    if [[ -f "$kwin_rules" ]] && [[ -f "$desktop_file" ]]; then
        local kwin_wmclass desk_wmclass
        kwin_wmclass=$(grep "^wmclass=" "$kwin_rules" | cut -d= -f2)
        desk_wmclass=$(grep "^StartupWMClass=" "$desktop_file" | cut -d= -f2)
        if [[ -n "$kwin_wmclass" ]] && [[ "$kwin_wmclass" == "$desk_wmclass" ]]; then
            record_pass "T3-CROSS-08" "KWin rules wmclass exactly matches desktop StartupWMClass ($kwin_wmclass)"
        else
            record_fail "T3-CROSS-08" "WMClass mismatch: KWin='$kwin_wmclass' vs Desktop='$desk_wmclass'"
        fi
    else
        record_fail "T3-CROSS-08" "KWin rules or desktop file missing"
    fi

    # --------------------------------------------------------------------------
    # 7. URL Route Consistency
    # --------------------------------------------------------------------------
    print_feature_header "7. Application URL Consistency"
    local ext_manifest="$REPO_ROOT/extension/manifest.json"
    if [[ -f "$ext_manifest" ]] && [[ -f "$toggle_file" ]]; then
        if grep -q "https://gemini.google.com" "$ext_manifest" && grep -q "https://gemini.google.com" "$toggle_file"; then
            record_pass "T3-CROSS-09" "Extension manifest match pattern aligns with toggle script application URL"
        else
            record_fail "T3-CROSS-09" "Inconsistent application URL across extension manifest and toggle script"
        fi
    else
        record_fail "T3-CROSS-09" "Extension manifest or toggle script missing"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tier3_tests
    echo -e "\nTier 3 Summary: Total=$TOTAL_TESTS, Passed=$PASSED_TESTS, Failed=$FAILED_TESTS, Skipped=$SKIPPED_TESTS"
    [[ "$FAILED_TESTS" -eq 0 ]] || exit 1
fi
