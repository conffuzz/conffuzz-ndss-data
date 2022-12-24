#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Authors: Hugo Lefeuvre <hugo.lefeuvre@manchester.ac.uk>

BASEDIR=$(pwd)

TMPF="/tmp/getcriticalsets.out.tmp"
TMPF_ALL="/tmp/getcriticalsets.outall.tmp"
TMPF_NONCRIT="/tmp/getcriticalsets.noncritout.tmp"
TMPF_NONCRIT_2="/tmp/getcriticalsets.noncritout2.tmp"
TMP_REWRITE="/tmp/getcriticalsets.rewrite.tmp"

# iterate through minimal fuzzer logs
for app in ${BASEDIR}/*/
do
    rm -rf $TMPF $TMPF_ALL $TMPF_NONCRIT $TMPF_NONCRIT_2 $TMP_REWRITE
    echo $app
    for inputlog in ${app}/crashes/bugs/crash*/minimal/input.log
    do
        f=$(cat $inputlog 2> /dev/null)
        noncrit=true
        cur_func=""
        while IFS= read -r l; do
            # ignore comments
            [[ $l =~ ^#.* ]] && continue

            # ignore empty lines
            [[ $l =~ ^$ ]] && continue

            if [[ $l =~ ^"~> instrumenting".* ]]; then
                continue
            elif [[ $l =~ ^"~> detected cb call".* ]]; then
                continue
            elif [[ $l =~ ^"~>".* ]]; then
                noncrit=false
                echo "  [api] $cur_func" >> $TMPF
            else
                if "$noncrit"; then
                    if [[ -n $cur_func ]]; then echo "  [api] $cur_func" >> $TMPF_NONCRIT; fi
                fi
                noncrit=true
                cur_func=$(echo "$l" | grep -Po "^([^(]*)\(" | head -c -2)
                echo "  [api] $cur_func" >> $TMPF_ALL
            fi
        done <<< "$f"

        if "$noncrit"; then
            if [[ -n $cur_func ]]; then echo "  [api] $cur_func" >> $TMPF_NONCRIT; fi
        fi
    done

    nodata=true

    if test -f "$TMPF"; then
        echo -ne "\e[32m\e[1m"
        cat $TMPF | sort -u
        echo -ne "\e[0m"
	nodata=false
    fi

    if test -f "$TMPF_NONCRIT"; then
        grep -F -v -x $TMPF_NONCRIT -f $TMPF > $TMPF_NONCRIT_2

        echo -ne "\e[31m\e[1m"
        cat $TMPF_NONCRIT_2 | sort -u
        echo -ne "\e[0m"
	nodata=false
    fi

    no_crit=$(cat $TMPF 2> /dev/null | sort -u | wc -l)
    no_total=$(cat $TMPF_ALL 2> /dev/null | sort -u | wc -l)

    if "$nodata"; then
        echo -e "  (no data)\n"
    else
        echo -e "\e[1mVulnerable ratio: ${no_crit} / ${no_total}\e[0m\n"
    fi

    sed -i 's/^  \[api\].*$//g' ${app}/crashes/session_info.txt
    sed -i '/^$/d' ${app}/crashes/session_info.txt

    f=$(cat ${app}/crashes/session_info.txt 2> /dev/null)
    nofind=true
    nofind_2=true
    while IFS= read -r l; do
        if [[ $l =~ ^"List of these endpoints:".* ]]; then
            echo "$l" >> $TMP_REWRITE
            cat $TMPF 2> /dev/null | sort -u >> $TMP_REWRITE
	    nofind=false
        elif [[ $l =~ ^"Number of API endpoints that are vulnerability vectors".* ]]; then
            echo "Number of API endpoints that are vulnerability vectors: ${no_crit}" >> $TMP_REWRITE
	    nofind_2=false
        elif [[ $l =~ ^"Ending time".* ]]; then
            if test -f "$TMPF"; then
                if "$nofind_2"; then
                    echo "Number of API endpoints that are vulnerability vectors: ${no_crit}" >> $TMP_REWRITE
                fi
                if "$nofind"; then
                    echo "List of these endpoints:" >> $TMP_REWRITE
                    cat $TMPF 2> /dev/null | sort -u >> $TMP_REWRITE
                fi
            fi
            echo "$l" >> $TMP_REWRITE
        else
            echo "$l" >> $TMP_REWRITE
        fi
    done <<< "$f"

    mv $TMP_REWRITE ${app}/crashes/session_info.txt
done
