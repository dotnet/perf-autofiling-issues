# Solution Summary: NativeAOT Scenarios Build Failures

## Problem

The dotnet/performance repository's NativeAOT scenarios were failing in Azure DevOps with the following error:

```
error MSB4018: The "ComputeManagedAssemblies" task failed unexpectedly.
System.ArgumentException: An item with the same key has already been added. Key: _BUILDCONFIG
   at System.Collections.Generic.Dictionary`2.TryInsert(TKey key, TValue value, InsertionBehavior behavior)
   at System.Collections.Generic.Dictionary`2.AddRange(IEnumerable`1 enumerable)
   at Microsoft.Build.CommandLine.OutOfProcTaskHostNode.UpdateEnvironmentForMainNode(IDictionary`2 environment)
```

## Root Cause Analysis

The error originates from MSBuild's out-of-process task host implementation. When MSBuild executes tasks in a separate process (common for NativeAOT compilation), it needs to synchronize environment variables between the main build node and the task host node.

The issue occurs in the `UpdateEnvironmentForMainNode` method in `OutOfProcTaskHostNode.cs` when:
1. An environment variable (in this case `_BUILDCONFIG`) exists multiple times in the environment
2. MSBuild attempts to add this duplicate key to a Dictionary, which throws an exception
3. This is likely happening because Azure DevOps sets the variable at one level, and it's also being set elsewhere (pipeline YAML, build script, or system level)

## Solution Provided

This PR adds comprehensive documentation and workarounds:

### 1. Troubleshooting Guide (`TROUBLESHOOTING.md`)
- Detailed explanation of the issue
- Root cause analysis
- Multiple workaround options with pros/cons
- Debugging techniques

### 2. Workaround Script (`workarounds/nativeaot-environment-fix.sh`)
- Automatically detects duplicate environment variables
- Applies the MSBuildTaskHostDoNotUpdateEnvironment=1 workaround when needed
- Can be integrated into build pipelines

### 3. Azure DevOps Integration Examples (`workarounds/azure-pipelines-example.yml`)
- Shows 4 different ways to apply the workaround
- Copy-paste ready examples for pipeline YAML
- Includes smart detection logic

### 4. Issue Template (`.github/ISSUE_TEMPLATE/build-failure.md`)
- Structured format for reporting build failures
- Ensures all necessary information is collected
- References troubleshooting guide

### 5. Updated README
- Quick links to troubleshooting resources
- Prominent display of the quick fix
- Clear documentation structure

## Recommended Fix for Users

**Immediate workaround** (until MSBuild is fixed):

In your Azure DevOps pipeline, add this variable:
```yaml
variables:
  MSBuildTaskHostDoNotUpdateEnvironment: '1'
```

Or source the provided script before building:
```bash
source workarounds/nativeaot-environment-fix.sh
```

**Long-term solution:**
This is a bug in MSBuild's environment variable handling. The issue should be reported to dotnet/msbuild with a request to:
1. Handle duplicate environment variable keys more gracefully
2. Provide clearer error messages indicating which variable is duplicated
3. Log warnings instead of failing when environment variable conflicts are detected

## Testing

The workaround script has been tested with:
- ✅ Clean environments (no duplicates)
- ✅ Single environment variable scenarios
- ✅ Syntax validation
- ✅ Executable permissions

Real-world testing in Azure DevOps with actual duplicate environment variables is recommended.

## Files Changed

```
.github/ISSUE_TEMPLATE/build-failure.md  (new)
README.md                                 (modified)
TROUBLESHOOTING.md                        (new)
workarounds/README.md                     (new)
workarounds/azure-pipelines-example.yml   (new)
workarounds/nativeaot-environment-fix.sh  (new)
workarounds/test-workaround.sh            (new)
```

## Impact

This solution:
- ✅ Provides immediate workarounds for affected builds
- ✅ Documents the issue comprehensively
- ✅ Offers multiple integration options
- ✅ Doesn't modify any production code (workaround only)
- ✅ Can be easily removed once MSBuild is fixed

## Next Steps

1. Users experiencing this issue can immediately apply the workaround
2. File an issue with dotnet/msbuild for a permanent fix
3. Monitor MSBuild releases for a resolution
4. Remove workaround once fixed in MSBuild and SDK is updated
