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

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

quiet=false
current_dir="$(pwd)"

required_helper=('git' 'grep' 'find' 'xargs' 'pwd' 'wc')

[ -z ${verbose} ] && verbose=0

patch=0

show_help() {
cat << EOF
Usage: ${0##*/} [-v] [-d DIRECTORY]

Update all local GIT working copies or clone GIT repositories if the GIT
repository is defined in >REPO_NAMES< but not cloned to
>DIR_NAME</local directory.

Use >`pwd`< if >DIR_NAME< environment variable and the directory argument
are empty.

    -h|-?         display this help and exit.
    -d DIRECTORY  directory contains the repositories list and branch name file ('${current_dir}').
    -p            execute patch script after update
    -v            verbose mode. Can be used multiple times for increased verbosity.
EOF
}

check_required_helper() {
  helper=("$@")
  for executable in "${helper[@]}";
  do
    # @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
    if hash $executable 2>/dev/null
      then
        [[ $verbose -gt 0 ]] && echo "found required executable: $executable"
      else
        echo "the executable: $executable is required!"
        return 1
    fi
  done
  return 0
}
### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "d:pvh?" opt;
do
  case "$opt" in
    d)  DIR_NAME="$OPTARG"
    ;;
    h|\?)
      show_help
      exit 0
    ;;
    p)  patch=1
    ;;
    v)  verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))
REPO_SERVER_URL_NAMES=(${1})

[ -z "${DIR_NAME}" ] && DIR_NAME="${current_dir}" || true

[ -z "${BRANCH_NAME}" ] && . git_branch_name.sh
[ -z "${BRANCH_NAME}" ] && echo "Not empty >BRANCH_NAME< expected" && exit 1 || true

[ 0 = ${#REPO_SERVER_URL_NAMES[@]} ] && . git_repositories.sh
[ 0 = ${#REPO_SERVER_URL_NAMES[@]} ] && echo "Not empty >REPO_NAMES< expected" && exit 1 || true

cd "${DIR_NAME}"

# update or clone GIT repositories with specific branch
counter=1
size=${#REPO_SERVER_URL_NAMES[@]}
for repo_server_url in "${REPO_SERVER_URL_NAMES[@]}"
do
  repo=(${repo_server_url})
  repo_name="${repo[0]}" # only the repo name
  repo_url="${repo[1]}" # the repo url
  # configure default repo url if empty
  [ -z "${repo_url}" ] && repo_url="${DEFAULT_GIT_SERVER_URL}/${repo_name}"
  # normalize repo name like: thirdparty/org.apche into: thirdparty_org.apache
  local_dir=${repo_name//[^a-zA-Z0-9_\.]/_}
  echo ''

  # check already cloned repo
  if [ ! -d "${local_dir}/.git" ]
    then
      echo "[${counter}/${size}] clone: ${repo_name} to: ${DIR_NAME}/${local_dir}"
      cd "${DIR_NAME}";
      if [ -d "${local_dir}" ]
        then
          cd "${local_dir}"
          local_dir='.'
      fi
      git clone ${repo_url} ${local_dir} || true
  fi
  pushd "${local_dir}" 2>&1>/dev/null

  # get actual repo state and switch to branch if possible
  echo "[${counter}/${size}] update: ${repo_name} and switch to branch: ${BRANCH_NAME}"
  git fetch --all --prune;
  if [ "" != "$(git branch --remote --list origin/${BRANCH_NAME})" ]
    then
    git checkout -B ${BRANCH_NAME} -t -f origin/${BRANCH_NAME};
    git fetch;
    git rebase origin/${BRANCH_NAME};
  fi

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
      # check if git server is a gerrit server
      ssh_cmd="${ssh_cmd} ${server_name} gerrit version"
      if `${ssh_cmd} > /dev/null 2>&1`;
        then
          git_dir=$(git rev-parse --git-dir)
          # check and configure Change-Id handling
          if [ "true" != "`git config --local --bool --get gerrit.createchangeid`" ]
            then
              git config --add "gerrit.createchangeid" "true"
          fi
          # check and configure branch refspecs
          if [ "HEAD:refs/for/${BRANCH_NAME}" != "`git config --local --get remote.origin.push`" ]
            then
              git config --add "remote.origin.push" "HEAD:refs/for/${BRANCH_NAME}"
          fi
          # check and download gerrit commit-msg hook
          if [ ! -f "${git_dir}/hooks/commit-msg" ]
            then
              # TODO: maybe check remote gerrit version to avoid download from
              # gerrit-review.googlesource.com
              if [ "#" != "`git config --get core.commentchar`" ]
                then
                  # download commit-msg hook archive to temp file
                  tmp_file_name="$(tempfile).zip"
                  wget -q -nv -O ${tmp_file_name} \
                    https://gerrit-review.googlesource.com/cat/58839,2,gerrit-server/src/main/resources/com/google/gerrit/server/tools/root/hooks/commit-msg%5E0
                  # extract commit-msg file from archive and delete archive
                  file_name="$(unzip -M ${tmp_file_name} -d /tmp | grep commit-msg | cut -d':' -f2 | tr -d [:blank:] && rm ${tmp_file_name} )"
                  # replace content of .git/hooks/commit-msg with content of
                  # downloaded commit-msg file and remove downloaded commit-msg
                  [ -f "${file_name}" ] && cat ${file_name} > ${git_dir}/hooks/commit-msg && rm ${file_name}
              else
                # download commit-msg if available
                scp_cmd="${scp_cmd} ${server_name}:hooks/commit-msg ${git_dir}/hooks/"
                ${scp_cmd} > /dev/null 2>&1 || true
              fi
          fi
      fi
  fi
  popd 2>&1 > /dev/null;
  counter=$((counter + 1))
done

cd "${current_dir}"

[ 0 != "${patch}" ] && . git_patch.sh || true

#
