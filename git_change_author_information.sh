#!/bin/sh
#
# Push changes: git push --force --tags origin 'refs/heads/*'
# Got from: https://help.github.com/articles/changing-author-info/


set -m
set -e
# set -x


old_email=""
correct_email=""
correct_name=""

use_force=0

_show_help() {
cat << EOF
Usage: ${0##*/} [-h?] -o OLD_EMAIL -e CORRECT_EMAIL -n CORRECT_NAME

Replace the author and commiter name and email on ALL commits in git repository

    -h|-?             display this help and exit.
    -f                force mode see: git-filter-branch --force ...
    -o OLD_EMAIL      the old email to replace
    -e CORRECT_EMAIL  the new correct email
    -n CORRECT_NAME   the new author name

Example:  ${0##*/}
          ${0##*/} -o "your-old-email@example.com" -e "your-correct-email@example.com"
          ${0##*/} -o "your-old-email@example.com" -n "Your Correct Name"
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "o:e:n:h?f" opt;
do
  case "$opt" in
    o) old_email="${OPTARG}"
    ;;
    e) correct_email="${OPTARG}"
    ;;
    n) correct_name="${OPTARG}"
    ;;
    f) use_force=1
    ;;
    h|\?)
      _show_help
      exit 0
    ;;
  esac
done

shift $((OPTIND-1))

[ -z "${correct_email}" ] && [ -z "${correct_name}" ] && echo "One of correct email or correct name expected" && _show_help && exit 1 || true

env_filter="
OLD_EMAIL=\"${old_email}\"
CORRECT_EMAIL=\"${correct_email}\"
CORRECT_NAME=\"${correct_name}\"
"
env_filter=${env_filter}'
if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    [ ! -z "${CORRECT_NAME}" ] && export GIT_COMMITTER_NAME="${CORRECT_NAME}"
    [ ! -z "${CORRECT_EMAIL}" ] && export GIT_COMMITTER_EMAIL="${CORRECT_EMAIL}"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    [ ! -z "${CORRECT_NAME}" ] && export GIT_AUTHOR_NAME="${CORRECT_NAME}"
    [ ! -z "${CORRECT_EMAIL}" ] && export GIT_AUTHOR_EMAIL="${CORRECT_EMAIL}"
fi
'

git_filter_branch_cmd='git --no-pager filter-branch '
[ "${use_force}" -gt 0 ] && git_filter_branch_cmd="${git_filter_branch_cmd} --force " || true

${git_filter_branch_cmd} --env-filter "${env_filter}" --tag-name-filter cat -- --branches --tags

