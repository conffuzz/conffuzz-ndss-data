#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$(pwd)

TMPFILE="/tmp/findcomplexcrashes.out.tmp"
echo "" > $TMPFILE

# iterate through minimal fuzzer logs
for inputlog in ${BASEDIR}/*/crashes/bugs/crash*/minimal/input.log
do
    actions=$(cat $inputlog | grep -P "(~> write|~> change)" | wc -l)
    echo "$actions $inputlog" >> $TMPFILE
done

cat $TMPFILE | sort -n
