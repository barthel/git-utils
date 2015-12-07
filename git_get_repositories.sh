#!/bin/bash
#
# Get all GIT repositories provided by git server.
#
# If the git server is managed by gitolite only the read- and writable repositories are used.
#
# Write the repository name and the repository url to standard out:
# <repo name><TAB><repo url>
#
# List projects on gerrit: gerrit ls-projects
# @see: https://gerrit.googlecode.com/svn/documentation/2.0/cmd-ls-projects.html

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

[ -z ${verbose} ] && verbose=0

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] [-c COMMAND] -s SERVER_URL

Get all (read- and writeable - managed by gitolite) GIT repositories
provided by git server via ssh connection.

Required non empty >DIR_NAME< environment variable or directory
argument.

    -h|-?         display this help and exit.
    -c COMMAND    command to execute on remote git repository server (e.g. "gerrit ls-projects").
    -s SERVER_URL server url to remote git repository server.
    -v            verbose mode. Can be used multiple times for increased verbosity.

Example: ${0##*/} -s ${USER}@gerrit.server.tld:4711 -c "gerrit ls-projects"
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "c:s:vh?" opt;
do
  case "$opt" in
    c)
      git_command="$OPTARG"
    ;;
    h|\?)
      show_help
      exit 0
    ;;
    s)
      git_server="$OPTARG"
    ;;
    v)
      verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))

[ -z "${git_server}" ] && show_help && exit 1 || true

server="${git_server##*//}" # remove schema/protocol all before '//'
server_name=${server%:*} # extract all before the last ':'
port="${server##*:}" # extract all behind last ':' as port

ssh_cmd="ssh ${server_name} "
[ "${server_name}" != "${port}" ] && ssh_cmd="${ssh_cmd} -p ${port}"
[ ! -z "${git_command}" ] && ssh_cmd="${ssh_cmd} ${git_command}"

repository_list=(`${ssh_cmd} 2>&1 | grep -H "R W" | cut -f2`)
[ 0 = ${#repository_list[@]} ] && repository_list=(`${ssh_cmd} 2>&1`)

for repo in "${repository_list[@]}"
do
  echo -e "${repo}\tssh://${server}/${repo}"
done

#
