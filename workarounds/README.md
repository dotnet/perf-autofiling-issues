# Performance Infrastructure Workarounds

This directory contains workaround scripts and configurations for known issues in the performance testing infrastructure.

## Available Workarounds

### nativeaot-environment-fix.sh

**Purpose:** Fixes the `_BUILDCONFIG` duplicate key error that occurs in NativeAOT scenario builds.

**Usage:**
```bash
# Source the script before running performance tests
source workarounds/nativeaot-environment-fix.sh

# Or run it directly
./workarounds/nativeaot-environment-fix.sh
```

**Integration with Azure DevOps:**
Add this to your pipeline YAML before the build step:
```yaml
- bash: |
    source $(Build.SourcesDirectory)/workarounds/nativeaot-environment-fix.sh
  displayName: 'Apply NativeAOT environment workaround'
```

**What it does:**
1. Checks for duplicate environment variables (case-insensitive)
2. If duplicates are found, sets `MSBuildTaskHostDoNotUpdateEnvironment=1`
3. This disables MSBuild's environment variable synchronization between nodes, avoiding the duplicate key error

**When to use:**
- When you see errors like: "An item with the same key has already been added. Key: _BUILDCONFIG"
- In Azure DevOps NativeAOT scenario runs
- When using PublishAot=true in .NET builds

## Contributing Workarounds

If you discover a new issue and develop a workaround:
1. Create a descriptive script or configuration file
2. Document it clearly in this README
3. Include usage instructions and integration examples
4. Note when the workaround can be removed (e.g., after a specific SDK/tool update)

## Reporting Issues

If these workarounds don't resolve your issue, please:
1. Check the main [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) guide
2. Search existing issues at [dotnet/performance](https://github.com/dotnet/performance/issues)
3. File a new issue with complete error details and steps to reproduce
