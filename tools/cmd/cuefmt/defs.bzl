"""Bazel aspect that validates cuefmt at build time.

This aspect attaches to cue_instance rules and creates build actions that validate
CUE source files are properly formatted. If any files fail check, the build fails.
"""

load(
    "@rules_cue//cue:cue.bzl",
    "CUEInstanceInfo",
)

# Provider to track check results
CuefmtCheckInfo = provider(
    doc = "Information about cuefmt check performed by the aspect",
    fields = {
        "checked_files": "List of files that were checked",
        "output": "File containing check results",
        "target_label": "Label of the checked target",
    },
)

def _should_skip_file(f):
    """Returns True if file should be skipped from check."""
    path = f.path

    # Skip generated files
    skip_patterns = [
        ".gen.cue",  # Generic generated
        "_gen.cue",  # Generic generated
        "cue.mod/",  # CUE module directory
    ]

    for pattern in skip_patterns:
        if pattern in path:
            return True

    # Skip vendor directories
    if "/vendor/" in path:
        return True

    # Skip bazel output
    if "bazel-out/" in path or path.startswith("bazel-"):
        return True

    return False

def _generate_script():
    return '''#!/bin/bash
set -euo pipefail

# Usage: $0 <cuefmt> <output> <target> <fix_mode> <file1> <file2> ...
if [ $# -lt 4 ]; then
    echo "Usage: $0 <cuefmt> <output> <target> <fix_mode> <files...>" >&2
    exit 1
fi

# Parse arguments
CUEFMT="$1"
OUTPUT="$2"
TARGET="$3"
FIX_MODE="$4"
shift 4  # Remaining args are files to check

# Initialize
mkdir -p "$(dirname "$OUTPUT")"
touch "$OUTPUT"
failed=0
fixed_count=0

# Check each file
for file in "$@"; do
    # Read the original content
    original=$(<"$file")

    # Format the file and capture output
    if formatted=$("$CUEFMT" fmt - < "$file" 2>&1); then
        if [ "$original" != "$formatted" ]; then
            if [ "$FIX_MODE" = "1" ]; then
                echo "FIXING: $file" >&2
                echo "$formatted" > "$file"
                fixed_count=$((fixed_count + 1))
            else
                echo "ERROR: $file is not properly formatted" >&2
                failed=1
            fi
        fi
    else
        echo "ERROR: cue fmt failed on $file: $formatted" >&2
        failed=1
    fi
done

echo "" >&2
if [ "$failed" = 1 ]; then
    echo "To fix formatting issues, run:" >&2
    echo "  bazel build --config=cue_checks_fix $TARGET" >&2
    echo "" >&2
    exit 1
fi
'''

def _cuefmt_check_aspect_impl(target, ctx):
    """Aspect implementation that creates build-time check actions."""

    # Only process targets that have CUEInstanceInfo
    if CUEInstanceInfo not in target:
        return []

    # Get the CUE toolchain
    cue_tool = ctx.toolchains["@rules_cue//tools/cue:toolchain_type"].cueinfo.tool

    # Collect CUE source files from the instance
    instance_info = target[CUEInstanceInfo]
    cue_sources = []

    for f in instance_info.files:
        if f.extension == "cue" and not _should_skip_file(f):
            cue_sources.append(f)

    if not cue_sources:
        # No sources to validate
        return [
            CuefmtCheckInfo(
                checked_files = [],
                output = None,
                target_label = str(target.label),
            ),
        ]

    # Create output file for check results (required by Bazel)
    output = ctx.actions.declare_file(
        "%s_cuefmt_check.txt" % target.label.name,
    )

    # Check if we're in fix mode using --define
    fix_mode = ctx.var.get("CUE_CHECKS_FIX", "") == "1"

    # Create the check script
    check_script = ctx.actions.declare_file(
        "%s_cuefmt_check.sh" % target.label.name,
    )

    # Write the check script
    ctx.actions.write(
        output = check_script,
        content = _generate_script(),
        is_executable = True,
    )

    # Build arguments for the script
    args = [
        cue_tool.path,
        output.path,
        str(target.label),
        "1" if fix_mode else "0",
    ]

    # Add all source files as arguments
    for src in cue_sources:
        args.append(src.path)

    # Use different execution requirements based on mode
    if fix_mode:
        # Fix mode: escape sandbox to modify source files
        execution_requirements = {
            "local": "1",
            "no-cache": "1",
            "no-sandbox": "1",
        }
        progress_message = "Fixing cuefmt for %s" % target.label
    else:
        # check mode: normal sandboxed execution
        execution_requirements = {}
        progress_message = "Validating cuefmt for %s" % target.label

    ctx.actions.run(
        outputs = [output],
        inputs = cue_sources + [cue_tool],
        executable = check_script,
        arguments = args,
        mnemonic = "Cuefmt",
        progress_message = progress_message,
        execution_requirements = execution_requirements,
    )

    return [
        CuefmtCheckInfo(
            checked_files = cue_sources,
            output = output,
            target_label = str(target.label),
        ),
        # Important: Add the check output to the default outputs
        # This ensures the check runs when the target is built
        OutputGroupInfo(
            check_validation = depset([output]),
        ),
    ]

cuefmt_check_aspect = aspect(
    implementation = _cuefmt_check_aspect_impl,
    attr_aspects = ["deps"],  # Propagate through dependencies
    toolchains = ["@rules_cue//tools/cue:toolchain_type"],
    doc = """Aspect that validates CUE source formatting at build time.

    This aspect works with cue_instance targets.
    It will fail the build if any CUE source files are not properly formatted.
    """,
)
