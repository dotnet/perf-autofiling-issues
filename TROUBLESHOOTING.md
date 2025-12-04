# Troubleshooting Guide for Performance Infrastructure Issues

## NativeAOT Scenarios Build Failures

### Issue: Duplicate `_BUILDCONFIG` Environment Variable Error

**Symptoms:**
- NativeAOT scenario runs fail in Azure DevOps
- Error message: `An item with the same key has already been added. Key: _BUILDCONFIG`
- Stack trace shows: `Microsoft.Build.CommandLine.OutOfProcTaskHostNode.UpdateEnvironmentForMainNode`
- Occurs during the `ComputeManagedAssemblies` task

**Root Cause:**
The MSBuild out-of-process task host attempts to update environment variables when switching between the main node and the task host process. When environment variables are duplicated (e.g., `_BUILDCONFIG` is set multiple times in the environment), the dictionary operation fails because it tries to add a key that already exists.

This issue typically manifests when:
1. Environment variables are set both in the CI/CD pipeline configuration and in build scripts
2. Case-sensitive vs case-insensitive environment variable handling differs between systems
3. Build configuration is being set through multiple mechanisms simultaneously

**Workarounds:**

#### Option 1: Disable Environment Updates (Quick Fix)
Set the following environment variable in your Azure DevOps pipeline before running the build:

```yaml
variables:
  MSBuildTaskHostDoNotUpdateEnvironment: '1'
```

Or in bash:
```bash
export MSBuildTaskHostDoNotUpdateEnvironment=1
```

**Note:** This disables the environment variable synchronization between the main MSBuild node and out-of-process task hosts. This is generally safe but may cause issues in cross-platform or cross-architecture builds.

#### Option 2: Clean Environment Variables
Ensure that `_BUILDCONFIG` and similar build-configuration environment variables are not set redundantly:

1. Check your Azure DevOps pipeline YAML for duplicate variable definitions
2. Review any build scripts that might be setting environment variables
3. Use `printenv | grep -i buildconfig` to identify duplicate entries

#### Option 3: Update MSBuild/SDK Version
If possible, update to the latest .NET SDK version which may include fixes for environment variable handling:

```bash
# Check current version
dotnet --version

# Update to latest SDK
# Follow instructions at https://dotnet.microsoft.com/download
```

#### Option 4: Use Case-Consistent Variable Names
Ensure all environment variable names use consistent casing throughout your build pipeline and scripts. Avoid having both `_BuildConfig` and `_BUILDCONFIG` set.

**Affected Scenarios:**
- `emptyconsolenativeaot`
- Other NativeAOT scenarios that use PublishAot=true
- Out-of-process MSBuild task hosts in Azure DevOps

**Related Information:**
- MSBuild Source: [OutOfProcTaskHostNode.cs](https://github.com/dotnet/msbuild/blob/master/src/MSBuild/OutOfProcTaskHostNode.cs)
- The error occurs in the `UpdateEnvironmentForMainNode` method when calling `Dictionary.AddRange()`
- Environment variable synchronization is handled by the `s_mismatchedEnvironmentValues` static dictionary

**Long-term Solution:**
This issue should be reported to the dotnet/msbuild repository as it represents a bug in the environment variable handling logic. The code should handle duplicate keys more gracefully or provide better error messages indicating which environment variable is causing the conflict.

**Additional Debugging:**
To get more detailed information about the failure, enable diagnostic logging:

```bash
export MSBUILDDEBUGCOMM=1
export MSBuildTaskHostUpdateEnvironmentAndLog=1
```

Then check the build logs for detailed environment variable information.

---

## General Performance Test Troubleshooting

### Failed Performance Runs
If you encounter issues with performance test runs, check:
1. The [dotnet/performance](https://github.com/dotnet/performance) repository for known issues
2. Recent changes to the test infrastructure
3. Environment-specific configurations

### Reporting New Issues
When reporting new performance infrastructure issues:
1. Include the complete error message and stack trace
2. Specify the test scenario that failed
3. Note the build configuration (Debug/Release, architecture, OS)
4. Include relevant environment variable settings
5. Provide the commit SHA or build ID where the failure occurred
