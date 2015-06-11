#!/bin/bash
#
# This script is wrapping the commit message editor for git.
# Replace the following placeholder:
#  GIT_COMMENT_CHAR - with the configured comment char got by 'git config'
#  BRANCH_NAME - with the actual branch name
# 
set -m
#set -x

. git_branch_name.sh

# check and set EDITOR if needed
[ -z "${EDITOR}" ] && EDITOR="/usr/bin/vi" || true

# get comment char from git configuration
GIT_COMMENT_CHAR="$(git config --get core.commentchar)"
[ -z "$GIT_COMMENT_CHAR" ] && GIT_COMMENT_CHAR="#" || true

# replace comment char and branch name in template file
sed -i "s/GIT_COMMENT_CHAR/${GIT_COMMENT_CHAR}/g;s/BRANCH_NAME/${BRANCH_NAME}/g" "$*"
exec ${EDITOR} "$*"

exit $?

