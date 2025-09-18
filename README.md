# Parallel File-Level Rsync

[![Tests](https://github.com/miagao/parallel-rsync/workflows/Tests/badge.svg)](https://github.com/miagao/parallel-rsync/actions/workflows/test.yml)
[![Security](https://github.com/miagao/parallel-rsync/workflows/Security/badge.svg)](https://github.com/miagao/parallel-rsync/actions/workflows/security.yml)
[![Version](https://img.shields.io/badge/version-2.1-blue)](bin/parallel_file_rsync.sh)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A high-performance file synchronization script that optimizes rsync operations by processing large files individually in parallel while batching small files for efficiency.

## 🚀 Quick Start

```bash
# Clone or download the project
cd parallel-rsync

# Make the script executable
chmod +x bin/parallel_file_rsync.sh

# Basic usage
./bin/parallel_file_rsync.sh -s /source/directory -d /destination/directory -v
```

## 📁 Project Structure

```
parallel-rsync/
├── bin/                          # Executable scripts
│   └── parallel_file_rsync.sh   # Main parallel rsync script
├── config/                       # Configuration files
├── docs/                        # Documentation
│   ├── README.md               # Detailed usage guide
│   └── README-testing.md       # Testing documentation
├── examples/                    # Usage examples and templates
├── tests/                       # Testing infrastructure
│   ├── docker/                 # Docker testing environment
│   │   ├── docker compose.yml  # Multi-container test setup
│   │   └── Dockerfile          # Test container definition
│   └── scripts/                # Test scripts
│       ├── test-data-generator.sh  # Creates test datasets
│       └── run-tests.sh            # Test suite runner
└── README.md                   # This file
```

## 🎯 Features

- **Intelligent Processing**: Large files (≥10MB) processed individually, small files batched
- **Parallel Execution**: Configurable job count for optimal performance
- **Progress Tracking**: Real-time transfer monitoring
- **Resume Support**: Continue interrupted transfers
- **Advanced Filtering**: Include/exclude patterns
- **Comprehensive Testing**: Docker-based test environment

## 📚 Documentation

- **[Usage Guide](docs/README.md)** - Comprehensive documentation
- **[Testing Guide](docs/README-testing.md)** - How to run tests
- **[Examples](examples/)** - Usage examples and templates

## 🧪 Testing

### GitHub Actions CI/CD
The project includes comprehensive automated testing:

- **🔍 Tests Workflow**: Runs on every push and pull request
  - Shellcheck linting for all scripts
  - Dependency validation
  - Docker integration tests (basic & comprehensive)
  - Edge case testing with special characters
  - Performance benchmarking
  - Documentation validation

- **🛡️ Security Workflow**: Weekly security scans
  - ShellCheck security analysis (`-S error`)
  - Secret detection scanning
  - File permissions validation
  - Docker vulnerability scanning (Trivy)
  - Code quality analysis
  - GitHub Actions security validation

### Local Testing
Run the comprehensive test suite using Docker:

```bash
cd tests/docker
docker compose up -d
docker compose exec rsync-source ./test-data-generator.sh -v
docker compose exec rsync-tester ./run-tests.sh
```

**Local Test Results**: 17/17 tests passing ✅

## 💡 Quick Examples

### Basic Synchronization
```bash
./bin/parallel_file_rsync.sh -s /media/photos -d /backup/photos -v
```

### High Performance
```bash
./bin/parallel_file_rsync.sh -s /data -d /backup -j 16 --sort-by-size
```

### Network Transfer
```bash
./bin/parallel_file_rsync.sh -s /local/data -d user@server:/remote/backup -j 4
```

### Resume Interrupted Transfer
```bash
./bin/parallel_file_rsync.sh -s /source -d /dest --resume -v
```

## 🔧 Requirements

- `rsync` - File synchronization utility
- `bc` - Calculator for size calculations
- `stat`, `find`, `realpath` - Standard Unix utilities
- **Optional**: Docker for testing

## 📊 Performance

**Tested Performance**:
- ✅ **Perfect Test Suite**: 17/17 tests passing (100% success rate)
- ✅ **Pattern Matching**: Include/exclude filters working correctly
- ✅ **Large files processed in parallel** (8 concurrent jobs by default)
- ✅ **Small files batched efficiently** (100 files per batch)
- ✅ **Real-time progress tracking** across all jobs
- ✅ **Production Ready**: All shellcheck security warnings resolved

## 🤝 Contributing

1. **Test your changes**: Use the Docker test environment and ensure CI/CD passes
2. **Security compliance**: All code must pass `shellcheck -S error`
3. **Update documentation**: Keep docs in sync with features
4. **Follow the structure**: Place files in appropriate directories

```bash
# Test your changes locally
cd tests/docker
docker compose up -d
docker compose exec rsync-tester ./run-tests.sh

# Verify security compliance
shellcheck -S error bin/parallel_file_rsync.sh tests/scripts/*.sh
```

**CI/CD Requirements**:
- ✅ All tests must pass (17/17)
- ✅ Security workflow must pass
- ✅ No shellcheck warnings allowed
- ✅ Documentation must be updated for new features

## 📄 License

MIT License - see LICENSE file for details.

---

**High-performance file synchronization made simple** 🚀