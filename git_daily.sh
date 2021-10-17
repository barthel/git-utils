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
# Create list of all my commits in an date range for a list of local GIT working copies.
#
# use: DIR_NAME fill with pwd if empty
# use: REPO_NAMES break if empty
# use: BRANCH_NAME breaks if empty
# activate job monitoring

# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

git_log_cmd="git --no-pager log --reverse --all --regexp-ignore-case --oneline "
quiet=0
current_dir="$(pwd)"
since_date="$(date '+%Y-%m-%d' )"
until_date=""

[ -z "${verbose}" ] && verbose=0

show_help() {
cat << EOF
Usage: ${0##*/} [-h?v] [-d DIRECTORY] [-s ISO-8601 date [-u ISO-8601 date]]

    List my commits within a date range in all local GIT working copies.

    -h|-?             display this help and exit.
    -s ISO-8601 date  start (since) date of date range with date in ISO-8601 date format: %Y-%m-%d ('${after_date}')
    -u ISO-8601 date  end (until) date of date range with date in ISO-8601 date format
    -d DIRECTORY      directory contains the branch name file ('${current_dir}').
    -q                quiet modus.
    -v                verbose mode. Can be used multiple times for increased verbosity.
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "a:s:b:u:d:h?qv" opt;
do
  case "$opt" in
    a|s) since_date="$OPTARG"
    ;;
    b|u) until_date="$OPTARG"
    ;;
    d)  DIR_NAME="$OPTARG"
    ;;
    h|\?)
      show_help
      exit 0
    ;;
    q)  quiet=$((quiet +1 ))
    ;;
    v)  verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))
REPO_NAMES=(${1})

[ -z "${DIR_NAME}" ] && DIR_NAME="${current_dir}" || true

[ -z "${BRANCH_NAME}" ] && . git_branch_name.sh
[ -z "${BRANCH_NAME}" ] && echo "Not empty >BRANCH_NAME< expected" && exit 1 || true

[ 0 = ${#REPO_NAMES[@]} ] && . git_repositories.sh
[ 0 = ${#REPO_NAMES[@]} ] && echo "Not empty >REPO_NAMES< expected" && exit 1 || true

[ "" = "${until_date}" ] && until_date="${since_date}"

cd "${DIR_NAME}" || exit 1

[ 0 = ${quiet} ] && echo "date range since ${since_date} and until ${until_date}" || true

[ 0 -lt ${verbose} ] && git_log_cmd+="  --date=iso " || git_log_cmd+="  --date=short "

# actualize branches
counter=1
size=${#REPO_NAMES[@]}
for repo in "${REPO_NAMES[@]}"
do
  local_dir="${repo}" #${repo//[^a-zA-Z0-9_\-\.]/_}
  if [ -d "${local_dir}" ]
    then
      { pushd "${local_dir}" > /dev/null; }  2>&1 || exit 1;
      # Get GIT information incl. hash and separate with space
      # The hash will be used to evaluate duplicate entries (author date and commit date differs)
      # Evaluate git committer based on local repository instead of global
      git_iam="$(git config --get user.email)"
      # starts log output wirth: [hash][ ]
      git_log_format_prefix="%H%x20"
      # filter date range by awk
      awk_author_date_filter="\$2>=\"${since_date}\" && \$2<=\"${until_date}\""
      # get commit list incl. author date: [hash][ ][ ][author timestamp]
      git_author_log_format="${git_log_format_prefix}%x20%ad"
      # append commit hash on verbose level > 1: [ ][hash]
      [ 1 -lt ${verbose} ] && git_author_log_format+="%x20%H" || true
      # append commit message at the end: [ ][commit message]
      git_author_log_format+="%x20%s"
      git_author_date_log_output=$(${git_log_cmd} --pretty=format:${git_author_log_format} --author=${git_iam} | awk "${awk_author_date_filter}")

      # get commit list by commit date
      since_date+="T00:00:00"
      until_date+="T23:59:59"
      git_log_cmd+=" --since=${since_date} --until=${until_date} "
      # get commit list filtered by git itself with commit date: [hash][ ][ ][commit timestamp]
      git_commit_log_format="${git_log_format_prefix}%x20%cd"
      # append commit hash on verbose level > 1: [ ][hash]
      [ 1 -lt ${verbose} ] && git_commit_log_format+="%x20%H" || true
      # append commit message at the end: [ ][commit message]
      git_commit_log_format+="%x20%s"
      git_commit_log_output="$(${git_log_cmd} --pretty=format:${git_commit_log_format} --author=${git_iam})"
      [ 0 = ${quiet} ] && echo "[${counter}/${size}] ${repo}: " || true
      # merge both lists, remove duplicates by first commit hash, remove the first commit hash and sort by date
      git_log_output="${git_author_date_log_output}"
      [[ "" != "${git_commit_log_output}" && "" != "${git_log_output}" ]] && git_log_output+='\n' || true
      git_log_output+=${git_commit_log_output}
      if [ "" != "${git_log_output}" ] 
        then
          echo -e "${git_log_output}" | awk '!x[$1]++' | sort -t' ' -k3,4 | cut -d' ' -f2-
      fi
  fi
  { popd > /dev/null; }  2>&1 || exit 1
  counter=$((counter + 1))
done
cd "${current_dir}" || exit 1
#
