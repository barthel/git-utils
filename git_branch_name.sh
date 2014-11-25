#!/bin/bash
#
# Get current GIT branch name based on file or git repository
# and store the branch name in BRANCH_NAME
#
# use: DIR_NAME breaks if empty
#
# export: DEFAULT_GIT_SERVER_URL
# export: BRANCH_NAME
#
set -e
# set -x

DEFAULT_GIT_SERVER_URL="ssh://git@git-server.icongmbh.de"

branch_name_file='.branch_name'

if [ "" = "${BRANCH_NAME}" ]
  then
    if `git rev-parse --git-dir > /dev/null 2>&1`;
      then
        BRANCH_NAME="`git rev-parse --abbrev-ref HEAD`"
      else
        # directory name
        if [ "" = "${DIR_NAME}" ]
          then
            echo "Not empty >DIR_NAME< expected"
            exit 1
        fi
        # check file containing the branch name
        if [ ! -f "${DIR_NAME}/${branch_name_file}" ]
          then
            echo "file >${branch_name_file}<, >BRANCH_NAME< or git repository is needed"
            exit 1
        fi
        # get branch name from file
        BRANCH_NAME="$(<${DIR_NAME}/${branch_name_file})"
    fi
fi

echo "use branch: ${BRANCH_NAME}"
