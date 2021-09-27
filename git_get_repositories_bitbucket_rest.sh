#!/bin/bash
#
# Get all repositories provided by a Bitbucket server via REST API.
#
# Write the repository name and the repository url to standard out:
# <repo name><TAB><repo url>
#
# List projects of a project and the ssh connection:
# @see: https://docs.atlassian.com/bitbucket-server/rest/7.16.0/bitbucket-rest.html#idp175

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

curl_cmd="curl -s"

[ -z "${verbose}" ] && verbose=0

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] -p PROJECT -s SERVER_URL [-u USER]

Get all GIT repositories of a project provided by Bitbucket server via REST API.

Required non empty >DIR_NAME< environment variable or directory
argument.

    -h|-?         display this help and exit.
    -p PROJECT    the project key on Bitbucket server.
    -s SERVER_URL Bitbucket server URL (e.g.: https://git.server.tld).
    -u USER       user ID for BASIC-Auth authentification against the Bitbucket server.
    -v            verbose mode. Can be used multiple times for increased verbosity.

Example: ${0##*/} -p "EXAMPLE" -s https://git.server.tld -u ${USER}
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "p:s:u:vh?" opt;
do
  case "$opt" in
    h|\?)
      show_help
      exit 0
    ;;
    p)
      project="$OPTARG"
    ;;
    s)
      bitbucket_server="$OPTARG"
    ;;
    u)
      user="$OPTARG"
    ;;
    v)
      verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))

[ -z "${project}" ] && echo "Bitbucket project required." && show_help && exit 1
[ -z "${bitbucket_server}" ] && echo "Bitbucket server URL required." && show_help && exit 1
[ -n "${user}" ] && curl_cmd+=" -u ${user}"

curl_cmd+=" -X GET ${bitbucket_server}/rest/api/1.0/projects/${project}/repos?limit=999"

${curl_cmd} | jq -r '.values[] | "\(.slug)\t\(.links.clone[] | select(.name=="ssh") .href)"'

#
