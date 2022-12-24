#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$(pwd)

for dir in ${BASEDIR}/*/
do
    dir=${dir%*/}      # remove the trailing "/"

    static=$(grep -r "Statically detected entry points" $dir | awk '{ print $NF }')
    dynamic=$(grep -r "Max number of call sites reached in a run" $dir | awk '{ print $NF }')

    echo -e "${dir##*/}\t${static}\t${dynamic}"
done
