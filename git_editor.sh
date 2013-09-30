#!/bin/bash

. git_branch_name.sh

if [ -z "$EDITOR" ]
    then
    EDITOR="/usr/bin/vi"
fi

sed -i "s/BRANCH_NAME/$BRANCH_NAME/g" "$*"
exec $EDITOR "$*"

exit $?

