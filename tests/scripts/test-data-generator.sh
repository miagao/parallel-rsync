#!/bin/bash

# Test Data Generator for Parallel Rsync Testing
# Generates various file sizes and structures for comprehensive testing

DATA_DIR="/data/source"
VERBOSE=false
FAST_MODE=false

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] $1${NC}"
}

# Function to create a file of specific size
create_file() {
    local filepath="$1"
    local size="$2"
    local content_type="${3:-random}"

    mkdir -p "$(dirname "$filepath")"

    case $content_type in
        "text")
            # Create text file with repeated content
            local text="This is test data for parallel rsync testing. Line number: "
            local temp_file
            temp_file="/tmp/test_data_$$_$(basename "$filepath")"
            {
                local i=1
                local current_size=0
                while [ "$current_size" -lt "$size" ]; do
                    echo "${text}${i}"
                    i=$((i + 1))
                    # Check size periodically to avoid infinite loops
                    if [ $((i % 100)) -eq 0 ]; then
                        current_size=$(stat -c%s "$temp_file" 2>/dev/null || echo 0)
                    fi
                done
            } > "$temp_file"
            # Truncate to exact size and move to final location
            truncate -s "$size" "$temp_file"
            mv "$temp_file" "$filepath"
            ;;
        "zeros")
            # Create file filled with zeros
            dd if=/dev/zero of="$filepath" bs=1024 count=$((size / 1024)) 2>/dev/null
            ;;
        "random")
            # Create file with random data
            dd if=/dev/urandom of="$filepath" bs=1024 count=$((size / 1024)) 2>/dev/null
            ;;
        "sparse")
            # Create sparse file
            dd if=/dev/zero of="$filepath" bs=1 count=0 seek="$size" 2>/dev/null
            ;;
    esac

    if [ "$VERBOSE" = true ]; then
        log "Created: $filepath ($(stat -c%s "$filepath") bytes, $content_type)"
    fi
}

# Function to create directory structure
create_test_structure() {
    log "Creating test directory structure..."

    # Clean existing data
    rm -rf "${DATA_DIR:?}"/*

    # Create basic structure
    mkdir -p "$DATA_DIR"/{small_files,large_files,mixed_sizes,deep/nested/structure,special_chars,empty_dirs}

    success "Base directory structure created"
}

# Function to generate small files (< 10MB)
generate_small_files() {
    log "Generating small files..."

    local small_dir="$DATA_DIR/small_files"

    # Various small files
    create_file "$small_dir/tiny.txt" 1024 "text"
    create_file "$small_dir/small.log" $((100 * 1024)) "text"
    create_file "$small_dir/medium.dat" $((1024 * 1024)) "random"
    create_file "$small_dir/config.json" $((50 * 1024)) "text"
    create_file "$small_dir/binary.bin" $((500 * 1024)) "random"

    # Create batch of small files
    for i in {1..20}; do
        local size=$((RANDOM % 1000000 + 1000))  # 1KB to ~1MB
        create_file "$small_dir/batch/file_${i}.txt" "$size" "text"
    done

    # Small files in subdirectories
    for subdir in {1..5}; do
        for file in {1..10}; do
            local size=$((RANDOM % 500000 + 10000))  # 10KB to ~500KB
            create_file "$small_dir/subdir_${subdir}/file_${file}.dat" "$size" "random"
        done
    done

    success "Small files generated ($(find "$small_dir" -type f | wc -l) files)"
}

# Function to generate large files (>= 10MB)
generate_large_files() {
    log "Generating large files..."

    local large_dir="$DATA_DIR/large_files"

    # Various large files with different content types
    create_file "$large_dir/large_text.txt" $((20 * 1024 * 1024)) "text"      # 20MB text
    create_file "$large_dir/huge_binary.bin" $((50 * 1024 * 1024)) "random"  # 50MB random
    create_file "$large_dir/big_zeros.dat" $((30 * 1024 * 1024)) "zeros"     # 30MB zeros
    create_file "$large_dir/sparse_file.sparse" $((100 * 1024 * 1024)) "sparse" # 100MB sparse

    # Medium-large files
    for i in {1..5}; do
        local size=$(((RANDOM % 20 + 10) * 1024 * 1024))  # 10-30MB
        create_file "$large_dir/medium_large_${i}.data" "$size" "random"
    done

    # Very large files
    create_file "$large_dir/very_large.bin" $((100 * 1024 * 1024)) "random"  # 100MB
    create_file "$large_dir/huge.dat" $((200 * 1024 * 1024)) "zeros"         # 200MB

    success "Large files generated ($(find "$large_dir" -type f | wc -l) files)"
}

# Function to generate mixed size structure
generate_mixed_structure() {
    log "Generating mixed size structure..."

    local mixed_dir="$DATA_DIR/mixed_sizes"

    # Mix of small and large files in same directory
    create_file "$mixed_dir/small.txt" $((100 * 1024)) "text"
    create_file "$mixed_dir/large.bin" $((25 * 1024 * 1024)) "random"
    create_file "$mixed_dir/medium.dat" $((5 * 1024 * 1024)) "random"
    create_file "$mixed_dir/tiny.log" 2048 "text"
    create_file "$mixed_dir/huge.data" $((75 * 1024 * 1024)) "zeros"

    # Nested structure with mixed sizes
    for level1 in {1..3}; do
        for level2 in {1..3}; do
            local dir="$mixed_dir/level${level1}/sublevel${level2}"

            # Random small file
            local small_size=$((RANDOM % 1000000 + 1000))
            create_file "$dir/small_${level1}_${level2}.txt" "$small_size" "text"

            # Random large file (50% chance)
            if [ $((RANDOM % 2)) -eq 0 ]; then
                local large_size=$(((RANDOM % 30 + 10) * 1024 * 1024))
                create_file "$dir/large_${level1}_${level2}.bin" "$large_size" "random"
            fi
        done
    done

    success "Mixed size structure generated"
}

# Function to generate files with special characters
generate_special_files() {
    log "Generating files with special characters..."

    local special_dir="$DATA_DIR/special_chars"

    # Files with spaces and special characters
    create_file "$special_dir/file with spaces.txt" $((100 * 1024)) "text"
    create_file "$special_dir/file-with-dashes.dat" $((200 * 1024)) "random"
    create_file "$special_dir/file_with_underscores.bin" $((300 * 1024)) "random"
    create_file "$special_dir/file.with.dots.log" $((50 * 1024)) "text"
    create_file "$special_dir/file[brackets].data" $((150 * 1024)) "random"
    create_file "$special_dir/file(parentheses).txt" $((75 * 1024)) "text"

    # Large file with special chars
    create_file "$special_dir/large file with spaces.bin" $((15 * 1024 * 1024)) "random"

    success "Special character files generated"
}

# Function to generate deep directory structure
generate_deep_structure() {
    log "Generating deep directory structure..."

    local deep_dir="$DATA_DIR/deep"

    # Create deep nested structure (10 levels deep)
    local current_dir="$deep_dir"
    for level in {1..10}; do
        current_dir="$current_dir/level_${level}"

        # Add files at each level
        create_file "$current_dir/file_at_level_${level}.txt" $((level * 50 * 1024)) "text"

        # Add large file at some levels
        if [ $((level % 3)) -eq 0 ]; then
            create_file "$current_dir/large_at_level_${level}.bin" $((level * 5 * 1024 * 1024)) "random"
        fi
    done

    success "Deep directory structure generated"
}

# Function to create empty directories
generate_empty_dirs() {
    log "Creating empty directories..."

    local empty_base="$DATA_DIR/empty_dirs"

    for i in {1..5}; do
        mkdir -p "$empty_base/empty_${i}"
        mkdir -p "$empty_base/nested_empty/level_${i}/empty"
    done

    success "Empty directories created"
}

# Function to generate test scenarios
generate_test_scenarios() {
    log "Generating specific test scenario files..."

    # Scenario 1: Many small files (stress test for batching)
    local batch_dir="$DATA_DIR/batch_test"
    for i in {1..100}; do
        local size=$((RANDOM % 50000 + 1000))  # 1KB to 50KB
        create_file "$batch_dir/batch_${i}.dat" "$size" "text"
    done

    # Scenario 2: Few very large files (stress test for parallel large file handling)
    local big_dir="$DATA_DIR/big_files_test"
    for i in {1..3}; do
        local size=$(((i * 150) * 1024 * 1024))  # 150MB, 300MB, 450MB
        create_file "$big_dir/massive_${i}.bin" "$size" "random"
    done

    # Scenario 3: Mixed workload
    local mixed_dir="$DATA_DIR/mixed_workload"
    for i in {1..10}; do
        # Small files
        local small_size=$((RANDOM % 100000 + 1000))
        create_file "$mixed_dir/small_${i}.txt" "$small_size" "text"

        # Large files (every other iteration)
        if [ $((i % 2)) -eq 0 ]; then
            local large_size=$(((RANDOM % 50 + 20) * 1024 * 1024))
            create_file "$mixed_dir/large_${i}.bin" "$large_size" "random"
        fi
    done

    success "Test scenario files generated"
}

# Function to show summary
show_summary() {
    log "Test data generation complete!"
    echo
    echo "=== Data Summary ==="

    local total_files
    total_files=$(find "$DATA_DIR" -type f | wc -l)
    local total_size
    total_size=$(du -sb "$DATA_DIR" 2>/dev/null | cut -f1)
    local total_size_human
    total_size_human=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)

    echo "Total files: $total_files"
    echo "Total size: $total_size_human ($total_size bytes)"
    echo

    echo "=== Directory breakdown ==="
    du -sh "$DATA_DIR"/* 2>/dev/null | sort -hr
    echo

    echo "=== File size distribution ==="
    echo "Small files (<10MB): $(find "$DATA_DIR" -type f -size -10M | wc -l)"
    echo "Large files (>=10MB): $(find "$DATA_DIR" -type f -size +10M | wc -l)"
    echo

    if [ "$VERBOSE" = true ]; then
        echo "=== Directory tree ==="
        tree "$DATA_DIR" -L 3 2>/dev/null || find "$DATA_DIR" -type d | head -20
    fi
}

# Fast mode main execution for CI
main_fast() {
    echo "=== Parallel Rsync Test Data Generator (Fast Mode) ==="
    echo

    create_test_structure

    # Generate only essential files for testing
    log "Generating minimal test files..."

    # Only 3 small files instead of 75
    local small_dir="$DATA_DIR/small_files"
    create_file "$small_dir/tiny.txt" $((50 * 1024)) "text"
    create_file "$small_dir/small.dat" $((100 * 1024)) "random"
    create_file "$small_dir/medium.bin" $((500 * 1024)) "random"
    success "Small files generated (3 files)"

    # Only 3 large files instead of 11, much smaller sizes
    local large_dir="$DATA_DIR/large_files"
    create_file "$large_dir/large_1.bin" $((2 * 1024 * 1024)) "random"    # 2MB instead of 20MB
    create_file "$large_dir/large_2.dat" $((3 * 1024 * 1024)) "zeros"     # 3MB instead of 50MB
    create_file "$large_dir/large_3.txt" $((1 * 1024 * 1024)) "text"      # 1MB instead of 100MB+
    success "Large files generated (3 files)"

    # Minimal special characters test
    local special_dir="$DATA_DIR/special_chars"
    create_file "$special_dir/file with spaces.txt" $((10 * 1024)) "text"
    success "Special character files generated"

    show_summary
}

# Main execution
main() {
    echo "=== Parallel Rsync Test Data Generator ==="
    echo

    create_test_structure
    generate_small_files
    generate_large_files
    generate_mixed_structure
    generate_special_files
    generate_deep_structure
    generate_empty_dirs
    generate_test_scenarios

    show_summary
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --fast)
            FAST_MODE=true
            shift
            ;;
        -d|--data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "  -v, --verbose    Verbose output"
            echo "  --fast           Fast mode with smaller files for CI"
            echo "  -d, --data-dir   Data directory (default: $DATA_DIR)"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
if [ "$FAST_MODE" = true ]; then
    main_fast
else
    main
fi