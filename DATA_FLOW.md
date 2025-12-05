# Data Flow Diagram: BuildConfig Through the System

## Overview

This document shows how the `BuildConfig` parameter flows through the performance testing system from the pipeline definition to the final build command.

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Pipeline Definition (sdk-perf-jobs.yml)                       │
│                                                                   │
│   jobParameters:                                                  │
│     runKind: maui_scenarios_android                              │
│     buildConfig: Debug  ◄─── SOURCE OF BUILD CONFIG             │
│     runtimeFlavor: mono                                          │
│     codeGenType: ProfiledAOT                                     │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ Passed via job template
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Job Template / Build Script                                   │
│                                                                   │
│   Sets pipeline variables:                                        │
│     --build-config Debug                                         │
│                                                                   │
│   Calls: python run_performance_job.py \                        │
│            --build-config Debug \                                │
│            --run-kind maui_scenarios_android ...                 │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ Command line argument
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Python Script (run_performance_job.py)                        │
│                                                                   │
│   RunPerformanceJobArgs:                                          │
│     build_config = "Debug"  ◄─── From command line              │
│                                                                   │
│   Call get_run_configurations(..., build_config="Debug")        │
│                                                                   │
│   Returns configurations dict:                                    │
│     {                                                             │
│       "RunKind": "maui_scenarios_android",                       │
│       "RuntimeType": "mono",                                     │
│       "CodegenType": "ProfiledAOT",                              │
│       "BuildConfig": "Debug"  ◄─── ADDED HERE                   │
│     }                                                             │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ Via ci_setup_arguments.build_configs
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. CI Setup (ci_setup.py)                                        │
│                                                                   │
│   build_configs = [                                               │
│     "RunKind=maui_scenarios_android",                            │
│     "RuntimeType=mono",                                          │
│     "CodegenType=ProfiledAOT",                                   │
│     "BuildConfig=Debug"                                          │
│   ]                                                               │
│                                                                   │
│   Writes to machine-setup script:                                │
│     export BuildConfig=Debug                                     │
│     export RunKind=maui_scenarios_android                        │
│     export RuntimeType=mono                                      │
│     export CodegenType=ProfiledAOT                               │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ Environment variables
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Helix Machine Setup                                            │
│                                                                   │
│   Runs machine-setup.sh/.cmd which sets:                         │
│     BuildConfig=Debug (as environment variable)                  │
│     RuntimeType=mono                                             │
│     CodegenType=ProfiledAOT                                      │
│     RunKind=maui_scenarios_android                               │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ MSBuild reads environment
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. Project File (maui_scenarios_android.proj)                    │
│                                                                   │
│   <PropertyGroup>                                                 │
│     <!-- Reads from environment variable -->                     │
│     <_BuildConfig Condition="'$(BuildConfig)' == ''">            │
│       Release                                                     │
│     </_BuildConfig>                                               │
│     <_BuildConfig Condition="'$(BuildConfig)' != ''">            │
│       $(BuildConfig)  ◄─── FROM ENVIRONMENT = "Debug"           │
│     </_BuildConfig>                                               │
│                                                                   │
│     <!-- Include in run config string -->                        │
│     <RunConfigsString>                                            │
│       $(RuntimeFlavor)_$(CodegenType)_$(_BuildConfig)            │
│       = mono_ProfiledAOT_Debug                                   │
│     </RunConfigsString>                                           │
│   </PropertyGroup>                                                │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ Used in command
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. PreparePayloadWorkItem Command                                 │
│                                                                   │
│   <Command>                                                       │
│     $(Python) pre.py publish \                                   │
│       -f net9.0-android \                                        │
│       -r android-arm64 \                                         │
│       --self-contained \                                         │
│       -c $(_BuildConfig) \  ◄─── USES: "Debug"                  │
│       --msbuild="..." \                                          │
│       --binlog path/mono_ProfiledAOT_Debug.binlog \  ◄─── IN NAME│
│       -o output/path                                             │
│   </Command>                                                      │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ Executed on Helix
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. pre.py Script Execution                                        │
│                                                                   │
│   Calls dotnet publish with:                                      │
│     dotnet publish \                                             │
│       -c Debug \  ◄─── FINAL USE: Creates Debug build           │
│       -f net9.0-android \                                        │
│       -r android-arm64 \                                         │
│       --self-contained \                                         │
│       /p:... (MSBuild args)                                      │
│                                                                   │
│   Result:                                                         │
│     ✓ Debug APK built                                            │
│     ✓ Binlog: mono_ProfiledAOT_Debug.binlog                     │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
                                      │ Artifacts uploaded
                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. Results & Telemetry                                            │
│                                                                   │
│   Performance results tagged with:                                │
│     BuildConfig: Debug                                           │
│     RunKind: maui_scenarios_android                              │
│     RuntimeType: mono                                            │
│     CodegenType: ProfiledAOT                                     │
│                                                                   │
│   Queryable and comparable with Release builds                   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Points

### 1. Configuration Source
- **Origin:** `buildConfig` parameter in `sdk-perf-jobs.yml`
- **Default:** "Release" (if not specified)
- **Values:** "Debug" or "Release"

### 2. Python Script Processing
- **Input:** Command line arg `--build-config`
- **Processing:** Added to configurations dict as "BuildConfig"
- **Output:** Passed to ci_setup via build_configs

### 3. Environment Variable
- **Name:** `BuildConfig`
- **Set by:** ci_setup.py in machine-setup script
- **Available to:** MSBuild project files

### 4. MSBuild Property
- **Name:** `_BuildConfig` (internal) / `BuildConfig` (external)
- **Usage:** In pre.py command via `-c $(_BuildConfig)`
- **Also used in:** RunConfigsString for binlog naming

### 5. Final Effect
- **Passed to:** `dotnet publish -c Debug/Release`
- **Result:** Proper build configuration applied
- **Telemetry:** BuildConfig included in performance data

## Parallel Flow Example

### Release Job
```
buildConfig: Release
  → args.build_config = "Release"
    → configurations["BuildConfig"] = "Release"
      → export BuildConfig=Release
        → _BuildConfig = "Release"
          → -c Release
            → Debug APK
```

### Debug Job (runs in parallel)
```
buildConfig: Debug
  → args.build_config = "Debug"
    → configurations["BuildConfig"] = "Debug"
      → export BuildConfig=Debug
        → _BuildConfig = "Debug"
          → -c Debug
            → Release APK
```

Both jobs can run simultaneously without conflict because:
1. Different job identifiers (Mono vs Mono_Debug)
2. Different output directories (via RunConfigsString)
3. Different binlog names (includes BuildConfig)

## Error Handling

### If BuildConfig not set
```
Pipeline → (no buildConfig) → args.build_config = "Release" (default)
                            → configurations["BuildConfig"] = "Release"
                            → Still works with Release
```

### If BuildConfig invalid
```
Pipeline → buildConfig: "InvalidValue"
        → args.build_config = "InvalidValue"
        → pre.py publish -c InvalidValue
        → dotnet publish fails with error
```

**Note:** No validation is added; dotnet publish will reject invalid configs.

## Verification Points

You can verify the flow at each step:

1. **Pipeline logs:** Look for `--build-config Debug` in command
2. **Python logs:** Check configurations dict includes `BuildConfig=Debug`
3. **machine-setup script:** Verify `export BuildConfig=Debug` line
4. **Pre.py command:** Verify `-c Debug` in the command
5. **Build output:** Check debug symbols and optimization in APK/IPA
6. **Binlog name:** Should include `_Debug` or `_Release`
7. **Results:** Query for `BuildConfig=Debug` in performance DB

## Alternative Flow (iOS)

iOS follows the same flow but with minor differences:

```
Same steps 1-6, then:

7. iOS proj file:
   <Command>
     ... pre.py publish ... -c $(_BuildConfig) ...
   </Command>
   
   Note: iOS doesn't include BuildConfig in binlog name
         (uses just scenario name)

8-9. Same as Android
```

## Summary

The BuildConfig parameter flows cleanly through the system:
- **Pipeline** defines it
- **Python** processes it into configurations
- **ci_setup** exports it as environment variable
- **MSBuild** reads it and uses in commands
- **pre.py** passes it to dotnet publish
- **Results** include it for analysis

All with minimal code changes and full backward compatibility.
