#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (c) barthel <barthel@users.noreply.github.com> https://github.com/barthel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Get current GIT repositoriy list based on file or git repository.
# Store pure git repository names in REPO_NAMES.
# Store the repository name and the GIT server url separated by
#  tab in REPO_SERVER_URL_NAMES.
#
# use: DIR_NAME breaks if empty
#
# export: REPO_NAMES {"<repository name>" ...}
# export: REPO_SERVER_URL_NAMES {"<repository name><TAB><repository url>" ...}
#

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

unset IFS
repo_list_file='.repositories'

[ -z "${verbose}" ] && verbose=0

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] [-f REPOLISTFILE]

Get current GIT repositoriy list based on file or git repository.

    -h|-?             display this help and exit.
    -f REPOLISTFILE   file name contains the list of GIT repositories ('${repo_list_file}').
    -v                verbose mode. Can be used multiple times for increased verbosity.

Example:  ${0##*/}
          ${0##*/} -v
          ${0##*/} -f myrepositories.txt
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "f:vh?" opt;
do
  case "$opt" in
    f)
      repo_list_file="$(basename "$OPTARG")"
      ;;
    h|\?)
      show_help
      exit 0
    ;;
    v)
      verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))

if [ 0 = ${#REPO_NAMES[@]} ]
  then
    [ -n "${DIR_NAME}" ] && pushd "${DIR_NAME}" > /dev/null 2>&1 || true
    # check if the current directory is a git repository
    if $(git rev-parse --git-dir > /dev/null 2>&1);
      then
        git_remote_origin_url="$(git config --get remote.origin.url)"
        top_level="$(git rev-parse --show-toplevel)"
        #git_remote_origin_host_port_path="${git_remote_origin_url##*\/\/}"
        #git_remote_origin_path="${git_remote_origin_host_port_path#*\/}"

        #REPO_NAMES=("${git_remote_origin_path}")
        #REPO_SERVER_URL_NAMES=("${git_remote_origin_path} ${git_remote_origin_url}")
        REPO_NAMES=("$(basename ${top_level})")
        REPO_SERVER_URL_NAMES=("${REPO_NAMES[0]} ${git_remote_origin_url}")
        DIR_NAME="$(dirname ${top_level})"
    else
      popd > /dev/null 2>&1 || exit
      # directory name
      if [ -z "${DIR_NAME}" ]
        then
          echo "Not empty >DIR_NAME< or directory argument expected."
          exit 1
      fi
      # check if repositories list file is available
      if [ ! -f "${DIR_NAME}/${repo_list_file}" ]
        then
          echo "File >${DIR_NAME}/${repo_list_file}<, >REPO_NAMES< or git repository is required."
          exit 1
        else
          # @see: http://stackoverflow.com/questions/10984432/how-to-read-the-file-content-into-a-variable-in-one-go
          REPO_SERVER_URL_NAMES=()
          REPO_NAMES=()
          while IFS= read -r line
            do
              if [ -n "${line}" ]
                then
                # ignore commented lines
                [[ ${line} =~ ^#.* ]] && continue
                REPO_SERVER_URL_NAMES[${#REPO_SERVER_URL_NAMES[@]}]="${line}"
                REPO_NAMES[${#REPO_NAMES[@]}]="$(echo "${line}" | cut -f1)"
              fi
            done < "${DIR_NAME}/${repo_list_file}"
          unset IFS
      fi
    fi
fi

[ "${verbose}" -gt 0 ] && echo "use repositories: ${REPO_NAMES[*]}" || true

#
