#!/bin/bash

. git_branch_name.sh

if [ -z "$EDITOR" ]
    then
    EDITOR="/usr/bin/vi"
fi

GIT_COMMENT_CHAR=`git config --get core.commentchar`
sed -i "s/GIT_COMMENT_CHAR/$GIT_COMMENT_CHAR/g;s/BRANCH_NAME/$BRANCH_NAME/g" "$*"
exec $EDITOR "$*"

exit $?

