#!/bin/bash

. git_branch_name.sh

repo_list_file='.repositories'
repo_names=('.')

# check if the current directory contains git repository
if [ ! -d ".git" ]
  then
  if [ ! -f "$DIR_NAME/$repo_list_file" ]
    then
      # repository names locate in directory
      repo_names=(`ls -A "${DIR_NAME}"`)
    else
      repo_names=(`cat "${repo_list_file}"`)
  fi
fi

cd "$DIR_NAME"

# actualize branches
counter=1
size=${#repo_names[@]}
for repo in "${repo_names[@]}" ; do
  local_dir=${repo//[^a-zA-Z_\.]/_}
  echo ''
  if [ -d "$DIR_NAME/$local_dir/.git" ]
    then
      echo "[$counter/$size] update $repo: ";
      cd "$DIR_NAME/$local_dir";
      echo "update $repo and switch to branch: $BRANCH_NAME"
      git fetch --all --prune;
      git checkout -B $BRANCH_NAME -t -f origin/$BRANCH_NAME;
      git fetch;
      git rebase origin/$BRANCH_NAME;
    else
      echo "clone: $repo to: $DIR_NAME/$local_dir"
      cd "$DIR_NAME";
      if [ -d "$DIR_NAME/$local_dir" ]
        then
        cd "$DIR_NAME/$local_dir"
        local_dir='.'
      fi
      if [ "$repo" == "$PATCH_LOCAL_NAME" ]
        then
          git clone --branch $BRANCH_NAME ssh://git@git-server.icongmbh.de/$PATCH_REPO_NAME $PATCH_LOCAL_NAME
        else
            git clone --branch $BRANCH_NAME ssh://git@git-server.icongmbh.de/$repo $local_dir
      fi
  fi
  cd "$DIR_NAME";
  counter=$((counter + 1))
done

. git_patch.sh
