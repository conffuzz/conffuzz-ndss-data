#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$(pwd)

for impact in "write" "read"
do
  for dir in ${BASEDIR}/*/
  do
    dir=${dir%*/}      # remove the trailing "/"

    echo -e "${dir##*/} ($impact)"

    for c in ${dir}/crashes/bugs/crash*; do
      number_addresses=$(for d in ${c}/run*; do (grep -r -C 10 "${impact,}" $d |
                                                 grep -Po "0x[0-9a-f]+" |
                                                 head -1); done | sort -u | wc -l)
      no_run=$(for d in ${c}/run*; do echo "run"; done | wc -l)

      echo -ne "  $c:  \t"
      if [ $number_addresses -gt 1 ]; then
        echo -ne "arbitrary\t($number_addresses / $no_run)"
        if ! grep -Fxq "cap_${impact,,}_arbitrary" ${c}/crash_info.txt; then
          echo "cap_${impact,,}_arbitrary" >> ${c}/crash_info.txt
          echo -ne "  \t*new*"
        fi
      else
        echo -ne "not arbitrary\t($number_addresses / $no_run)"
      fi
      echo ""
    done
  done
done
