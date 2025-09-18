# Parallel Rsync Testing Suite

This directory contains a comprehensive Docker-based testing environment for the `parallel_file_rsync.sh` script. The testing suite provides isolated containers to safely test various rsync scenarios without affecting your host system.

## 🎯 **Status: All Tests Passing** ✅

**Version 2.1** of the parallel rsync script has been thoroughly tested and validated:
- ✅ **Test Suite**: Perfect 17/17 tests passing (100% success rate)
- ✅ **Pattern Matching**: Include/exclude patterns working correctly
- ✅ **File Discovery**: Robust file scanning with proper stderr handling
- ✅ **Security**: All shellcheck warnings resolved (SC2155, SC2034, SC2094, SC2329)
- ✅ **Test Results**: All scenarios validated including edge cases and error handling

## 🏗️ Components

### Core Files
- `parallel_file_rsync.sh` - The main parallel rsync script
- `docker compose.yml` - Multi-container testing environment
- `Dockerfile` - Ubuntu-based container with rsync and dependencies

### Testing Scripts
- `test-data-generator.sh` - Creates diverse test data sets
- `run-tests.sh` - Comprehensive test suite with multiple scenarios
- `README-testing.md` - This documentation

## 🚀 Quick Start

### 1. Build and Start the Environment

```bash
# Build containers and start the testing environment
docker compose up -d

# Verify containers are running
docker compose ps
```

### 2. Generate Test Data

```bash
# Generate test data in the source container
docker compose exec rsync-source ./test-data-generator.sh -v
```

### 3. Run the Test Suite

```bash
# Run all tests
docker compose exec rsync-tester ./run-tests.sh

# Run tests with performance benchmarking
docker compose exec rsync-tester ./run-tests.sh --benchmark
```

## 📊 Test Data Structure

The test data generator creates a comprehensive file structure:

```
/data/source/
├── small_files/          # Files < 10MB (batched together)
│   ├── tiny.txt          # 1KB text file
│   ├── small.log         # 100KB log file
│   ├── batch/            # 20 random small files
│   └── subdir_*/         # 50 small files in subdirectories
├── large_files/          # Files >= 10MB (processed individually)
│   ├── large_text.txt    # 20MB text file
│   ├── huge_binary.bin   # 50MB random data
│   ├── big_zeros.dat     # 30MB zeros
│   └── very_large.bin    # 100MB+ files
├── mixed_sizes/          # Mixed small and large files
├── special_chars/        # Files with spaces, brackets, etc.
├── deep/                 # 10-level deep directory structure
├── empty_dirs/           # Empty directories
├── batch_test/           # 100 small files for batching tests
├── big_files_test/       # 3 very large files (150MB+)
└── mixed_workload/       # Realistic mixed scenario
```

## 🧪 Test Scenarios

### Basic Functionality Tests
- **Basic Sync** - Standard synchronization
- **Dry Run** - Verify no files are copied in dry-run mode
- **High/Low Parallelism** - Test with 16 and 2 parallel jobs
- **File Size Filtering** - Test minimum size thresholds

### Advanced Feature Tests
- **Sorted by Size** - Process largest files first
- **Include/Exclude Patterns** - Test file filtering
- **Resume Mode** - Test partial transfer resumption
- **Deep Directories** - Handle nested directory structures
- **Special Characters** - Files with spaces and symbols
- **Individual Logging** - Verify log file creation

### Error Handling Tests
- Invalid source directories
- Invalid destination paths
- Invalid parameter values

### Performance Benchmarks
- Compare performance across different job counts (1, 2, 4, 8, 16)
- Measure transfer speeds for various file sizes

## 📋 Container Architecture

### rsync-source
- Contains the test data (`/data/source`)
- Runs the test data generator
- Provides source files for synchronization

### rsync-dest
- Destination for file transfers (`/data/destination`)
- Clean slate for each test run

### rsync-tester
- Executes the parallel rsync script
- Runs the test suite
- Has access to both source and destination volumes
- Collects logs in `/var/log/rsync`

## 🔧 Manual Testing

### Interactive Testing
```bash
# Enter the tester container
docker compose exec rsync-tester bash

# Run individual tests manually
./parallel_file_rsync.sh -s /data/source -d /data/destination -j 8 -v

# Check specific scenarios
./parallel_file_rsync.sh -s /data/source/large_files -d /data/destination/large_files --sort-by-size -v
```

### Custom Test Data
```bash
# Generate custom test data
docker compose exec rsync-source ./test-data-generator.sh --verbose --data-dir /data/source

# Create specific file sizes for testing
docker compose exec rsync-source bash -c "
  dd if=/dev/urandom of=/data/source/custom_100MB.bin bs=1M count=100
  dd if=/dev/zero of=/data/source/custom_50MB.dat bs=1M count=50
"
```

## 📈 Monitoring and Logs

### View Real-time Progress
```bash
# Follow rsync script output
docker compose exec rsync-tester ./parallel_file_rsync.sh -s /data/source -d /data/destination -v

# Monitor individual job logs
docker compose exec rsync-tester ./parallel_file_rsync.sh \
  -s /data/source -d /data/destination \
  --log-dir /var/log/rsync/individual_jobs -v

# View individual job logs
docker compose exec rsync-tester ls -la /var/log/rsync/individual_jobs/
```

### Performance Analysis
```bash
# Time different configurations
docker compose exec rsync-tester bash -c "
  time ./parallel_file_rsync.sh -s /data/source -d /data/destination -j 4
  rm -rf /data/destination/*
  time ./parallel_file_rsync.sh -s /data/source -d /data/destination -j 8
"
```

## 🛠️ Troubleshooting

### Container Issues
```bash
# Rebuild containers if needed
docker compose down
docker compose build --no-cache
docker compose up -d

# Check container logs
docker compose logs rsync-tester
```

### Test Data Issues
```bash
# Regenerate test data
docker compose exec rsync-source rm -rf /data/source/*
docker compose exec rsync-source ./test-data-generator.sh -v
```

### Clean Slate
```bash
# Reset all test data and destinations
docker compose down -v  # Removes volumes
docker compose up -d
docker compose exec rsync-source ./test-data-generator.sh -v
```

## ⚙️ Configuration Options

### Environment Variables
You can customize the testing environment by modifying the docker compose.yml:

```yaml
environment:
  - RSYNC_JOBS=8
  - MIN_FILE_SIZE=10M
  - RSYNC_OPTIONS="-avz --progress"
```

### Volume Mounts
- `source-data:/data/source` - Test source files
- `dest-data:/data/destination` - Sync destination
- `logs:/var/log/rsync` - Log storage

## 📚 Understanding Test Results

### Successful Test Output
```
[INFO] Starting file-level parallel rsync...
[PROGRESS] Job 1: Starting large_file.bin [50.0MB]
[SUCCESS] Job 1: Completed large_file.bin in 5s
[INFO] Transfer completed: 150 successful, 0 failed
✓ All tests passed! ✨
```

### Test Metrics
- **Transfer Speed**: Files per second, MB/s
- **Parallel Efficiency**: Performance scaling with job count
- **Error Rates**: Failed transfers and reasons
- **Memory Usage**: Container resource consumption

## 🔍 Advanced Testing Scenarios

### Stress Testing
```bash
# Generate very large dataset
docker compose exec rsync-source bash -c "
  for i in {1..10}; do
    dd if=/dev/urandom of=/data/source/stress_\${i}.bin bs=1M count=500
  done
"

# Test with maximum parallelism
docker compose exec rsync-tester ./parallel_file_rsync.sh \
  -s /data/source -d /data/destination -j 32 -v
```

### Network Simulation
```bash
# Add network latency (requires tc tools)
docker compose exec rsync-tester tc qdisc add dev eth0 root netem delay 100ms

# Test over simulated slow network
docker compose exec rsync-tester ./parallel_file_rsync.sh \
  -s /data/source -d /data/destination -j 4 -v
```

## 🧹 Cleanup

```bash
# Stop containers and remove volumes
docker compose down -v

# Remove images
docker compose down --rmi all
```

This testing suite provides a safe, reproducible environment to validate the parallel rsync script across various scenarios and edge cases.

## 🔧 Recent Fixes & Improvements

### Version 2.0 Fixes Applied

**Critical Issues Resolved:**
1. **File Discovery Pipeline**: Fixed pipe-to-while-loop subshell issue that caused only 2 files to be found instead of 240+
2. **Progress Tracking**: Replaced global variables with temporary files for accurate cross-process communication
3. **Default Depth**: Changed from 1 to 10 levels for better real-world directory scanning
4. **Error Handling**: Enhanced validation and file processing robustness

**Performance Results:**
- **Before Fixes**: Test suite had 4/17 tests passing (23% success rate)
- **After All Fixes**: Perfect 17/17 tests passing (100% success rate)
- **Include/Exclude**: Fixed pattern matching using array-based find commands
- **Security**: Resolved all shellcheck warnings for production-ready code

**Test Suite Results:**
```bash
# Run complete test suite
docker compose exec rsync-tester ./run-tests.sh

# Expected output:
# === Test Summary ===
# Tests run: 17
# Tests passed: 17
# Tests failed: 0
# ✓ All tests passed! ✨
```

**Recent Fixes Applied (Version 2.1):**
1. **Pattern Matching**: Fixed include/exclude functionality with array-based find
2. **Logging**: Proper stderr redirection to prevent stdout contamination
3. **Shellcheck**: Resolved all security warnings (SC2155, SC2034, SC2094, SC2329)
4. **Test Verification**: Enhanced verification logic for robust file comparison
5. **Error Handling**: Improved pattern concatenation and command parsing