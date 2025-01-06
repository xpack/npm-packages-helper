#!/usr/bin/env bash

# -----------------------------------------------------------------------------
#
# This file is part of the xPack project (http://xpack.github.io).
# Copyright (c) 2024 Liviu Ionescu.  All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
#
# If a copy of the license was not distributed with this file, it can
# be obtained from https://opensource.org/licenses/mit/.
#
# -----------------------------------------------------------------------------

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

do_init="false"
do_dry_run="false"
is_xpack="false"
is_xpack_dev_tools="false"
prefix=""

while [ $# -gt 0 ]
do
  case "$1" in
    --init )
      do_init="true"
      shift
      ;;

    --dry-run )
      do_dry_run="true"
      shift
      ;;

    --xpack )
      is_xpack="true"
      prefix="_xpack"
      shift
      ;;

    --xpack-dev-tools )
      is_xpack_dev_tools="true"
      prefix="_xpack-dev-tools"
      shift
      ;;

    * )
      echo "Unsupported option $1"
      shift
  esac
done

export do_init
export do_dry_run
export is_xpack
export is_xpack_dev_tools
export prefix

# -----------------------------------------------------------------------------

helper_folder_path="$(dirname "${script_folder_path}")"

if [ "${is_xpack}" == "true" ]
then
  # The script is invoked via the following top npm script:
  # "generate-top-commons": "bash node_modules/@xpack/npm-packages-helper/scripts/generate-top-commons.sh"
  project_folder_path="$(dirname $(dirname $(dirname $(dirname "${script_folder_path}"))))"
elif [ "${is_xpack_dev_tools}" == "true" ]
then
  # The script is invoked via the following build-scripts xpm action:
  # "generate-top-commons": "bash node_modules/@xpack/npm-packages-helper/scripts/generate-top-commons.sh"
  project_folder_path="$(dirname $(dirname $(dirname $(dirname $(dirname "${script_folder_path}")))))"
else
  echo "Unsupported configuration..."
  exit 1
fi

if [ -d "${project_folder_path}/website" ]
then
  website_folder_path="${project_folder_path}/website"
else
  website_folder_path=""
fi

export project_folder_path
export helper_folder_path
export website_folder_path

# Process package.json files and leave results in environment variables.
source "${script_folder_path}/compute-context.sh"

# -----------------------------------------------------------------------------

if [ "${do_dry_run}" == "true" ]
then
  echo
  echo "Dry run!"
  echo
fi

# Script passed to find | xargs to process template files.
tmp_script_file="$(mktemp -t script.XXXXX)"

# Note: __EOF__ is quoted to prevent substitutions.
cat <<'__EOF__' >"${tmp_script_file}"

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

tmp_file_path="$(mktemp -t top_commons.XXXXX)"

# xargs stops only for exit code 255.
function trap_handler()
{
  local message="$1"
  shift
  local line_number="$1"
  shift
  local exit_code="$1"
  shift

  echo "FAIL ${message} line: ${line_number} exit: ${exit_code}"

  rm -rfv "${tmp_file_path}"
  exit 255
}

function substitute()
{
  local from_relative_file_path="$1" # liquid source
  local to_relative_file_path="$2" # destination
  # $3 - destination absolute folder path

  local to_absolute_file_path="${3}/${to_relative_file_path}"

  echo "liquidjs -> ${to_relative_file_path}"

  if [ "${do_dry_run}" != "true" ]
  then
    liquidjs --context "${xpack_context}" --template "@${from_relative_file_path}" --output "${to_absolute_file_path}.new"

    rm -f "${to_absolute_file_path}"
    mv "${to_absolute_file_path}.new" "${to_absolute_file_path}"
  fi
}

function substitute_and_merge()
{
  local from_relative_file_path="$1" # liquid source
  local to_absolute_file_path="$2" # destination
  # $3 - destination absolute folder path

  local to_absolute_file_path="${3}/${to_relative_file_path}"

  echo "liquidjs | merge -> ${to_relative_file_path}"

  if [ "${do_dry_run}" != "true" ]
  then
    liquidjs --context "${xpack_context}" --template "@${from_relative_file_path}" --output "${tmp_file_path}"

    # json -f "${tmp_file_path}"

    # https://trentm.com/json
    cat "${to_absolute_file_path}" "${tmp_file_path}" | json --deep-merge >"${to_absolute_file_path}.new"

    rm -f "${to_absolute_file_path}"
    mv "${to_absolute_file_path}.new" "${to_absolute_file_path}"
  fi
}

# -----------------------------------------------------------------------------

# Runs in the source folder.
# $1 = relative file path to source
# $2 = absolute folder path to destination

# echo $@
# set -x

# The source file path.
from_relative_file_path="$(echo "${1}" | sed -e 's|^\.\/||')"

file_prefix="$(echo "${from_relative_file_path}" | sed -e 's|/.*||')"
if [ "${file_prefix}" == "_xpack" ] ||
   [ "${file_prefix}" == "_xpack-dev-tools" ]
then
  if [ "${file_prefix}" != "${prefix}" ]
  then
    exit 0
  fi

  to_relative_file_path="$(echo "${from_relative_file_path}" | sed -e 's|^_xpack/||' -e 's|^_xpack-dev-tools/||' -e 's|-merge-liquid||' -e 's|-liquid||')"
else
  to_relative_file_path="$(echo "${from_relative_file_path}" | sed -e 's|-merge-liquid||' -e 's|-liquid||')"
fi

# The destination file path.
to_absolute_file_path="${2}/${to_relative_file_path}"

# Used to enforce an exit code of 255, required by xargs.
trap 'trap_handler ${from_relative_file_path} $LINENO $?; return 255' ERR

# -----------------------------------------------------------------------------

# Superfluous, `find -type f` should not allow this.
if [ ! -f "${from_relative_file_path}" ]
then
  echo "${from_relative_file_path} not a file"
  exit 1
fi

if [ "$(basename "${from_relative_file_path}")" == ".DS_Store" ]
then
  echo "${from_relative_file_path} ignored" # Skip macOS specifics.
  exit 0
fi

# -----------------------------------------------------------------------------

# Destination relative file paths to skip.
skip_pages_array=()

if [ "${is_xpack}" == "true" ]
then
  :
elif [ "${is_xpack_dev_tools}" == "true" ]
then
  :
fi

if [ "${xpack_is_typescript}" != "true" ]
then
  skip_pages_array+=(\
    "tsconfig-common.json" \
    "tsconfig.json" \
  )
fi

if [ "${xpack_skip_tests}" == "true" ]
then
  skip_pages_array+=(\
    ".github/workflows/test-ci.yml" \
  )
fi

if [ "${xpack_is_web_deploy_only}" != "true" ]
then
  skip_pages_array+=(\
    ".github/workflows/publish-github-pages-from-remote.yml" \
  )
fi

if [ "${xpack_has_trigger_publish}" != "true" ]
then
  skip_pages_array+=(\
    ".github/workflows/trigger-publish-github-pages.yml" \
  )
fi

if [ "${xpack_has_trigger_publish_preview}" != "true" ]
then
  skip_pages_array+=(\
    ".github/workflows/trigger-publish-github-pages-preview.yml" \
  )
fi

if [ "${xpack_is_not_npm_module}" == "true" ]
then
  skip_pages_array+=(\
    ".npmignore" \
  )
fi

set +o nounset # Do not exit if variable not set.

# echo "skip_pages_array=${skip_pages_array[@]}"
# echo "to_relative_path=${to_relative_path}"

if [[ ${skip_pages_array[@]} =~ "${to_relative_file_path}" ]]
then
  echo "skipped: ${from_relative_file_path}"
  rm -f "${tmp_file_path}"
  exit 0
fi

set -o nounset # Exit if variable not set.

# -----------------------------------------------------------------------------

if [ -f "${to_absolute_file_path}" ]
then
  # Be sure destination is writeable.
  chmod -f +w "${to_absolute_file_path}"
fi

# -----------------------------------------------------------------------------

mkdir -p "$(dirname ${to_absolute_file_path})"

if [[ "$(basename "${from_relative_file_path}")" =~ .*-merge-liquid.* ]]
then
  substitute_and_merge "${from_relative_file_path}" "${to_relative_file_path}" "${2}"
elif [[ "$(basename "${from_relative_file_path}")" =~ .*-liquid.* ]]
then
  substitute "${from_relative_file_path}" "${to_relative_file_path}"  "${2}"
else
  echo "cp -> ${to_relative_file_path}"
  if [ "${do_dry_run}" != "true" ]
  then
    cp "${from_relative_file_path}" "${to_absolute_file_path}"
  fi
fi

if [ "${do_dry_run}" != "true" ]
then
  # Except package.json which may need frequent updates,
  # make everything else read only.
  if [ "$(basename "${to_absolute_file_path}")" != "package.json" ]
  then
    chmod -w "${to_absolute_file_path}"
  fi
else
  if [ ! -f "${to_absolute_file_path}" ]
  then
    echo ">>>> ${to_relative_file_path} not present >>>>"
  fi
fi

rm -rf "${tmp_file_path}"
exit 0

__EOF__

# -----------------------------------------------------------------------------

cd "${helper_folder_path}/templates"

echo
echo "Processing templates from $(pwd)..."
echo

# Main pass to copy/generate common files.
find . -type f -print0 | sort -zn | \
  xargs -0 -I '{}' bash "${tmp_script_file}" '{}' "${project_folder_path}"

# -----------------------------------------------------------------------------

rm -rf "${tmp_script_file}"

echo
echo "${script_name} done"

# Completed successfully.
exit 0
