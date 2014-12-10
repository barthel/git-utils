#!/bin/bash
#
# Check the status of a list of local GIT working copies.
#
# use: DIR_NAME fill with pwd if empty
# use: REPO_NAMES break if empty
# use: BRANCH_NAME breaks if empty
# activate job monitoring

# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

git_status_cmd="git status "
quiet=false
current_dir="$(pwd)"

required_helper=('git' 'pwd' 'wc')

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

check_required_helper() {
  helper=("$@")
  for executable in "${helper[@]}";
  do
    # @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
    if hash $executable 2>/dev/null
      then
        [[ $verbose -gt 0 ]] && echo "found required executable: $executable"
      else
        echo "the executable: $executable is required!"
        return 1
    fi
  done
  return 0
}
### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "d:h?qv" opt;
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
      pushd "${local_dir}" 2>&1 > /dev/null;
      pending_commits=`git log --format=oneline ${BRANCH_NAME} ^origin/${BRANCH_NAME} | wc -l`;
      echo -n "[${counter}/${size}] check status of ${repo}: ";
      [ false == ${quiet} ] && echo "" && ${git_status_cmd} || echo -e "\t#$(${git_status_cmd} | wc -l) #${pending_commits}"
      [[ 0 != ${pending_commits} && false == ${quiet} && 0 = ${verbose} ]] && echo " MP pending commits: ${pending_commits}";
  fi
  popd 2>&1 > /dev/null;
  counter=$((counter + 1))
done
cd "${current_dir}"

#
