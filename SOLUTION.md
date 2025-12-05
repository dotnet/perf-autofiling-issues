# Solution: Adding Debug Configured Runs to MAUI Mobile Scenarios

## Overview

This solution implements support for running MAUI Android and iOS scenarios with both Release and Debug build configurations. Previously, these scenarios were hardcoded to use Release configuration only.

## Problem Statement

The existing performance testing infrastructure for `maui_scenarios_android.proj` and `maui_scenarios_ios.proj` only supported Release builds. We needed to add support for Debug builds by:

1. Passing `buildConfig: debug` (or `release`) through the `sdk-perf-jobs.yml` job parameters
2. Updating `get_run_configurations` in `run_performance_job.py` to include "BuildConfig" as a configuration property
3. Passing the `BuildConfig` value to the `pre.py publish` command via `-c {debug|release}`
4. Including BuildConfig in the RunConfig string property for proper job identification

## Solution Components

### 1. Pipeline Configuration (`sdk-perf-jobs.yml`)

**Changes Made:**
- Added duplicate job definitions for each mobile scenario configuration with `buildConfig: Debug`
- Kept existing jobs with explicit `buildConfig: Release` parameter
- Updated `additionalJobIdentifier` to distinguish debug jobs (e.g., `Mono_Debug` vs `Mono`)

**Example:**
```yaml
# Release configuration (existing, now explicit)
- template: /eng/pipelines/templates/build-machine-matrix.yml
  parameters:
    jobParameters:
      runKind: maui_scenarios_android
      runtimeFlavor: mono
      codeGenType: ProfiledAOT
      additionalJobIdentifier: Mono
      buildConfig: Release  # Explicit

# Debug configuration (new)
- template: /eng/pipelines/templates/build-machine-matrix.yml
  parameters:
    jobParameters:
      runKind: maui_scenarios_android
      runtimeFlavor: mono
      codeGenType: ProfiledAOT
      additionalJobIdentifier: Mono_Debug
      buildConfig: Debug  # Debug builds
```

### 2. Python Script (`run_performance_job.py`)

**Changes Made:**

#### a. Update `get_run_configurations` function signature:
```python
def get_run_configurations(
        run_kind: str,
        runtime_type: str,
        codegen_type: str,
        pgo_run_type: Optional[str] = None,
        physical_promotion_run_type: Optional[str] = None,
        r2r_run_type: Optional[str] = None,
        experiment_name: Optional[str] = None,
        linking_type: Optional[str] = None,
        runtime_flavor: Optional[str] = None,
        ios_llvm_build: bool = False,
        ios_strip_symbols: bool = False,
        javascript_engine: Optional[str] = None,
        build_config: str = "Release"):  # NEW PARAMETER
```

#### b. Add BuildConfig to configurations for mobile scenarios:
```python
# .NET Android and .NET MAUI Android sample app scenarios
if run_kind == "maui_scenarios_android":
    if not runtime_flavor in ("mono", "coreclr"):
        raise Exception("Runtime flavor must be specified for maui_scenarios_android")
    configurations["CodegenType"] = str(codegen_type)
    configurations["RuntimeType"] = str(runtime_flavor)
    configurations["BuildConfig"] = str(build_config)  # NEW LINE

# .NET iOS and .NET MAUI iOS sample app scenarios
if run_kind == "maui_scenarios_ios":
    if not runtime_flavor in ("mono", "coreclr"):
        raise Exception("Runtime flavor must be specified for maui_scenarios_ios")
    configurations["CodegenType"] = str(codegen_type)
    configurations["RuntimeType"] = str(runtime_flavor)
    configurations["BuildConfig"] = str(build_config)  # NEW LINE
```

#### c. Pass build_config when calling get_run_configurations:
```python
configurations = get_run_configurations(
    args.run_kind, args.runtime_type, args.codegen_type, args.pgo_run_type, 
    args.physical_promotion_run_type, args.r2r_run_type, args.experiment_name, 
    args.linking_type, args.runtime_flavor, args.ios_llvm_build, 
    args.ios_strip_symbols, args.javascript_engine,
    args.build_config  # NEW PARAMETER
)
```

**Note:** The `build_config` parameter already exists in `RunPerformanceJobArgs` dataclass with a default value of "Release", so no changes are needed there.

### 3. Android Project File (`maui_scenarios_android.proj`)

**Changes Made:**

#### a. Define _BuildConfig property with fallback:
```xml
<PropertyGroup>
    <!-- Default to Release if BuildConfig is not set -->
    <_BuildConfig Condition="'$(BuildConfig)' == ''">Release</_BuildConfig>
    <_BuildConfig Condition="'$(BuildConfig)' != ''">$(BuildConfig)</_BuildConfig>
    
    <!-- Include BuildConfig in RunConfigsString for proper identification -->
    <RunConfigsString>$(RuntimeFlavor)_$(CodegenType)_$(_BuildConfig)</RunConfigsString>
</PropertyGroup>
```

#### b. Update PreparePayloadWorkItem command to use -c flag:
```xml
<PreparePayloadWorkItem Include="@(MAUIAndroidScenario)">
  <Command>$(Python) pre.py publish -f $(PERFLAB_Framework)-android -r android-arm64 --self-contained -c $(_BuildConfig) --msbuild="$(_MSBuildArgs)" --binlog ... -o ...</Command>
  <WorkingDirectory>%(PreparePayloadWorkItem.PayloadDirectory)</WorkingDirectory>
</PreparePayloadWorkItem>
```

**Key Changes:**
- Added `-c $(_BuildConfig)` to the pre.py publish command
- Updated `RunConfigsString` to include `$(_BuildConfig)` for proper binlog naming and identification

### 4. iOS Project File (`maui_scenarios_ios.proj`)

**Changes Made:**

#### a. Define _BuildConfig property with fallback:
```xml
<PropertyGroup>
    <!-- Default to Release if BuildConfig is not set -->
    <_BuildConfig Condition="'$(BuildConfig)' == ''">Release</_BuildConfig>
    <_BuildConfig Condition="'$(BuildConfig)' != ''">$(BuildConfig)</_BuildConfig>
</PropertyGroup>
```

#### b. Update PreparePayloadWorkItem command to use -c flag:
```xml
<PreparePayloadWorkItem Include="@(MAUIiOSScenario)">
  <Command>sudo xcode-select -s /Applications/Xcode_26.0.1.app; $(Python) pre.py publish -f $(PERFLAB_Framework)-ios --self-contained -c $(_BuildConfig) -r ios-arm64 $(NativeAOTCommandProps) --binlog ... -o ...; cd ../; zip -r ...</Command>
  <WorkingDirectory>%(PreparePayloadWorkItem.PayloadDirectory)</WorkingDirectory>
</PreparePayloadWorkItem>
```

**Key Changes:**
- Added `-c $(_BuildConfig)` to the pre.py publish command
- iOS scenarios use the BuildConfig but don't include it in the binlog name like Android does

## How It Works

### Data Flow

1. **Pipeline Configuration**: The `sdk-perf-jobs.yml` file specifies `buildConfig: Debug` or `buildConfig: Release` in the job parameters
2. **Script Processing**: The `run_performance_job.py` script receives the `build_config` parameter and:
   - Adds it to the configurations dictionary as `BuildConfig`
   - Passes it to `ci_setup` which sets it as an environment variable
3. **Project Execution**: The `.proj` files:
   - Read the `BuildConfig` environment variable (set by ci_setup via build_configs)
   - Use it to set the `_BuildConfig` MSBuild property
   - Pass it to `pre.py publish` via the `-c` flag
   - Include it in `RunConfigsString` for proper job identification

### Environment Variables

The BuildConfig is exposed as an environment variable through the `ci_setup_arguments.build_configs` mechanism:
```python
ci_setup_arguments.build_configs=[f"{k}={v}" for k, v in configurations.items()]
```

This results in environment variables like:
- `BuildConfig=Release`
- `BuildConfig=Debug`

The MSBuild properties in the `.proj` files can then access these via `$(BuildConfig)`.

## Benefits

1. **Debug Performance Testing**: Enables performance testing of debug builds to identify debug-specific performance issues
2. **Build Configuration Comparison**: Allows comparing Release vs Debug performance characteristics
3. **Minimal Code Changes**: Leverages existing infrastructure with small, focused changes
4. **Backward Compatibility**: Defaults to Release if no BuildConfig is specified
5. **Clear Job Identification**: Debug jobs are clearly identified via `additionalJobIdentifier` suffix

## Testing

To test these changes in the actual dotnet/performance repository:

### 1. Local Testing
```bash
python scripts/run_performance_job.py \
  --run-kind maui_scenarios_android \
  --architecture arm64 \
  --os-group windows \
  --runtime-flavor mono \
  --codegen-type ProfiledAOT \
  --build-config Debug \
  --performance-repo-dir . \
  --is-scenario
```

### 2. Pipeline Testing
Trigger the pipeline with the debug jobs enabled and verify:
- Jobs run successfully with both Debug and Release configurations
- Binlogs have proper naming (e.g., `mauiandroid.mono_ProfiledAOT_Debug.binlog`)
- Results are properly tagged with BuildConfig in the performance database
- Debug and Release jobs are distinguishable in the results

## Files Modified

In the actual dotnet/performance repository, the following files need to be modified:

1. `eng/pipelines/sdk-perf-jobs.yml` - Add duplicate jobs with `buildConfig: Debug`
2. `scripts/run_performance_job.py` - Update `get_run_configurations` function
3. `eng/performance/maui_scenarios_android.proj` - Use `_BuildConfig` variable
4. `eng/performance/maui_scenarios_ios.proj` - Use `_BuildConfig` variable

## Implementation Notes

- The `build_config` parameter in `RunPerformanceJobArgs` already exists with a default of "Release"
- The change is opt-in via explicit job parameters; existing jobs continue to work
- The solution follows the existing pattern used for other configuration properties (RuntimeFlavor, CodegenType, etc.)
- All mobile scenario variants (AOT, R2R, JIT, NativeAOT, etc.) should have Debug counterparts added

## Future Enhancements

1. Could extend to other scenario types if needed
2. Could add a pipeline parameter to enable/disable debug jobs globally
3. Could add telemetry to track debug vs release performance trends over time
