#!/bin/bash
#
# Update all local GIT working copies or clone GIT repositories
# if the GIT repository is defined in REPO_NAMES but not cloned to
# DIR_NAME/local directory.
#
# Download hooks/commit-msg from remote server if available and
# install into local .git/hooks/.
#
# @use: DEFAULT_GIT_SERVER_URL
# @modify: DIR_NAME fill with pwd if empty
# @modify: BRANCH_NAME breaks if empty
# @modify: REPO_SERVER_URL_NAMES breaks if empty

# activate job monitoring
# @see: http://www.linuxforums.org/forum/programming-scripting/139939-fg-no-job-control-script.html
set -m
# set -x

# missing tolls on MacOS X
# mktemp / tempfile
# curl / wget
required_helper=('hash' 'date' 'git' 'mktemp' 'cat' 'grep' 'cut' 'sed' 'curl' 'ssh' 'readlink')

quiet=false
gerrit_automatic_configuration=true
current_dir="$(pwd)"

tempfile_cmd="tempfile "
download_cmd="wget -q -nv -O "

git_cmd="git --no-pager "
git_checkout_cmd="${git_cmd} checkout "
git_fetch_cmd="${git_cmd} fetch "
git_clone_cmd="${git_cmd} clone "
git_rebase_cmd="${git_cmd} rebase "
git_stash_save_cmd="${git_cmd} stash save "
git_config_cmd="${git_cmd} config "

[ -z ${verbose} ] && verbose=0

patch=0

default="default"
default_include_gitconfig_file_name_prefix="~/.gitconfig_"
include_gitconfig_file=""

# Print usage information on prompt.
#
# @param: none
#
_show_help() {
cat << EOF
Usage: ${0##*/} [-h?gpqv] [-d DIRECTORY] [-i [FILENAME | ${default}]]

Update all local GIT working copies or clone GIT repositories if the GIT
repository is defined in >REPO_NAMES< but not cloned to >DIR_NAME</local directory.

    -h|-?                      display this help and exit.
    -d DIRECTORY               directory contains the repositories list and branch name file ('${current_dir}').
    -i FILENAME or "${default}"   insert include statement in GIT repository configuration ("${default}" use '${default_include_gitconfig_file}<git server name>')
    -g                         disable automatic "gerrit" configuration
    -p                         execute patch script after update
    -q                         quiet modus. View only summary of changed files and pending commits for repository.
    -v                         verbose mode. Can be used multiple times for increased verbosity.
EOF
}

# Cheks the required tools and commands.
#
# @param #1: array of tool/command name
# @returns: 1 if executable was not found, otherwise 0
#
_check_required_helper() {
   helper=($@)
   for executable in "${helper[@]}";
   do
     # @see: http://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
     if hash ${executable} 2>/dev/null
     then
       [ 0 -lt ${verbose} ] && echo "found required executable: ${executable}"
     else
       echo "the executable: ${executable} is required!"
       return 1
     fi
   done
   return 0
}

# Append 'quiet' mode command line switch on git commands.
#
# @use: ${quiet}
# @modify: ${git_checkout_cmd}, ${git_fetch_cmd}, ${git_clone_cmd},
#          ${git_rebase_cmd}, ${git_stash_save_cmd}
# @param: none
# @returns: none
#
_config_quiet_mode_cmds() {
  if [ true == ${quiet} ]
    then
      git_checkout_cmd="${git_checkout_cmd} -q "
      git_fetch_cmd="${git_fetch_cmd} -q "
      git_clone_cmd="${git_clone_cmd} -q "
      git_rebase_cmd="${git_rebase_cmd} -q "
      git_stash_save_cmd="${git_stash_save_cmd} -q "
  fi
}

# Append 'verbose' mode command line switch on git commands.
#
# @use: ${verbose}
# @modify: ${git_fetch_cmd}, ${git_clone_cmd}, ${git_rebase_cmd}
# @param: none
# @returns: none
#
_config_verbose_mode_cmds() {
  if [ 0 -lt ${verbose} ]
    then
      [ 2 -lt ${verbose} ] && git_fetch_cmd="${git_fetch_cmd} -v "
      git_clone_cmd="${git_clone_cmd} -v "
      git_rebase_cmd="${git_rebase_cmd} -v "
  fi
}

# Clone the repository into the local dir.
#
# @use: ${quiet}, ${git_clone_cmd}
# @param #1: repository url
# @param #2: localdirectory
# @param #3: log prefix (optional)
# returns: exit code of ${git_clone_cmd}
#
_clone_git_repository() {
  repo_url="${1}"
  local_dir="${2}"
  log_prefix="${3}"

  if [ ! -d "${local_dir}/.git" ]
    then
      echo "${log_prefix} clone: ${repo_url} to: ${DIR_NAME}/${local_dir}"
      if [ -d "${local_dir}" ]
        then
          pushd "${local_dir}" 2>&1>/dev/null
          [ true == ${quiet} ] && script --quiet --append --return --command "${git_clone_cmd} ${repo_url} ." /dev/null 2>&1 > /dev/null || ${git_clone_cmd} ${repo_url} .
          popd 2>&1 > /dev/null
        else
          [ true == ${quiet} ] && script --quiet --append --return --command "${git_clone_cmd} ${repo_url} ${local_dir}" /dev/null 2>&1 > /dev/null || ${git_clone_cmd} ${repo_url} ${local_dir}
      fi
  fi
  return $?
 }

# Fetch the new state of git repository and switch to branch.
#
# @use: ${BRANCH_NAME}, ${git_cmd}, ${git_stash_save_cmd}, ${git_fetch_cmd}, ${git_checkout_cmd},
#       ${git_rebase_cmd}
# @param #1: repository name
# @param #2: logging prefix (optional)
# @returns: exit code(s) of git commands
#
_git_fetch_and_switch_to_branch() {
  repo_name="${1}"
  log_prefix="${2}"

  echo "${log_prefix} update: ${repo_name} and switch to branch: ${BRANCH_NAME}"
  pending_changes=$(${git_cmd} status -s --porcelain | wc -l);
  [ 0 -ne ${pending_changes} ] && ${git_stash_save_cmd} --keep-index --include-untracked "stashed by ${0##*/} ($(date +%Y-%m-%dT%H:%M:%S))"
  [ 0 -lt ${verbose} ] && echo " #${pending_changes} (un-)tracked changes stashed"
  ${git_fetch_cmd}  --all --prune
  [ 0 != $? ] && return $? || true
  if [ ! -z "$(${git_cmd} branch --remote --list origin/${BRANCH_NAME})" ]
    then
      ${git_checkout_cmd} -B ${BRANCH_NAME} -t -f origin/${BRANCH_NAME};
      [ 0 != $? ] && return $? || true
      ${git_fetch_cmd};
      [ 0 != $? ] && return $? || true
      ${git_rebase_cmd} origin/${BRANCH_NAME};
      [ 0 != $? ] && return $? || true
  fi
  return $?
}

# Set GIT configuration 'include.path' with passed (param #1) file.
# Resolve 'default' to default name schema: "${default_include_gitconfig_file_name_prefix}${server_name}" like
# e.g.: ~/.gitconfig_my.server.tld
#
# @use ${default_include_gitconfig_file_name_prefix}, ${git_config_cmd}, ${default}, ${verbose}
# @param #1: file path and name for include file
# @param #2: repository name
# @param #3: logging prefix (optional)
#
  _git_configure_repository() {
  include_file="${1}"
  repo_name="${2}"
  log_prefix="${3}"

  [ "" == "${include_file}" ] && return || true

  [ 1 -lt ${verbose} ] && echo "${log_prefix} configure: ${repo_name}"

  # build the 'default' include file name: "${default_include_gitconfig_file_name_prefix}${server_name}"
  # e.g.: ~/.gitconfig_my.server.tld
  if [ "${default}" == "${include_file}" ]
    then
      # !!! duplicate code @see: _automatic_gerrit_configuration !!!
      git_remote_origin_url=$(${git_config_cmd} --local --get "remote.origin.url")
      # remove schema/protocol - all before '//'
      # identity@my.server.tld:29418/repo.name
      git_remote_origin_host_port_path="${git_remote_origin_url##*\/\/}"
      # extract identity, server name and port - all before first '/'
      # identity@my.server.tld:29418
      git_remote_origin_host_port="${git_remote_origin_host_port_path%%\/*}"
      # get server name and identity - extract all before the last ':'
      # identity@my.server.tld
      git_remote_origin_host="${git_remote_origin_host_port%:*}"
      # remove identity - all before '@'
      # my.server.tld
      server_name="${git_remote_origin_host##*@}"
      include_file="${default_include_gitconfig_file_name_prefix}${server_name}"
      [ 1 -lt ${verbose} ] && echo " Default include file '${include_file}' will be used."
  fi
  if [ ! -f $(readlink -f ${include_file}) ]
    then
      [ 1 -lt ${verbose} ] && echo " Include file '${include_file}' NOT found."
      if [ "${include_file}" == "$(${git_config_cmd} --local --get include.path)" ]
        then
          [ 1 -lt ${verbose} ] && echo " Remove unknown file '${include_file}' from GIT configuration."
          ${git_config_cmd} --local --unset include.path
      fi
      return
  fi
  [ 1 -lt ${verbose} ] && echo " Include file '${include_file}' in local GIT configuration."
  ${git_config_cmd} --local "include.path" "${include_file}"
}

# Configure gerrit environment on git repository.
#
# @use: ${gerrit_automatic_configuration}, ${git_config_cmd}, ${git_cmd}, ${BRANCH_NAME}, ${quiet}, ${verbose}
# @param #1: repository name
# @param #2: logging prefix (optional)
#
_automatic_gerrit_configuration() {
  [ false == ${gerrit_automatic_configuration} ] && return 0 || true
  repo_name="${1}"
  log_prefix="${2}"

  git_remote_origin_url=$(${git_config_cmd} --local --get "remote.origin.url")

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
          [ false == ${quiet} ] && echo "${log_prefix} check gerrit configuration: ${repo_name}"
          git_dir=$(${git_cmd} rev-parse --git-dir)
          # check and configure Change-Id handling
          if [ "true" != "$(${git_config_cmd} --local --bool --get gerrit.createchangeid)" ]
            then
              [ 0 -lt ${verbose} ] && echo "add config: 'gerrit.createchangeid' 'true'"
              ${git_config_cmd} --add "gerrit.createchangeid" "true"
          fi
          # check and configure branch refspecs
          if [ "HEAD:refs/for/${BRANCH_NAME}" != "$(${git_config_cmd} --local --get remote.origin.push)" ]
            then
              [ 0 -lt ${verbose} ] && echo "add config: 'remote.origin.push' 'HEAD:refs/for/${BRANCH_NAME}'"
              ${git_config_cmd} --add "remote.origin.push" "HEAD:refs/for/${BRANCH_NAME}"
          fi
          # check and download gerrit commit-msg hook
          _gerrit_commit_msg_configuration "${scp_cmd}" "${git_dir}"
        else
          [ 0 -lt ${verbose} ] && echo "${log_prefix} ${repo_name} is not a gerrit managed repository."
      fi
  fi
}

# Configure commit-msg hook for gerrit.
#
# @use: ${verbose}, ${git_config_cmd}, 
# @param #1: scp command line
# @param #2: git directory
#
_gerrit_commit_msg_configuration() {
  scp_cmd="${1}"
  git_dir="${2}"

  if [ ! -f "${git_dir}/hooks/commit-msg" ]
    then
      [ 0 -lt ${verbose} ] && echo "configure 'commit-msg' hook"
      # TODO: maybe check remote gerrit version to avoid download from
      # gerrit-review.googlesource.com
      if [ "#" != "$(${git_config_cmd} --get core.commentchar)" ]
        then
          # download commit-msg hook archive to temp file
          template_url="https://gerrit-review.googlesource.com/cat/58839,2,gerrit-server/src/main/resources/com/google/gerrit/server/tools/root/hooks/commit-msg%5E0"
          [ 1 -lt ${verbose} ] && echo "download 'commit-msg' hook template from: ${template_url}"
          tmp_file_name="$(${tempfile_cmd}).zip"
          ${download_cmd} ${tmp_file_name} ${template_url}
          # extract commit-msg file from archive and delete archive
          file_name="$(unzip -M ${tmp_file_name} -d /tmp | grep commit-msg | cut -d':' -f2 | tr -d [:blank:] && rm ${tmp_file_name} )"
          # replace content of .git/hooks/commit-msg with content of
          # downloaded commit-msg file and remove downloaded commit-msg
          [ -f "${file_name}" ] && cat ${file_name} > ${git_dir}/hooks/commit-msg && rm ${file_name}
        else
          # download commit-msg if available
          template_url="${server_name}:hooks/commit-msg ${git_dir}/hooks/"
          [ 1 -lt ${verbose} ] && echo "download 'commit-msg' hook template from: ${template_url}"
          scp_cmd="${scp_cmd} ${template_url}"
          ${scp_cmd} > /dev/null 2>&1 || true
      fi
      # // set executable bit on commit hook
      chmod +x ${git_dir}/hooks/commit-msg
  fi
}
### CMD ARGS
# process command line arguments
# @see: http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash#192266
# @see: http://mywiki.wooledge.org/BashFAQ/035#getopts
OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "d:gi:pqvh?" opt;
do
  case "$opt" in
    d)  DIR_NAME="$OPTARG"
    ;;
    g)  gerrit_automatic_configuration=false
    ;;
    h|\?)
      _show_help
      exit 0
    ;;
    i)  [ "" == "$OPTARG" ] && include_gitconfig_file="${default}" || include_gitconfig_file="$OPTARG"
    ;;
    p)  patch=1
    ;;
    q)  quiet=true
    ;;
    v)  verbose=$((verbose + 1))
    ;;
  esac
done

shift $((OPTIND-1))
REPO_SERVER_URL_NAMES=(${1})

_check_required_helper "${required_helper[@]}"
[ 0 != $? ] && exit 1 || true

[ -z "${DIR_NAME}" ] && DIR_NAME="${current_dir}" || true

[ -z "${BRANCH_NAME}" ] && . git_branch_name.sh
[ -z "${BRANCH_NAME}" ] && echo "Not empty >BRANCH_NAME< expected" && exit 1 || true

[ 0 = ${#REPO_SERVER_URL_NAMES[@]} ] && . git_repositories.sh
[ 0 = ${#REPO_SERVER_URL_NAMES[@]} ] && echo "Not empty >REPO_NAMES< expected" && exit 1 || true

[ $(hash wget > /dev/null 2>&1) ] && true || download_cmd="curl -sSo "
[ $(hash tempfile > /dev/null 2>&1) ] && true || tempfile_cmd="mktemp tmp.XXXXXX "

# configure git commands
_config_quiet_mode_cmds
_config_verbose_mode_cmds

cd "${DIR_NAME}"

# update or clone GIT repositories with specific branch
counter=1
size=${#REPO_SERVER_URL_NAMES[@]}
for repo_server_url in "${REPO_SERVER_URL_NAMES[@]}"
do
  log_prefix="[${counter}/${size}]"
  repo=(${repo_server_url})
  repo_name="${repo[0]}" # only the repo name
  repo_url="${repo[1]}" # the repo url
  # configure default repo url if empty
  [ -z "${repo_url}" ] && repo_url="${DEFAULT_GIT_SERVER_URL}/${repo_name}"
  # normalize repo name like: thirdparty/org.apche into: thirdparty_org.apache
  local_dir=${repo_name//[^a-zA-Z0-9_\-\.]/_}
  [ false == $quiet ] && echo ''

  # check already cloned repo
  _clone_git_repository "${repo_url}" "${local_dir}" "${log_prefix}"
  [ 0 != $? ] && exit $? || true

  [ ! -d "$local_dir" ] && echo "local working copy: ${local_dir} not found." && exit 1 || true
  pushd "${local_dir}" 2>&1>/dev/null

  # get actual repo state and switch to branch if possible
  _git_fetch_and_switch_to_branch "${repo_name}" "${log_prefix}"
  [ 0 != $? ] && exit $? || true

  _git_configure_repository "${include_gitconfig_file}" "${repo_name}" "${log_prefix}"
  [ 0 != $? ] && exit $? || true

  [ false == ${gerrit_automatic_configuration} ] && popd 2>&1 > /dev/null && counter=$((counter + 1)) && continue

  _automatic_gerrit_configuration "${repo_name}" "${log_prefix}"

  popd 2>&1 > /dev/null;
  counter=$((counter + 1))
done

cd "${current_dir}"

[ 0 != "${patch}" ] && . git_patch.sh || true

#
