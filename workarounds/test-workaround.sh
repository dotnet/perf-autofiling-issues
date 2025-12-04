#!/bin/bash
# Test script to verify the nativeaot-environment-fix.sh workaround

set -e

echo "=== Testing NativeAOT Environment Fix Workaround ==="
echo ""

# Test 1: Clean environment (no Azure DevOps, no build config vars)
echo "Test 1: Clean environment"
echo "-------------------------"
unset _BUILDCONFIG BUILDCONFIG BuildConfig MSBuildTaskHostDoNotUpdateEnvironment TF_BUILD AGENT_ID
source ./nativeaot-environment-fix.sh
if [ -z "$MSBuildTaskHostDoNotUpdateEnvironment" ]; then
    echo "✓ PASS: Workaround not applied in clean environment"
else
    echo "✗ FAIL: Workaround should not be applied in clean environment"
    exit 1
fi
echo ""

# Test 2: With _BUILDCONFIG variable present
echo "Test 2: _BUILDCONFIG variable present"
echo "--------------------------------------"
unset MSBuildTaskHostDoNotUpdateEnvironment TF_BUILD AGENT_ID
export _BUILDCONFIG="Release"
source ./nativeaot-environment-fix.sh
if [ "$MSBuildTaskHostDoNotUpdateEnvironment" = "1" ]; then
    echo "✓ PASS: Workaround applied when _BUILDCONFIG is present"
else
    echo "✗ FAIL: Workaround should be applied when _BUILDCONFIG is present"
    exit 1
fi
unset _BUILDCONFIG MSBuildTaskHostDoNotUpdateEnvironment
echo ""

# Test 3: Azure DevOps environment (TF_BUILD)
echo "Test 3: Azure DevOps environment (TF_BUILD)"
echo "--------------------------------------------"
unset MSBuildTaskHostDoNotUpdateEnvironment _BUILDCONFIG
export TF_BUILD="True"
source ./nativeaot-environment-fix.sh
if [ "$MSBuildTaskHostDoNotUpdateEnvironment" = "1" ]; then
    echo "✓ PASS: Workaround applied in Azure DevOps environment"
else
    echo "✗ FAIL: Workaround should be applied in Azure DevOps environment"
    exit 1
fi
unset TF_BUILD MSBuildTaskHostDoNotUpdateEnvironment
echo ""

# Test 4: Azure DevOps environment (AGENT_ID)
echo "Test 4: Azure DevOps environment (AGENT_ID)"
echo "--------------------------------------------"
unset MSBuildTaskHostDoNotUpdateEnvironment TF_BUILD
export AGENT_ID="12345"
source ./nativeaot-environment-fix.sh
if [ "$MSBuildTaskHostDoNotUpdateEnvironment" = "1" ]; then
    echo "✓ PASS: Workaround applied with AGENT_ID present"
else
    echo "✗ FAIL: Workaround should be applied with AGENT_ID present"
    exit 1
fi
unset AGENT_ID MSBuildTaskHostDoNotUpdateEnvironment
echo ""

# Test 5: Verify script executes without errors
echo "Test 5: Script syntax validation"
echo "---------------------------------"
if bash -n ./nativeaot-environment-fix.sh; then
    echo "✓ PASS: Script syntax is valid"
else
    echo "✗ FAIL: Script has syntax errors"
    exit 1
fi
echo ""

# Test 6: Check script is executable
echo "Test 6: Executable permissions"
echo "-------------------------------"
if [ -x ./nativeaot-environment-fix.sh ]; then
    echo "✓ PASS: Script has execute permissions"
else
    echo "✗ FAIL: Script is not executable"
    exit 1
fi
echo ""

echo "=== All tests passed! ==="
echo ""
echo "The workaround script correctly:"
echo "- Skips workaround in clean environments"
echo "- Applies workaround when build config variables are present"
echo "- Applies workaround in Azure DevOps environments"
echo "- Has valid syntax and execute permissions"
