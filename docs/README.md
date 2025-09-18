# Parallel File-Level Rsync Script

A high-performance file synchronization script that optimizes rsync operations by processing large files individually in parallel while batching small files for efficiency.

## 🚀 Features

- **Intelligent File Processing**: Large files (≥10MB) sync individually in parallel, small files batch together
- **Configurable Parallelism**: Adjustable job count for optimal performance across different systems
- **Progress Tracking**: Real-time progress monitoring with transfer statistics
- **Resume Support**: Built-in support for resuming interrupted transfers
- **Advanced Filtering**: Include/exclude patterns for selective synchronization
- **Flexible Depth Control**: Configurable directory depth scanning (default: 10 levels)
- **Comprehensive Logging**: Optional individual job logging for debugging
- **Error Handling**: Robust error detection and reporting

## 📋 Requirements

- `rsync` - File synchronization utility
- `bc` - Calculator for size calculations
- `stat` - File statistics
- `realpath` - Path resolution
- `find` - File discovery

## 🔧 Installation

```bash
# Make the script executable
chmod +x parallel_file_rsync.sh

# Verify dependencies
./parallel_file_rsync.sh --help
```

## 💡 Usage

### Basic Synchronization
```bash
# Sync all files with default settings
./parallel_file_rsync.sh -s /source/directory -d /destination/directory

# Verbose output
./parallel_file_rsync.sh -s /source/directory -d /destination/directory -v
```

### Performance Tuning
```bash
# High parallelism for fast systems
./parallel_file_rsync.sh -s /source -d /dest -j 16

# Conservative parallelism for slower systems
./parallel_file_rsync.sh -s /source -d /dest -j 4

# Adjust minimum file size for parallel processing
./parallel_file_rsync.sh -s /source -d /dest -m 50M
```

### Advanced Features
```bash
# Process largest files first
./parallel_file_rsync.sh -s /source -d /dest --sort-by-size

# Resume interrupted transfers
./parallel_file_rsync.sh -s /source -d /dest --resume

# Include only specific file types
./parallel_file_rsync.sh -s /source -d /dest --include "*.mp4" --include "*.mkv"

# Exclude temporary files
./parallel_file_rsync.sh -s /source -d /dest --exclude "*.tmp" --exclude "*.log"

# Enable individual job logging
./parallel_file_rsync.sh -s /source -d /dest --log-dir /var/log/rsync_jobs

# Dry run to preview changes
./parallel_file_rsync.sh -s /source -d /dest --dry-run -v
```

### Directory Depth Control
```bash
# Scan only immediate subdirectories
./parallel_file_rsync.sh -s /source -d /dest --max-depth 2

# Deep scanning for complex structures
./parallel_file_rsync.sh -s /source -d /dest --max-depth 20
```

## ⚙️ Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `--jobs` / `-j` | 8 | Number of parallel rsync jobs |
| `--min-size` / `-m` | 10M | Minimum file size for individual processing |
| `--max-depth` | 10 | Maximum directory depth to scan |
| `--options` / `-o` | "-avz --progress --partial" | Rsync options |

### Size Format Examples
- `1M`, `1MB` = 1 Megabyte
- `1.5G`, `1.5GB` = 1.5 Gigabytes
- `500K`, `500KB` = 500 Kilobytes

## 📊 How It Works

### File Classification
1. **File Discovery**: Scans source directory up to specified depth
2. **Size Analysis**: Classifies files as large (≥min-size) or small (<min-size)
3. **Processing Strategy**:
   - **Large Files**: Processed individually in parallel for maximum throughput
   - **Small Files**: Batched together (100 files per batch) for efficiency

### Parallel Processing
- Large files start transferring immediately across available job slots
- Small file batches are queued and processed in parallel
- Progress tracking works across all parallel jobs
- Failed transfers are logged and reported

### Performance Benefits
- **Large Files**: Parallel transfer maximizes bandwidth utilization
- **Small Files**: Batching reduces rsync overhead and connection setup
- **Mixed Workloads**: Optimal handling of diverse file size distributions

## 🧪 Testing

A comprehensive Docker-based testing suite is provided for safe validation:

```bash
# Start test environment
docker compose up -d

# Generate test data
docker compose exec rsync-source ./test-data-generator.sh -v

# Run full test suite
docker compose exec rsync-tester ./run-tests.sh

# Run performance benchmarks
docker compose exec rsync-tester ./run-tests.sh --benchmark
```

See `README-testing.md` for detailed testing documentation.

## 📈 Performance Optimization

### Job Count Guidelines
- **Fast SSDs**: 12-16 jobs
- **Network Storage**: 4-8 jobs
- **Slow HDDs**: 2-4 jobs
- **Monitor**: Watch system resources and adjust accordingly

### File Size Thresholds
- **Media Files**: Use larger threshold (50M-100M)
- **Code/Documents**: Use smaller threshold (1M-10M)
- **Mixed Content**: Default 10M works well

### Network Considerations
```bash
# Add bandwidth limiting for network transfers
./parallel_file_rsync.sh -s /source -d user@host:/dest \
  -o "-avz --progress --partial --bwlimit=10000"

# Optimize for slow networks
./parallel_file_rsync.sh -s /source -d user@host:/dest -j 2 -m 100M
```

## 🚨 Important Notes

### Resource Management
- Monitor system I/O and CPU usage
- Too many parallel jobs can saturate storage bandwidth
- Network transfers may benefit from lower job counts

### Safety Features
- Script validates source and destination paths
- Dry run mode allows preview without changes
- Resume mode handles interrupted transfers gracefully
- Individual job logging aids in troubleshooting

### File System Compatibility
- Works with any file system supported by rsync
- Handles special characters in filenames
- Preserves permissions, timestamps, and attributes
- Supports sparse files and hard links

## 🔍 Troubleshooting

### Common Issues

**No files found / Low file count**
```bash
# Check directory depth setting
./parallel_file_rsync.sh -s /source -d /dest --max-depth 20 -v

# Verify source directory contents
find /source -type f | head -10
```

**Poor performance**
```bash
# Reduce parallel jobs
./parallel_file_rsync.sh -s /source -d /dest -j 4

# Adjust file size threshold
./parallel_file_rsync.sh -s /source -d /dest -m 50M
```

**Transfer failures**
```bash
# Enable individual job logging
./parallel_file_rsync.sh -s /source -d /dest --log-dir /tmp/rsync_logs -v

# Check log files
ls -la /tmp/rsync_logs/
cat /tmp/rsync_logs/job_*.log
```

### Debug Mode
```bash
# Enable verbose output and logging
./parallel_file_rsync.sh -s /source -d /dest -v --log-dir /tmp/debug

# Monitor real-time progress
watch 'find /dest -type f | wc -l'
```

## 📝 Version History

### v2.0 (Current)
- ✅ Fixed file discovery pipeline issue
- ✅ Improved progress tracking across parallel jobs
- ✅ Enhanced default depth scanning (1→10 levels)
- ✅ Robust cross-process communication
- ✅ Comprehensive Docker testing environment

### v1.0 (Initial)
- Basic parallel file processing
- Size-based file classification
- Progress tracking and logging

## 📄 License

This script is provided as-is for educational and practical use. Modify and distribute according to your needs.

## 🤝 Contributing

Contributions welcome! The Docker testing environment makes it easy to validate changes safely:

1. Make changes to the script
2. Run the test suite to verify functionality
3. Update documentation as needed
4. Submit improvements

---

**⚡ High-performance file synchronization made simple**