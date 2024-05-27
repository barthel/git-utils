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
# Get all public and private repositories of my own or all (only) pubic repositories for a user provided by a GitLab server via REST API.
#
# Write the repository name and the ssh repository url to standard out:
# <repo name><TAB><repo url>
#
# List projects of a user and the REST connection:
# @see: https://docs.gitlab.com/ee/api/projects.html#list-user-projects

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

curl_cmd="curl -s"

[ -z "${verbose}" ] && verbose=0
gitlab_api_server="https://api.gitlab.com"
# https://docs.gitlab.com/ee/api/members.html#roles
# No access (0), Minimal access (5), Guest (10), Reporter (20), Developer (30), Maintainer (40), Owner (50)
access_level="30"

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] [-a ACCESS LEVEL] [-s SERVER_URL] [-t PAT | -u USER]

Get all GIT repositories for a user provided by a GitLab server via REST API.

    -h|-?           display this help and exit.
    -a ACCESS LEVEL Optional one of the following numeric values listed at https://docs.gitlab.com/ee/api/members.html#roles :
                      No access (0), Minimal access (5), Guest (10), Reporter (20),
                      Developer (30) (default),
                      Maintainer (40), Owner (50)
    -s SERVER_URL   GitLab API server URL (default: https://api.gitlab.com).
    -t PAT          Personal Access Token to fetch your own public and private repositories.
    -u USER         GitLab user name to fetch the public repositories from.
    -v              verbose mode. Can be used multiple times for increased verbosity.

Example: ${0##*/} -s https://gitlab.company.tld -u ${USER}
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
      access_level="$OPTARG"
    ;;
    s)
      gitlab_api_server="$OPTARG"
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

# @see: https://docs.gitlab.com/ee/api/rest/#content-type
http_headers='Accept: application/json;'
gitlab_api_base_url="${gitlab_api_server}/api/v4/"

if [ -n "${pat}" ]
then
  # get all private and public repositories of GitLab user provided by the Personal Access Token
  # @see: https://docs.gitlab.com/ee/api/rest/#personalprojectgroup-access-tokens
  # @see: https://docs.github.com/en/rest/reference/repos#list-repositories-for-the-authenticated-user
  http_headers="Authorization: Bearer ${pat}"
  curl_cmd+=" -X GET ${gitlab_api_base_url}/projects?archived=false&min_access_level=${access_level}"
elif [ -n "${user}" ]
then
  # reolve user ID
  user_id="$(${curl_cmd} -X GET ${gitlab_api_base_url}/users/?username="${user}" | jq -r '.[] | "\(.id)"' )"
  [ "${user_id}" == "" ] && echo "User ${user} unknown." && exit 1
  # get (only) public repositories of passed GitLab User
  # @see: https://docs.gitlab.com/ee/api/projects.html#list-user-projects
  curl_cmd+=" -X GET ${gitlab_api_base_url}/users/${user}/projects?archived=false&min_access_level=${access_level}"
else
  echo "At least one Personal Access Token (PAT) or GitLab user name is required."
  show_help
  exit 1
fi

${curl_cmd} -H "${http_headers}" | jq -r '.[] | select(.empty_repo == false) | select(.archived == false) | "\(.path_with_namespace)\t\(.ssh_url_to_repo)"'

#
