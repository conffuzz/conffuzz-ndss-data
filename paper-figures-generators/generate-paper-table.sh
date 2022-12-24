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

sum_crashes_raw=0
sum_crashes_dedup=0
sum_targetlibs=0
sum_read_impact=0
sum_write_impact=0
sum_exec_impact=0
sum_read_arb_impact=0
sum_write_arb_impact=0
sum_exec_arb_impact=0
sum_alloc_corrupt_impact=0
sum_null_impact=0

analyze() {
  echo -e "app-lib:& raw:& dedup:& victims:& callers:& coverage:& read (arbitrary):& write (arb.):& exec (arb.):& alloc:& NULL"
  for dir in ${BASEDIR}/*/
  do
      dir=${dir%*/}      # remove the trailing "/"

      crashes_raw=$(ls ${dir}/crashes/bugs/crash*/* | grep -P "run\d" | wc -l)
      sum_crashes_raw=$((sum_crashes_raw+crashes_raw))

      crashes_dedup=$(ls ${dir}/crashes/bugs/ | grep -P "crash\d" | wc -l)
      sum_crashes_dedup=$((sum_crashes_dedup+crashes_dedup))

      targetlibs=$(grep -r "fault_location" ${dir}/crashes/bugs/ | grep -ve "wild jump" | cut -f2 -d":" | sort -u | wc -l)
      sum_targetlibs=$((sum_targetlibs+targetlibs))

      read_impact=$(grep -r "cap_read" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_read_impact=$((sum_read_impact+read_impact))

      read_arb_impact=$(grep -r "cap_read_arbitrary" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_read_arb_impact=$((sum_read_arb_impact+read_arb_impact))

      write_impact=$(grep -r "cap_write" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_write_impact=$((sum_write_impact+write_impact))

      write_arb_impact=$(grep -r "cap_write_arbitrary" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_write_arb_impact=$((sum_write_arb_impact+write_arb_impact))

      exec_impact=$(grep -r "cap_exec" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_exec_impact=$((sum_exec_impact+exec_impact))

      exec_arb_impact=$(grep -r "cap_exec_arbitrary" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_exec_arb_impact=$((sum_exec_arb_impact+exec_arb_impact))

      alloc_corrupt_impact=$(grep -r "cap_corrupt" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_alloc_corrupt_impact=$((sum_alloc_corrupt_impact+alloc_corrupt_impact))

      null_impact=$(grep -r "cap_null" ${dir}/crashes/bugs/ | cut -f1 -d":" | sort -u | wc -l)
      sum_null_impact=$((sum_null_impact+null_impact))

      coverage=$(grep -r "Number of API endpoints reached" ${dir}/crashes/session_info.txt | awk '{ print $NF }')
      coverage_total=$(grep -r "Statically detected called API endpoints" ${dir}/crashes/session_info.txt | awk '{ print $NF }')
      cov_per=$(bc <<< "100*${coverage}/${coverage_total}")

      echo -e "${dir##*/}:& ${crashes_raw}:& ${crashes_dedup}:& ${targetlibs}:& ??:& ${cov_per}\% (${coverage}/${coverage_total}) :& ${read_impact} (${read_arb_impact}):& ${write_impact} (${write_arb_impact}):& ${exec_impact} (${exec_arb_impact}):& ${alloc_corrupt_impact}:& ${null_impact}"
  done

  echo ""
  echo -e "SUM:& ${sum_crashes_raw}:& ${sum_crashes_dedup}:& ${sum_targetlibs}:& ?? :& N/A :& ${sum_read_impact} (${sum_read_arb_impact}):& ${sum_write_impact} (${sum_write_arb_impact}):& ${sum_exec_impact} (${sum_exec_arb_impact}):& ${sum_alloc_corrupt_impact}:& ${sum_null_impact}"
}

analyze 2> /dev/null | column -t -s ':'
