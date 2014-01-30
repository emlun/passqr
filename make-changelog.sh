#!/bin/bash

changelog=${1:-'changelog.txt'}
rm -f "${changelog}"

tags=()
for commit in $(git rev-list --first-parent --merges HEAD); do
    tags+=("$(git describe --exact-match $commit)")
done
tags+=('1.1.0')

for tag in ${tags[@]}; do
    date=$(git show 1.2.0 --pretty=format:%ci | tail -n1 | cut -d \  -f 1,3)
    git cat-file commit $tag \
        | grep -E "^Version ${tag}$" -A 10000 \
        | grep -vE "Changelog:|Signed-off-by:" \
        | sed "s/^Version ${tag}.*/\0 (${date})/" \
        >> "${changelog}"
    echo >> "${changelog}"
done
