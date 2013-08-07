#!/bin/bash

. git_branch_name.sh


# patch directory
PATCH_LOCAL_DIR_NAME="$DIR_NAME/$PATCH_LOCAL_NAME"

# check if patch repository is available on disk and check the branch name
if [[ -d "$PATCH_LOCAL_DIR_NAME" && "$BRANCH_NAME" == "`cd $PATCH_LOCAL_DIR_NAME && git rev-parse --abbrev-ref HEAD`" ]]
then
    # repository names locate in directory
    REPO_NAMES="`ls -A $DIR_NAME`"
    cd "$DIR_NAME"
    for repo_name in $REPO_NAMES; do
      if [[ -d "$repo_name" && "$repo_name" != "$PATCH_LOCAL_NAME" ]]
      then
          PATCH_FILES="`find $PATCH_LOCAL_DIR_NAME -name *.patch`"
          cd "$DIR_NAME/$repo_name";
          for patch_file in $PATCH_FILES; do
            TARGET_FILE_PATH="${patch_file%.[^.]*}"
            TARGET_FILE="$repo_name/${TARGET_FILE_PATH:${#PATCH_LOCAL_DIR_NAME}+1}"
            if [ -f "$DIR_NAME/$TARGET_FILE" ]
            then
                echo " * reset target file: $TARGET_FILE"
                git checkout -f -- $DIR_NAME/$TARGET_FILE
                echo " * apply patchfile: $patch_file on target file: $TARGET_FILE"
                git apply --ignore-whitespace --recount $patch_file
            fi
          done
          cd "$DIR_NAME";
      fi
    done
fi
