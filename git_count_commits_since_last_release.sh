#!/bin/bash
#
# Get count of commits since the last release commit.
#
# use: DIR_NAME fill with pwd if empty
# use: REPO_NAMES break if empty
# use: BRANCH_NAME breaks if empty
#
set -m
# set -x

release_commiter_name="ic_jenkins"
release_commit_eyecatcher='\[maven-release-plugin\]'
regexp_release_commit='.*'${release_commit_eyecatcher}'.*release'
quit=false

[ -z ${verbose} ] && verbose=0

show_help() {
cat << EOF

  Usage: ${0##*/} [-v]
  Get count of commits since the last release commit.

  Use >`pwd`< if >DIR_NAME< environment variable and the directory argument
  are empty.

  -d DIRECTORY  directory contains the repository file (${repo_list_file})
  -v            verbose mode. Can be used multiple times for increased verbosity.
                A
  -q            quit modus. View only commit count summary for repository.
EOF
}

### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "d:qvh?" opt;
do
  case "$opt" in
    d)
      DIR_NAME="$(dirname $OPTARG)"
    ;;
    h|\?)
      show_help
      exit 0
    ;;
    q)
      quit=true
    ;;
    v)
      verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))

[ "" = "${DIR_NAME}" ] && DIR_NAME="`pwd`"

[ "" = "${BRANCH_NAME}" ] && . git_branch_name.sh
if [ "" = "${BRANCH_NAME}" ]
  then
    echo "Not empty >BRANCH_NAME< expected"
    exit 1
fi

REPO_NAMES=(${1})
[ 0 = ${#REPO_NAMES[@]} ] && . git_repositories.sh
if [ 0 = ${#REPO_NAMES[@]} ]
  then
    echo "Not empty >REPO_NAMES< expected"
    exit 1
fi

cd "$DIR_NAME"

counter=1
size=${#REPO_NAMES[@]}
# loop over all known repositories
for repo in "${REPO_NAMES[@]}"
do
  # normalize repository name
  local_dir=${repo//[^a-zA-Z0-9_\.]/_}
  if [ -d "${DIR_NAME}/${local_dir}" ]
    then
      counter_commits=0
      cd "${DIR_NAME}/${local_dir}";
      echo -n "[${counter}/${size}] check commits since last release of ${repo}: ";
      [ false == ${quit} ] && echo "" || true
      # find all directories within the current repo but ignore: './target'
      # and all directories starts with './.'
      IFS=$' '
      for directory in `find . -maxdepth 1 -type d | grep -v "^\.\/target\|^\./\..*$" | xargs`
      do
        # check if ${directory} is the current directory and use pom.xml
        # instead or continue
        if [ "." == "${directory}" ]
          then
            [ -f "./pom.xml" ] && directory="./pom.xml" || continue
        fi
        # get the last release commit based on commit message regular expression
        # and the name of the committer
        IFS=$'\t'
        last_release_commit=($(git log --pretty=format:"%H%x09\"%s\"" --all --max-count=1 --regexp-ignore-case --committer ${release_commiter_name} --branches=${BRANCH_NAME} --basic-regexp --grep "${regexp_release_commit}" -- ${directory}))
        # check the count of commit since the ${last_release_commit} commit
        # hash and ignore other release commits (like the next iteration commit)
        # instead
        pending_commits=`git log --pretty=format:"%H%x09\"%s\"" ${BRANCH_NAME}  ${last_release_commit[0]}.. -- ${directory} | grep -v "${release_commit_eyecatcher}" | wc -l`
        counter_commits=$((counter_commits + pending_commits))
        if [[ 0 -lt "${pending_commits}" && false == ${quit} ]]
          then
            echo -e -n "\t${directory##*/}:\t#${pending_commits}"
            [ 0 -lt "${verbose}" ] && echo -e -n "\t (since: ${last_release_commit[0]} ${last_release_commit[1]})";
            echo ""
        fi
      done
      [[ 0 -lt "${verbose}" || true == ${quit} ]] && echo -e "\t#${counter_commits}" || true
  fi
  cd "${DIR_NAME}";
  counter=$((counter + 1))
done

#
