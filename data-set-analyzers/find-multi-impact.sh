#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$(pwd)

m=0

for infoLog in ${BASEDIR}/*/crashes/bugs/crash*/crash_info.txt
do
    has_read=$(cat $infoLog  | grep -P "cap_read"  | sed "s/_arbitrary//g" | sort -u | wc -l)
    has_write=$(cat $infoLog | grep -P "cap_write" | sed "s/_arbitrary//g" | sort -u | wc -l)
    has_exec=$(cat $infoLog  | grep -P "cap_exec"  | sed "s/_arbitrary//g" | sort -u | wc -l)
    has_alloc=$(cat $infoLog | grep -P "cap_alloc" | sed "s/_arbitrary//g" | sort -u | wc -l)
    has_null=$(cat $infoLog  | grep -P "cap_null"  | sed "s/_arbitrary//g" | sort -u | wc -l)

    t=$((${has_read}+${has_write}+${has_exec}+${has_alloc}+${has_null}))
    if [ $t -gt 1 ]; then
        m=$(($m+1))
        echo "$has_read $has_write $has_exec $has_alloc $has_null"
    fi
done

echo "$m"
