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
# Get all repositories for a user provided by a GitHub server via REST API.
#
# Write the repository name and the ssh repository url to standard out:
# <repo name><TAB><repo url>
#
# List projects of a project and the REST connection:
# @see: https://docs.github.com/en/rest/reference/repos#list-repositories-for-a-user

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

curl_cmd="curl -s"

[ -z "${verbose}" ] && verbose=0
github_api_server="https://api.github.com"

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] [-s SERVER_URL] -u USER

Get all GIT repositories for a user provided by a GitHub server via REST API.

    -h|-?         display this help and exit.
    -s SERVER_URL GitHub API server URL (default: https://api.github.com).
    -u USER       GitHub user ID.
    -v            verbose mode. Can be used multiple times for increased verbosity.

Example: ${0##*/} -s https://github.company.tld -u ${USER}
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
    s)
      github_api_server="$OPTARG"
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

[ -z "${user}" ] && echo "GitHub user ID required." && show_help && exit 1

# @see: https://docs.github.com/en/rest/overview/media-types
curl_cmd+=' -H "Accept: application/vnd.github.v3+json"'
# @see: https://docs.github.com/en/rest/reference/repos#list-repositories-for-a-user
#   https://api.github.com/users/barthel/repos?per_page=100
curl_cmd+=" -X GET ${github_api_server}/users/${user}/repos?per_page=100"

${curl_cmd} | jq -r '.[] | select(.archived == false) | "\(.name)\tssh://\(.ssh_url)"'

#
