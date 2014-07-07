#!/bin/bash
#
# Get current GIT repositories list based on file or git repository
#
set -e
# set -x

repo_list_file='.repositories'

if [ 0 = ${#REPO_NAMES[@]} ]
  then
    # check if the current directory is a git repository
    if `git rev-parse --git-dir > /dev/null 2>&1`;
      then
        REPO_NAMES=('.')
    else
      # directory name
      if [ "" = "${DIR_NAME}" ]
        then
          echo "Not empty >DIR_NAME< expected"
          exit 1
      fi
      # check if repositories list file is available
      if [ ! -f "${DIR_NAME}/${repo_list_file}" ]
        then
          echo "file >${repo_list_file}<, >REPO_NAMES< or git repository is needed"
          exit 1
      else
        REPO_NAMES=($(<${DIR_NAME}/${repo_list_file}))
      fi
    fi
fi

echo "use repositories: ${REPO_NAMES[@]}"

