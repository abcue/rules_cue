"""
This module contains a rule for running cue commands.
"""

_cue_toolchain_type = "//tools/cue:toolchain_type"

def _cue_cmd_impl(ctx):
    cue_tool = ctx.toolchains[_cue_toolchain_type].cueinfo.tool
    cmd_sh = ctx.actions.declare_file(ctx.attr.name + ".sh")
    substitutions = {
        "%{CMD}": ctx.attr.cmd,
        "%{CUE}": cue_tool.path,
        "%{CWD}": ctx.label.package,
        "%{TOOL}": ctx.attr.tool or ctx.attr.command,
    }
    ctx.actions.expand_template(
        template = ctx.file._cmd_tpl,
        output = cmd_sh,
        substitutions = substitutions,
    )

    return DefaultInfo(
        executable = cmd_sh,
        runfiles = ctx.runfiles(
            files = [
                cue_tool,
            ],
        ),
    )

cue_cmd = rule(
    attrs = {
        # The cue command to run (e.g., "fmt", "vet").
        "cmd": attr.string(
            mandatory = False,
            default = "",
        ),
        # Command to run with cue cmd {command}. assign it to TOOL
        # keep name 'command' for backward compatibility
        # DEPRECATED: Use 'tool' instead of 'command'
        "command": attr.string(
            mandatory = False,
            doc = "DEPRECATED: Use 'tool' instead of 'command'",
        ),
        "tool": attr.string(
            mandatory = False,
        ),
        "_cmd_tpl": attr.label(
            default = Label("//cue:cmd.sh.tpl"),
            allow_single_file = True,
        ),
    },
    implementation = _cue_cmd_impl,
    executable = True,
    toolchains = [_cue_toolchain_type],
)

def cue_binary(name, **kwargs):
    """
    A convenience alias for cue_cmd.

    Args:
        name: The name of the rule.
        **kwargs: Additional arguments to pass to cue_cmd.
    """
    cue_cmd(
        name = name,
        cmd = "",
        **kwargs
    )
