# Implementation Guide: Step-by-Step Instructions

## Prerequisites

This guide assumes you are working in the `dotnet/performance` repository (not `dotnet/perf-autofiling-issues`).

## Step 1: Update sdk-perf-jobs.yml

### File: `eng/pipelines/sdk-perf-jobs.yml`

For each mobile scenario job in the private jobs section, you need to:
1. Add explicit `buildConfig: Release` to existing jobs
2. Duplicate the job with `buildConfig: Debug` and updated `additionalJobIdentifier`

### Example Implementation:

```yaml
# Find this section in the file (around line 450):
- ${{ if parameters.runPrivateJobs }}:

  # Locate each mobile job and apply the pattern below:
  
  # =========== ANDROID JOBS ===========
  
  # 1. Mono ProfiledAOT - Release (EXISTING - ADD buildConfig)
  - template: /eng/pipelines/templates/build-machine-matrix.yml
    parameters:
      jobTemplate: /eng/pipelines/templates/run-scenarios-job.yml
      buildMachines:
        - win-x64-android-arm64-pixel
        - win-x64-android-arm64-galaxy
      isPublic: false
      jobParameters:
        runKind: maui_scenarios_android
        projectFileName: maui_scenarios_android.proj
        channels:
          - main
        runtimeFlavor: mono
        codeGenType: ProfiledAOT
        additionalJobIdentifier: Mono
        buildConfig: Release  # ← ADD THIS LINE
        ${{ each parameter in parameters.jobParameters }}:
          ${{ parameter.key }}: ${{ parameter.value }}

  # 2. Mono ProfiledAOT - Debug (NEW JOB - DUPLICATE AND MODIFY)
  - template: /eng/pipelines/templates/build-machine-matrix.yml
    parameters:
      jobTemplate: /eng/pipelines/templates/run-scenarios-job.yml
      buildMachines:
        - win-x64-android-arm64-pixel
        - win-x64-android-arm64-galaxy
      isPublic: false
      jobParameters:
        runKind: maui_scenarios_android
        projectFileName: maui_scenarios_android.proj
        channels:
          - main
        runtimeFlavor: mono
        codeGenType: ProfiledAOT
        additionalJobIdentifier: Mono_Debug  # ← CHANGE THIS (add _Debug)
        buildConfig: Debug  # ← ADD THIS LINE
        ${{ each parameter in parameters.jobParameters }}:
          ${{ parameter.key }}: ${{ parameter.value }}
```

**Repeat this pattern for ALL Android jobs:**
- Mono AOT
- CoreCLR JIT
- CoreCLR R2R
- CoreCLR R2RComposite
- CoreCLR NativeAOT

**And for ALL iOS jobs:**
- Mono FullAOT
- CoreCLR NativeAOT

---

## Step 2: Update run_performance_job.py

### File: `scripts/run_performance_job.py`

#### 2a. Update function signature (Line ~580)

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
        build_config: str = "Release"):  # ← ADD THIS LINE
```

#### 2b. Add BuildConfig to configurations (Lines ~645 and ~652)

Find the `maui_scenarios_android` section:
```python
    # .NET Android and .NET MAUI Android sample app scenarios
    if run_kind == "maui_scenarios_android":
        if not runtime_flavor in ("mono", "coreclr"):
            raise Exception("Runtime flavor must be specified for maui_scenarios_android")
        configurations["CodegenType"] = str(codegen_type)
        configurations["RuntimeType"] = str(runtime_flavor)
        configurations["BuildConfig"] = str(build_config)  # ← ADD THIS LINE
```

Find the `maui_scenarios_ios` section:
```python
    # .NET iOS and .NET MAUI iOS sample app scenarios
    if run_kind == "maui_scenarios_ios":
        if not runtime_flavor in ("mono", "coreclr"):
            raise Exception("Runtime flavor must be specified for maui_scenarios_ios")
        configurations["CodegenType"] = str(codegen_type)
        configurations["RuntimeType"] = str(runtime_flavor)
        configurations["BuildConfig"] = str(build_config)  # ← ADD THIS LINE
```

#### 2c. Pass build_config when calling function (Line ~933)

Find this call:
```python
    configurations = get_run_configurations(
        args.run_kind, args.runtime_type, args.codegen_type, args.pgo_run_type, args.physical_promotion_run_type,
        args.r2r_run_type, args.experiment_name, args.linking_type,
        args.runtime_flavor, args.ios_llvm_build, args.ios_strip_symbols, args.javascript_engine
    )
```

Change to:
```python
    configurations = get_run_configurations(
        args.run_kind, args.runtime_type, args.codegen_type, args.pgo_run_type, args.physical_promotion_run_type,
        args.r2r_run_type, args.experiment_name, args.linking_type,
        args.runtime_flavor, args.ios_llvm_build, args.ios_strip_symbols, args.javascript_engine,
        args.build_config  # ← ADD THIS LINE
    )
```

---

## Step 3: Update maui_scenarios_android.proj

### File: `eng/performance/maui_scenarios_android.proj`

#### 3a. Find the first PropertyGroup (around line 10-30)

Look for this section:
```xml
  <PropertyGroup>
    <AfterPreparePayloadWorkItemCommand>$(Python) post.py</AfterPreparePayloadWorkItemCommand>
    <PreparePayloadOutDirectoryName>scenarios_out</PreparePayloadOutDirectoryName>
    <!-- ... other properties ... -->
    
    <!-- Existing line: -->
    <RunConfigsString>$(RuntimeFlavor)_$(CodegenType)</RunConfigsString>
  </PropertyGroup>
```

#### 3b. Modify to add _BuildConfig:

```xml
  <PropertyGroup>
    <AfterPreparePayloadWorkItemCommand>$(Python) post.py</AfterPreparePayloadWorkItemCommand>
    <PreparePayloadOutDirectoryName>scenarios_out</PreparePayloadOutDirectoryName>
    <!-- ... other properties ... -->
    
    <!-- ADD THESE THREE LINES: -->
    <_BuildConfig Condition="'$(BuildConfig)' == ''">Release</_BuildConfig>
    <_BuildConfig Condition="'$(BuildConfig)' != ''">$(BuildConfig)</_BuildConfig>
    
    <!-- MODIFY THIS LINE to include _BuildConfig: -->
    <RunConfigsString>$(RuntimeFlavor)_$(CodegenType)_$(_BuildConfig)</RunConfigsString>
  </PropertyGroup>
```

#### 3c. Update PreparePayloadWorkItem (around line 70)

Find:
```xml
  <ItemGroup>
    <PreparePayloadWorkItem Include="@(MAUIAndroidScenario)">
      <Command>$(Python) pre.py publish -f $(PERFLAB_Framework)-android -r android-arm64 --self-contained --msbuild="$(_MSBuildArgs)" --binlog $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName)\%(PreparePayloadWorkItem.ScenarioDirectoryName).$(RunConfigsString).binlog -o $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName)</Command>
```

Change to (add `-c $(_BuildConfig)` after `--self-contained`):
```xml
  <ItemGroup>
    <PreparePayloadWorkItem Include="@(MAUIAndroidScenario)">
      <Command>$(Python) pre.py publish -f $(PERFLAB_Framework)-android -r android-arm64 --self-contained -c $(_BuildConfig) --msbuild="$(_MSBuildArgs)" --binlog $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName)\%(PreparePayloadWorkItem.ScenarioDirectoryName).$(RunConfigsString).binlog -o $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName)</Command>
```

---

## Step 4: Update maui_scenarios_ios.proj

### File: `eng/performance/maui_scenarios_ios.proj`

#### 4a. Find the PropertyGroup with NativeAOTCommandProps (around line 15)

Look for:
```xml
  <PropertyGroup>
    <AfterPreparePayloadWorkItemCommand>$(Python) post.py</AfterPreparePayloadWorkItemCommand>
    <PreparePayloadOutDirectoryName>scenarios_out</PreparePayloadOutDirectoryName>
    <PreparePayloadWorkItemBaseDirectory Condition="'$(TargetsWindows)' == 'true'">$(CorrelationPayloadDirectory)$(PreparePayloadOutDirectoryName)\</PreparePayloadWorkItemBaseDirectory>
    <PreparePayloadWorkItemBaseDirectory Condition="'$(TargetsWindows)' != 'true'">$(CorrelationPayloadDirectory)$(PreparePayloadOutDirectoryName)/</PreparePayloadWorkItemBaseDirectory>
    
    <NativeAOTCommandProps Condition="'$(RuntimeFlavor)' == 'coreclr'">--nativeaot true</NativeAOTCommandProps>
  </PropertyGroup>
```

#### 4b. Add _BuildConfig lines:

```xml
  <PropertyGroup>
    <AfterPreparePayloadWorkItemCommand>$(Python) post.py</AfterPreparePayloadWorkItemCommand>
    <PreparePayloadOutDirectoryName>scenarios_out</PreparePayloadOutDirectoryName>
    <PreparePayloadWorkItemBaseDirectory Condition="'$(TargetsWindows)' == 'true'">$(CorrelationPayloadDirectory)$(PreparePayloadOutDirectoryName)\</PreparePayloadWorkItemBaseDirectory>
    <PreparePayloadWorkItemBaseDirectory Condition="'$(TargetsWindows)' != 'true'">$(CorrelationPayloadDirectory)$(PreparePayloadOutDirectoryName)/</PreparePayloadWorkItemBaseDirectory>
    
    <NativeAOTCommandProps Condition="'$(RuntimeFlavor)' == 'coreclr'">--nativeaot true</NativeAOTCommandProps>
    
    <!-- ADD THESE LINES: -->
    <_BuildConfig Condition="'$(BuildConfig)' == ''">Release</_BuildConfig>
    <_BuildConfig Condition="'$(BuildConfig)' != ''">$(BuildConfig)</_BuildConfig>
  </PropertyGroup>
```

#### 4c. Update PreparePayloadWorkItem (around line 60)

Find:
```xml
  <ItemGroup>
    <PreparePayloadWorkItem Include="@(MAUIiOSScenario)">
      <Command>sudo xcode-select -s /Applications/Xcode_26.0.1.app; $(Python) pre.py publish -f $(PERFLAB_Framework)-ios --self-contained -c Release -r ios-arm64 $(NativeAOTCommandProps) --binlog $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName)/%(PreparePayloadWorkItem.ScenarioDirectoryName).binlog -o $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName); cd ../; zip -r %(PreparePayloadWorkItem.ScenarioDirectoryName).zip %(PreparePayloadWorkItem.ScenarioDirectoryName)</Command>
```

Change `-c Release` to `-c $(_BuildConfig)`:
```xml
  <ItemGroup>
    <PreparePayloadWorkItem Include="@(MAUIiOSScenario)">
      <Command>sudo xcode-select -s /Applications/Xcode_26.0.1.app; $(Python) pre.py publish -f $(PERFLAB_Framework)-ios --self-contained -c $(_BuildConfig) -r ios-arm64 $(NativeAOTCommandProps) --binlog $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName)/%(PreparePayloadWorkItem.ScenarioDirectoryName).binlog -o $(PreparePayloadWorkItemBaseDirectory)%(PreparePayloadWorkItem.ScenarioDirectoryName); cd ../; zip -r %(PreparePayloadWorkItem.ScenarioDirectoryName).zip %(PreparePayloadWorkItem.ScenarioDirectoryName)</Command>
```

---

## Step 5: Test Your Changes

### Local Testing

```bash
# Test with Release (default)
python scripts/run_performance_job.py \
  --run-kind maui_scenarios_android \
  --architecture arm64 \
  --os-group windows \
  --runtime-flavor mono \
  --codegen-type ProfiledAOT \
  --performance-repo-dir . \
  --is-scenario \
  --send-to-helix

# Test with Debug
python scripts/run_performance_job.py \
  --run-kind maui_scenarios_android \
  --architecture arm64 \
  --os-group windows \
  --runtime-flavor mono \
  --codegen-type ProfiledAOT \
  --build-config Debug \
  --performance-repo-dir . \
  --is-scenario \
  --send-to-helix
```

### Verification Steps

1. **Check binlog names**: Should include the build configuration
   - Release: `mauiandroid.mono_ProfiledAOT_Release.binlog`
   - Debug: `mauiandroid.mono_ProfiledAOT_Debug.binlog`

2. **Check job output**: Verify the pre.py command includes correct -c flag
   ```
   Looking for: pre.py publish ... -c Debug ...
   or: pre.py publish ... -c Release ...
   ```

3. **Check configurations**: Verify BuildConfig is in the run configurations
   ```python
   # Should see in logs:
   BuildConfig=Debug
   or
   BuildConfig=Release
   ```

4. **Pipeline test**: Trigger the pipeline and verify:
   - Both Release and Debug jobs appear
   - Jobs have distinct identifiers (Mono vs Mono_Debug)
   - No conflicts between parallel jobs

---

## Troubleshooting

### Issue: BuildConfig not being passed to proj file

**Symptom:** Still seeing hardcoded Release/Debug in builds

**Fix:** Check that `ci_setup_arguments.build_configs` includes BuildConfig:
```python
# In run_performance_job.py, verify:
ci_setup_arguments.build_configs=[f"{k}={v}" for k, v in configurations.items()]
# Should include BuildConfig=Debug or BuildConfig=Release
```

### Issue: Binlog has wrong name

**Symptom:** Binlog doesn't include build config

**Fix:** Verify `RunConfigsString` in proj file includes `$(_BuildConfig)`:
```xml
<RunConfigsString>$(RuntimeFlavor)_$(CodegenType)_$(_BuildConfig)</RunConfigsString>
```

### Issue: Jobs conflict with same name

**Symptom:** Pipeline shows only one of Release/Debug jobs

**Fix:** Ensure `additionalJobIdentifier` is different:
```yaml
# Release job:
additionalJobIdentifier: Mono

# Debug job:
additionalJobIdentifier: Mono_Debug
```

---

## Validation Checklist

Before submitting PR:

- [ ] All mobile scenario jobs have Release variants with explicit `buildConfig: Release`
- [ ] All mobile scenario jobs have Debug variants with `buildConfig: Debug`
- [ ] Debug jobs have unique `additionalJobIdentifier` (suffix with `_Debug`)
- [ ] `get_run_configurations` function has `build_config` parameter
- [ ] `get_run_configurations` adds BuildConfig for both Android and iOS
- [ ] `get_run_configurations` is called with `args.build_config`
- [ ] `maui_scenarios_android.proj` defines `_BuildConfig` property
- [ ] `maui_scenarios_android.proj` uses `-c $(_BuildConfig)` in pre.py command
- [ ] `maui_scenarios_android.proj` includes `$(_BuildConfig)` in `RunConfigsString`
- [ ] `maui_scenarios_ios.proj` defines `_BuildConfig` property
- [ ] `maui_scenarios_ios.proj` uses `-c $(_BuildConfig)` in pre.py command
- [ ] Local testing passes for both Release and Debug
- [ ] Pipeline testing passes for both Release and Debug
- [ ] No existing tests broken by changes

---

## Expected Results

After implementation:

1. **Pipeline Jobs:**
   - `maui_scenarios_android_mono_ProfiledAOT_Release`
   - `maui_scenarios_android_mono_ProfiledAOT_Debug`
   - `maui_scenarios_ios_mono_FullAOT_Release`
   - `maui_scenarios_ios_mono_FullAOT_Debug`
   - (and similar for all other configurations)

2. **Binlog Files:**
   - `mauiandroid.mono_ProfiledAOT_Release.binlog`
   - `mauiandroid.mono_ProfiledAOT_Debug.binlog`

3. **Build Commands:**
   - Release: `pre.py publish ... -c Release ...`
   - Debug: `pre.py publish ... -c Debug ...`

4. **Performance Results:**
   - Tagged with `BuildConfig=Release` or `BuildConfig=Debug`
   - Distinguishable in performance database
   - Comparable side-by-side
