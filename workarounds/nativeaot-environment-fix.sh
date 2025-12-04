#!/bin/bash
# Workaround script for NativeAOT scenarios _BUILDCONFIG duplicate key error
# This script applies the MSBuild workaround to prevent environment variable sync issues

echo "Applying NativeAOT environment workaround..."

# The duplicate environment variable issue occurs when the Azure DevOps agent or
# build environment has variables set at multiple levels (system, agent, pipeline).
# Since bash doesn't allow us to detect these cross-process duplicates, we apply
# the workaround preventively when known problematic variables exist.

# Check if _BUILDCONFIG or similar variables are set
has_buildconfig_vars=0
if [ -n "$_BUILDCONFIG" ] || [ -n "$BUILDCONFIG" ] || [ -n "$BuildConfig" ]; then
    has_buildconfig_vars=1
    echo "Build configuration variables detected in environment:"
    [ -n "$_BUILDCONFIG" ] && echo "  _BUILDCONFIG=$_BUILDCONFIG"
    [ -n "$BUILDCONFIG" ] && echo "  BUILDCONFIG=$BUILDCONFIG"
    [ -n "$BuildConfig" ] && echo "  BuildConfig=$BuildConfig"
fi

# In Azure DevOps environments, apply the workaround preventively
# since we can't detect duplicate variables set at different levels
if [ -n "$TF_BUILD" ] || [ -n "$AGENT_ID" ]; then
    echo "Azure DevOps environment detected."
    echo "Applying MSBuildTaskHostDoNotUpdateEnvironment=1 workaround to prevent duplicate key errors."
    export MSBuildTaskHostDoNotUpdateEnvironment=1
elif [ "$has_buildconfig_vars" -eq 1 ]; then
    echo "Build configuration variables present."
    echo "Applying MSBuildTaskHostDoNotUpdateEnvironment=1 workaround as a precaution."
    export MSBuildTaskHostDoNotUpdateEnvironment=1
else
    echo "No Azure DevOps environment or build configuration variables detected."
    echo "Skipping workaround."
fi

echo ""
echo "Environment setup complete. Proceeding with build..."
