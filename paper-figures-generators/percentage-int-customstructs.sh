#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$1

PRIM_DICT=${BASEDIR}/../conffuzz/conffuzz/primitive-types.txt

analyze() {
  sum_intascontrol=0
  sum_intstruct=0
  sum_total=0
  sum_rest=0

  for x in "sandbox" "safebox"
  do
    for dir in ${BASEDIR}/${x}/*/
    do
      dir=${dir%*/} # remove the trailing "/"

      types_path="/tmp/${dir##*/}-types.txt"

      if [[ $(ls ${dir}/crashes/bugs/crash*/ | grep -L minimal) ]]; then
        continue
      fi

      for m in ${dir}/crashes/bugs/crash*/minimal/input.log
      do
        sum_total=$((sum_total+1))

        cat $m | grep "~>" |
            sed "/~> instrumenting/d" | sed "/~> detected/d" | grep -Po "\{.*\}" |
            sed "s/{//g" | sed "s/}//g" | sed "s/^void\*$/voidstar_raw_buffer_type/g" |
            sed "s/^\*$/voidstar_raw_buffer_type/g" | sed "s/&//g" | sed "s/\*//g" |
            sort | sed "/^unknown$/d" > $types_path

        no_int=$(cat $types_path | grep -f ${PRIM_DICT} | grep -v "^char$" | wc -l)
	if [ "$no_int" -ne "0" ]; then
          sum_intstruct=$((sum_intstruct+1))
        fi

        no_cstyle=$(cat $types_path | grep -f ${PRIM_DICT} | grep "^char$" | wc -l)
	if [ "$no_cstyle" -ne "0" ]; then
          sum_rest=$((sum_rest+1))
        fi

        no_customstruct=$(cat $types_path | grep -vf ${PRIM_DICT} | grep -v voidstar_raw_buffer_type | wc -l)
	if [ "$no_customstruct" -ne "0" ]; then
          if [ "$no_int" -eq "0" ]; then
            sum_intstruct=$((sum_intstruct+1))
          fi
        fi

        no_rawbuf=$(cat $types_path | grep voidstar_raw_buffer_type | wc -l)
	if [ "$no_rawbuf" -ne "0" ]; then
          if [ "$no_cstyle" -eq "0" ]; then
            sum_rest=$((sum_rest+1))
          fi
        fi

	if [ "$no_int" -ne "0" ]; then
          if [ "$no_int" -gt "1" ]; then
            sum_intascontrol=$((sum_intascontrol+1))
	    continue
          fi
          if [ "$no_cstyle" -ne "0" ]; then
            sum_intascontrol=$((sum_intascontrol+1))
	    continue
          fi
          if [ "$no_customstruct" -ne "0" ]; then
            sum_intascontrol=$((sum_intascontrol+1))
	    continue
          fi
          if [ "$no_rawbuf" -ne "0" ]; then
            sum_intascontrol=$((sum_intascontrol+1))
	    continue
          fi
        fi
      done
    done
  done

  echo "Proportion of crashes due to ints or custom structs: $(bc <<< "100*${sum_intstruct}/${sum_total}")%"
  echo "Proportion of crashes due to C-style strings or void*: $(bc <<< "100*${sum_rest}/${sum_total}")%"
  echo "Proportion of crashes due to int + something else: $(bc <<< "100*${sum_intascontrol}/${sum_total}")%"
}

analyze 2> /dev/null
