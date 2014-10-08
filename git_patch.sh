#!/bin/bash
#
# create patch file:
#   git diff -- [file to patch] > [patch repository]/[file to patch].patch
# apply patch
#   git apply --ignore-whitespace --recount < [patch repository]/[file to patch].patch
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

[ 0 = ${#REPO_NAMES[@]} ] && . git_repositories.sh
if [ 0 = ${#REPO_NAMES[@]} ]
  then
    echo "No repository found for applying patches to."
    exit 0
fi

echo ''

# patch repository
patch_branch_name_file='.patch_branch_name'
if [ "" = "${PATCH_BRANCH_NAME}" ]
  then
    if [ ! -f "${DIR_NAME}/${patch_branch_name_file}" ]
      then
        PATCH_BRANCH_NAME="${BRANCH_NAME}"
      else
        PATCH_BRANCH_NAME="$(<${DIR_NAME}/${patch_branch_name_file})"
    fi
fi
patch_repo_file='.patch_repository'

if [ "" = "${PATCH_REPO_NAME}" ]
  then
    [ -f "${DIR_NAME}/${patch_repo_file}" ] && PATCH_REPO_NAME="$(<${DIR_NAME}/${patch_repo_file})"
fi
local_dir="patch_repo"

# exit if no patch repository is defined
[ "" = "${PATCH_REPO_NAME}" ] && exit 0

# don't clone the patch repository into base git repositoy
# patch directory
if [ "${REPO_NAMES[0]}" = "." ]
  then
  patch_local_dir_name="${DIR_NAME}/../${local_dir}"
else
  patch_local_dir_name="${DIR_NAME}/${local_dir}"
fi

# update or clone patch repository
if [ -d "${patch_local_dir_name}/.git" ]
  then
    echo "update ${PATCH_REPO_NAME}: ";
    cd "${patch_local_dir_name}";
    echo "update ${PATCH_REPO_NAME} and switch to branch: ${iPATCH_BRANCH_NAME}"
    git fetch --all --prune;
    git checkout -B ${PATCH_BRANCH_NAME} -t -f origin/${PATCH_BRANCH_NAME};
    git fetch;
    git rebase origin/${PATCH_BRANCH_NAME};
else
  echo "clone: ${PATCH_REPO_NAME} to: ${patch_local_dir_name}"
  cd "${DIR_NAME}";
  if [ -d "${patch_local_dir_name}" ]
    then
    cd "${patch_local_dir_name}"
    local_dir='.'
  fi
  git clone --branch ${PATCH_BRANCH_NAME} ssh://git@git-server.icongmbh.de/${PATCH_REPO_NAME} ${local_dir} || true
fi

cd "${DIR_NAME}"

echo ''

# check if patch repository is available on disk and check the branch name
if [ -d "${patch_local_dir_name}" ]
then
    # repository names locate in directory
    cd "${DIR_NAME}"
    repo_counter=1
    repo_size=${#REPO_NAMES[@]}
    for repo_name in ${REPO_NAMES[@]}
    do
      echo "[${repo_counter}/${repo_size}] Apply patches on repository: ${repo_name}"
      if [[ -d "${repo_name}" && "${repo_name}" != "${local_dir}" ]]
      then
          patch_files=(`find ${patch_local_dir_name} -name *.patch`)
          if [ -d "${DIR_NAME}/${repo_name}" ]
            then
            cd "${DIR_NAME}/${repo_name}";
            for patch_file in ${patch_files[@]}
            do
              target_file_path="${patch_file%.[^.]*}"
              target_file_name="${repo_name}/${target_file_path:${#patch_local_dir_name}+1}"
              if [ -f "${DIR_NAME}/${target_file_name}" ]
              then
                  echo " try to apply patch: ${patch_file:${#patch_local_dir_name}+1}"
                  if `git checkout -f -- ${DIR_NAME}/${target_file_name} > /dev/null 2>&1` ;
                    then
                    echo " * reset target file: ${target_file_name}"
                    echo " * apply patchfile: ${patch_file} on target file: ${target_file_name}"
                    git apply --ignore-whitespace --recount < ${patch_file} || true
                  else
                    echo " * unable to patch file: ${target_file_name}"
                  fi
              fi
            done
          fi
          cd "${DIR_NAME}";
      fi
      repo_counter=$((repo_counter + 1))
    done
fi

#
