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
is_xpack="false"
is_xpack_dev_tools="false"

while [ $# -gt 0 ]
do
  case "$1" in
    --init )
      do_init="true"
      shift
      ;;

    --xpack )
      is_xpack="true"
      shift
      ;;

    --xpack-dev-tools )
      is_xpack_dev_tools="true"
      shift
      ;;

    * )
      echo "Unsupported option $1"
      shift
  esac
done

export is_xpack
export is_xpack_dev_tools

# -----------------------------------------------------------------------------

# The script is invoked via the following npm script:
# "generate-commons": "bash node_modules/@xpack/npm-packages-helper/scripts/generate-commons.sh"

project_folder_path="$(dirname $(dirname $(dirname $(dirname "${script_folder_path}"))))"
helper_folder_path="$(dirname "${script_folder_path}")"

if [ -d "${project_folder_path}/website" ]
then
  website_folder_path="${project_folder_path}/website"
else
  website_folder_path=""
fi

export project_folder_path
export helper_folder_path
export website_folder_path

source "${script_folder_path}/compute-context.sh"

tmp_file="$(mktemp -t top_commons.XXXXX)"

# xargs stops only for exit code 255.
function trap_handler()
{
  local message="$1"
  shift
  local line_number="$1"
  shift
  local exit_code="$1"
  shift

  echo "FAIL ${message}, line: ${line_number}, exit: ${exit_code}"

  rm -rf "${tmp_file}"

  exit 255
}

# Used to enforce an exit code of 255, required by xargs.
trap 'trap_handler ${script_name} $LINENO $?; return 255' ERR

# -----------------------------------------------------------------------------

function merge_json()
{
  from_file="$1" # liquid source
  to_file="$2" # destination

  liquidjs --context "${xpack_context}" --template "@${from_file}" --output "${tmp_file}"

  # json -f "${tmp_file}"

  mkdir -pv "$(dirname "${to_file}")"

  # https://trentm.com/json
  cat "${to_file}" "${tmp_file}" | json --deep-merge >"${to_file}.new"
  rm "${to_file}"
  mv -v "${to_file}.new" "${to_file}"
}

function substitute()
{
  from_file="$1" # liquid source
  to_file="$2" # destination

  mkdir -pv "$(dirname "${to_file}")"

  echo "liquidjs -> ${to_file}"
  liquidjs --context "${xpack_context}" --template "@${from_file}" --output "${to_file}"
}

# -----------------------------------------------------------------------------

if [ "${is_xpack}" == "true" ]
then

  echo
  echo "Generating top package.json..."

  merge_json "${helper_folder_path}/templates/_xpack/package-liquid.json" "${project_folder_path}/package.json"

  echo
  echo "Generating workflows..."

  mkdir -pv "${project_folder_path}/.github/workflows/"

  if [ "${xpack_is_web_deploy_only}" != "true" ] && [ "${xpack_skip_tests}" != "true" ]
  then
    substitute "${helper_folder_path}/templates/_xpack/.github/workflows/test-ci-liquid.yml" "${project_folder_path}/.github/workflows/test-ci.yml"
  fi

  if [ "${xpack_is_web_deploy_only}" == "true" ]
  then
    substitute "${helper_folder_path}/templates/_xpack/.github/workflows/publish-github-pages-from-remote-liquid.yml" "${project_folder_path}/.github/workflows/publish-github-pages-from-remote.yml"
  else
    substitute "${helper_folder_path}/templates/_xpack/.github/workflows/publish-github-pages-liquid.yml" "${project_folder_path}/.github/workflows/publish-github-pages.yml"
  fi

  if [ "${xpack_npm_package_homepage}" != "${xpack_npm_package_homepage_preview}" ]
  then
    substitute "${helper_folder_path}/templates/_xpack/.github/workflows/trigger-publish-github-pages-liquid.yml" "${project_folder_path}/.github/workflows/trigger-publish-github-pages.yml"
  fi

  cp -v "${helper_folder_path}/templates/_xpack/.github/FUNDING.yml" "${project_folder_path}/.github"

  # echo
  # echo "Generating tests package.json..."

  # merge_json "${helper_folder_path}/templates/_xpack/tests/package-liquid.json" "${project_folder_path}/tests/package.json"

  echo
  echo "Copying other..."

  cp -v "${helper_folder_path}/templates/_xpack/.gitignore" "${project_folder_path}"

  if [ "${xpack_is_not_npm_module}" != "true" ]
  then

    cp -v "${helper_folder_path}/templates/_xpack/.npmignore" "${project_folder_path}"

    if [ "${xpack_is_typescript}" == "true" ]
    then
      cp -v "${helper_folder_path}/templates/_xpack/tsconfig.json" "${project_folder_path}"
      cp -v "${helper_folder_path}/templates/_xpack/tsconfig-common.json" "${project_folder_path}"
    fi

  fi

elif [ "${is_xpack}" == "true" ]
then
  :
else
  echo "Unsupported configuration..."
  exit 1
fi

# -----------------------------------------------------------------------------

rm -rf "${tmp_file}"

echo
echo "${script_name} done"

# Completed successfully.
exit 0
