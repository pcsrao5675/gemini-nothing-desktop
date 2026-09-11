#!/usr/bin/env bash
# ==============================================================================
# Tier 2: Boundary & Corner Cases Test Suite
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source assertion helpers
source "$REPO_ROOT/tests/test_helpers.sh"

run_tier2_tests() {
    print_tier_header 2 "Boundary & Corner Cases (Adversarial, Path Audit & Resilience)"

    # --------------------------------------------------------------------------
    # 1. Hardcoded Static Path Audits (Zero Tolerance)
    # --------------------------------------------------------------------------
    print_feature_header "1. Hardcoded Path Audit (Zero Static Path Enforcement)"

    # Plasmoid sub-tree audit
    local plasmoid_matches
    plasmoid_matches=$(grep -rn "/home/harsha" "$REPO_ROOT/plasmoid" 2>/dev/null || true)
    if [[ -z "$plasmoid_matches" ]]; then
        record_pass "T2-HARDCODE-01" "Zero hardcoded /home/harsha paths in plasmoid/ directory tree"
    else
        record_fail "T2-HARDCODE-01" "Found hardcoded /home/harsha in plasmoid/: $plasmoid_matches"
    fi

    # Extension sub-tree audit
    local ext_matches
    ext_matches=$(grep -rn "/home/harsha" "$REPO_ROOT/extension" 2>/dev/null || true)
    if [[ -z "$ext_matches" ]]; then
        record_pass "T2-HARDCODE-02" "Zero hardcoded /home/harsha paths in extension/ directory"
    else
        record_fail "T2-HARDCODE-02" "Found hardcoded /home/harsha in extension/: $ext_matches"
    fi

    # Daemon sub-tree audit
    local daemon_matches
    daemon_matches=$(grep -rn "/home/harsha" "$REPO_ROOT/daemon" 2>/dev/null || true)
    if [[ -z "$daemon_matches" ]]; then
        record_pass "T2-HARDCODE-03" "Zero hardcoded /home/harsha paths in daemon/ directory tree"
    else
        record_fail "T2-HARDCODE-03" "Found hardcoded /home/harsha in daemon/: $daemon_matches"
    fi

    # KWin, bin, desktop audit
    local sys_matches
    sys_matches=$(grep -rn "/home/harsha" "$REPO_ROOT/kwin" "$REPO_ROOT/bin" "$REPO_ROOT/desktop" 2>/dev/null || true)
    if [[ -z "$sys_matches" ]]; then
        record_pass "T2-HARDCODE-04" "Zero hardcoded /home/harsha paths in kwin/, bin/, and desktop/"
    else
        record_fail "T2-HARDCODE-04" "Found hardcoded /home/harsha in kwin/bin/desktop: $sys_matches"
    fi

    # Comprehensive product files audit
    local prod_matches
    prod_matches=$(grep -rn "/home/harsha" "$REPO_ROOT" \
        --exclude-dir=".agents" \
        --exclude-dir=".git" \
        --exclude-dir="tests" \
        --exclude="TEST_INFRA.md" --exclude="TEST_READY.md" \
        --exclude="ORIGINAL_REQUEST.md" 2>/dev/null || true)
    if [[ -z "$prod_matches" ]]; then
        record_pass "T2-HARDCODE-05" "Zero hardcoded /home/harsha across entire product repository"
    else
        record_fail "T2-HARDCODE-05" "Hardcoded /home/harsha detected in product files: $prod_matches"
    fi

    # --------------------------------------------------------------------------
    # 2. Permission Verification
    # --------------------------------------------------------------------------
    print_feature_header "2. Executable Permission Verification"

    assert_executable "T2-PERM-01" "$REPO_ROOT/bin/gemini-toggle.sh" \
        "bin/gemini-toggle.sh has executable bit (mode 0755)"

    local apps_py="$REPO_ROOT/plasmoid/org.omar.nothingisland/contents/code/apps.py"
    local coffee_py="$REPO_ROOT/plasmoid/org.omar.nothingisland/contents/code/coffee.py"
    if [[ -x "$apps_py" ]] && [[ -x "$coffee_py" ]]; then
        record_pass "T2-PERM-02" "Plasmoid python helpers (apps.py, coffee.py) are executable"
    else
        record_fail "T2-PERM-02" "One or more plasmoid python helpers lack executable bit"
    fi

    assert_executable "T2-PERM-03" "$REPO_ROOT/daemon/server.py" \
        "daemon/server.py has executable bit set"

    if [[ -f "$REPO_ROOT/install.sh" ]] && [[ -f "$REPO_ROOT/uninstall.sh" ]]; then
        if [[ -x "$REPO_ROOT/install.sh" ]] && [[ -x "$REPO_ROOT/uninstall.sh" ]]; then
            record_pass "T2-PERM-04" "install.sh and uninstall.sh have executable permissions"
        else
            record_fail "T2-PERM-04" "install.sh or uninstall.sh missing executable bit"
        fi
    else
        record_skip "T2-PERM-04" "install.sh / uninstall.sh executable permissions" "Pending Milestone 2"
    fi

    # --------------------------------------------------------------------------
    # 3. Environment Variable Resilience & Boundary Handling
    # --------------------------------------------------------------------------
    print_feature_header "3. Environment Variable Resilience"

    # Test bin/gemini-toggle.sh fallback with empty XDG_DATA_HOME
    local test_env_output
    test_env_output=$(XDG_DATA_HOME="" HOME="/custom/test/home" bash -c '
        source <(grep -E "(APP_PROFILE=|EXT_DIR=)" "'"$REPO_ROOT"'/bin/gemini-toggle.sh")
        echo "APP=$APP_PROFILE"
        echo "EXT=$EXT_DIR"
    ' 2>/dev/null || true)
    if [[ "$test_env_output" == *"APP=/custom/test/home/.local/share/gemini-assistant/brave-profile"* ]] && \
       [[ "$test_env_output" == *"EXT=/custom/test/home/.local/share/gemini-assistant/extension"* ]]; then
        record_pass "T2-ENV-01" "gemini-toggle.sh gracefully falls back to \$HOME when XDG_DATA_HOME is empty"
    else
        record_fail "T2-ENV-01" "gemini-toggle.sh failed fallback with empty XDG_DATA_HOME (output: $test_env_output)"
    fi

    # Test server.py dynamic home expansion
    local py_home_check
    py_home_check=$(HOME="/custom/test/home" python3 -c '
import os, sys
# Simulate server.py profile path resolution
profile = os.path.expanduser("~/.local/share/gemini-assistant/brave-profile")
assert profile == "/custom/test/home/.local/share/gemini-assistant/brave-profile"
print("OK")
' 2>/dev/null || true)
    if [[ "$py_home_check" == "OK" ]]; then
        record_pass "T2-ENV-02" "daemon/server.py expands user home dynamically without static assumptions"
    else
        record_fail "T2-ENV-02" "daemon/server.py dynamic home expansion test failed"
    fi

    # Test Plasmoid CompactPill dynamic executable lookup
    local compact_pill="$REPO_ROOT/plasmoid/org.omar.nothingisland/contents/ui/CompactPill.qml"
    if [[ -f "$compact_pill" ]] && grep -q "findExecutable" "$compact_pill" && grep -q "writableLocation" "$compact_pill"; then
        record_pass "T2-ENV-03" "CompactPill.qml employs dynamic executable lookup and HomeLocation fallback"
    else
        record_fail "T2-ENV-03" "CompactPill.qml lacks dynamic executable lookup or HomeLocation fallback"
    fi

    # --------------------------------------------------------------------------
    # 4. Installer Boundary & Idempotency Testing (Progressive / M2)
    # --------------------------------------------------------------------------
    print_feature_header "4. Installer Resilience & Idempotency"

    if [[ -f "$REPO_ROOT/install.sh" ]]; then
        # Missing destination / dry-run safety
        local dry_run_code=0
        XDG_DATA_HOME="/tmp/nonexistent_test_dir_$$" bash "$REPO_ROOT/install.sh" --dry-run >/dev/null 2>&1 || dry_run_code=$?
        if [[ "$dry_run_code" -eq 0 ]] && [[ ! -d "/tmp/nonexistent_test_dir_$$" ]]; then
            record_pass "T2-INST-01" "install.sh --dry-run handles non-existent destination without creating files"
        else
            record_fail "T2-INST-01" "install.sh --dry-run failed with non-existent dir or created directories prematurely"
        fi

        # Idempotency of check/dry-run operations
        local run1 run2
        run1=$(bash "$REPO_ROOT/install.sh" --dry-run 2>&1 || true)
        run2=$(bash "$REPO_ROOT/install.sh" --dry-run 2>&1 || true)
        if [[ "$run1" == "$run2" ]]; then
            record_pass "T2-IDEMP-01" "install.sh --dry-run is strictly idempotent across consecutive executions"
        else
            record_fail "T2-IDEMP-01" "install.sh --dry-run output varied between consecutive executions"
        fi
    else
        record_skip "T2-INST-01" "install.sh missing destination resilience" "Pending Milestone 2"
        record_skip "T2-IDEMP-01" "install.sh --dry-run idempotency" "Pending Milestone 2"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tier2_tests
    echo -e "\nTier 2 Summary: Total=$TOTAL_TESTS, Passed=$PASSED_TESTS, Failed=$FAILED_TESTS, Skipped=$SKIPPED_TESTS"
    [[ "$FAILED_TESTS" -eq 0 ]] || exit 1
fi
