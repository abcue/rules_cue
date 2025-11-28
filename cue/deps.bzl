load(
    "//cue/private/tools/cue:toolchain.bzl",
    "download_tool",
    "known_release_versions",
)

def _cue_tool(name = "cue_tool", version = None, register_toolchains = True):
    download_tool(
        name = name,
        version = version,
    )
    if register_toolchains:
        native.register_toolchains("@{}_toolchains//:all".format(name))

# Register the Cue toolchain for the specified version
def cue_register_toolchains(name = "cue_tool", version = None, register_toolchains = True):
    latest_release = known_release_versions()[0]  # Get the latest version from the known release versions
    if not version:
        version = latest_release  # Use the latest version if none is specified
    _cue_tool(name = name, version = version, register_toolchains = register_toolchains)
