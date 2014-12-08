#!/bin/bash
#
# Get current GIT repositoriy list based on file or git repository.
# Store pure git repository names in REPO_NAMES.
# Store the repository name and the GIT server url separated by
#  space in REPO_SERVER_URL_NAMES.
#
# export: REPO_NAMES {"<repository name>" ...}
# export: REPO_SERVER_URL_NAMES {"<repository name><TAB><repository url>" ...}
#
set -e
# set -x

repo_list_file='.repositories'

[ -z ${verbose} ] && verbose=0

show_help() {
cat << EOF

  Usage: ${0##*/} [-v] [-d DIRECTORY]
  Get current GIT repositoriy list based on file or git repository.

  Required non empty >DIR_NAME< environment variable or directory
  argument.

  -d DIRECTORY  directory contains the repository file (${repo_list_file})
  -v            verbose mode. Can be used multiple times for increased verbosity.
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "d:vh?" opt;
do
  case "$opt" in
    d)
      DIR_NAME="$(dirname $OPTARG)"
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
    # check if the current directory is a git repository
    if `git rev-parse --git-dir > /dev/null 2>&1`;
      then
        git_remote_origin_url="$(git config --get remote.origin.url)"
        top_level="$(git rev-parse --show-toplevel)"
        git_remote_origin_host_port_path="${git_remote_origin_url##*\/\/}"
        git_remote_origin_path="${git_remote_origin_host_port_path#*\/}"

        REPO_NAMES=("${git_remote_origin_path}")
        REPO_SERVER_URL_NAMES=("${git_remote_origin_path} ${git_remote_origin_url}")
        DIR_NAME="$(dirname ${top_level})"
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
              [ "" != "${line}" ] && REPO_SERVER_URL_NAMES[${#REPO_SERVER_URL_NAMES[@]}]="${line}"
            done < ${DIR_NAME}/${repo_list_file}
          REPO_NAMES=(`cat ${DIR_NAME}/${repo_list_file}|cut -f1`)
      fi
    fi
fi

[ 0 -lt "${verbose}" ] && echo "use repositories: ${REPO_NAMES[@]}" || true

#
