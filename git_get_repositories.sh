#!/bin/bash
#
# Get all (read- and writeable - managed by gitolite) GIT repositories
# provided by git server.
#
# Write the repository name and the repository url to standard out:
# <repo name><TAB><repo url>
#
set -e
# set -x

git_server="${1}"
git_command="${2}"

if [ "" == "${git_server}" ]
  then
    echo "Not empty argument (git server: git@my-git.server.tld:4711) expected"
    echo "Usage: ${0##*/} GIT_SERVER_URL [GIT_COMMAND]"
    echo "Example: ${0##*/} git@gerrit.server.tld:4711 \"gerrit ls-projects\""
    exit 1
fi

server="${git_server##*//}" # remove schema/protocol all before '//'
server_name=${server%:*} # extract all before the last ':'
port="${server##*:}" # extract all behind last ':' as port

ssh_cmd="ssh ${server_name} "
[ "${server_name}" != "${port}" ] && ssh_cmd="${ssh_cmd} -p ${port}"
[ "" != "${git_command}" ] && ssh_cmd="${ssh_cmd} ${git_command}"

repository_list=(`${ssh_cmd} 2>&1 | grep -H "R W" | cut -f2`)
[ 0 = ${#repository_list[@]} ] && repository_list=(`${ssh_cmd} 2>&1`)

for repo in "${repository_list[@]}"
do
  echo -e "${repo}\tssh://${server}/${repo}"
done

#
