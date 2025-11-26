"""
This module contains a rule for running cue commands.
"""

def _cue_cmd_impl(ctx):
    cue_tool = ctx.toolchains["@rules_cue//tools/cue:toolchain_type"].cueinfo.tool
    cmd_sh = ctx.actions.declare_file(ctx.attr.name + ".sh")
    substitutions = {
        "%{BUILT_IN}": ctx.attr.built_in,
        "%{COMMAND}": ctx.attr.command,
        "%{CUE}": cue_tool.path,
        "%{CWD}": ctx.label.package,
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
        # The cue built-in command to run (e.g., "fmt", "vet").
        # See https://cuelang.org/docs/reference/command/
        "built_in": attr.string(
            mandatory = False,
            default = "",
        ),
        # User command to run with cue cmd {command}.
        # keep name 'command' for backward compatibility
        # See https://cuelang.org/docs/reference/command/cue-help-commands/
        "command": attr.string(
            mandatory = False,
        ),
        "_cmd_tpl": attr.label(
            default = Label("//tools/cue:cmd.sh.tpl"),
            allow_single_file = True,
        ),
    },
    implementation = _cue_cmd_impl,
    executable = True,
    toolchains = ["@rules_cue//tools/cue:toolchain_type"],
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
        built_in = "",
        **kwargs
    )
