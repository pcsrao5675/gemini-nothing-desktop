#!/usr/bin/env bash
# ==============================================================================
# Common Test Assertion & Reporting Helpers for Gemini Floating Assistant &
# Nothing OS Island E2E Test Suite
# ==============================================================================

# Enable strict mode where appropriate
set -u

# Terminal Colors
if [[ -t 1 ]] && [[ "${NO_COLOR:-0}" == "0" ]]; then
    COLOR_RED="\033[0;31m"
    COLOR_GREEN="\033[0;32m"
    COLOR_YELLOW="\033[0;33m"
    COLOR_BLUE="\033[0;34m"
    COLOR_MAGENTA="\033[0;35m"
    COLOR_CYAN="\033[0;36m"
    COLOR_BOLD="\033[1m"
    COLOR_RESET="\033[0m"
else
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_MAGENTA=""
    COLOR_CYAN=""
    COLOR_BOLD=""
    COLOR_RESET=""
fi

# Test Metrics Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Log indentation
CURRENT_TIER=""
CURRENT_FEATURE=""

print_tier_header() {
    local tier_num="$1"
    local tier_name="$2"
    CURRENT_TIER="Tier $tier_num"
    echo -e "\n${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  TIER ${tier_num}: ${tier_name}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_BLUE}════════════════════════════════════════════════════════════════════════════════${COLOR_RESET}"
}

print_feature_header() {
    local feature_name="$1"
    CURRENT_FEATURE="$feature_name"
    echo -e "\n  ${COLOR_BOLD}${COLOR_MAGENTA}▶ Feature Area: ${feature_name}${COLOR_RESET}"
}

record_pass() {
    local test_id="$1"
    local desc="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo -e "    ${COLOR_GREEN}✔ [PASS]${COLOR_RESET} [${test_id}] ${desc}"
}

record_fail() {
    local test_id="$1"
    local desc="$2"
    local detail="${3:-}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo -e "    ${COLOR_RED}✘ [FAIL]${COLOR_RESET} [${test_id}] ${desc}"
    if [[ -n "$detail" ]]; then
        echo -e "           ${COLOR_RED}↳ Detail: ${detail}${COLOR_RESET}"
    fi
}

record_skip() {
    local test_id="$1"
    local desc="$2"
    local reason="${3:-Milestone dependency pending}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
    echo -e "    ${COLOR_YELLOW}↷ [SKIP]${COLOR_RESET} [${test_id}] ${desc} (${reason})"
}

# --- Assertions ---

assert_file_exists() {
    local test_id="$1"
    local filepath="$2"
    local desc="$3"
    if [[ -f "$filepath" ]]; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "File not found: $filepath"
        return 1
    fi
}

assert_file_count() {
    local test_id="$1"
    local dirpath="$2"
    local expected_count="$3"
    local desc="$4"
    if [[ ! -d "$dirpath" ]]; then
        record_fail "$test_id" "$desc" "Directory does not exist: $dirpath"
        return 1
    fi
    local actual_count
    actual_count=$(find "$dirpath" -type f -not -path "*/__pycache__*" -not -name "*.pyc" | wc -l)
    if [[ "$actual_count" -eq "$expected_count" ]]; then
        record_pass "$test_id" "$desc (Count: $actual_count)"
        return 0
    else
        record_fail "$test_id" "$desc" "Expected $expected_count files, found $actual_count"
        return 1
    fi
}

assert_executable() {
    local test_id="$1"
    local filepath="$2"
    local desc="$3"
    if [[ -x "$filepath" ]]; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "File is not executable: $filepath"
        return 1
    fi
}

assert_valid_json() {
    local test_id="$1"
    local filepath="$2"
    local desc="$3"
    if [[ ! -f "$filepath" ]]; then
        record_fail "$test_id" "$desc" "File not found: $filepath"
        return 1
    fi
    if python3 -c "import json; json.load(open('$filepath'))" 2>/dev/null; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "Invalid JSON syntax in: $filepath"
        return 1
    fi
}

assert_valid_bash() {
    local test_id="$1"
    local filepath="$2"
    local desc="$3"
    if [[ ! -f "$filepath" ]]; then
        record_fail "$test_id" "$desc" "File not found: $filepath"
        return 1
    fi
    if bash -n "$filepath" 2>/dev/null; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "Bash syntax check failed on: $filepath"
        return 1
    fi
}

assert_valid_python() {
    local test_id="$1"
    local filepath="$2"
    local desc="$3"
    if [[ ! -f "$filepath" ]]; then
        record_fail "$test_id" "$desc" "File not found: $filepath"
        return 1
    fi
    if python3 -m py_compile "$filepath" 2>/dev/null; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "Python compilation/syntax check failed on: $filepath"
        return 1
    fi
}

assert_file_contains() {
    local test_id="$1"
    local filepath="$2"
    local pattern="$3"
    local desc="$4"
    if [[ ! -f "$filepath" ]]; then
        record_fail "$test_id" "$desc" "File not found: $filepath"
        return 1
    fi
    if grep -q -E "$pattern" "$filepath" 2>/dev/null; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "Pattern '$pattern' not found in: $filepath"
        return 1
    fi
}

assert_file_not_contains() {
    local test_id="$1"
    local filepath="$2"
    local pattern="$3"
    local desc="$4"
    if [[ ! -f "$filepath" ]]; then
        record_fail "$test_id" "$desc" "File not found: $filepath"
        return 1
    fi
    if ! grep -q -E "$pattern" "$filepath" 2>/dev/null; then
        record_pass "$test_id" "$desc"
        return 0
    else
        local match
        match=$(grep -n -E "$pattern" "$filepath" | head -n 1)
        record_fail "$test_id" "$desc" "Forbidden pattern '$pattern' found in: $filepath ($match)"
        return 1
    fi
}

assert_command_exit_code() {
    local test_id="$1"
    local cmd="$2"
    local expected_code="$3"
    local desc="$4"
    local actual_code=0
    eval "$cmd" >/dev/null 2>&1 || actual_code=$?
    if [[ "$actual_code" -eq "$expected_code" ]]; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "Command '$cmd' returned exit code $actual_code, expected $expected_code"
        return 1
    fi
}

assert_command_output_contains() {
    local test_id="$1"
    local cmd="$2"
    local pattern="$3"
    local desc="$4"
    local output
    output=$(eval "$cmd" 2>&1 || true)
    if echo "$output" | grep -q -E "$pattern"; then
        record_pass "$test_id" "$desc"
        return 0
    else
        record_fail "$test_id" "$desc" "Output of '$cmd' did not match pattern '$pattern'"
        return 1
    fi
}

export -f print_tier_header print_feature_header record_pass record_fail record_skip
export -f assert_file_exists assert_file_count assert_executable assert_valid_json
export -f assert_valid_bash assert_valid_python assert_file_contains assert_file_not_contains
export -f assert_command_exit_code assert_command_output_contains
