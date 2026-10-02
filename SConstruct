#!/usr/bin/env python
import os
import sys

# Load godot-cpp environment
env = SConscript("godot-cpp/SConstruct")

# CRITICAL: Prevent LNK2038 runtime mismatch errors.
# godot-cpp is compiled with the static release C++ runtime (/MT).
# Ensure no debug runtime flags (/MDd, /MTd, /RTC1, etc.) are injected into the build.
if env.get("is_msvc", False):
    debug_runtime_flags = {"/MDd", "/MTd", "-MDd", "-MTd", "/RTC1", "/RTCs", "/RTCu"}
    for var in ["CCFLAGS", "CFLAGS", "CXXFLAGS"]:
        if var in env:
            env[var] = [flag for flag in env[var] if flag not in debug_runtime_flags]

    # Enforce /MT (or /MD if use_static_cpp=False)
    if env.get("use_static_cpp", True):
        if "/MD" in env["CCFLAGS"]:
            env["CCFLAGS"].remove("/MD")
        if "/MT" not in env["CCFLAGS"]:
            env.Append(CCFLAGS=["/MT"])
    else:
        if "/MT" in env["CCFLAGS"]:
            env["CCFLAGS"].remove("/MT")
        if "/MD" not in env["CCFLAGS"]:
            env.Append(CCFLAGS=["/MD"])

# Add project include directory
env.Append(CPPPATH=["src/"])

# Gather C++ sources from src/
sources = Glob("src/*.cpp")

# Output DLL target: bin/libbiopunk.windows.template_debug.x86_64.dll
target_output = "bin/libbiopunk{}{}".format(env["suffix"], env["SHLIBSUFFIX"])
library = env.SharedLibrary(target_output, source=sources)

env.NoCache(library)
Default(library)
