#!/bin/bash
#
# 
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
  local_dir=${repo//[^a-zA-Z_\.]/_}
  echo ''
  if [ -d "${DIR_NAME}/${local_dir}/.git" ]
    then
      echo "[${counter}/${size}] update ${repo}: ";
      cd "${DIR_NAME}/${local_dir}";
      echo "update ${repo} and switch to branch: ${BRANCH_NAME}"
      git fetch --all --prune;
      git checkout -B ${BRANCH_NAME} -t -f origin/${BRANCH_NAME};
      git fetch;
      git rebase origin/${BRANCH_NAME};
  else
    echo "clone: ${repo} to: ${DIR_NAME}/${local_dir}"
    cd "${DIR_NAME}";
    if [ -d "${DIR_NAME}/${local_dir}" ]
      then
      cd "${DIR_NAME}/${local_dir}"
      local_dir='.'
    fi
    git clone --branch ${BRANCH_NAME} ssh://git@git-server.icongmbh.de/${repo} ${local_dir} || true
  fi
  cd "${DIR_NAME}";
  counter=$((counter + 1))
done

. git_patch.sh
