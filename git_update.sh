#!/bin/bash
#
# Update all local GIT working copies or clone GIT repositories
# if the GIT repository is defined in REPO_NAMES but not cloned to
# DIR_NAME/local directory.
#
# use: DIR_NAME fill with pwd if empty
# use: BRANCH_NAME breaks if empty
# use: REPO_SERVER_URL_NAMES breaks if empty
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

REPO_SERVER_URL_NAMES=(${1})
[ 0 = ${#REPO_SERVER_URL_NAMES[@]} ] && . git_repositories.sh

if [ 0 = ${#REPO_SERVER_URL_NAMES[@]} ]
  then
    echo "Not empty >REPO_NAMES< expected"
    exit 1
fi

cd "$DIR_NAME"

# actualize branches
counter=1
size=${#REPO_SERVER_URL_NAMES[@]}
echo ${REPO_SERVER_URL_NAMES[@]}
for repo_server_url in "${REPO_SERVER_URL_NAMES[@]}"
do
  repo=(${repo_server_url})
  local_dir=${repo[0]//[^a-zA-Z0-9_\.]/_}
  echo ''
  if [ -d "${DIR_NAME}/${local_dir}/.git" ]
    then
      echo "[${counter}/${size}] update ${repo[0]}: ";
      cd "${DIR_NAME}/${local_dir}";
      echo "update ${repo[0]} and switch to branch: ${BRANCH_NAME}"
      git fetch --all --prune;
      git checkout -B ${BRANCH_NAME} -t -f origin/${BRANCH_NAME};
      git fetch;
      git rebase origin/${BRANCH_NAME};
  else
    echo "clone: ${repo[0]} to: ${DIR_NAME}/${local_dir}"
    cd "${DIR_NAME}";
    if [ -d "${DIR_NAME}/${local_dir}" ]
      then
      cd "${DIR_NAME}/${local_dir}"
      local_dir='.'
    fi
    git clone --branch ${BRANCH_NAME} ${repo[1]} ${local_dir} || true
  fi
  cd "${DIR_NAME}";
  counter=$((counter + 1))
done

. git_patch.sh
