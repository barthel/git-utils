#!/bin/bash
#
# Update all local GIT working copies or clone GIT repositories
# if the GIT repository is defined in REPO_NAMES but not cloned to
# DIR_NAME/local directory.
#
# Download hooks/commit-msg from remote server if available and
# install into local .git/hooks/.
#
# use: DIR_NAME fill with pwd if empty
# use: BRANCH_NAME breaks if empty
# use: REPO_SERVER_URL_NAMES breaks if empty
# use: DEFAULT_GIT_SERVER_URL
#
set -e
# set -x

[ "" = "${DIR_NAME}" ] && DIR_NAME="`pwd`"

[ "" = "${BRANCH_NAME}" ] && . git_branch_name.sh

if [ "" = "${BRANCH_NAME}" ]
  then
    echo "Not empty >BRANCH_NAME< expected"
    exit 1
fi

REPO_SERVER_URL_NAMES=(${1})
[ 0 = ${#REPO_SERVER_URL_NAMES[@]} ] && . git_repositories.sh

if [ 0 = ${#REPO_SERVER_URL_NAMES[@]} ]
  then
    echo "Not empty >REPO_NAMES< expected"
    exit 1
fi

cd "$DIR_NAME"

# actualize branches
counter=1
size=${#REPO_SERVER_URL_NAMES[@]}
for repo_server_url in "${REPO_SERVER_URL_NAMES[@]}"
do
  repo=(${repo_server_url})
  repo_name="${repo[0]}"
  repo_url="${repo[1]}"
  [ "" == "${repo_url}" ] && repo_url="${DEFAULT_GIT_SERVER_URL}/${repo_name}"
  local_dir=${repo_name//[^a-zA-Z0-9_\.]/_}
  echo ''
  if [ -d "${DIR_NAME}/${local_dir}/.git" ]
    then
      cd "${DIR_NAME}/${local_dir}";
      echo "[${counter}/${size}] update: ${repo_name} and switch to branch: ${BRANCH_NAME}"
      git fetch --all --prune;
      git checkout -B ${BRANCH_NAME} -t -f origin/${BRANCH_NAME};
      git fetch;
      git rebase origin/${BRANCH_NAME};
    else
      echo "[${counter}/${size}] clone: ${repo_name} to: ${DIR_NAME}/${local_dir}"
      cd "${DIR_NAME}";
      if [ -d "${DIR_NAME}/${local_dir}" ]
        then
          cd "${DIR_NAME}/${local_dir}"
          local_dir='.'
      fi
      git clone --branch ${BRANCH_NAME} ${repo_url} ${local_dir} || true
  fi
  cd "${DIR_NAME}/${local_dir}"

  git_remote_origin_url=$(git config --local --get "remote.origin.url")

  # @see: http://thinkinginsoftware.blogspot.de/2013/12/bash-extract-tokens-from-string-using.html
  # ssh://identity@gerrit.server.tld:29418/repo.name
  # extract server protocol - all before '://'
  # ssh
  git_remote_origin_url_protocol="${git_remote_origin_url%%:\/\/*}"
  if [ "ssh" == "${git_remote_origin_url_protocol}" ]
    then
      # remove schema/protocol - all before '//'
      # identity@gerrit.server.tld:29418/repo.name
      git_remote_origin_host_port_path="${git_remote_origin_url##*\/\/}"
      # get repo name - all after first '/'
      # repo.name
      git_remote_origin_path="${git_remote_origin_host_port_path#*\/}"
      # extract identity, server name and port - all before first '/'
      # identity@gerrit.server.tld:29418
      git_remote_origin_host_port="${git_remote_origin_host_port_path%%\/*}"
      # get server name and identity - extract all before the last ':'
      # identity@gerrit.server.tld
      server_name="${git_remote_origin_host_port%:*}"
      # extract port - extract all after ':'
      # 29418
      server_port="${git_remote_origin_host_port##*\:}"

      # gerrit check
      ssh_cmd="ssh "
      scp_cmd="scp -p "
      [ "${server_name}" != "${server_port}" ] && scp_cmd="${scp_cmd} -P ${server_port}" && ssh_cmd="${ssh_cmd} -p ${server_port}"
      ssh_cmd="${ssh_cmd} ${server_name} gerrit version"
      if `${ssh_cmd} > /dev/null 2>&1`;
        then
          git_dir=$(git rev-parse --git-dir)
          if [ "true" != "`git config --local --bool --get gerrit.createchangeid`" ]
            then
              git config --add "gerrit.createchangeid" "true"
          fi
          if [ ! -f "${git_dir}/hooks/commit-msg" ]
            then
              # download commit-msg if available
              scp_cmd="${scp_cmd} ${server_name}:hooks/commit-msg ${git_dir}/hooks/"
              ${scp_cmd} > /dev/null 2>&1 || true
          fi
      fi
  fi
  cd "${DIR_NAME}";
  counter=$((counter + 1))
done

. git_patch.sh

#
