"""
DEMONSTRATION FILE FOR dotnet/perf-autofiling-issues REPOSITORY
================================================================

This file demonstrates the changes needed to run_performance_job.py in the
dotnet/performance repository.

⚠️ IMPORTANT: This is NOT a standalone script. Apply these changes to the existing
   run_performance_job.py file in the dotnet/performance repository.

The changes shown here follow the existing parameter naming conventions in the
actual run_performance_job.py file (using snake_case: build_config).
"""

# CHANGE 1: Update the RunPerformanceJobArgs dataclass to include build_config with default "Release"
# Location: Around line 58 in the original file
# The build_config parameter already exists with default "Release", so no change needed here
# But we need to ensure it's used for mobile scenarios

# CHANGE 2: Update get_run_configurations function
# Location: Around line 580 in the original file

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
        build_config: str = "Release"):  # ADD THIS PARAMETER
    
    configurations = { "CompilationMode": "Tiered", "RunKind": run_kind }

    is_aot = codegen_type.lower() == "aot"
    if runtime_type == "mono":
        llvm = is_aot and not run_kind == "android_scenarios"
        configurations["LLVM"] = str(llvm)
        configurations["MonoInterpreter"] = str(codegen_type.lower() == "interpreter")
        configurations["MonoAOT"] = str(is_aot)

    if runtime_type == "wasm":
        configurations["CompilationMode"] = "wasm"
        if is_aot:
            configurations["AOT"] = "true"

        if javascript_engine == "javascriptcore":
            configurations["JSEngine"] = "javascriptcore"

    if pgo_run_type == "nodynamicpgo":
        configurations["PGOType"] = "nodynamicpgo"

    if physical_promotion_run_type == "physicalpromotion":
        configurations["PhysicalPromotionType"] = "physicalpromotion"

    if r2r_run_type == "nor2r":
        configurations["R2RType"] = "nor2r"

    if experiment_name is not None:
        configurations["ExperimentName"] = experiment_name

    # dotnet/runtime Android sample app scenarios
    if run_kind == "android_scenarios":
        if not runtime_flavor in ("mono", "coreclr"):
            raise Exception("Runtime flavor must be specified for runtime android scenarios")
        configurations["CodegenType"] = str(codegen_type)
        configurations["LinkingType"] = str(linking_type)
        configurations["RuntimeType"] = str(runtime_flavor)

    # dotnet/runtime iOS sample app scenarios
    if run_kind == "ios_scenarios":
        if not runtime_flavor in ("mono", "coreclr"):
            raise Exception("Runtime flavor must be specified for runtime ios scenarios")
        configurations["CodegenType"] = str(codegen_type)
        configurations["RuntimeType"] = str(runtime_flavor)
        configurations["iOSStripSymbols"] = str(ios_strip_symbols)

        if runtime_flavor == "mono":
            configurations["iOSLlvmBuild"] = str(ios_llvm_build)

    # .NET Android and .NET MAUI Android sample app scenarios
    if run_kind == "maui_scenarios_android":
        if not runtime_flavor in ("mono", "coreclr"):
            raise Exception("Runtime flavor must be specified for maui_scenarios_android")
        configurations["CodegenType"] = str(codegen_type)
        configurations["RuntimeType"] = str(runtime_flavor)
        configurations["BuildConfig"] = str(build_config)  # ADD THIS LINE

    # .NET iOS and .NET MAUI iOS sample app scenarios
    if run_kind == "maui_scenarios_ios":
        if not runtime_flavor in ("mono", "coreclr"):
            raise Exception("Runtime flavor must be specified for maui_scenarios_ios")
        configurations["CodegenType"] = str(codegen_type)
        configurations["RuntimeType"] = str(runtime_flavor)
        configurations["BuildConfig"] = str(build_config)  # ADD THIS LINE

    return configurations


# CHANGE 3: Update the call to get_run_configurations in run_performance_job function
# Location: Around line 933 in the original file
# Change from:
#   configurations = get_run_configurations(
#       args.run_kind, args.runtime_type, args.codegen_type, args.pgo_run_type, args.physical_promotion_run_type,
#       args.r2r_run_type, args.experiment_name, args.linking_type,
#       args.runtime_flavor, args.ios_llvm_build, args.ios_strip_symbols, args.javascript_engine
#   )
# To:
#   configurations = get_run_configurations(
#       args.run_kind, args.runtime_type, args.codegen_type, args.pgo_run_type, args.physical_promotion_run_type,
#       args.r2r_run_type, args.experiment_name, args.linking_type,
#       args.runtime_flavor, args.ios_llvm_build, args.ios_strip_symbols, args.javascript_engine,
#       args.build_config  # ADD THIS LINE
#   )


# CHANGE 4: Update the RunConfig string to include BuildConfig for mobile scenarios
# This happens after get_run_configurations is called
# The RunConfigsString needs to be passed to the proj files via environment variable or property
# This is already handled by the ci_setup_arguments.build_configs which includes all configurations

# Summary of changes:
# 1. Add build_config parameter to get_run_configurations function
# 2. Add BuildConfig to configurations dict for maui_scenarios_android and maui_scenarios_ios
# 3. Pass args.build_config when calling get_run_configurations
# 4. The build_config will be exposed as an environment variable that the .proj files can use
