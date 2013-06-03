#!/bin/bash

. git_branch_name.sh

# patch repository
PATCH_REPO_NAME="$DIR_NAME/eclipse.private"

# repository names locate in directory
REPO_NAMES="`ls -A $DIR_NAME`"

cd "$DIR_NAME"

# check if patch repository is available on disk and check the branch name
if [[ -d "$PATCH_REPO_NAME" && "$BRANCH_NAME" == "`cd $PATCH_REPO_NAME && git rev-parse --abbrev-ref HEAD`" ]]
  then
    cd "$DIR_NAME"
    for repo_name in $REPO_NAMES; do
      if [ -d "$repo_name" ]
        then
          PATCH_FILES="`find $PATCH_REPO_NAME -name *.patch`"
          cd "$DIR_NAME/$repo_name";
          for patch_file in $PATCH_FILES; do
            TARGET_FILE_PATH="${patch_file%.[^.]*}"
            TARGET_FILE="$repo_name/${TARGET_FILE_PATH:${#PATCH_REPO_NAME}+1}"
            if [ -f "$DIR_NAME/$TARGET_FILE" ]
              then
                echo " * reset target file: $TARGET_FILE"
                git checkout -- $DIR_NAME/$TARGET_FILE
                echo " * apply patchfile: $patch_file on target file: $TARGET_FILE"
                git apply --ignore-whitespace --recount $patch_file
            fi
          done
          cd "$DIR_NAME";
      fi
    done
fi
