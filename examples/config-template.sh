#!/bin/bash

# Parallel Rsync Configuration Template
# Copy and modify this file for your specific use cases

# =============================================================================
# BASIC CONFIGURATION
# =============================================================================

# Script location (adjust based on your installation)
PARALLEL_RSYNC="../bin/parallel_file_rsync.sh"

# Source and destination paths
SOURCE_DIR="/path/to/source"
DESTINATION_DIR="/path/to/destination"

# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================

# Number of parallel jobs (adjust based on your system)
# Guidelines:
# - Fast SSDs: 12-16 jobs
# - Network storage: 4-8 jobs
# - Slow HDDs: 2-4 jobs
PARALLEL_JOBS=8

# Minimum file size for individual parallel processing
# Files smaller than this will be batched together
# Options: 1M, 10M, 50M, 100M, 1G
MIN_FILE_SIZE="10M"

# Maximum directory depth to scan
# Higher values scan deeper but take longer
MAX_DEPTH=10

# =============================================================================
# RSYNC OPTIONS
# =============================================================================

# Base rsync options (modify as needed)
RSYNC_OPTS="-avz --progress --partial"

# Additional options for different scenarios:
# For network transfers with bandwidth limiting:
# RSYNC_OPTS="-avz --progress --partial --bwlimit=10000"
#
# For preserving extended attributes:
# RSYNC_OPTS="-avzX --progress --partial"
#
# For excluding certain file types:
# RSYNC_OPTS="-avz --progress --partial --exclude='*.tmp' --exclude='*.log'"

# =============================================================================
# FILTERING OPTIONS
# =============================================================================

# Include only specific file patterns (leave empty to include all)
INCLUDE_PATTERNS=""
# Examples:
# INCLUDE_PATTERNS="--include '*.mp4' --include '*.mkv' --include '*.avi'"
# INCLUDE_PATTERNS="--include '*.jpg' --include '*.png' --include '*.tiff'"

# Exclude specific file patterns
EXCLUDE_PATTERNS=""
# Examples:
# EXCLUDE_PATTERNS="--exclude '*.tmp' --exclude '*.log' --exclude '.DS_Store'"
# EXCLUDE_PATTERNS="--exclude 'Thumbs.db' --exclude '*.partial'"

# =============================================================================
# ADVANCED OPTIONS
# =============================================================================

# Sort files by size (process largest first)
SORT_BY_SIZE=false

# Resume interrupted transfers
RESUME_MODE=false

# Enable verbose output
VERBOSE=true

# Dry run (preview without actual transfer)
DRY_RUN=false

# Directory for individual job logs (leave empty to disable)
LOG_DIR=""
# Example: LOG_DIR="/var/log/parallel-rsync"

# =============================================================================
# EXECUTION FUNCTION
# =============================================================================

run_sync() {
    local cmd="$PARALLEL_RSYNC"

    # Required arguments
    cmd="$cmd -s '$SOURCE_DIR' -d '$DESTINATION_DIR'"

    # Performance settings
    cmd="$cmd -j $PARALLEL_JOBS -m $MIN_FILE_SIZE --max-depth $MAX_DEPTH"

    # Rsync options
    cmd="$cmd -o '$RSYNC_OPTS'"

    # Filtering
    if [ -n "$INCLUDE_PATTERNS" ]; then
        cmd="$cmd $INCLUDE_PATTERNS"
    fi
    if [ -n "$EXCLUDE_PATTERNS" ]; then
        cmd="$cmd $EXCLUDE_PATTERNS"
    fi

    # Advanced options
    if [ "$SORT_BY_SIZE" = true ]; then
        cmd="$cmd --sort-by-size"
    fi
    if [ "$RESUME_MODE" = true ]; then
        cmd="$cmd --resume"
    fi
    if [ "$VERBOSE" = true ]; then
        cmd="$cmd -v"
    fi
    if [ "$DRY_RUN" = true ]; then
        cmd="$cmd --dry-run"
    fi
    if [ -n "$LOG_DIR" ]; then
        cmd="$cmd --log-dir '$LOG_DIR'"
    fi

    echo "Executing: $cmd"
    eval "$cmd"
}

# =============================================================================
# USAGE
# =============================================================================

# To use this configuration:
# 1. Copy this file and modify the settings above
# 2. Source the file: source your-config.sh
# 3. Run the sync: run_sync
#
# Or create a simple wrapper script:
# #!/bin/bash
# source /path/to/your-config.sh
# run_sync