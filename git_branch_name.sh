#!/bin/bash

if [ "" == "$BRANCH_NAME" ]
  then

  # directory name
  export DIR_NAME="`pwd`"

  if ! git rev-parse --git-dir > /dev/null 2>&1;
    then
    # check file containing the branch name
    if [ ! -f "$DIR_NAME/.branch_name" ]
      then
        echo "file >.branch_name< or git repository is needed"
        exit 1
    fi
    # get branch name from file
    export BRANCH_NAME="$(<$DIR_NAME/.branch_name)"
  else
    export BRANCH_NAME="`git rev-parse --abbrev-ref HEAD`"
  fi

  echo "use branch: $BRANCH_NAME"
fi
