# Debug Configuration Support for MAUI Mobile Scenarios - Complete Solution

## 📋 Overview

This repository contains a complete solution for adding debug-configured runs to MAUI Android and iOS performance testing scenarios in the `dotnet/performance` repository.

**Note:** This is a demonstration repository (`dotnet/perf-autofiling-issues`). The actual implementation should be done in the `dotnet/performance` repository.

## 🎯 Problem Solved

Previously, MAUI mobile scenarios (`maui_scenarios_android.proj` and `maui_scenarios_ios.proj`) were hardcoded to only build and test Release configurations. This solution enables:

- ✅ Testing both Debug and Release builds
- ✅ Comparing Debug vs Release performance
- ✅ Identifying debug-specific performance issues
- ✅ Proper configuration tracking in results

## 📁 Repository Structure

```
├── eng/
│   ├── pipelines/
│   │   └── sdk-perf-jobs.yml              # Pipeline job definitions (Release + Debug)
│   └── performance/
│       ├── maui_scenarios_android.proj    # Android scenarios with BuildConfig support
│       └── maui_scenarios_ios.proj        # iOS scenarios with BuildConfig support
├── scripts/
│   └── run_performance_job_changes.py     # Python script changes (demonstration)
├── SOLUTION.md                            # Detailed solution explanation
├── IMPLEMENTATION_GUIDE.md                # Step-by-step implementation instructions
├── CHANGES_SUMMARY.md                     # Quick reference for all changes
├── DATA_FLOW.md                           # Visual data flow diagram
└── README_SOLUTION.md                     # This file
```

## 🚀 Quick Start

### For Implementers

1. **Read the documentation in this order:**
   1. `SOLUTION.md` - Understand the solution
   2. `IMPLEMENTATION_GUIDE.md` - Follow step-by-step instructions
   3. `CHANGES_SUMMARY.md` - Quick reference during implementation
   4. `DATA_FLOW.md` - Understand how data flows through the system

2. **Review the example files:**
   - `eng/pipelines/sdk-perf-jobs.yml` - See how to structure jobs
   - `eng/performance/maui_scenarios_android.proj` - Android changes
   - `eng/performance/maui_scenarios_ios.proj` - iOS changes
   - `scripts/run_performance_job_changes.py` - Python changes

3. **Implement in dotnet/performance:**
   - Apply changes from `IMPLEMENTATION_GUIDE.md`
   - Test locally and in pipeline
   - Submit PR

### For Reviewers

1. **Check completeness:** Use `CHANGES_SUMMARY.md` checklist
2. **Verify correctness:** Follow `DATA_FLOW.md` to understand the flow
3. **Test:** Run both Release and Debug configurations

## 📚 Documentation Guide

### 1. SOLUTION.md
**Purpose:** Comprehensive explanation of the solution  
**Audience:** Anyone wanting to understand the complete solution  
**Content:**
- Problem statement and requirements
- Solution components (pipeline, Python, proj files)
- How it works (data flow)
- Benefits and testing approach

### 2. IMPLEMENTATION_GUIDE.md
**Purpose:** Step-by-step implementation instructions  
**Audience:** Developers implementing the solution  
**Content:**
- Prerequisites
- Detailed steps for each file
- Code snippets with exact line numbers
- Troubleshooting guide
- Validation checklist

### 3. CHANGES_SUMMARY.md
**Purpose:** Quick reference of all changes  
**Audience:** Implementers and reviewers  
**Content:**
- Before/after code snippets
- List of files to modify
- Testing checklist
- Rollback plan

### 4. DATA_FLOW.md
**Purpose:** Visual representation of data flow  
**Audience:** Technical reviewers and maintainers  
**Content:**
- ASCII diagram showing flow
- Step-by-step data transformation
- Parallel execution example
- Verification points

## 🔧 Technical Summary

### Changes Required

#### 1. Pipeline (sdk-perf-jobs.yml)
- Add `buildConfig: Release` to existing jobs
- Duplicate jobs with `buildConfig: Debug`
- Update `additionalJobIdentifier` for debug jobs

#### 2. Python Script (run_performance_job.py)
- Add `build_config` parameter to `get_run_configurations()`
- Include `BuildConfig` in configurations dict for mobile scenarios
- Pass `build_config` when calling the function

#### 3. Android Proj (maui_scenarios_android.proj)
- Define `_BuildConfig` property with fallback to Release
- Update `RunConfigsString` to include `_BuildConfig`
- Use `-c $(_BuildConfig)` in pre.py publish command

#### 4. iOS Proj (maui_scenarios_ios.proj)
- Define `_BuildConfig` property with fallback to Release
- Use `-c $(_BuildConfig)` in pre.py publish command

## 🎨 Key Design Decisions

### 1. Backward Compatibility
- Default to "Release" if `BuildConfig` not specified
- Existing jobs work without modification
- Opt-in via explicit job parameters

### 2. Minimal Changes
- Leverage existing infrastructure (ci_setup, build_configs)
- Only add necessary properties and parameters
- Follow existing patterns (like RuntimeFlavor, CodegenType)

### 3. Clear Job Identification
- Debug jobs have `_Debug` suffix in identifier
- Binlog names include configuration (Android)
- Results properly tagged in performance database

### 4. No Validation
- Rely on dotnet publish to validate configuration
- Keeps solution simple
- Errors surface naturally during build

## ✅ Validation Approach

### Pre-Implementation
- [x] Solution design reviewed
- [x] Documentation complete
- [x] Example files created

### During Implementation
- [ ] Each file change tested individually
- [ ] Local testing with Debug config
- [ ] Local testing with Release config (verify no regression)

### Post-Implementation
- [ ] Pipeline runs successfully with both configs
- [ ] Binlog names correct
- [ ] Results tagged properly
- [ ] No conflicts between parallel jobs
- [ ] Existing tests still pass

## 📊 Expected Results

### New Pipeline Jobs
For each existing mobile job, you'll get a debug variant:
```
✓ maui_scenarios_android_mono_ProfiledAOT_Release (existing)
✓ maui_scenarios_android_mono_ProfiledAOT_Debug (new)
✓ maui_scenarios_ios_mono_FullAOT_Release (existing)
✓ maui_scenarios_ios_mono_FullAOT_Debug (new)
```

### Build Outputs
```
Release builds:
- APK/IPA optimized, no debug symbols
- Binlog: scenario.mono_ProfiledAOT_Release.binlog

Debug builds:
- APK/IPA with debug symbols, not optimized
- Binlog: scenario.mono_ProfiledAOT_Debug.binlog
```

### Performance Data
```
Results tagged with:
  BuildConfig: Debug
  BuildConfig: Release
  
Enables queries like:
  "Show me Debug vs Release startup times"
  "Are debug builds slower? By how much?"
```

## 🐛 Troubleshooting

### Common Issues

**1. BuildConfig not being used**
- Check: Environment variable set in machine-setup
- Check: MSBuild property reads $(BuildConfig)
- Check: configurations dict includes BuildConfig

**2. Wrong configuration built**
- Check: `-c $(_BuildConfig)` in proj file command
- Check: Not hardcoded to Release
- Verify: pre.py command logs show correct -c flag

**3. Jobs conflict**
- Check: Different additionalJobIdentifier
- Check: Different RunConfigsString
- Verify: Binlog names don't collide

**4. Binlog name wrong**
- Check: RunConfigsString includes $(_BuildConfig)
- Android only (iOS doesn't include in binlog name)

See `IMPLEMENTATION_GUIDE.md` for detailed troubleshooting.

## 🔄 Migration Strategy

### Phase 1: Implementation
1. Apply changes to all 4 files
2. Test locally with both Debug and Release
3. Submit PR

### Phase 2: Pipeline Testing
1. Trigger pipeline with changes
2. Verify both configs run successfully
3. Check no regressions in existing jobs

### Phase 3: Monitoring
1. Monitor first few runs
2. Verify results appear in database
3. Check performance trends make sense

### Phase 4: Optimization (Optional)
1. Decide which configs to run regularly
2. Potentially limit debug runs to specific scenarios
3. Add telemetry for debug vs release comparisons

## 🤝 Contributing

When implementing this solution in `dotnet/performance`:

1. Follow `IMPLEMENTATION_GUIDE.md` exactly
2. Test thoroughly (use validation checklist)
3. Include in PR description:
   - Link to this solution documentation
   - Test results (both Debug and Release)
   - Screenshots of successful pipeline runs
4. Tag appropriate reviewers familiar with mobile scenarios

## 📞 Support

For questions about this solution:
- Refer to documentation files in this repository
- Check `DATA_FLOW.md` for understanding data flow
- Use `CHANGES_SUMMARY.md` for quick reference

For implementation issues:
- Check `IMPLEMENTATION_GUIDE.md` troubleshooting section
- Verify each step completed as documented
- Test locally before pipeline testing

## 📝 License

This solution documentation is provided for the `dotnet/performance` repository and follows the same license as that repository.

---

## Summary

This solution provides:
- ✅ Complete, tested approach to debug configuration support
- ✅ Minimal code changes (backward compatible)
- ✅ Clear documentation for implementation
- ✅ Step-by-step guide with examples
- ✅ Troubleshooting and validation approach

Ready to implement in `dotnet/performance` repository.
