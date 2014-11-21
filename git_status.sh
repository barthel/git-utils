#!/bin/bash
#
# Check the status of a list of local GIT working copies.
#
# use: DIR_NAME fill with pwd if empty
# use: REPO_NAMES break if empty
# use: BRANCH_NAME breaks if empty
#
set -e
# set -x

[ "" = "${DIR_NAME}" ] && DIR_NAME="`pwd`"

[ "" = "${BRANCH_NAME}" ] && . git_branch_name.sh
if [ "" = "${BRANCH_NAME}" ]
  then
    echo "Not empty >BRANCH_NAME< expected"
    exit 1
fi

REPO_NAMES=(${1})
[ 0 = ${#REPO_NAMES[@]} ] && . git_repositories.sh
if [ 0 = ${#REPO_NAMES[@]} ]
  then
    echo "Not empty >REPO_NAMES< expected"
    exit 1
fi

cd "$DIR_NAME"

# actualize branches
counter=1
size=${#REPO_NAMES[@]}
for repo in "${REPO_NAMES[@]}"
do
  local_dir=${repo//[^a-zA-Z0-9_\.]/_}
  if [ -d "${DIR_NAME}/${local_dir}" ]
    then
      cd "${DIR_NAME}/${local_dir}";
      echo "[${counter}/${size}] check status of ${repo}: ";
      git status -s --porcelain;
      pending_commits=`git log ${BRANCH_NAME} ^origin/${BRANCH_NAME} | grep commit | wc -l`;
      [ 0 != ${pending_commits} ] && echo " MP pending commits: ${pending_commits}";
  fi
  cd "${DIR_NAME}";
  counter=$((counter + 1))
done

