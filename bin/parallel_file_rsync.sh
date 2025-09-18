#!/bin/bash

# Parallel File-Level Rsync Script
# Syncs individual files from a source directory in parallel
# Perfect for directories with many large files

# Default configuration
DEFAULT_JOBS=8
DEFAULT_RSYNC_OPTIONS="-avz --progress --partial"
DEFAULT_MIN_SIZE="10M"
DEFAULT_MAX_DEPTH=10
JOBS=$DEFAULT_JOBS
RSYNC_OPTIONS=$DEFAULT_RSYNC_OPTIONS
MIN_FILE_SIZE=$DEFAULT_MIN_SIZE
MAX_DEPTH=$DEFAULT_MAX_DEPTH
SOURCE_DIR=""
DESTINATION=""
VERBOSE=false
DRY_RUN=false
SORT_BY_SIZE=false
EXCLUDE_PATTERNS=""
INCLUDE_PATTERNS=""
# RESUME_MODE removed - functionality integrated into rsync commands
LOG_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global counters
TOTAL_FILES=0
TOTAL_SIZE=0

# Function to display usage
show_usage() {
    cat << EOF
Parallel File-Level Rsync Script - Sync large files simultaneously

Usage: $0 [OPTIONS]

OPTIONS:
    -s, --source DIR                  Source directory
    -d, --destination DIR             Destination directory
    -j, --jobs NUM                    Number of parallel jobs (default: $DEFAULT_JOBS)
    -o, --options "OPTIONS"           Rsync options (default: "$DEFAULT_RSYNC_OPTIONS")
    -m, --min-size SIZE               Minimum file size to parallel sync (default: $DEFAULT_MIN_SIZE)
                                      Examples: 1M, 100M, 1G, 500K
    --max-depth NUM                   Maximum directory depth to scan (default: $DEFAULT_MAX_DEPTH)
    --sort-by-size                    Process largest files first
    --exclude "PATTERN"               Exclude files matching pattern (can be used multiple times)
    --include "PATTERN"               Include only files matching pattern (can be used multiple times)
    --resume                          Resume interrupted transfers
    --log-dir DIR                     Directory to store individual job logs
    -n, --dry-run                     Perform a trial run with no changes made
    -v, --verbose                     Verbose output
    -h, --help                        Show this help message

SIZE FORMATS:
    K or KB = Kilobytes, M or MB = Megabytes, G or GB = Gigabytes
    Examples: 10M, 1.5G, 500K, 2GB

EXAMPLES:
    # Sync all files >50MB with 12 parallel jobs
    $0 -s "/data/large_files/" -d "/backup/large_files/" -j 12 -m 50M

    # Process largest files first, exclude temp files
    $0 -s "/media/" -d "/backup/media/" --sort-by-size --exclude "*.tmp"

    # Include only video files, with logging
    $0 -s "/videos/" -d "/backup/videos/" --include "*.mp4" --include "*.mkv" --log-dir "/tmp/rsync_logs"

    # Resume interrupted transfer
    $0 -s "/data/" -d "/backup/" --resume -v

    # Dry run to see what would be transferred
    $0 -s "/source/" -d "/dest/" -n -v

NOTES:
    - Small files (below min-size) are synced together in a single rsync job
    - Large files are synced individually for better parallelism
    - Use --partial in rsync options to resume interrupted large file transfers
    - Monitor system resources - too many parallel jobs can saturate I/O

EOF
}

# Function to log messages
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        "INFO")
            echo -e "${BLUE}[$timestamp] INFO:${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] SUCCESS:${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] WARNING:${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] ERROR:${NC} $message"
            ;;
        "PROGRESS")
            echo -e "${CYAN}[$timestamp] PROGRESS:${NC} $message"
            ;;
    esac
}

# Function to convert size to bytes
size_to_bytes() {
    local size=$1
    local number
    number=${size//[^0-9.]/}
    local unit
    unit=$(echo "${size//[0-9.]/}" | tr '[:lower:]' '[:upper:]')

    case $unit in
        "K"|"KB") echo "$number * 1024" | bc -l | cut -d. -f1 ;;
        "M"|"MB") echo "$number * 1024 * 1024" | bc -l | cut -d. -f1 ;;
        "G"|"GB") echo "$number * 1024 * 1024 * 1024" | bc -l | cut -d. -f1 ;;
        "") echo "$number" | cut -d. -f1 ;;
        *) echo "0" ;;
    esac
}

# Function to format bytes to human readable
bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=1; $bytes / 1073741824" | bc)GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc)MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=1; $bytes / 1024" | bc)KB"
    else
        echo "${bytes}B"
    fi
}


# Function to get file list with sizes
get_file_list() {
    local min_bytes
    min_bytes=$(size_to_bytes "$MIN_FILE_SIZE")

    log "INFO" "Scanning directory: $SOURCE_DIR" >&2
    log "INFO" "Max depth: $MAX_DEPTH, Min size: $MIN_FILE_SIZE ($min_bytes bytes)" >&2

    # Build find command directly without complex eval
    local temp_file="/tmp/find_output_$$"

    # Create find command with include/exclude patterns
    if [ -n "$INCLUDE_PATTERNS" ] || [ -n "$EXCLUDE_PATTERNS" ]; then
        # Build find command with patterns directly (avoid eval complexity)
        local find_args=("$SOURCE_DIR" "-maxdepth" "$MAX_DEPTH" "-type" "f")

        # Add include patterns (if any)
        if [ -n "$INCLUDE_PATTERNS" ]; then
            local include_added=false
            find_args+=("(")
            for pattern in $INCLUDE_PATTERNS; do
                if [ "$include_added" = true ]; then
                    find_args+=("-o")
                fi
                find_args+=("-name" "$pattern")
                include_added=true
            done
            find_args+=(")")
        fi

        # Add exclude patterns (if any)
        if [ -n "$EXCLUDE_PATTERNS" ]; then
            for pattern in $EXCLUDE_PATTERNS; do
                find_args+=("!" "-name" "$pattern")
            done
        fi

        find "${find_args[@]}" -exec stat -c '%s:%n' {} \; 2>/dev/null > "$temp_file"
    else
        # Simple case - direct find command
        find "$SOURCE_DIR" -maxdepth "$MAX_DEPTH" -type f -exec stat -c '%s:%n' {} \; 2>/dev/null > "$temp_file"
    fi

    # Process the results
    while IFS=':' read -r size filepath; do
        if [ -n "$size" ] && [ -n "$filepath" ]; then
            if [ "$size" -ge "$min_bytes" ]; then
                echo "LARGE:$size:$filepath"
            else
                echo "SMALL:$size:$filepath"
            fi
        fi
    done < "$temp_file"

    rm -f "$temp_file"
}

# Function to sync a single large file
sync_large_file() {
    local filepath=$1
    local job_id=$2
    local filesize=$3
    local log_file=""

    if [ -n "$LOG_DIR" ]; then
        log_file="$LOG_DIR/job_${job_id}.log"
        mkdir -p "$LOG_DIR"
    fi

    local rel_path
    rel_path=$(realpath --relative-to="$SOURCE_DIR" "$filepath")
    local dest_path="$DESTINATION/$rel_path"
    local dest_dir
    dest_dir=$(dirname "$dest_path")

    # Create destination directory
    mkdir -p "$dest_dir"

    log "PROGRESS" "Job $job_id: Starting $(basename "$filepath") [$(bytes_to_human "$filesize")]"

    # Build rsync command
    local cmd="rsync $RSYNC_OPTIONS"
    if [ "$DRY_RUN" = true ]; then
        cmd="$cmd --dry-run"
    fi
    cmd="$cmd \"$filepath\" \"$dest_path\""

    if [ "$VERBOSE" = true ]; then
        log "INFO" "Job $job_id: Command: $cmd"
    fi

    # Execute rsync
    local start_time
    start_time=$(date +%s)
    local result=0

    if [ -n "$log_file" ]; then
        if eval "$cmd" &> "$log_file"; then
            result=0
        else
            result=$?
        fi
    else
        if eval "$cmd" >/dev/null 2>&1; then
            result=0
        else
            result=$?
        fi
    fi

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $result -eq 0 ]; then
        # Use temp files for cross-process communication
        echo "$filesize" >> "/tmp/completed_files_$$"
        log "SUCCESS" "Job $job_id: Completed $(basename "$filepath") in ${duration}s"
    else
        echo "1" >> "/tmp/failed_files_$$"
        log "ERROR" "Job $job_id: Failed $(basename "$filepath") (exit code: $result)"
        if [ -n "$log_file" ]; then
            log "ERROR" "Job $job_id: Check log file: $log_file"
        fi
    fi

    return $result
}

# Function to sync small files in batch
sync_small_files() {
    local small_files_list=$1
    local job_id=$2

    if [ ! -s "$small_files_list" ]; then
        return 0
    fi

    local file_count
    file_count=$(wc -l < "$small_files_list")
    log "PROGRESS" "Job $job_id: Starting batch of $file_count small files"

    # Build files-from list (relative paths)
    local files_from_list="/tmp/rsync_small_files_$$_$job_id"
    while read -r filepath; do
        realpath --relative-to="$SOURCE_DIR" "$filepath"
    done < "$small_files_list" > "$files_from_list"

    # Build rsync command for batch
    local cmd="rsync $RSYNC_OPTIONS"
    if [ "$DRY_RUN" = true ]; then
        cmd="$cmd --dry-run"
    fi
    cmd="$cmd --files-from=\"$files_from_list\" \"$SOURCE_DIR/\" \"$DESTINATION/\""

    if [ "$VERBOSE" = true ]; then
        log "INFO" "Job $job_id: Batch command: $cmd"
    fi

    # Execute batch rsync
    local start_time
    start_time=$(date +%s)
    if eval "$cmd" >/dev/null 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        # Use temp files for cross-process communication
        for _ in $(seq 1 "$file_count"); do
            echo "0" >> "/tmp/completed_files_$$"
        done
        log "SUCCESS" "Job $job_id: Completed batch of $file_count files in ${duration}s"
        rm -f "$files_from_list"
        return 0
    else
        local exit_code=$?
        for _ in $(seq 1 "$file_count"); do
            echo "1" >> "/tmp/failed_files_$$"
        done
        log "ERROR" "Job $job_id: Failed batch sync (exit code: $exit_code)"
        rm -f "$files_from_list"
        return $exit_code
    fi
}

# Function to show progress
show_progress() {
    # Read progress from temp files
    local completed_count=0
    local failed_count=0
    local transferred_bytes=0

    if [ -f "/tmp/completed_files_$$" ]; then
        completed_count=$(wc -l < "/tmp/completed_files_$$" 2>/dev/null || echo 0)
        transferred_bytes=$(awk '{sum += $1} END {print sum+0}' "/tmp/completed_files_$$" 2>/dev/null || echo 0)
    fi

    if [ -f "/tmp/failed_files_$$" ]; then
        failed_count=$(wc -l < "/tmp/failed_files_$$" 2>/dev/null || echo 0)
    fi

    local percent=0
    if [ "$TOTAL_FILES" -gt 0 ]; then
        percent=$(( (completed_count + failed_count) * 100 / TOTAL_FILES ))
    fi

    local transferred_human
    transferred_human=$(bytes_to_human "$transferred_bytes")
    local total_human
    total_human=$(bytes_to_human "$TOTAL_SIZE")

    log "PROGRESS" "Overall: $percent% complete ($completed_count/$TOTAL_FILES files, $transferred_human/$total_human transferred)"
}

# Function to process all files
process_files() {
    local temp_dir="/tmp/parallel_rsync_$$"
    mkdir -p "$temp_dir"

    # Initialize progress tracking temp files
    rm -f "/tmp/completed_files_$$" "/tmp/failed_files_$$"
    touch "/tmp/completed_files_$$" "/tmp/failed_files_$$"

    local all_files="$temp_dir/all_files.txt"
    local large_files="$temp_dir/large_files.txt"
    local small_files="$temp_dir/small_files.txt"
    local small_batch_size=100

    # Get file list
    log "INFO" "Building file list..."
    get_file_list > "$all_files"

    if [ ! -s "$all_files" ]; then
        log "ERROR" "No files found matching criteria"
        rm -rf "$temp_dir"
        return 1
    fi

    # Separate large and small files
    grep "^LARGE:" "$all_files" | cut -d: -f3 > "$large_files"
    grep "^SMALL:" "$all_files" | cut -d: -f3 > "$small_files"

    # Calculate totals
    TOTAL_FILES=$(wc -l < "$all_files")
    TOTAL_SIZE=$(awk -F: '{sum += $2} END {print sum+0}' "$all_files")

    local large_count
    large_count=$(wc -l < "$large_files")
    local small_count
    small_count=$(wc -l < "$small_files")

    log "INFO" "Found $TOTAL_FILES files ($(bytes_to_human "$TOTAL_SIZE") total)"
    log "INFO" "  - $large_count large files (>=$MIN_FILE_SIZE)"
    log "INFO" "  - $small_count small files (<$MIN_FILE_SIZE)"

    # Sort large files by size if requested
    if [ "$SORT_BY_SIZE" = true ] && [ -s "$large_files" ]; then
        log "INFO" "Sorting large files by size (largest first)..."
        local large_with_sizes="$temp_dir/large_with_sizes.txt"
        while read -r filepath; do
            local size
            size=$(stat -c '%s' "$filepath" 2>/dev/null || echo 0)
            echo "$size:$filepath"
        done < "$large_files" | sort -nr > "$large_with_sizes"
        cut -d: -f2 "$large_with_sizes" > "$large_files"
    fi

    local job_count=0

    # Process large files in parallel
    if [ -s "$large_files" ]; then
        log "INFO" "Starting parallel sync of large files..."

        while read -r filepath; do
            # Wait if we've reached max jobs
            while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do
                sleep 0.1
                show_progress
            done

            job_count=$((job_count + 1))
            local filesize
            filesize=$(stat -c '%s' "$filepath" 2>/dev/null || echo 0)

            # Start background job for large file
            sync_large_file "$filepath" "$job_count" "$filesize" &

        done < "$large_files"
    fi

    # Process small files in batches
    if [ -s "$small_files" ]; then
        log "INFO" "Processing small files in batches..."

        local batch_num=0
        local batch_file=""
        local line_count=0

        while read -r filepath; do
            if [ $((line_count % small_batch_size)) -eq 0 ]; then
                # Start new batch
                if [ -n "$batch_file" ] && [ -s "$batch_file" ]; then
                    # Wait for available slot
                    while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do
                        sleep 0.1
                        show_progress
                    done

                    job_count=$((job_count + 1))
                    sync_small_files "$batch_file" "$job_count" &
                fi

                batch_num=$((batch_num + 1))
                batch_file="$temp_dir/small_batch_$batch_num.txt"
                true > "$batch_file"  # Clear file
            fi

            echo "$filepath" >> "$batch_file"
            line_count=$((line_count + 1))
        done < "$small_files"

        # Process final batch
        if [ -n "$batch_file" ] && [ -s "$batch_file" ]; then
            while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do
                sleep 0.1
                show_progress
            done

            job_count=$((job_count + 1))
            sync_small_files "$batch_file" "$job_count" &
        fi
    fi

    # Wait for all jobs to complete
    log "INFO" "Waiting for all transfer jobs to complete..."
    while [ "$(jobs -r | wc -l)" -gt 0 ]; do
        sleep 1
        show_progress
    done

    # Final wait to ensure all background processes are done
    wait

    # Cleanup
    rm -rf "$temp_dir"

    # Final summary
    show_progress

    # Read final counts from temp files
    local final_completed=0
    local final_failed=0
    if [ -f "/tmp/completed_files_$$" ]; then
        final_completed=$(wc -l < "/tmp/completed_files_$$" 2>/dev/null || echo 0)
    fi
    if [ -f "/tmp/failed_files_$$" ]; then
        final_failed=$(wc -l < "/tmp/failed_files_$$" 2>/dev/null || echo 0)
    fi

    log "INFO" "Transfer completed: $final_completed successful, $final_failed failed"

    # Cleanup temp files
    rm -f "/tmp/completed_files_$$" "/tmp/failed_files_$$"

    if [ "$final_failed" -gt 0 ]; then
        log "WARNING" "Some files failed to transfer. Check logs for details."
        return 1
    else
        log "SUCCESS" "All files transferred successfully!"
        return 0
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -d|--destination)
            DESTINATION="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -o|--options)
            RSYNC_OPTIONS="$2"
            shift 2
            ;;
        -m|--min-size)
            MIN_FILE_SIZE="$2"
            shift 2
            ;;
        --max-depth)
            MAX_DEPTH="$2"
            shift 2
            ;;
        --sort-by-size)
            SORT_BY_SIZE=true
            shift
            ;;
        --exclude)
            EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:+$EXCLUDE_PATTERNS }$2"
            shift 2
            ;;
        --include)
            INCLUDE_PATTERNS="${INCLUDE_PATTERNS:+$INCLUDE_PATTERNS }$2"
            shift 2
            ;;
        --resume)
            # Resume mode enabled (functionality built into rsync commands)
            RSYNC_OPTIONS="$RSYNC_OPTIONS --partial"
            shift
            ;;
        --log-dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$SOURCE_DIR" ] || [ -z "$DESTINATION" ]; then
    log "ERROR" "Both source (-s) and destination (-d) are required"
    show_usage
    exit 1
fi

# Validate source directory
if [ ! -d "$SOURCE_DIR" ]; then
    log "ERROR" "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

# Validate destination parent
DEST_PARENT=$(dirname "$DESTINATION")
if [ ! -d "$DEST_PARENT" ]; then
    log "ERROR" "Destination parent directory does not exist: $DEST_PARENT"
    exit 1
fi

# Validate jobs parameter
if ! [[ "$JOBS" =~ ^[0-9]+$ ]] || [ "$JOBS" -lt 1 ]; then
    log "ERROR" "Jobs parameter must be a positive integer"
    exit 1
fi

# Check dependencies
for cmd in rsync stat bc realpath; do
    if ! command -v "$cmd" &> /dev/null; then
        log "ERROR" "$cmd is not installed or not in PATH"
        exit 1
    fi
done

# Create destination directory
mkdir -p "$DESTINATION"

# Display configuration
log "INFO" "=== Parallel File-Level Rsync Configuration ==="
log "INFO" "Source directory: $SOURCE_DIR"
log "INFO" "Destination: $DESTINATION"
log "INFO" "Parallel jobs: $JOBS"
log "INFO" "Minimum file size for parallel sync: $MIN_FILE_SIZE"
log "INFO" "Maximum scan depth: $MAX_DEPTH"
log "INFO" "Rsync options: $RSYNC_OPTIONS"
if [ "$SORT_BY_SIZE" = true ]; then
    log "INFO" "File processing: Largest files first"
fi
if [ -n "$EXCLUDE_PATTERNS" ]; then
    log "INFO" "Exclude patterns:$EXCLUDE_PATTERNS"
fi
if [ -n "$INCLUDE_PATTERNS" ]; then
    log "INFO" "Include patterns:$INCLUDE_PATTERNS"
fi
if [ "$DRY_RUN" = true ]; then
    log "INFO" "Mode: DRY RUN (no changes will be made)"
fi
if [ -n "$LOG_DIR" ]; then
    log "INFO" "Individual job logs: $LOG_DIR"
fi

# Start processing
log "INFO" "Starting file-level parallel rsync..."
process_files

# Exit with appropriate code
exit $?