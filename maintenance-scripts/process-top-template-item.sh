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
# be obtained from https://opensource.org/licenses/mit.
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

export script_path
export script_name="$(basename "${script_path}")"

export script_folder_path="$(dirname "${script_path}")"
export script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

# set -x

source "${script_folder_path}/scripts-helper-source.sh"

# -----------------------------------------------------------------------------

# Runs in the source folder.
# $1 = relative file path to source, starts with `./`
# $2 = absolute folder path to destination

# echo
# echo "argv: $@"
# echo "pwd: $(pwd)"
# set -x

# -----------------------------------------------------------------------------

# If one of the selector paths is present, but not the right one, exit.
if check_if_should_ignore_path "$@"
then
  exit 0
fi

prepare_paths "$@"

# -----------------------------------------------------------------------------

tmp_file_path="$(mktemp -t top_commons.XXXXX)"

# Used to enforce an exit code of 255, required by xargs.
trap 'trap_handler ${from_relative_file_path} $LINENO $? ${tmp_file_path}; return 255' ERR

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
# Compute exclusions.

# Destination relative file paths to skip.
skip_pages_array=("BEGIN")

if [ "${is_xpack}" == "true" ]
then

  if [ "${xpack_is_typescript}" != "true" ]
  then
    skip_pages_array+=(\
      "tsconfig-common.json" \
      "tsconfig.json" \
    )
  fi

  if [ "${xpack_skip_ci_tests}" == "true" ] ||
    [ "${xpack_npm_package_version}" == "0.0.0" ]
  then
    skip_pages_array+=(\
      ".github/workflows/test-ci.yml" \
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

elif [ "${is_xpack_dev_tools}" == "true" ]
then
  platforms_with_commas=",${xpack_platforms},"
  if [ "${platforms_with_commas}" == ",all," ]
  then
    platforms_with_commas=",linux-x64,linux-arm64,linux-arm,darwin-x64,darwin-arm64,win32-x64,"
  fi

  if [ "${xpack_is_organization_web}" == "true" ] ||
     [ "${xpack_is_web_deploy_only}" == "true" ] ||
     [ "${xpack_npm_package_is_xpack}" != "true" ]
  then

    skip_pages_array+=(\
      ".github/workflows/body-github-pre-releases-test.md" \
      ".github/workflows/build-darwin-arm64.yml" \
      ".github/workflows/build-darwin-x64.yml" \
      ".github/workflows/build-linux-arm.yml" \
      ".github/workflows/build-linux-arm64.yml" \
      ".github/workflows/build-linux-x64.yml" \
      ".github/workflows/build.yml" \
      ".github/workflows/build-win32-x64.yml" \
      ".github/workflows/copyright.yml" \
      ".github/workflows/deep-clean.yml" \
      ".github/workflows/publish-release.yml" \
      ".github/workflows/test-docker-linux-arm.yml" \
      ".github/workflows/test-docker-linux-intel.yml" \
      ".github/workflows/test-prime.yml" \
      ".github/workflows/test-xpm.yml" \
      "build-assets/scripts/build.sh" \
      "build-assets/scripts/test.sh" \
    )

  else

    # Used internally.
    skip_pages_array+=(\
      ".github/workflows/copyright.yml" \
    )

    # No longer used.
    skip_pages_array+=(\
      ".github/workflows/build.yml" \
    )

    if [[ ! "${platforms_with_commas}" =~ ,darwin-x64, ]]
    then
      skip_pages_array+=(\
        ".github/workflows/build-darwin-x64.yml" \
      )
    fi
    if [[ ! "${platforms_with_commas}" =~ ,darwin-arm64, ]]
    then
      skip_pages_array+=(\
        ".github/workflows/build-darwin-arm64.yml" \
      )
    fi
    if [[ ! "${platforms_with_commas}" =~ ,linux-x64, ]]
    then
      skip_pages_array+=(\
        ".github/workflows/build-linux-x64.yml" \
        ".github/workflows/test-docker-linux-intel.yml" \
      )
    fi
    if [[ ! "${platforms_with_commas}" =~ ,linux-arm, ]]
    then
      skip_pages_array+=(\
        ".github/workflows/build-linux-arm.yml" \
      )
    fi
    if [[ ! "${platforms_with_commas}" =~ ,linux-arm64, ]]
    then
      skip_pages_array+=(\
        ".github/workflows/build-linux-arm64.yml" \
      )
    fi
    if [[ ! "${platforms_with_commas}" =~ ,win32-x64, ]]
    then
      skip_pages_array+=(\
        ".github/workflows/build-win32-x64.yml" \
      )
    fi
    if [[ ! "${platforms_with_commas}" =~ ,linux-arm, ]] &&
       [[ ! "${platforms_with_commas}" =~ ,linux-arm64, ]]
    then
      skip_pages_array+=(\
        ".github/workflows/test-docker-linux-arm.yml" \
      )
    fi
  fi

fi

if [ "${xpack_has_folder_build_assets_package}" != "true" ]
then
  skip_pages_array+=(\
    "build-assets/package.json" \
  )
fi

if [ "${xpack_has_folder_website_package}" != "true" ]
then
  skip_pages_array+=(\
    ".github/workflows/publish-github-pages.yml" \
  )
fi

if [ "${xpack_is_web_deploy_only}" != "true" ]
then
  skip_pages_array+=(\
    ".github/workflows/publish-github-pages-from-remote.yml" \
  )
else
  skip_pages_array+=(\
    ".clang-format" \
    ".github/workflows/test-all.yml" \
    ".github/workflows/test-ci.yml" \
  )
fi

if [ "${xpack_npm_package_version}" == "0.0.0" ]
then
  skip_pages_array+=(\
    ".npmignore" \
  )
fi

if [ "${xpack_has_test_all}" == "false" ]
then
  skip_pages_array+=(\
    ".github/workflows/test-all.yml" \
  )
fi

if [ "${xpack_has_folder_tests_package}" != "true" ]
then
  skip_pages_array+=(\
    "tests/cmake/common-options.cmake" \
    "tests/cmake/tests-main.cmake" \
    "tests/meson/common-options/meson.build" \
    "tests/package.json" \
  )
fi

if [ "${xpack_base_url_preview}" == "${xpack_base_url}" ]
then
  skip_pages_array+=(\
    ".github/workflows/trigger-publish-github-pages-preview.yml" \
  )
fi

# -----------------------------------------------------------------------------

skip_pages_array+=("END")

# The array members are concatenated with spaces separators.
# echo "skip_pages_array=${skip_pages_array[@]}"
# echo "to_relative_file_path=${to_relative_file_path}"

set +o nounset # Do not exit if variable not set (empty skip_pages_array).

# To ensure proper match, use explicit spaces.
if [[ ${skip_pages_array[@]} =~ " ${to_relative_file_path} " ]]
then
  # echo "skipped: ${from_relative_file_path}"
  echo "skipped: ${to_relative_file_path}"
  rm -f "${tmp_file_path}"
  exit 0
fi

set -o nounset # Exit if variable not set.

# -----------------------------------------------------------------------------

export do_force="false"

process_file

rm -rf "${tmp_file_path}"

# Completed successfully.
exit 0

# -----------------------------------------------------------------------------
