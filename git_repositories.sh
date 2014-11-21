#!/bin/bash
#
# Get current GIT repositories list based on file or git repository.
# Store pure git repository names in REPO_NAMES.
# Store the repository names and the GIT server url separated by
#  space in REPO_SERVER_URL_NAMES.
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
        REPO_SERVER_URL_NAMES=(". `git config --get remote.origin.url`")
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
        # @see: http://stackoverflow.com/questions/10984432/how-to-read-the-file-content-into-a-variable-in-one-go
        REPO_SERVER_URL_NAMES=()
        while IFS= read -r line
          do
            REPO_SERVER_URL_NAMES[${#REPO_SERVER_URL_NAMES[@]}]="${line}"
          done < ${DIR_NAME}/${repo_list_file}

        REPO_NAMES=(`cat ${DIR_NAME}/${repo_list_file}|cut -d' ' -f1`)
      fi
    fi
fi

echo "use repositories: ${REPO_NAMES[@]}"

