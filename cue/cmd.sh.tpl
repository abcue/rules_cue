#!/bin/bash

set -euo pipefail

CUE=$(readlink -f %{CUE})

if [ -n "%{TOOL}" ]; then
    cd "${BUILD_WORKSPACE_DIRECTORY}/%{CWD}"
    CUE_DEBUG=sortfields $CUE cmd %{TOOL} "$@"
else
    CUE_DEBUG=sortfields $CUE %{CMD} "$@"
fi
