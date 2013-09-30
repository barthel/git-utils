#!/bin/bash

. git_branch_name.sh

# check and set EDITOR if needed
if [ -z "$EDITOR" ]
    then
    EDITOR="/usr/bin/vi"
fi

# get comment char from git configuration
GIT_COMMENT_CHAR=`git config --get core.commentchar`
if [ -z "$GIT_COMMENT_CHAR" ]
    then
    GIT_COMMENT_CHAR="#"
fi

# replace comment char and branch name in template file
sed -i "s/GIT_COMMENT_CHAR/$GIT_COMMENT_CHAR/g;s/BRANCH_NAME/$BRANCH_NAME/g" "$*"
exec $EDITOR "$*"

exit $?

