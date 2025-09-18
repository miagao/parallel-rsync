#!/bin/bash

# Basic Parallel Rsync Examples
# These examples demonstrate common usage patterns

SCRIPT_PATH="../bin/parallel_file_rsync.sh"

echo "=== Parallel Rsync Usage Examples ==="
echo

# Example 1: Basic local sync
echo "1. Basic local synchronization:"
echo "$SCRIPT_PATH -s /source/directory -d /destination/directory -v"
echo

# Example 2: High performance sync
echo "2. High performance (16 parallel jobs, largest files first):"
echo "$SCRIPT_PATH -s /media/videos -d /backup/videos -j 16 --sort-by-size -v"
echo

# Example 3: Network sync with bandwidth limit
echo "3. Network sync with bandwidth limiting:"
echo "$SCRIPT_PATH -s /local/data -d user@server:/remote/backup \\"
echo "  -j 4 -o '-avz --progress --partial --bwlimit=10000'"
echo

# Example 4: Selective sync with filters
echo "4. Sync only video files, exclude temporary files:"
echo "$SCRIPT_PATH -s /media -d /backup/media \\"
echo "  --include '*.mp4' --include '*.mkv' --include '*.avi' \\"
echo "  --exclude '*.tmp' --exclude '*.partial' -v"
echo

# Example 5: Resume interrupted transfer
echo "5. Resume interrupted transfer with logging:"
echo "$SCRIPT_PATH -s /large/dataset -d /backup/dataset \\"
echo "  --resume --log-dir /var/log/rsync-jobs -v"
echo

# Example 6: Dry run to preview changes
echo "6. Dry run to see what would be transferred:"
echo "$SCRIPT_PATH -s /source -d /destination --dry-run -v"
echo

# Example 7: Adjust for different file sizes
echo "7. For many small files (lower threshold):"
echo "$SCRIPT_PATH -s /code/repository -d /backup/code -m 1M -j 4 -v"
echo

echo "8. For very large files only (higher threshold):"
echo "$SCRIPT_PATH -s /video/raw -d /backup/raw -m 100M -j 8 --sort-by-size -v"
echo

echo "=== Performance Tuning Guidelines ==="
echo "• Fast SSDs: Use 12-16 jobs"
echo "• Network storage: Use 4-8 jobs"
echo "• Slow HDDs: Use 2-4 jobs"
echo "• Monitor system resources and adjust accordingly"