# Parallel File-Level Rsync

[![Tests](https://img.shields.io/badge/tests-passing-brightgreen)](tests/)
[![Version](https://img.shields.io/badge/version-2.0-blue)](bin/parallel_file_rsync.sh)
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
│   │   ├── docker-compose.yml  # Multi-container test setup
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

Run the comprehensive test suite using Docker:

```bash
cd tests/docker
docker-compose up -d
docker-compose exec rsync-source ./test-data-generator.sh -v
docker-compose exec rsync-tester ./run-tests.sh
```

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
- ✅ 231 files (1.8GB) transferred successfully
- ✅ Large files processed in parallel (8 concurrent jobs)
- ✅ Small files batched efficiently (100 files per batch)
- ✅ Real-time progress tracking across all jobs

## 🤝 Contributing

1. **Test your changes**: Use the Docker test environment
2. **Update documentation**: Keep docs in sync with features
3. **Follow the structure**: Place files in appropriate directories

```bash
# Test your changes
cd tests/docker
docker-compose up -d
docker-compose exec rsync-tester ./run-tests.sh
```

## 📄 License

MIT License - see LICENSE file for details.

---

**High-performance file synchronization made simple** 🚀