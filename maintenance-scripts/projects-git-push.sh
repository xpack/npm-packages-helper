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
function custom_action()
{
  (
    local from_folder_path="$(dirname "${1}")"

    cd "${from_folder_path}"

    echo
    echo "----------------------------------------------------------------------------"
    pwd

    # set -x

    name="$(basename "$(pwd)")"

    run_verbose git push
  )
}

# -----------------------------------------------------------------------------

# Runs as
# .../xpack.github/packages/npm-packages-helper.git/maintenance-scripts/projects-commit-and-push-top-commons.sh

my_projects_folder_path="$(dirname $(dirname $(dirname $(dirname "${script_folder_path}"))))"

if [ "${is_xpack}" == "true" ]
then
  xpack_github_folder_path="${my_projects_folder_path}/xpack.github"
  packages_folder_path="${xpack_github_folder_path}/packages"
  www_folder_path="${xpack_github_folder_path}/www"

  for file_path in "${packages_folder_path}"/*/.git "${www_folder_path}"/*/.git
  do
    custom_action "${file_path}"
  done
elif [ "${is_xpack_dev_tools}" == "true" ]
then
  xpack_dev_tools_github_folder_path="${my_projects_folder_path}/xpack-dev-tools.github"
  xpacks_folder_path="${xpack_dev_tools_github_folder_path}/xPacks"
  www_folder_path="${xpack_dev_tools_github_folder_path}/www"

  for file_path in "${xpacks_folder_path}"/*/.git "${www_folder_path}"/*/.git "${xpack_dev_tools_github_folder_path}/xpack-build-box.git/.git"
  do
    custom_action "${file_path}"
  done
else
  echo "Unsupported configuration..."
  exit 1
fi

echo
echo "'${script_name} ${argv}' done"

exit 0

# -----------------------------------------------------------------------------
