#!/usr/bin/env bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (c) barthel <barthel@users.noreply.github.com> https://github.com/barthel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Gets the current GIT branch name based on file or GIT repository
# and exports the branch name as BRANCH_NAME environment variable.
#
# use: DIR_NAME
#
# export: BRANCH_NAME

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

branch_name_file='.branch_name'

[ -z ${verbose} ] && verbose=0

show_help() {
cat << EOF
Usage: ${0##*/} [-vh?] [-f BRANCHNAMEFILE]

Gets the current GIT branch name based on file or GIT repository
and exports the branch name as >BRANCH_NAME< environment variable.

Requires a non empty >DIR_NAME< environment variable or directory
argument.

    -h|-?             display this help and exit.
    -f BRANCHNAMEFILE file name contains the branch name ('${branch_name_file}').
    -v                verbose mode. Can be used multiple times for increased verbosity.

Example:  ${0##*/}
          ${0##*/} -v
          ${0##*/} -f mybranchname.txt
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "f:h?v" opt;
do
  case "$opt" in
    f)  branch_name_file="$(basename $OPTARG)"
    ;;
    h|\?)
      show_help
      exit 0
    ;;
    v)  verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))

if [ -z "${BRANCH_NAME}" ]
  then
    if $(git rev-parse --git-dir > /dev/null 2>&1);
      then
        BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
      else
        # directory name
        if [ -z "${DIR_NAME}" ]
          then
            echo "Not empty >DIR_NAME< or directory argument expected."
            exit 1
        fi
        # check file containing the branch name
        if [ ! -f "${DIR_NAME}/${branch_name_file}" ]
          then
            current_directory="$(pwd)"
            cd "${DIR_NAME}"
            if $(git rev-parse --git-dir > /dev/null 2>&1);
              then
                BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
                cd "${current_directory}"
            else
              echo "File >${DIR_NAME}/${branch_name_file}<, >BRANCH_NAME< or git repository is required."
              cd "${current_directory}"
              exit 1
            fi
        else
          # get branch name from file
          BRANCH_NAME="$(<${DIR_NAME}/${branch_name_file})"
        fi
    fi
fi

[ 0 -lt "${verbose}" ] && echo "use branch: ${BRANCH_NAME}" || true

#
