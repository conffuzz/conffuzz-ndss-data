#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$(pwd)

NEW=$1
OLD=$2

analyze() {
  for t1 in ${NEW}/crashes/bugs/crash*/crash_trace.txt; do
    cat $t1 | sed "s/^.* 0xaddr //g" > /tmp/t1tmp
    found=0
    for t2 in ${OLD}/crashes/bugs/crash*/crash_trace.txt; do
      cat $t2 | sed "s/^.* 0xaddr //g" > /tmp/t2tmp
      dsize=$(diff /tmp/t1tmp /tmp/t2tmp | wc -l)
      if [ "$dsize" -eq "0" ]; then
        found=1
      fi
    done

    if [ "$found" -eq "0" ]; then
      echo "In $NEW but not in $OLD:"
      echo "   $t1"
    fi
  done
}

analyze
