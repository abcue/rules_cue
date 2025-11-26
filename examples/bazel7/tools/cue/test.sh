#!/bin/bash

pushd "$(dirname "${BASH_SOURCE[0]}")"

bazel run //tools/cue -- version

# Get all items and count them
items=($(bazel query 'kind("cue_cmd rule", //...)'))
total=${#items[@]}
current=1

for i in "${items[@]}" ; do
    echo "[$current/$total] $i"
    bazel build $i
    ((current++))
done

popd
