#!/bin/bash
#
# 
#
set -e
# set -x

[ "" = "${DIR_NAME}" ] && DIR_NAME="`pwd`"

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
  local_dir=${repo//[^a-zA-Z_\.]/_}
  if [ -d "${DIR_NAME}/${local_dir}" ]
    then
      cd "${DIR_NAME}/${local_dir}";
      echo "[${counter}/${size}] check status of ${repo}: ";
      git status -s --porcelain;
  fi
  cd "${DIR_NAME}";
  counter=$((counter + 1))
done

