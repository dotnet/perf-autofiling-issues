# Documentation Index

## 🎯 Start Here

👉 **[README_SOLUTION.md](README_SOLUTION.md)** - Complete overview of the solution

## 📖 Documentation by Role

### For Implementers (Developers)
Follow these documents in order:

1. **[SOLUTION.md](SOLUTION.md)** - Understand what you're implementing
2. **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Follow step-by-step
3. **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - Quick reference while coding

### For Reviewers
Use these documents to review changes:

1. **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - See what changed and where
2. **[DATA_FLOW.md](DATA_FLOW.md)** - Understand the complete flow
3. **[SOLUTION.md](SOLUTION.md)** - Deep dive into the solution

### For Project Managers / PMs
Quick summary:

1. **[README_SOLUTION.md](README_SOLUTION.md)** - High-level overview
2. **[SOLUTION.md](SOLUTION.md)** - Benefits section

### For Maintainers
Long-term reference:

1. **[DATA_FLOW.md](DATA_FLOW.md)** - How data flows through the system
2. **[SOLUTION.md](SOLUTION.md)** - Complete technical details
3. **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Troubleshooting section

## 📁 File Reference

### Documentation Files

| File | Purpose | Audience | Read Time |
|------|---------|----------|-----------|
| [README_SOLUTION.md](README_SOLUTION.md) | Complete overview and entry point | Everyone | 5 min |
| [SOLUTION.md](SOLUTION.md) | Detailed technical explanation | Technical | 15 min |
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) | Step-by-step instructions | Implementers | 20 min |
| [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) | Quick reference of changes | Implementers/Reviewers | 5 min |
| [DATA_FLOW.md](DATA_FLOW.md) | Visual data flow diagram | Technical/Reviewers | 10 min |

### Implementation Files

| File | Description | Lines Changed |
|------|-------------|---------------|
| [eng/pipelines/sdk-perf-jobs.yml](eng/pipelines/sdk-perf-jobs.yml) | Pipeline jobs (Release + Debug) | ~8 jobs duplicated |
| [eng/performance/maui_scenarios_android.proj](eng/performance/maui_scenarios_android.proj) | Android scenarios project | ~5 lines |
| [eng/performance/maui_scenarios_ios.proj](eng/performance/maui_scenarios_ios.proj) | iOS scenarios project | ~4 lines |
| [scripts/run_performance_job_changes.py](scripts/run_performance_job_changes.py) | Python script changes demo | ~5 lines |

## 🔍 Find Information By Topic

### Understanding the Problem
- **[SOLUTION.md#Overview](SOLUTION.md#overview)** - Problem statement
- **[README_SOLUTION.md#Problem-Solved](README_SOLUTION.md#-problem-solved)** - What we're solving

### Understanding the Solution
- **[SOLUTION.md#Solution-Components](SOLUTION.md#solution-components)** - Complete breakdown
- **[DATA_FLOW.md](DATA_FLOW.md)** - How it works visually
- **[README_SOLUTION.md#Technical-Summary](README_SOLUTION.md#-technical-summary)** - Quick technical overview

### Implementing the Solution
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Complete guide
- **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - Quick reference
- **[IMPLEMENTATION_GUIDE.md#Validation-Checklist](IMPLEMENTATION_GUIDE.md#validation-checklist)** - Before submitting

### Reviewing Changes
- **[CHANGES_SUMMARY.md](CHANGES_SUMMARY.md)** - What changed
- **[DATA_FLOW.md#Verification-Points](DATA_FLOW.md#verification-points)** - How to verify
- **[IMPLEMENTATION_GUIDE.md#Troubleshooting](IMPLEMENTATION_GUIDE.md#troubleshooting)** - Common issues

### Testing
- **[IMPLEMENTATION_GUIDE.md#Step-5-Test-Your-Changes](IMPLEMENTATION_GUIDE.md#step-5-test-your-changes)** - Testing guide
- **[SOLUTION.md#Testing](SOLUTION.md#testing)** - Testing approach
- **[README_SOLUTION.md#Validation-Approach](README_SOLUTION.md#-validation-approach)** - Validation checklist

### Troubleshooting
- **[IMPLEMENTATION_GUIDE.md#Troubleshooting](IMPLEMENTATION_GUIDE.md#troubleshooting)** - Detailed guide
- **[README_SOLUTION.md#Troubleshooting](README_SOLUTION.md#-troubleshooting)** - Common issues
- **[DATA_FLOW.md#Error-Handling](DATA_FLOW.md#error-handling)** - What happens on errors

## 🚀 Quick Start Paths

### Path 1: "I need to implement this now"
1. [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) - Start here
2. [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) - Keep open as reference
3. [IMPLEMENTATION_GUIDE.md#Validation-Checklist](IMPLEMENTATION_GUIDE.md#validation-checklist) - Check before PR

### Path 2: "I need to understand this first"
1. [README_SOLUTION.md](README_SOLUTION.md) - High-level overview
2. [SOLUTION.md](SOLUTION.md) - Deep dive
3. [DATA_FLOW.md](DATA_FLOW.md) - See how it works
4. Then follow Path 1

### Path 3: "I need to review a PR"
1. [CHANGES_SUMMARY.md](CHANGES_SUMMARY.md) - What to look for
2. [DATA_FLOW.md](DATA_FLOW.md) - Verify flow is correct
3. [IMPLEMENTATION_GUIDE.md#Troubleshooting](IMPLEMENTATION_GUIDE.md#troubleshooting) - Check for issues

### Path 4: "I need to present/explain this"
1. [README_SOLUTION.md](README_SOLUTION.md) - Executive summary
2. [DATA_FLOW.md](DATA_FLOW.md) - Visual diagram to show
3. [SOLUTION.md#Benefits](SOLUTION.md#benefits) - Why we did this

## 📋 Checklists

### Implementation Checklist
See: [IMPLEMENTATION_GUIDE.md#Validation-Checklist](IMPLEMENTATION_GUIDE.md#validation-checklist)

### Testing Checklist
See: [CHANGES_SUMMARY.md#Testing-Checklist](CHANGES_SUMMARY.md#testing-checklist)

### Review Checklist
- [ ] All 4 files modified correctly
- [ ] Build config defaults to Release
- [ ] Debug jobs have _Debug identifier
- [ ] Commands use -c $(_BuildConfig)
- [ ] Binlog names include config (Android)
- [ ] No hardcoded Release/Debug
- [ ] Tests pass for both configs

## 🎓 Learning Resources

### If you're new to...

**Performance Testing:**
- Read [SOLUTION.md#Overview](SOLUTION.md#overview)
- Review example jobs in [sdk-perf-jobs.yml](eng/pipelines/sdk-perf-jobs.yml)

**MSBuild:**
- Check [IMPLEMENTATION_GUIDE.md#Step-3](IMPLEMENTATION_GUIDE.md#step-3-update-maui_scenarios_androidproj)
- See property examples in proj files

**Python Performance Scripts:**
- Review [run_performance_job_changes.py](scripts/run_performance_job_changes.py)
- Read [DATA_FLOW.md#Step-3](DATA_FLOW.md)

**Azure Pipelines:**
- Check [IMPLEMENTATION_GUIDE.md#Step-1](IMPLEMENTATION_GUIDE.md#step-1-update-sdk-perf-jobsyml)
- See job structure in [sdk-perf-jobs.yml](eng/pipelines/sdk-perf-jobs.yml)

## 🔗 Related Documentation

In the actual dotnet/performance repository, see also:
- `docs/` - General performance testing documentation
- `eng/pipelines/README.md` - Pipeline documentation
- `scripts/README.md` - Scripts documentation

## 📞 Getting Help

If you can't find what you need:

1. **Check the INDEX** (this file) - Quick search by topic
2. **Start with README_SOLUTION.md** - Might have the answer
3. **Use the search function** - Search all .md files
4. **Check troubleshooting sections** - Common issues covered

## 🗺️ Solution Overview Diagram

```
Problem: Only Release builds tested
    ↓
Solution: Add Debug builds support
    ↓
├─ Pipeline (yml) → Duplicate jobs with buildConfig: Debug
├─ Python (py)    → Add BuildConfig to configurations
├─ Android (proj) → Use -c $(_BuildConfig)
└─ iOS (proj)     → Use -c $(_BuildConfig)
    ↓
Result: Both Debug and Release tested
    ↓
Benefits: Compare configurations, find debug issues
```

## 📊 Documentation Status

| Document | Status | Last Updated |
|----------|--------|--------------|
| README_SOLUTION.md | ✅ Complete | Latest |
| SOLUTION.md | ✅ Complete | Latest |
| IMPLEMENTATION_GUIDE.md | ✅ Complete | Latest |
| CHANGES_SUMMARY.md | ✅ Complete | Latest |
| DATA_FLOW.md | ✅ Complete | Latest |
| INDEX.md | ✅ Complete | Latest |

All documentation is ready for implementation in `dotnet/performance` repository.

---

**Navigation:** [↑ Back to Top](#documentation-index) | [→ Start Reading](README_SOLUTION.md)
