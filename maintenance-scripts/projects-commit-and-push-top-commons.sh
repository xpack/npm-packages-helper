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

script_name="$(basename "${script_path}")"

script_folder_path="$(dirname "${script_path}")"
script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

# set -x
skip_website="false"
# skip_website="true"

while [ $# -gt 0 ]
do
  case "$1" in
    --skip-website )
      skip_website="true"
      shift
      ;;

    * )
      echo "Unsupported option $1"
      shift
  esac
done

export skip_website

# -----------------------------------------------------------------------------

# Runs as
# .../xpack.github/packages/npm-packages-helper.git/maintenance-scripts/projects-commit-and-push-top-commons.sh
packages_folder_path="$(dirname $(dirname "${script_folder_path}"))"
www_folder_path="$(dirname "${packages_folder_path}")/www"

for f in "${packages_folder_path}"/*/.git "${www_folder_path}"/*/.git
do
  (
    cd "${f}/.."

    echo
    pwd

    # set -x

    name="$(basename "$(pwd)")"

    xconfig="$(json -f "package.json" -o json-0 xConfig)"
    if [ -z "${xconfig}" ]
    then
      echo "${name} has no xConfig..."
      continue
    fi

    has_empty_master="$(echo "${xconfig}" | json hasEmptyMaster)"

    if [ "${has_empty_master}" == "true" ]
    then
      if git branch | grep webpreview >/dev/null
      then
        development_branch="webpreview"
      else
        development_branch="website"
      fi
    else
      if git branch | grep development >/dev/null
      then
        development_branch="development"
      else
        development_branch="master"
      fi
    fi

    git checkout "${development_branch}"

    git add .github .gitignore README*.md package*.json
    if [ -f .npmignore ]
    then
      git add .npmignore
    fi
    if [ -f tsconfig.json ]
    then
      git add tsconfig*.json
    fi

    git commit -m "re-generate commons" || true

    git push
  )
done

echo
echo "${script_name} done"
exit 0

# -----------------------------------------------------------------------------
