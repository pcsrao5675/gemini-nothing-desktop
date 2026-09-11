#!/usr/bin/env bash
# ==============================================================================
# Gemini Floating Assistant & Nothing OS Island Desktop Customization Suite
# Comprehensive End-to-End Automated Test Runner (Tiers 1-4)
# ==============================================================================

set -u

readonly TEST_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$TEST_RUNNER_DIR/.." && pwd)"

# Source test helpers for colors and formatting
source "$TEST_RUNNER_DIR/test_helpers.sh"

GLOBAL_TOTAL=0
GLOBAL_PASSED=0
GLOBAL_FAILED=0
GLOBAL_SKIPPED=0

TARGET_TIER="all"
VERBOSE_MODE=0

show_help() {
    cat << USAGE
Usage: $0 [OPTIONS]

Comprehensive E2E Test Runner for Gemini Floating Assistant & Nothing OS Island suite.

Options:
  --tier <1|2|3|4|all>   Run specific test tier (default: all)
  --verbose              Display verbose test diagnostics
  --no-color             Disable ANSI color output
  -h, --help             Show this help message and exit

Tiers:
  Tier 1: Core Feature Coverage (Plasmoid, Extension, Daemon, KWin, Shortcuts, Scripts)
  Tier 2: Boundary & Corner Cases (Hardcoded path audit, permissions, env resilience)
  Tier 3: Cross-Feature Integration (Subsystem contracts, REST & DBus consistency)
  Tier 4: Real-World Scenarios (Manifest integrity, dry-run workflows, simulated life-cycle)

Exit status:
  0 if all run tests pass with zero failures.
  1 if any test fails.
USAGE
}

# Parse CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tier)
            TARGET_TIER="${2:-all}"
            shift 2
            ;;
        --verbose)
            VERBOSE_MODE=1
            shift
            ;;
        --no-color)
            export NO_COLOR=1
            source "$TEST_RUNNER_DIR/test_helpers.sh"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

print_suite_banner() {
    echo -e "${COLOR_BOLD}${COLOR_CYAN}"
    echo "================================================================================"
    echo "  GEMINI FLOATING ASSISTANT & NOTHING OS ISLAND SUITE — E2E TEST RUNNER"
    echo "================================================================================"
    echo -e "${COLOR_RESET}"
    echo "Repository Root : $REPO_ROOT"
    echo "Target Scope    : Tier $TARGET_TIER"
    echo "Timestamp       : $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}

run_tier() {
    local tier_num="$1"
    local tier_pattern="$TEST_RUNNER_DIR/test_cases/tier${tier_num}_*.sh"
    local resolved_script
    resolved_script=$(ls $tier_pattern 2>/dev/null | head -n 1)

    if [[ -z "$resolved_script" ]] || [[ ! -f "$resolved_script" ]]; then
        echo -e "${COLOR_RED}Error: Test script for Tier $tier_num not found!${COLOR_RESET}"
        GLOBAL_FAILED=$((GLOBAL_FAILED + 1))
        return 1
    fi

    # Run the tier script and capture both display output and return code
    local tier_output tier_exit=0
    # Execute directly so formatted streaming output is shown in real time
    local temp_out
    temp_out=$(mktemp)

    bash "$resolved_script" 2>&1 | tee "$temp_out"
    tier_exit=${PIPESTATUS[0]}

    # Parse summary metrics from output
    local summary_line
    summary_line=$(grep "Tier ${tier_num} Summary:" "$temp_out" | tail -n 1)

    if [[ -n "$summary_line" ]]; then
        local t_total t_pass t_fail t_skip
        t_total=$(echo "$summary_line" | grep -o 'Total=[0-9]*' | cut -d= -f2)
        t_pass=$(echo "$summary_line" | grep -o 'Passed=[0-9]*' | cut -d= -f2)
        t_fail=$(echo "$summary_line" | grep -o 'Failed=[0-9]*' | cut -d= -f2)
        t_skip=$(echo "$summary_line" | grep -o 'Skipped=[0-9]*' | cut -d= -f2)

        GLOBAL_TOTAL=$((GLOBAL_TOTAL + t_total))
        GLOBAL_PASSED=$((GLOBAL_PASSED + t_pass))
        GLOBAL_FAILED=$((GLOBAL_FAILED + t_fail))
        GLOBAL_SKIPPED=$((GLOBAL_SKIPPED + t_skip))
    else
        if [[ "$tier_exit" -ne 0 ]]; then
            GLOBAL_FAILED=$((GLOBAL_FAILED + 1))
        fi
    fi

    rm -f "$temp_out"
    return "$tier_exit"
}

print_final_summary() {
    echo -e "\n${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_BOLD}  FINAL TEST SUITE EXECUTION SUMMARY${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "  Total Assertions    : ${COLOR_BOLD}${GLOBAL_TOTAL}${COLOR_RESET}"
    echo -e "  Passed Assertions   : ${COLOR_GREEN}${COLOR_BOLD}${GLOBAL_PASSED}${COLOR_RESET}"
    echo -e "  Failed Assertions   : ${COLOR_RED}${COLOR_BOLD}${GLOBAL_FAILED}${COLOR_RESET}"
    echo -e "  Skipped / Pending   : ${COLOR_YELLOW}${COLOR_BOLD}${GLOBAL_SKIPPED}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}────────────────────────────────────────────────────────────────────────────────${COLOR_RESET}"

    if [[ "$GLOBAL_FAILED" -eq 0 ]]; then
        echo -e "  Overall Status      : ${COLOR_GREEN}${COLOR_BOLD}PASS (ALL ACTIVE TESTS PASSED)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}\n"
        return 0
    else
        echo -e "  Overall Status      : ${COLOR_RED}${COLOR_BOLD}FAIL ($GLOBAL_FAILED FAILURES DETECTED)${COLOR_RESET}"
        echo -e "${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}\n"
        return 1
    fi
}

# Main Execution
print_suite_banner

case "$TARGET_TIER" in
    1)
        run_tier 1
        ;;
    2)
        run_tier 2
        ;;
    3)
        run_tier 3
        ;;
    4)
        run_tier 4
        ;;
    all|ALL)
        run_tier 1
        run_tier 2
        run_tier 3
        run_tier 4
        ;;
    *)
        echo -e "${COLOR_RED}Invalid tier target: $TARGET_TIER. Choose 1, 2, 3, 4, or all.${COLOR_RESET}"
        exit 1
        ;;
esac

print_final_summary
