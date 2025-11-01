#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Identify the script location, to reach, for example, the helper scripts.

script_path="$0"
if [[ "${script_path}" != /* ]]
then
  # Make relative path absolute.
  script_path="$(pwd)/$0"
fi

export script_path
export script_name="$(basename "${script_path}")"

export script_folder_path="$(dirname "${script_path}")"
export script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

# set -x

argv="$@"

helper_folder_path="$(dirname ${script_folder_path})"

source "${helper_folder_path}/maintenance-scripts/scripts-helper-source.sh"

# Parse --init, --dry-run, --xpack, --xpack-dev-tools
# and leave variables in the environment.
parse_options "$@"

# -----------------------------------------------------------------------------

# $1 = *.git
function generate_top_commons()
{
  (
    local from_folder_path="$(dirname "${1}")"
    local git_folder_name="$(basename "${from_folder_path}")"

    if [ -f "${stamps_folder_path}/${git_folder_name}" ]
    then
      echo "${git_folder_name} already generated..."
      return 0
    fi

    cd "${from_folder_path}"

    echo
    echo "----------------------------------------------------------------------------"
    pwd

    # set -x

    name="$(basename "$(pwd)")"

    top_config="$(json -f "package.json" -o json-0 topConfig)"
    if [ -z "${top_config}" ]
    then
      echo "${name} has no topConfig..."
      return
    fi

    has_empty_master="$(echo "${top_config}" | json hasEmptyMaster)"

    if [ "${has_empty_master}" == "true" ]
    then
      if git branch | grep webpreview >/dev/null
      then
        development_branch="webpreview"
      else
        development_branch="website"
      fi
    else
      if git branch | grep xpack-development >/dev/null
      then
        development_branch="xpack-development"
      elif git branch | grep development >/dev/null
      then
        development_branch="development"
      else
        development_branch="master"
      fi
    fi

    run_verbose git checkout "${development_branch}"

    run_verbose npm run npm-install
    run_verbose npm run npm-link-helpers
    run_verbose npm run generate-top-commons

    run_verbose npm run deep-clean
    run_verbose npm run npm-install
    run_verbose npm run npm-link-helpers

    run_verbose mkdir -pv "${stamps_folder_path}"
    run_verbose touch "${stamps_folder_path}/${git_folder_name}"
  )
}

# -----------------------------------------------------------------------------

# Runs as
# .../xpack.github/packages/npm-packages-helper.git/maintenance-scripts/projects-generate-top-commons.sh

my_projects_folder_path="$(dirname $(dirname $(dirname $(dirname "${script_folder_path}"))))"
stamps_folder_name="$(echo "${script_name}" | sed -e 's|\.sh$||')"

if [ "${is_xpack}" == "true" ]
then
  xpack_github_folder_path="${my_projects_folder_path}/xpack.github"
  export stamps_folder_path="${xpack_github_folder_path}/stamps/${stamps_folder_name}"
  export packages_folder_path="${xpack_github_folder_path}/packages"
  export www_folder_path="${xpack_github_folder_path}/www"
  
  if [ "${do_restart}" == "true" ]
  then
    echo "Clearing stamps folder path: '${stamps_folder_path}'..."
    rm -rf "${stamps_folder_path}"
  else
    echo "Stamps folder path: '${stamps_folder_path}'..."
  fi
  echo

  for file_path in "${packages_folder_path}"/*/.git "${www_folder_path}"/*/.git
  do
    generate_top_commons "${file_path}"
  done
elif [ "${is_xpack_dev_tools}" == "true" ]
then
  xpack_dev_tools_github_folder_path="${my_projects_folder_path}/xpack-dev-tools.github"
  export stamps_folder_path="${xpack_dev_tools_github_folder_path}/stamps/${stamps_folder_name}"
  export xpacks_folder_path="${xpack_dev_tools_github_folder_path}/xPacks"
  export www_folder_path="${xpack_dev_tools_github_folder_path}/www"

  if [ "${do_restart}" == "true" ]
  then
    echo "Clearing stamps folder path: '${stamps_folder_path}'..."
    rm -rf "${stamps_folder_path}"
  else
    echo "Stamps folder path: '${stamps_folder_path}'..."
  fi
  echo

  for file_path in "${xpacks_folder_path}"/*/.git "${www_folder_path}"/*/.git "${xpack_dev_tools_github_folder_path}/xpack-build-box.git/.git"
  do
    generate_top_commons "${file_path}"
  done
elif [ "${is_micro_os_plus}" == "true" ]
then
  echo TODO
else
  echo "Unsupported configuration..."
  exit 1
fi

echo
echo "'${script_name} ${argv}' done"

exit 0

# -----------------------------------------------------------------------------
