#!/bin/bash

LIST_FILE="${1}"
AUTO_RUN=1

if [ "${LIST_FILE}" = "" ] ; then
  echo "Please give path to commit list file!"
  echo "Usage: cherry-pick-list <file/to/picklist>"
  exit 1
fi

echo "Cherry-picking all commits from file ${LIST_FILE} ..."

IFS=$'\n'
for commit in $(cat "${LIST_FILE}") ; do
# format based on git alias: issue-cherry-pick-list
  hash=$(echo ${commit} | cut -d$' ' -f 2)
  echo -n "cherry picking ${hash} ... "
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
done

