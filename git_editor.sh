#!/usr/bin/env bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# (c) barthel <barthel@users.noreply.github.com> https://github.com/barthel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

