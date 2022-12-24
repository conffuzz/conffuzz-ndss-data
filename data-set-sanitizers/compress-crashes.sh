#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

# execute this script in the crashes/ folder (where session_info.txt is)

BASEDIR=$(pwd)

echo "Size before: $(du -hs $(pwd) | awk '{print $1;}')"

for x in "bugs" "false-positives"; do
  if [[ -d "$x" ]]; then
    echo "Compressing ${x}..."
    for c in ${x}/crash*; do
      pushd ${c} &> /dev/null
        # compress
	tar -czf compressed_runs.tar.gz $(ls | grep "run.*") &> /dev/null
        # remove
        rm -rf run*
      popd &> /dev/null
    done
  fi
done

echo "Size after: $(du -hs $(pwd) | awk '{print $1;}')"
