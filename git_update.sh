#!/bin/bash

. git_branch_name.sh

# patch repository
PATCH_REPO_NAME="$DIR_NAME/eclipse.private"

# repository names locate in directory
REPO_NAMES="`ls -A $DIR_NAME`"

cd "$DIR_NAME"

# actualize branches
for f in $REPO_NAMES; do
  if [ -d "$DIR_NAME/$f" ]
    then
	cd "$DIR_NAME/$f";
	echo "$f: ";
	git fetch;
	git checkout -f $BRANCH_NAME;
	git fetch;
	git rebase;
	cd "$DIR_NAME";
  fi
done

. git_patch.sh
