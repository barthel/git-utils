#!/bin/bash

. git_branch_name.sh

if [ -z "$EDITOR" ]
    then
    EDITOR="/usr/bin/vi"
fi

for word in "$*"; do echo "$word"; done
sed -i "s/BRANCH_NAME/$BRANCH_NAME/g" "$*"
exec $EDITOR "$*"

