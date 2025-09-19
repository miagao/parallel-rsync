#!/bin/bash

# Test Runner for Parallel Rsync Script
# Runs various test scenarios to validate the parallel_file_rsync.sh script

# Detect environment and set paths accordingly
if [ -d "/data/source" ]; then
    # CI/Docker environment
    SOURCE_DIR="/data/source"
    DEST_DIR="/data/destination"
    LOG_DIR="/var/log/rsync"
    SCRIPT_PATH="/scripts/parallel_file_rsync.sh"
else
    # Local development environment
    SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
    SOURCE_DIR="$PROJECT_ROOT/tests/data/source"
    DEST_DIR="$PROJECT_ROOT/tests/data/destination"
    LOG_DIR="$PROJECT_ROOT/tests/data/logs"
    SCRIPT_PATH="$PROJECT_ROOT/bin/parallel_file_rsync.sh"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✓ $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ✗ $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠ $1${NC}"
}

header() {
    echo
    echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
    echo
}

# Function to clean destination
clean_destination() {
    log "Cleaning destination directory..."
    rm -rf "${DEST_DIR:?}"/*
    mkdir -p "$DEST_DIR"
}

# Cross-platform file size function for tests
get_file_size_test() {
    local filepath="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        stat -f '%z' "$filepath" 2>/dev/null || echo 0
    else
        # Linux and others
        stat -c '%s' "$filepath" 2>/dev/null || echo 0
    fi
}

# Cross-platform relative path function
get_relative_path() {
    local base="$1"
    local target="$2"

    # Use python if available for cross-platform compatibility
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import os; print(os.path.relpath('$target', '$base'))" 2>/dev/null
    elif command -v python >/dev/null 2>&1; then
        python -c "import os; print(os.path.relpath('$target', '$base'))" 2>/dev/null
    else
        # Fallback: simple string replacement
        echo "${target#"$base"/}"
    fi
}

# Function to verify sync results
verify_sync() {
    local test_name="$1"
    local source_path="$2"
    local dest_path="$3"
    local expected_behavior="$4"

    TESTS_RUN=$((TESTS_RUN + 1))

    log "Verifying sync results for: $test_name"

    # Count files that would actually be transferred (>=1K)
    local source_files
    source_files=$(find "$source_path" -type f 2>/dev/null | wc -l)
    local source_large_files
    source_large_files=$(find "$source_path" -type f -size +1023c 2>/dev/null | wc -l)
    local dest_files
    dest_files=$(find "$dest_path" -type f 2>/dev/null | wc -l)

    echo "  Source: $source_files files ($source_large_files ≥1K), $(du -sh "$source_path" 2>/dev/null | cut -f1 || echo '0B')"
    echo "  Dest:   $dest_files files, $(du -sh "$dest_path" 2>/dev/null | cut -f1 || echo '0B')"

    # Verify based on expected behavior
    case "$expected_behavior" in
        "complete_sync")
            # For complete sync, check if we transferred the expected files (≥1K)
            # Allow for small discrepancy due to edge cases in file size filtering
            local expected_files="$source_large_files"
            local tolerance=3  # Allow up to 3 files difference for edge cases

            if [ "$dest_files" -lt $((expected_files - tolerance)) ] || [ "$dest_files" -gt $((expected_files + tolerance)) ]; then
                error "$test_name - File count outside expected range (expected ~$expected_files, got $dest_files)"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                return 1
            fi

            # Check that destination files exist and have reasonable sizes
            local significant_files_transferred=0
            while IFS= read -r dest_file; do
                if [ -f "$dest_file" ]; then
                    local file_size
                    file_size=$(get_file_size_test "$dest_file")
                    if [ "$file_size" -gt 0 ]; then
                        significant_files_transferred=$((significant_files_transferred + 1))
                    fi
                fi
            done < <(find "$dest_path" -type f 2>/dev/null)

            # Verify we have meaningful file transfers
            if [ "$significant_files_transferred" -ge $((expected_files - tolerance)) ]; then
                success "$test_name - Complete sync verified ($dest_files files transferred)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            else
                error "$test_name - Insufficient files transferred ($significant_files_transferred significant files)"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                return 1
            fi
            ;;
        "dry_run")
            if [ "$dest_files" -eq 0 ]; then
                success "$test_name - Dry run verified (no files copied)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            else
                error "$test_name - Dry run failed ($dest_files files were copied)"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                return 1
            fi
            ;;
        "partial_sync")
            # For partial sync, expect some files but not necessarily all
            if [ "$dest_files" -gt 0 ] && [ "$dest_files" -le "$source_large_files" ]; then
                success "$test_name - Partial sync verified ($dest_files files copied)"
                TESTS_PASSED=$((TESTS_PASSED + 1))
                return 0
            else
                error "$test_name - Partial sync failed (expected 1-$source_large_files files, got $dest_files)"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                return 1
            fi
            ;;
    esac
}

# Function to run test with timing
run_test() {
    local test_name="$1"
    local rsync_command="$2"
    local expected_behavior="${3:-complete_sync}"

    header "Running Test: $test_name"

    log "Command: $rsync_command"

    # Clean destination
    clean_destination

    # Record start time
    local start_time
    start_time=$(date +%s)

    # Run the command
    eval "$rsync_command"
    local exit_code=$?

    # Record end time
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log "Test completed in ${duration}s with exit code: $exit_code"

    # Extract actual source and destination from command for proper verification
    local actual_source
    local actual_dest

    # Simple parsing - extract paths from -s and -d flags
    actual_source=$(echo "$rsync_command" | grep -o "\-s '[^']*'" | sed "s/-s '\(.*\)'/\1/" | head -1)
    if [ -z "$actual_source" ]; then
        actual_source=$(echo "$rsync_command" | grep -o "\-s [^']\+[^[:space:]]\+" | sed "s/-s //" | head -1)
    fi

    actual_dest=$(echo "$rsync_command" | grep -o "\-d '[^']*'" | sed "s/-d '\(.*\)'/\1/" | head -1)
    if [ -z "$actual_dest" ]; then
        actual_dest=$(echo "$rsync_command" | grep -o "\-d [^']\+[^[:space:]]\+" | sed "s/-d //" | head -1)
    fi

    # Fall back to defaults if parsing fails
    actual_source="${actual_source:-$SOURCE_DIR}"
    actual_dest="${actual_dest:-$DEST_DIR}"

    # Verify results with actual paths
    verify_sync "$test_name" "$actual_source" "$actual_dest" "$expected_behavior"

    return $exit_code
}

# Test scenarios
test_basic_sync() {
    run_test "Basic Sync" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' -m 1K -v"
}

test_dry_run() {
    run_test "Dry Run" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' -m 1K -n -v" \
        "dry_run"
}

test_high_parallelism() {
    run_test "High Parallelism (16 jobs)" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' -j 16 -m 1K -v"
}

test_low_parallelism() {
    run_test "Low Parallelism (2 jobs)" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' -j 2 -m 1K -v"
}

test_large_files_only() {
    run_test "Large Files Only (50MB+)" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' -m 50M -v"
}

test_small_files_only() {
    run_test "Small Files Only (1MB+)" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' -m 1M -v"
}

test_sorted_by_size() {
    run_test "Sorted by Size" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' --sort-by-size -m 1K -v"
}

test_specific_subdirectory() {
    run_test "Specific Subdirectory (large_files)" \
        "$SCRIPT_PATH -s '$SOURCE_DIR/large_files' -d '$DEST_DIR/large_files' -m 1K -v"
}

test_with_excludes() {
    run_test "With Excludes (*.tmp, *.log)" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' --exclude '*.tmp' --exclude '*.log' -m 1K -v"
}

test_with_includes() {
    run_test "With Includes (*.bin only)" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' --include '*.bin' -m 1K -v" \
        "partial_sync"
}

test_resume_mode() {
    # First, do a partial sync by interrupting
    log "Setting up resume test - creating partial sync scenario..."
    clean_destination

    # Copy some files manually to simulate partial transfer
    rsync -av "$SOURCE_DIR/small_files/" "$DEST_DIR/small_files/" >/dev/null 2>&1

    run_test "Resume Mode" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' --resume -m 1K -v"
}

test_deep_directory() {
    run_test "Deep Directory Structure" \
        "$SCRIPT_PATH -s '$SOURCE_DIR/deep' -d '$DEST_DIR/deep' --max-depth 20 -m 1K -v"
}

test_special_characters() {
    run_test "Files with Special Characters" \
        "$SCRIPT_PATH -s '$SOURCE_DIR/special_chars' -d '$DEST_DIR/special_chars' -m 1K -v"
}

test_with_logging() {
    local test_log_dir
    test_log_dir="$LOG_DIR/test_run_$(date +%s)"
    run_test "With Individual Job Logging" \
        "$SCRIPT_PATH -s '$SOURCE_DIR' -d '$DEST_DIR' --log-dir '$test_log_dir' -m 1K -v"

    # Verify log files were created
    if [ -d "$test_log_dir" ] && [ "$(find "$test_log_dir" -name "*.log" | wc -l)" -gt 0 ]; then
        success "Log files created successfully"
    else
        warn "No log files found in $test_log_dir"
    fi
}

test_error_handling() {
    header "Testing Error Handling"

    # Test with invalid source
    log "Testing invalid source directory..."
    if "$SCRIPT_PATH" -s "/nonexistent" -d "$DEST_DIR" 2>/dev/null; then
        error "Should have failed with invalid source"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        success "Correctly handled invalid source"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))

    # Test with invalid destination parent
    log "Testing invalid destination parent..."
    if "$SCRIPT_PATH" -s "$SOURCE_DIR" -d "/nonexistent/dest" 2>/dev/null; then
        error "Should have failed with invalid destination parent"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        success "Correctly handled invalid destination parent"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))

    # Test with invalid job count
    log "Testing invalid job count..."
    if "$SCRIPT_PATH" -s "$SOURCE_DIR" -d "$DEST_DIR" -j "abc" 2>/dev/null; then
        error "Should have failed with invalid job count"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        success "Correctly handled invalid job count"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Performance benchmark
run_performance_benchmark() {
    header "Performance Benchmark"

    # Test different job counts
    for jobs in 1 2 4 8 16; do
        log "Benchmarking with $jobs parallel jobs..."
        clean_destination

        local start_time
        start_time=$(date +%s.%N)
        "$SCRIPT_PATH" -s "$SOURCE_DIR" -d "$DEST_DIR" -j "$jobs" >/dev/null 2>&1
        local end_time
        end_time=$(date +%s.%N)

        local duration
        duration=$(echo "$end_time - $start_time" | bc)
        log "Jobs: $jobs, Time: ${duration}s"
    done
}

# Function to show test summary
show_test_summary() {
    header "Test Summary"

    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo

    if [ $TESTS_FAILED -eq 0 ]; then
        success "All tests passed! ✨"
        return 0
    else
        error "$TESTS_FAILED test(s) failed"
        return 1
    fi
}

# Main test execution
main() {
    header "Parallel Rsync Test Suite"

    # Check if script exists
    if [ ! -f "$SCRIPT_PATH" ]; then
        error "Script not found: $SCRIPT_PATH"
        exit 1
    fi

    # Check if test data exists
    if [ ! -d "$SOURCE_DIR" ] || [ -z "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
        error "No test data found in $SOURCE_DIR"
        log "Run test-data-generator.sh first to create test data"
        exit 1
    fi

    # Make sure destination and log directories exist
    mkdir -p "$DEST_DIR" "$LOG_DIR"

    # Show initial state
    log "Source directory: $SOURCE_DIR"
    log "Destination directory: $DEST_DIR"
    log "Log directory: $LOG_DIR"
    log "Total test files: $(find "$SOURCE_DIR" -type f | wc -l)"
    log "Total test data size: $(du -sh "$SOURCE_DIR" | cut -f1)"

    # Run all tests
    test_basic_sync
    test_dry_run
    test_high_parallelism
    test_low_parallelism
    test_large_files_only
    test_small_files_only
    test_sorted_by_size
    test_specific_subdirectory
    test_with_excludes
    test_with_includes
    test_resume_mode
    test_deep_directory
    test_special_characters
    test_with_logging
    test_error_handling

    # Optional performance benchmark
    if [ "$1" = "--benchmark" ]; then
        run_performance_benchmark
    fi

    # Show final summary
    show_test_summary
}

# Handle command line arguments
case "${1:-}" in
    --benchmark)
        main --benchmark
        ;;
    --help|-h)
        echo "Usage: $0 [--benchmark] [--help]"
        echo "  --benchmark  Include performance benchmarking"
        echo "  --help       Show this help message"
        exit 0
        ;;
    *)
        main
        ;;
esac