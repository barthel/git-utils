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

[ -z ${verbose} ] && verbose=0

show_help() {
cat << EOF

  Usage: ${0##*/} [-v] [-d DIRECTORY]
  Get current GIT branch name based on file or git repository
  and store the branch name in >BRANCH_NAME<.

  Required non empty >DIR_NAME< environment variable or directory
  argument.

  -d DIRECTORY  directory contains the branch name file (${branch_name_file})
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

[ 0 -lt "${verbose}" ] && echo "use branch: ${BRANCH_NAME}" || true

#
