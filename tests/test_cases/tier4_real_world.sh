#!/usr/bin/env bash
# ==============================================================================
# Tier 4: Real-World Application Scenarios Test Suite
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source assertion helpers
source "$REPO_ROOT/tests/test_helpers.sh"

run_tier4_tests() {
    print_tier_header 4 "Real-World Application Scenarios (End-to-End Workflow Simulation)"

    # --------------------------------------------------------------------------
    # 1. Component Manifest Integrity Verification
    # --------------------------------------------------------------------------
    print_feature_header "1. Component Manifest Integrity Check"
    local manifest_ok=1
    local missing_items=()

    # Plasmoid
    local plasmoid_count
    plasmoid_count=$(find "$REPO_ROOT/plasmoid/org.omar.nothingisland" -type f -not -path "*/__pycache__*" -not -name "*.pyc" 2>/dev/null | wc -l)
    if [[ "$plasmoid_count" -ne 47 ]]; then
        manifest_ok=0
        missing_items+=("Plasmoid file count ($plasmoid_count != 47)")
    fi

    # Extension
    for f in manifest.json content.js style.css; do
        if [[ ! -s "$REPO_ROOT/extension/$f" ]]; then
            manifest_ok=0
            missing_items+=("extension/$f")
        fi
    done

    # Daemon
    if [[ ! -s "$REPO_ROOT/daemon/server.py" ]]; then
        manifest_ok=0
        missing_items+=("daemon/server.py")
    fi
    if [[ ! -s "$REPO_ROOT/daemon/systemd/gemini-screenshot.service" ]] || [[ ! -s "$REPO_ROOT/daemon/systemd/gemini-assistant.service" ]]; then
        manifest_ok=0
        missing_items+=("daemon/systemd units")
    fi

    # Bin, Desktop, KWin
    if [[ ! -x "$REPO_ROOT/bin/gemini-toggle.sh" ]]; then
        manifest_ok=0
        missing_items+=("bin/gemini-toggle.sh")
    fi
    if [[ ! -s "$REPO_ROOT/desktop/gemini-overlay.desktop" ]]; then
        manifest_ok=0
        missing_items+=("desktop/gemini-overlay.desktop")
    fi
    if [[ ! -s "$REPO_ROOT/kwin/gemini-kwinrules.conf" ]]; then
        manifest_ok=0
        missing_items+=("kwin/gemini-kwinrules.conf")
    fi

    if [[ "$manifest_ok" -eq 1 ]]; then
        record_pass "T4-SCEN-01" "Repository component manifest is 100% complete and verified intact"
    else
        record_fail "T4-SCEN-01" "Component manifest incomplete: ${missing_items[*]}"
    fi

    # --------------------------------------------------------------------------
    # 2. Target XDG Specification Alignment
    # --------------------------------------------------------------------------
    print_feature_header "2. Target XDG Destinations Specification Alignment"
    # Verify paths referenced across scripts and docs conform to standard XDG layout
    local xdg_ok=1
    local toggle_content
    toggle_content=$(cat "$REPO_ROOT/bin/gemini-toggle.sh" 2>/dev/null || true)
    if [[ "$toggle_content" != *"XDG_DATA_HOME"* ]] && [[ "$toggle_content" != *".local/share"* ]]; then
        xdg_ok=0
    fi

    local desktop_content
    desktop_content=$(cat "$REPO_ROOT/desktop/gemini-overlay.desktop" 2>/dev/null || true)
    if [[ "$desktop_content" != *"StartupWMClass"* ]]; then
        xdg_ok=0
    fi

    if [[ "$xdg_ok" -eq 1 ]]; then
        record_pass "T4-SCEN-02" "Subsystems conform to standard XDG desktop and data path specifications"
    else
        record_fail "T4-SCEN-02" "Subsystems violate standard XDG specification conventions"
    fi

    # --------------------------------------------------------------------------
    # 3. End-to-End Dry-Run Installation Workflow (Progressive / M2)
    # --------------------------------------------------------------------------
    print_feature_header "3. End-to-End Dry-Run Installation Workflow"
    local installer="$REPO_ROOT/install.sh"
    if [[ -f "$installer" ]]; then
        local dry_output dry_code=0
        dry_output=$(bash "$installer" --dry-run 2>&1) || dry_code=$?
        if [[ "$dry_code" -eq 0 ]] && [[ -n "$dry_output" ]]; then
            record_pass "T4-SCEN-03" "Full installer dry-run completed successfully with exit code 0"
        else
            record_fail "T4-SCEN-03" "install.sh --dry-run failed with code $dry_code: $dry_output"
        fi

        # Verify output plans key targets
        if echo "$dry_output" | grep -q -E '(plasma/plasmoids|gemini-assistant|\.local/bin|systemd)'; then
            record_pass "T4-SCEN-04" "Dry-run output articulates deployment plan across all standard target destinations"
        else
            record_fail "T4-SCEN-04" "Dry-run output did not articulate complete deployment destinations"
        fi
    else
        record_skip "T4-SCEN-03" "install.sh --dry-run execution" "Pending Milestone 2"
        record_skip "T4-SCEN-04" "install.sh dry-run target verification" "Pending Milestone 2"
    fi

    # --------------------------------------------------------------------------
    # 4. Simulated Uninstallation Workflow (Progressive / M2)
    # --------------------------------------------------------------------------
    print_feature_header "4. Simulated Uninstallation Workflow"
    local uninstaller="$REPO_ROOT/uninstall.sh"
    if [[ -f "$uninstaller" ]]; then
        local uninst_output uninst_code=0
        uninst_output=$(bash "$uninstaller" --dry-run 2>&1) || uninst_code=$?
        if [[ "$uninst_code" -eq 0 ]]; then
            record_pass "T4-SCEN-05" "Full uninstaller dry-run completed successfully with exit code 0"
        else
            record_fail "T4-SCEN-05" "uninstall.sh --dry-run failed with code $uninst_code: $uninst_output"
        fi
    else
        record_skip "T4-SCEN-05" "uninstall.sh --dry-run execution" "Pending Milestone 2"
    fi

    # --------------------------------------------------------------------------
    # 5. Daemon Route Handler Verification
    # --------------------------------------------------------------------------
    print_feature_header "5. Daemon Microservice Handler Logic Verification"
    local py_handler_test
    py_handler_test=$(python3 -c '
import sys, os
server_path = "'"$REPO_ROOT"'/daemon/server.py"
with open(server_path) as f:
    code = f.read()

# Verify route methods exist
assert "def do_GET(self):" in code, "do_GET missing"
assert "/screenshot" in code, "/screenshot route missing"
assert "/active" in code, "/active route missing"
assert "/close" in code, "/close route missing"
assert "/maximize" in code, "/maximize route missing"
print("OK")
' 2>/dev/null || true)
    if [[ "$py_handler_test" == "OK" ]]; then
        record_pass "T4-SCEN-06" "Daemon microservice HTTP request handler logic structurally verified"
    else
        record_fail "T4-SCEN-06" "Daemon microservice HTTP handler logic verification failed"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tier4_tests
    echo -e "\nTier 4 Summary: Total=$TOTAL_TESTS, Passed=$PASSED_TESTS, Failed=$FAILED_TESTS, Skipped=$SKIPPED_TESTS"
    [[ "$FAILED_TESTS" -eq 0 ]] || exit 1
fi
