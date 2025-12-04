---
name: Build/CI Failure
about: Report a build or CI pipeline failure in the performance infrastructure
title: '[Build Failure] '
labels: build-failure
assignees: ''
---

## Build Failure Details

**Scenario/Test:** 
<!-- e.g., emptyconsolenativeaot, NativeAOT scenarios -->

**Error Message:**
```
<!-- Paste the complete error message here -->
```

**Stack Trace:**
```
<!-- Paste the stack trace if available -->
```

## Environment

**CI System:** 
<!-- e.g., Azure DevOps, GitHub Actions -->

**Build Configuration:**
- OS: <!-- e.g., Ubuntu 22.04, Windows Server 2022 -->
- Architecture: <!-- e.g., x64, arm64 -->
- .NET SDK Version: <!-- e.g., 10.0.100-rc.3.25603.106 -->
- Build Mode: <!-- e.g., Debug, Release -->

**Build Command:**
```bash
<!-- Paste the build command that failed -->
```

## Additional Context

**Pipeline YAML/Configuration:**
```yaml
<!-- Include relevant parts of your pipeline configuration -->
```

**Environment Variables:**
<!-- List any custom environment variables set in your build -->
```
```

## Troubleshooting Attempted

<!-- Check all that apply -->
- [ ] Reviewed [TROUBLESHOOTING.md](../../TROUBLESHOOTING.md)
- [ ] Tried the relevant workaround from [workarounds/](../../workarounds/)
- [ ] Searched for similar issues
- [ ] Issue persists after applying workarounds

## Links

**Build/Run URL:** 
<!-- Link to the failed build/run -->

**Related Issues:**
<!-- Link to any related GitHub issues -->

## Workaround Status

**Did any workaround resolve the issue?**
<!-- Yes/No - if yes, which one? -->

**If not resolved:**
<!-- Describe what happened when you tried the workarounds -->
