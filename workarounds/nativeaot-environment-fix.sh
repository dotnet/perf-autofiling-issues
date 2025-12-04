#!/bin/bash
# Workaround script for NativeAOT scenarios _BUILDCONFIG duplicate key error
# This script cleans up duplicate environment variables that may cause MSBuild errors

echo "Checking for duplicate environment variables..."

# Function to check for case-insensitive duplicates
check_duplicates() {
    local varname="$1"
    local count=$(printenv | grep -i "^${varname}=" | wc -l)
    if [ "$count" -gt 1 ]; then
        echo "WARNING: Found $count instances of ${varname} (case-insensitive)"
        printenv | grep -i "^${varname}="
        return 1
    fi
    return 0
}

# Check common build configuration variables
has_duplicates=0
for var in "_BUILDCONFIG" "BUILDCONFIG" "BuildConfig"; do
    if ! check_duplicates "$var"; then
        has_duplicates=1
    fi
done

if [ "$has_duplicates" -eq 1 ]; then
    echo ""
    echo "Found duplicate environment variables. Applying workaround..."
    echo "Setting MSBuildTaskHostDoNotUpdateEnvironment=1 to disable environment synchronization"
    export MSBuildTaskHostDoNotUpdateEnvironment=1
else
    echo "No duplicate environment variables detected."
fi

# Optional: Clean up specific known problematic variables
# Uncomment if you want to forcefully remove _BUILDCONFIG
# unset _BUILDCONFIG
# unset BUILDCONFIG
# unset BuildConfig

echo ""
echo "Environment check complete. Proceeding with build..."
