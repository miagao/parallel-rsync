# Contributing to Parallel Rsync

Thank you for your interest in contributing to the Parallel Rsync project! We welcome contributions of all kinds, from bug reports to code improvements.

## 🚀 Quick Start for Contributors

### Prerequisites
- Docker and Docker Compose (for testing)
- Basic knowledge of Bash scripting
- Git for version control

### Setting Up Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/parallel-rsync.git
   cd parallel-rsync
   ```

2. **Test the Current Version**
   ```bash
   cd tests/docker
   docker compose up -d
   docker compose exec rsync-source ./test-data-generator.sh -v
   docker compose exec rsync-tester ./run-tests.sh
   docker compose down -v
   ```

## 📋 Types of Contributions

### 🐛 Bug Reports
- Use the GitHub issue tracker
- Include steps to reproduce
- Provide system information (OS, Docker version, etc.)
- Include relevant log outputs

### 💡 Feature Requests
- Describe the problem you're trying to solve
- Explain why the feature would be useful
- Consider backward compatibility

### 🔧 Code Contributions
- Fix bugs
- Add new features
- Improve performance
- Enhance documentation

### 📚 Documentation
- Fix typos or unclear explanations
- Add usage examples
- Improve installation instructions
- Update configuration guides

## 🛠️ Development Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 2. Make Your Changes
- Follow the existing code style
- Add comments for complex logic
- Update documentation as needed

### 3. Test Your Changes
```bash
# Run the full test suite
cd tests/docker
docker compose up -d
docker compose exec rsync-source ./test-data-generator.sh
docker compose exec rsync-tester ./run-tests.sh

# Test specific functionality
docker compose exec rsync-tester ./parallel_file_rsync.sh \
  -s /data/source/large_files -d /data/destination/test -v

# Clean up
docker compose down -v
```

### 4. Lint Your Code
```bash
# Install shellcheck
# On macOS: brew install shellcheck
# On Ubuntu: sudo apt-get install shellcheck

# Lint the main script
shellcheck bin/parallel_file_rsync.sh

# Lint test scripts
shellcheck tests/scripts/*.sh
```

### 5. Commit Your Changes
```bash
git add .
git commit -m "type: brief description

Longer explanation of the change if needed.

Fixes #123"
```

**Commit Message Format:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `test:` Test improvements
- `refactor:` Code refactoring
- `perf:` Performance improvements
- `chore:` Maintenance tasks

### 6. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## 🧪 Testing Guidelines

### Required Tests
- All existing tests must pass
- New features should include tests
- Bug fixes should include regression tests

### Test Structure
```bash
tests/
├── docker/              # Docker test environment
├── scripts/
│   ├── test-data-generator.sh  # Creates test datasets
│   └── run-tests.sh           # Main test runner
```

### Writing New Tests
Add test cases to `tests/scripts/run-tests.sh`:

```bash
test_new_feature() {
    run_test "New Feature Test" \
        "$SCRIPT_PATH -s /data/source -d /data/destination --new-option" \
        "complete_sync"
}
```

### Performance Testing
- Test with different file sizes
- Verify parallel processing works correctly
- Check memory usage doesn't exceed reasonable limits

## 📖 Code Style Guidelines

### Bash Scripting Standards
- Use `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail` (where appropriate)
- Use meaningful variable names
- Quote variables: `"$variable"`
- Use functions for repeated code
- Add comments for complex logic

### Script Organization
- Keep the main script focused and modular
- Use helper functions
- Separate configuration from logic
- Follow existing patterns

### Error Handling
- Check command exit codes
- Provide meaningful error messages
- Clean up temporary files
- Validate inputs

### Example Code Style
```bash
# Good
process_files() {
    local source_dir="$1"
    local dest_dir="$2"

    if [ ! -d "$source_dir" ]; then
        log "ERROR" "Source directory does not exist: $source_dir"
        return 1
    fi

    # Process files...
}

# Avoid
process_files() {
    if [ ! -d $1 ]; then
        echo "Error: $1 not found"
        exit 1
    fi
    # Process files...
}
```

## 🔍 Code Review Process

### What We Look For
- **Functionality**: Does it work as intended?
- **Tests**: Are there adequate tests?
- **Documentation**: Is it properly documented?
- **Performance**: Does it maintain or improve performance?
- **Security**: Are there any security implications?
- **Compatibility**: Does it work across different systems?

### Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests pass locally and in CI
- [ ] Documentation is updated
- [ ] No security vulnerabilities introduced
- [ ] Performance impact is acceptable
- [ ] Backward compatibility maintained

## 🚦 Continuous Integration

### Automated Checks
- **Linting**: ShellCheck for code quality
- **Testing**: Comprehensive test suite
- **Security**: Security vulnerability scanning
- **Documentation**: Ensure docs are up to date

### CI Workflows
- **Tests**: Run on every push and PR
- **Security**: Weekly security scans
- **Release**: Automated releases on tags

## 📚 Resources

### Documentation
- [README.md](../README.md) - Project overview
- [docs/README.md](../docs/README.md) - Detailed usage guide
- [docs/README-testing.md](../docs/README-testing.md) - Testing guide

### Examples
- [examples/basic-sync.sh](../examples/basic-sync.sh) - Usage examples
- [examples/config-template.sh](../examples/config-template.sh) - Configuration template

### Configuration
- [config/defaults.conf](../config/defaults.conf) - Default settings

## 🤝 Community Guidelines

### Be Respectful
- Use inclusive language
- Be constructive in feedback
- Help newcomers learn

### Communication
- Use GitHub issues for discussions
- Tag maintainers when needed
- Provide clear and detailed information

### Recognition
- Contributors will be acknowledged in releases
- Significant contributions may be highlighted

## ❓ Getting Help

### Questions
- Check existing issues first
- Use GitHub Discussions for general questions
- Tag issues appropriately

### Support
- Include system information
- Provide minimal reproduction steps
- Share relevant logs

---

Thank you for contributing to Parallel Rsync! 🚀