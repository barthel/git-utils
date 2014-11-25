#!/bin/bash
#
# Use argument as a file and cherry-pick all containing commit-hashes
#
LIST_FILE="${1}"
AUTO_RUN=1

if [ "${LIST_FILE}" = "" ] ; then
  echo "Please give path to commit list file!"
  echo "Usage: cherry-pick-list <file/to/picklist>"
  exit 1
fi

echo "Cherry-picking all commits from file ${LIST_FILE} ..."

IFS=$'\n'
commit_list=(`cat "${LIST_FILE}"`)

counter=1
size=${#commit_list[@]}
for commit in "${commit_list[@]}" ; do
# format based on git alias: issue-cherry-pick-list
  hash=$(echo ${commit} | cut -d$' ' -f 2)
  echo -n "[$counter/$size] cherry picking: ${hash} ... "
  git cherry-pick "${hash}"

  if [[ $? -eq 0 ]]
  then
    if [[ ${AUTO_RUN} -eq 1 ]]
    then
      echo "done."
    else
      read -p "Press [ENTER] key if you are sure and to continue ..."
    fi
  else
    echo "There are conflicts to resolve!"
    read -p "Press [ENTER] key if you have resolved the conflicts and to continue ..."
  fi
  git commit --amend -m"${commit}"
  counter=$((counter + 1))
done
echo "cherry picking of $size commits done."
echo "use the following command to squash these commits: git rebase -i HEAD~$size"
