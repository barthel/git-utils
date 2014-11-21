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
git_server_list=(${@})

if [ 0 = ${#git_server_list[@]} ]
  then
    echo "Not empty argument (git server: git@my-git.server.tld:4711) expected"
    echo "Usage: ${0##*/} GIT_SERVER_URL [ GIT_SERVER_URL]..."
    exit 1
fi
counter=1
size=${#git_server_list[@]}
for server in "${git_server_list[@]##*//}" ; do # remove schema/protocol all before '//'
  server_name=${server%:*} # extract all before the last ':'
  port="${server##*:}" # extract all behind last ':' as port
  ssh_cmd="ssh ${server_name}"
  [ "${server_name}" != "${port}" ] && ssh_cmd="${ssh_cmd} -p ${port}"
  repository_list=(`${ssh_cmd} 2>&1 | grep -H "R W" | cut -f2`)
  for repo in "${repository_list[@]}" ; do
    echo "${repo} ssh://${server}/${repo}"
  done
done

