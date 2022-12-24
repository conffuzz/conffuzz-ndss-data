#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$1

TMP=/tmp/generate-raw-data.sh.tmp

analyze() {
    rm -rf $TMP
    echo "scenario:\"Fuzzed API Elements (No Vulnerability Found)\":\"Fuzzed API Elements (Vulnerable)\":\"% vulnerable\""

    for x in "sandbox" "safebox"
    do
        for dir in ${BASEDIR}/${x}/*/
        do
            dir=${dir%*/} # remove the trailing "/"

	    valid=$(find $dir -name minimal)
	    if [ -z "$valid" ]; then
		if [[ -d "${dir}/crashes/bugs/" ]]
                then
                    continue
                fi
            fi

            total=$(grep -r "Number of API endpoints reached" $dir | awk '{ print $NF }')
            vuln=$(grep -r "Number of API endpoints that are vulnerability vectors" $dir | awk '{ print $NF }')

            scenario=$(echo "${dir##*/}" | sed "s/-/ \/ /")

            echo -e "\"${scenario}\":$(bc <<< "${total}-${vuln}"):${vuln}:$(bc <<< "100*${vuln}/${total}")" >> $TMP
        done
    done

    cat $TMP | sort -u
}

analyze 2> /dev/null | column -t -s ':'
