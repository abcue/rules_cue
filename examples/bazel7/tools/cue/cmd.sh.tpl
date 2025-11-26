#!/bin/bash

set +ex

CUE=$(readlink -f %{CUE})
cd "${BUILD_WORKSPACE_DIRECTORY}/%{CWD}"

if [ -n "%{COMMAND}" ]; then
    CUE_DEBUG=sortfields $CUE cmd %{COMMAND} "$@"
else
    CUE_DEBUG=sortfields $CUE %{BUILT_IN} "$@"
fi
