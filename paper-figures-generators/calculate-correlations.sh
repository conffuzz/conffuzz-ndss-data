#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

# This script generates the main table of the ConfFuzz paper. Run it under
# safebox/ or under sandbox/
#
# $ cd sandbox && ../gentable.sh
# or
# $ cd safebox && ../gentable.sh

BASEDIR=$(pwd)

analyze_fuzzed_api() {
  for dir in ${BASEDIR}/*/*/
  do
      dir=${dir%*/}      # remove the trailing "/"

      bugs=$(ls ${dir}/crashes/bugs/ | grep -P "crash\d" | wc -l)
      coverage=$(grep -r "Number of API endpoints reached" ${dir}/crashes/session_info.txt | awk '{ print $NF }')

      echo "$bugs:$coverage"
  done
}

analyze_api_size() {
  for dir in ${BASEDIR}/*/*/
  do
      dir=${dir%*/}      # remove the trailing "/"

      bugs=$(ls ${dir}/crashes/bugs/ | grep -P "crash\d" | wc -l)
      apisize=$(grep -r "Statically detected called API endpoints" ${dir}/crashes/session_info.txt | awk '{ print $NF }')

      echo "$bugs:$apisize"
  done
}

echo -n "Correlation number of CIVs / N# of fuzzed API elements: "
analyze_fuzzed_api 2> /dev/null | column -t -s ':' | datamash -W ppearson 1:2

echo -n "Correlation number of CIVs / API size: "
analyze_api_size 2> /dev/null | column -t -s ':' | datamash -W ppearson 1:2
