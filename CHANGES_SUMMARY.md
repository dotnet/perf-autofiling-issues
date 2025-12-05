# Summary of Changes for Debug Configuration Support

## Quick Reference: What Changed and Where

### 1. `eng/pipelines/sdk-perf-jobs.yml`

**What:** Add duplicate job definitions with debug configuration

**Where:** In the `runPrivateJobs` section, for each mobile scenario job

**Change Pattern:**
```yaml
# For each existing Release job, add a Debug variant:

# BEFORE (implicit Release):
jobParameters:
  runKind: maui_scenarios_android
  runtimeFlavor: mono
  codeGenType: ProfiledAOT
  additionalJobIdentifier: Mono

# AFTER (explicit Release + new Debug):
jobParameters:
  runKind: maui_scenarios_android
  runtimeFlavor: mono
  codeGenType: ProfiledAOT
  additionalJobIdentifier: Mono
  buildConfig: Release  # Add this

# Plus new Debug job:
jobParameters:
  runKind: maui_scenarios_android
  runtimeFlavor: mono
  codeGenType: ProfiledAOT
  additionalJobIdentifier: Mono_Debug
  buildConfig: Debug  # Add this
```

**Jobs to Duplicate:**
- Maui Android scenario benchmarks (Mono ProfiledAOT)
- Maui Android scenario benchmarks (Mono AOT)
- Maui Android scenario benchmarks (CoreCLR JIT)
- Maui Android scenario benchmarks (CoreCLR R2R)
- Maui Android scenario benchmarks (CoreCLR R2R Composite)
- Maui Android scenario benchmarks (CoreCLR NativeAOT)
- Maui iOS Mono scenario benchmarks
- Maui iOS Native AOT scenario benchmarks

---

### 2. `scripts/run_performance_job.py`

#### Change 2a: Update `get_run_configurations` function signature

**Location:** ~Line 580

**Before:**
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
        javascript_engine: Optional[str] = None):
```

**After:**
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
        build_config: str = "Release"):  # ADD THIS LINE
```

#### Change 2b: Add BuildConfig to configurations dict

**Location:** In `get_run_configurations` function, in the mobile scenarios sections

**Add these lines:**
```python
# In maui_scenarios_android section (around line 645):
if run_kind == "maui_scenarios_android":
    if not runtime_flavor in ("mono", "coreclr"):
        raise Exception("Runtime flavor must be specified for maui_scenarios_android")
    configurations["CodegenType"] = str(codegen_type)
    configurations["RuntimeType"] = str(runtime_flavor)
    configurations["BuildConfig"] = str(build_config)  # ADD THIS LINE

# In maui_scenarios_ios section (around line 652):
if run_kind == "maui_scenarios_ios":
    if not runtime_flavor in ("mono", "coreclr"):
        raise Exception("Runtime flavor must be specified for maui_scenarios_ios")
    configurations["CodegenType"] = str(codegen_type)
    configurations["RuntimeType"] = str(runtime_flavor)
    configurations["BuildConfig"] = str(build_config)  # ADD THIS LINE
```

#### Change 2c: Pass build_config parameter

**Location:** ~Line 933 where `get_run_configurations` is called

**Before:**
```python
configurations = get_run_configurations(
    args.run_kind, args.runtime_type, args.codegen_type, args.pgo_run_type, args.physical_promotion_run_type,
    args.r2r_run_type, args.experiment_name, args.linking_type,
    args.runtime_flavor, args.ios_llvm_build, args.ios_strip_symbols, args.javascript_engine
)
```

**After:**
```python
configurations = get_run_configurations(
    args.run_kind, args.runtime_type, args.codegen_type, args.pgo_run_type, args.physical_promotion_run_type,
    args.r2r_run_type, args.experiment_name, args.linking_type,
    args.runtime_flavor, args.ios_llvm_build, args.ios_strip_symbols, args.javascript_engine,
    args.build_config  # ADD THIS LINE
)
```

---

### 3. `eng/performance/maui_scenarios_android.proj`

#### Change 3a: Add _BuildConfig property

**Location:** In the first `<PropertyGroup>` section, after the MSBuildArgs

**Add:**
```xml
<PropertyGroup>
    <!-- existing properties... -->
    
    <!-- Add these lines: -->
    <_BuildConfig Condition="'$(BuildConfig)' == ''">Release</_BuildConfig>
    <_BuildConfig Condition="'$(BuildConfig)' != ''">$(BuildConfig)</_BuildConfig>
    <RunConfigsString>$(RuntimeFlavor)_$(CodegenType)_$(_BuildConfig)</RunConfigsString>
</PropertyGroup>
```

**Note:** Update the existing `RunConfigsString` line to include `_$(_BuildConfig)` at the end.

#### Change 3b: Update pre.py publish command

**Location:** In `<PreparePayloadWorkItem>` ItemGroup

**Before:**
```xml
<Command>$(Python) pre.py publish -f $(PERFLAB_Framework)-android -r android-arm64 --self-contained --msbuild="$(_MSBuildArgs)" --binlog ... -o ...</Command>
```

**After:**
```xml
<Command>$(Python) pre.py publish -f $(PERFLAB_Framework)-android -r android-arm64 --self-contained -c $(_BuildConfig) --msbuild="$(_MSBuildArgs)" --binlog ... -o ...</Command>
```

**Change:** Add `-c $(_BuildConfig)` after `--self-contained`

---

### 4. `eng/performance/maui_scenarios_ios.proj`

#### Change 4a: Add _BuildConfig property

**Location:** In the PropertyGroup after `NativeAOTCommandProps`

**Add:**
```xml
<PropertyGroup>
    <!-- existing properties... -->
    
    <!-- Add these lines: -->
    <_BuildConfig Condition="'$(BuildConfig)' == ''">Release</_BuildConfig>
    <_BuildConfig Condition="'$(BuildConfig)' != ''">$(BuildConfig)</_BuildConfig>
</PropertyGroup>
```

#### Change 4b: Update pre.py publish command

**Location:** In `<PreparePayloadWorkItem>` ItemGroup

**Before:**
```xml
<Command>sudo xcode-select -s /Applications/Xcode_26.0.1.app; $(Python) pre.py publish -f $(PERFLAB_Framework)-ios --self-contained -c Release -r ios-arm64 $(NativeAOTCommandProps) --binlog ... -o ...; cd ../; zip -r ...</Command>
```

**After:**
```xml
<Command>sudo xcode-select -s /Applications/Xcode_26.0.1.app; $(Python) pre.py publish -f $(PERFLAB_Framework)-ios --self-contained -c $(_BuildConfig) -r ios-arm64 $(NativeAOTCommandProps) --binlog ... -o ...; cd ../; zip -r ...</Command>
```

**Change:** Replace `-c Release` with `-c $(_BuildConfig)`

---

## Testing Checklist

After applying changes:

- [ ] Verify Python script changes don't break existing functionality
- [ ] Verify .proj files use correct _BuildConfig variable
- [ ] Test Release configuration still works as expected
- [ ] Test Debug configuration produces debug builds
- [ ] Verify binlog names include build config for Android
- [ ] Verify job identifiers properly distinguish Debug vs Release
- [ ] Check that BuildConfig appears in performance results/telemetry

## Rollback Plan

If issues arise:
1. Remove duplicate Debug jobs from sdk-perf-jobs.yml
2. Revert changes to get_run_configurations (remove build_config parameter)
3. Revert .proj file changes (remove _BuildConfig properties, restore hardcoded values)

The changes are designed to be backward compatible - if buildConfig is not specified, it defaults to "Release".
