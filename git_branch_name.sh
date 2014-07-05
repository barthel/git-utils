#!/bin/bash

# directory name
export DIR_NAME="`pwd`"

branch_name_file='.branch_name'

if [ "" == "$BRANCH_NAME" ]
  then
  if ! git rev-parse --git-dir > /dev/null 2>&1;
  then
    # check file containing the branch name
    if [ ! -f "$DIR_NAME/$branch_name_file" ]
    then
        echo "file >$branch_name_file< or git repository is needed"
        exit 1
    fi
    # get branch name from file
    export BRANCH_NAME="$(<$DIR_NAME/$branch_name_file)"
  else
    export BRANCH_NAME="`git rev-parse --abbrev-ref HEAD`"
  fi
fi

echo "use branch: $BRANCH_NAME"

# patch repository
export PATCH_REPO_NAME="UweBarthel/eclipse"
export PATCH_LOCAL_NAME="eclipse.private"

#
