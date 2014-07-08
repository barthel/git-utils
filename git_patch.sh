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

echo ''

# patch repository
repo="UweBarthel/eclipse"
local_dir="eclipse.private"
# patch directory
patch_local_dir_name="${DIR_NAME}/${local_dir}"

# update or clone patch repository
if [ -d "${patch_local_dir_name}/.git" ]
  then
    echo "update ${repo}: ";
    cd "${patch_local_dir_name}";
    echo "update ${repo} and switch to branch: ${BRANCH_NAME}"
    git fetch --all --prune;
    git checkout -B ${BRANCH_NAME} -t -f origin/${BRANCH_NAME};
    git fetch;
    git rebase origin/${BRANCH_NAME};
else
  echo "clone: ${repo} to: ${patch_local_dir_name}"
  cd "${DIR_NAME}";
  if [ -d "${patch_local_dir_name}" ]
    then
    cd "${patch_local_dir_name}"
    local_dir='.'
  fi
  git clone --branch ${BRANCH_NAME} ssh://git@git-server.icongmbh.de/${repo} ${local_dir} || true
fi

cd "${DIR_NAME}"

echo ''

# check if patch repository is available on disk and check the branch name
#if [[ -d "$PATCH_LOCAL_DIR_NAME" && "$BRANCH_NAME" == "`cd $PATCH_LOCAL_DIR_NAME && git rev-parse --abbrev-ref HEAD`" ]]
if [ -d "${patch_local_dir_name}" ]
then
    [ 0 = ${#REPO_NAMES[@]} ] && . git_repositories.sh

    if [ 0 = ${#REPO_NAMES[@]} ]
      then
        echo "No repository found for applying patch to"
        exit 0
    fi

    echo ''

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
                    git apply --ignore-whitespace --recount ${patch_file} || true
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
