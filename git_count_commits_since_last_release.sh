#!/bin/bash
#
# Get count of commits since the last release commit.
#
# use: DIR_NAME
# use: REPO_NAMES break if empty
# use: BRANCH_NAME breaks if empty
#

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

unset IFS
release_commit_eyecatcher='\[.*[unleash|release].*-plugin\]'
regexp_release_commit='.*'${release_commit_eyecatcher}'.*'

quiet=false

[ -z "${verbose}" ] && verbose=0

show_help() {
cat << EOF
Usage: ${0##*/} [-h?qv] [-d DIRECTORY]

Get count of commits since the last release commit.

    -h|-?        display this help and exit.
    -d DIRECTORY directory contains the repositories list and branch name file ('$(pwd)').
    -q           quiet modus. View only commit count summary for repository.
    -v           verbose mode. Can be used multiple times for increased verbosity.
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "d:qvh?" opt;
do
  case "$opt" in
    d)
      DIR_NAME="$OPTARG"
    ;;
    h|\?)
      show_help
      exit 0
    ;;
    q)
      quiet=true
    ;;
    v)
      verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))
REPO_NAMES=("${1}")

[ -z "${DIR_NAME}" ] && DIR_NAME="$(pwd)" || true

[ -z "${BRANCH_NAME}" ] && . git_branch_name.sh
[ -z "${BRANCH_NAME}" ] && echo "Not empty >BRANCH_NAME< expected" && exit 1 || true

[ 0 = ${#REPO_NAMES[@]} ] && . git_repositories.sh
[ 0 = ${#REPO_NAMES[@]} ] && echo "Not empty >REPO_NAMES< expected" && exit 1 || true

cd "${DIR_NAME}" || exit

counter=1
size=${#REPO_NAMES[@]}
# loop over all known repositories
for repo in "${REPO_NAMES[@]}"
do
  # normalize repository name
  local_dir=${repo} # ${repo//[^a-zA-Z0-9_\-\.]/_}
  if [ -d "${DIR_NAME}/${local_dir}" ]
    then
      counter_commits=0
      cd "${DIR_NAME}/${local_dir}" || exit;
      echo -n "[${counter}/${size}] check commits since last release of ${repo}: ";
      [ false == ${quiet} ] && echo "" || true
      # find all directories within the current repo but ignore: './target'
      # and all directories starts with './.'
      IFS=$' '
      for directory in $(find . -maxdepth 1 -type d | grep -v "^\.\/target\|^\./\..*$" | xargs)
      do
        # check if ${directory} is the current directory and use pom.xml
        # instead or continue
        if [ "." == "${directory}" ]
          then
            [ -f "./pom.xml" ] && directory="./pom.xml" || continue
        fi
        # get the last release commit based on commit message regular expression
        # and the name of the committer
        IFS=$'\t'
        last_release_commit=($(git log --pretty=format:"%H%x09\"%s\"" --max-count=1 --regexp-ignore-case --basic-regexp --grep "${regexp_release_commit}" --remotes=${BRANCH_NAME} origin/${BRANCH_NAME} -- ${directory} | grep -v "Revert" | head -n1))
        # check the count of commit since the ${last_release_commit} commit
        # hash and ignore other release commits (like the next iteration commit)
        # instead
        pending_commits=$(git log --pretty=format:"%H%x09\"%s\"" --reverse "${BRANCH_NAME}"  ${last_release_commit[0]}.. -- ${directory} | grep -cv "${release_commit_eyecatcher}")
        counter_commits=$((counter_commits + pending_commits))
        if [[ 0 -lt "${pending_commits}" && false == "${quiet}" ]]
          then
            echo -e -n "\t${directory##*/}:\t#${pending_commits}"
            [ 0 -lt "${verbose}" ] && echo -e -n "\t (since: ${last_release_commit[0]} ${last_release_commit[1]})";
            echo ""
        fi
      done
      unset IFS
      [[ 0 -lt "${verbose}" || true == "${quiet}" ]] && echo -e "\t#${counter_commits}" || true
  fi
  cd "${DIR_NAME}" || exit;
  counter=$((counter + 1))
done

#
