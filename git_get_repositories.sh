#!/bin/bash
#
# Get all read- and writeable GIT repositories provided by git server.
#
# Write the repository name and the repository url to standard out:
# <repo name><SPACE><repo url>
#
set -e
# set -x

# space separated list of git server urls like: git@my-git.server.tld
git_server_url_list=("git@git-server.icongmbh.de" "git@git-server.icongmbh.de")

counter=1
size=${#git_server_url_list[@]}
for server in "${git_server_url_list[@]}" ; do
  repository_list=(`ssh ${server} 2>&1 | grep -H "R W" | cut -f2`)
  for repo in "${repository_list[@]}" ; do
    echo "${repo} ${server}/${repo}"
  done
done

