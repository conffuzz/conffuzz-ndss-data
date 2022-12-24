#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>
#
BASEDIR=$1

PRIM_DICT=${BASEDIR}/../conffuzz/conffuzz/primitive-types.txt
TMP=/tmp/generate-raw-data.sh.tmp

analyze() {
  rm -rf $TMP
  echo -e 'app-lib:"Integer Types":"C-style Strings":"Custom Structs/Classes":"{/:Monospace*0.9 void*} Raw Buffers":"Unique Custom Structs/Classes"'

  for x in "sandbox" "safebox"
  do
    for dir in ${BASEDIR}/${x}/*/
    do
      dir=${dir%*/}      # remove the trailing "/"
      types_path="/tmp/${dir##*/}-types.txt"
  
      if [[ $(ls ${dir}/crashes/bugs/crash*/ | grep -L minimal) ]]; then
        continue
      fi
  
      cat ${dir}/crashes/bugs/crash*/minimal/input.log | grep "~>" |
          sed "/~> instrumenting/d" | sed "/~> detected/d" | grep -Po "\{.*\}" |
          sed "s/{//g" | sed "s/}//g" | sed "s/^void\*$/voidstar_raw_buffer_type/g" |
          sed "s/^\*$/voidstar_raw_buffer_type/g" | sed "s/&//g" | sed "s/\*//g" |
          sort | sed "/^unknown$/d" > $types_path
  
      no_int=$(cat $types_path | grep -f ${PRIM_DICT} | grep -v "^char$" | wc -l)
      no_unique_int=$(cat $types_path | sort -u | grep -f ${PRIM_DICT} | grep -v "^char$" | wc -l)
  
      no_cstyle=$(cat $types_path | grep -f ${PRIM_DICT} | grep "^char$" | wc -l)
  
      no_customstruct=$(cat $types_path | grep -vf ${PRIM_DICT} | grep -v voidstar_raw_buffer_type | wc -l)
      no_unique_customstruct=$(cat $types_path | grep -vf ${PRIM_DICT} | grep -v voidstar_raw_buffer_type | \
                                                 sort -u | wc -l)
  
      no_rawbuf=$(cat $types_path | grep voidstar_raw_buffer_type | wc -l)

      scenario=$(echo "${dir##*/}" | sed "s/-/ \/ /")
  
      echo "\"${scenario}\":${no_int}:${no_cstyle}:${no_customstruct}:${no_rawbuf}:${no_unique_customstruct}" >> $TMP
    done
  done

  cat $TMP | sort -u
}

analyze 2> /dev/null | column -t -s ':'
