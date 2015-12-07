#!/bin/bash
#
# Check the status of local GIT working copies.
#
# Show/count untracked changes (pending changes), pending commits and available stash entries.
#
# use: DIR_NAME fill with pwd if empty
# use: REPO_NAMES break if empty
# use: BRANCH_NAME breaks if empty
# activate job monitoring

# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

git_cmd="git --no-pager "
git_status_cmd="${git_cmd} status "
git_stash_list_cmd="${git_cmd} stash list "
quiet=0
current_dir="$(pwd)"

[ -z ${verbose} ] && verbose=0

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] [-d DIRECTORY]

    Check the status of a list of local GIT working copies.

    -h|-?         display this help and exit.
    -d DIRECTORY  directory contains the branch name file ('${current_dir}').
    -q            quiet modus. View only summary of changed files and pending commits for repository.
    -v            verbose mode. Can be used multiple times for increased verbosity.
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "d:h?qv" opt;
do
  case "$opt" in
    d)  DIR_NAME="$OPTARG"
    ;;
    h|\?)
      show_help
      exit 0
    ;;
    q)  quiet=$((quiet +1 ))
    ;;
    v)  verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))
REPO_NAMES=(${1})

[ -z "${DIR_NAME}" ] && DIR_NAME="${current_dir}" || true

[ -z "${BRANCH_NAME}" ] && . git_branch_name.sh
[ -z "${BRANCH_NAME}" ] && echo "Not empty >BRANCH_NAME< expected" && exit 1 || true

[ 0 = ${#REPO_NAMES[@]} ] && . git_repositories.sh
[ 0 = ${#REPO_NAMES[@]} ] && echo "Not empty >REPO_NAMES< expected" && exit 1 || true

[ 0 = "${verbose}" ] && git_status_cmd="${git_status_cmd} -s --porcelain"

cd "${DIR_NAME}"

# actualize branches
counter=1
size=${#REPO_NAMES[@]}
for repo in "${REPO_NAMES[@]}"
do
  local_dir=${repo//[^a-zA-Z0-9_\.]/_}
  if [ -d "${local_dir}" ]
    then
      echo -n "[${counter}/${size}] check status of ${repo}: ";
      pushd "${local_dir}" > /dev/null 2>&1;
      pending_changes=$(${git_status_cmd} -s --porcelain | wc -l);
      pending_commits=$(${git_cmd} log --format=oneline ${BRANCH_NAME} ^origin/${BRANCH_NAME} | wc -l);
      pending_stash_entries=$(${git_stash_list_cmd} | grep " ${BRANCH_NAME}:" | wc -l);
      # echo -n "[${counter}/${size}] check status of ${repo}: ";
      [ 0 -eq ${quiet} ] && echo "" && ${git_status_cmd} || echo -e "\t#${pending_changes} #${pending_commits} #${pending_stash_entries}"
      [[ 0 -ne ${pending_commits} && 0 -eq ${quiet} && 0 -eq ${verbose} ]] && echo " MP pending commits: ${pending_commits}";
      [[ 0 -ne ${pending_stash_entries} && 0 -eq ${quiet} && 0 -eq ${verbose} ]] && echo " MS pending stash entries: ${pending_stash_entries}";
      [[ 0 -ne ${pending_stash_entries} && 0 -ne ${verbose} ]] && ${git_stash_list_cmd}
      popd > /dev/null 2>&1;
  fi
  counter=$((counter + 1))
done
cd "${current_dir}"

#
