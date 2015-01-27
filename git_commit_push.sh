#!/bin/bash
#

message=""

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "m:" opt;
do
  case "$opt" in
    m)  message="$OPTARG"
    ;;
  esac
done

shift $((OPTIND-1))

[ "" == "${message}" ] && exit 1 || true

repo_list=$(git_status.sh | grep -B1 "^.M .*" | grep "^\[" | cut -d' ' -f5 | cut -d':' -f1)
for repo in ${repo_list[@]}
do
  echo "${repo}"
#  continue;
  pushd ${repo} >> /dev/null 2>&1;
  git add -u;
  git commit -m"${message}";
  git fetch;
  git rebase;
  git push --no-thin;
  popd >> /dev/null 2>&1;
done;
