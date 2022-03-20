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
# Get all public and private repositories of my own or all (only) pubic repositories for a user provided by a GitHub server via REST API.
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
affiliation="owner"

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] [-a AFFILIATION] [-s SERVER_URL] [-t PAT | -u USER]

Get all GIT repositories for a user provided by a GitHub server via REST API.

    -h|-?           display this help and exit.
    -a AFFILIATION  Optional comma-separated list of values. Can include:
                    * owner: Repositories that are owned by the authenticated user. (Default)
                    * collaborator: Repositories that the user has been added to as a collaborator.
                    * organization_member: Repositories that the user has access to through being a member of an organization.
                      This includes every repository on every team that the user is on.
    -s SERVER_URL   GitHub API server URL (default: https://api.github.com).
    -t PAT          Personal Access Token to fetch your own public and private repositories.
    -u USER         GitHub user ID to fetch the public repositories from.
    -v              verbose mode. Can be used multiple times for increased verbosity.

Example: ${0##*/} -s https://github.company.tld -u ${USER}
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "a:p:s:t:u:vh?" opt;
do
  case "$opt" in
    h|\?)
      show_help
      exit 0
    ;;
    a)
      affiliation="$OPTARG"
    ;;
    s)
      github_api_server="$OPTARG"
    ;;
    t)
      pat="$OPTARG"
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

# @see: https://docs.github.com/en/rest/overview/media-types
http_headers='Accept: application/vnd.github.v3+json;'

if [ -n "${pat}" ]
then
  # get all private and public repositories of Github user provided by the Personal Access Token
  # @see: https://docs.github.com/en/rest/reference/repos#list-repositories-for-the-authenticated-user
  http_headers="Authorization: token ${pat}"
  curl_cmd+=" -X GET ${github_api_server}/user/repos?visibility=all&archived=false&affiliation=${affiliation}"
elif [ -n "${user}" ]
then
  # get (only) public repositories of passed Github User ID
  # @see: https://docs.github.com/en/rest/reference/repos#list-repositories-for-a-user
  #   https://api.github.com/users/barthel/repos?per_page=100
  curl_cmd+=" -X GET ${github_api_server}/users/${user}/repos?per_page=100"
  [ "${affiliation}" != "owner" ] && curl_cmd+="&type=all"
else
  echo "At least one Personal Access Token (PAT) or Github user ID is required."
  show_help
  exit 1
fi

${curl_cmd} -H "${http_headers}" | jq -r '.[] | select(.archived == false) | "\(.name)\t\(.ssh_url)"'

#
