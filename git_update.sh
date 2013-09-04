#!/bin/bash

. git_branch_name.sh

# check if the current directory contains git repository
if [ -d ".git" ]
  then
    # repository name
    REPO_NAMES="."
  else
    # repository names locate in directory
    REPO_NAMES="`ls -A $DIR_NAME`"
fi

cd "$DIR_NAME"

# actualize branches
for f in $REPO_NAMES; do
  if [ -d "$DIR_NAME/$f" ]
    then
    echo "$f: ";
    if [ -d "$DIR_NAME/$f/.git" ]
        then
        cd "$DIR_NAME/$f";
        echo "update $f and switch to branch: $BRANCH_NAME"
        git fetch --all --prune;
        git checkout -B $BRANCH_NAME -t -f origin/$BRANCH_NAME;
        git fetch;
        git rebase origin/$BRANCH_NAME;
    else
        cd "$DIR_NAME";
        echo "clone $f"
        if [ "$f" == "$PATCH_LOCAL_NAME" ]
        then
            git clone --branch $BRANCH_NAME ssh://git@git-server.icongmbh.de/$PATCH_REPO_NAME $PATCH_LOCAL_NAME
        else
            git clone --branch $BRANCH_NAME ssh://git@git-server.icongmbh.de/$f $f
        fi
    fi
    cd "$DIR_NAME";
  fi
done

. git_patch.sh
