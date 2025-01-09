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

export script_path
export script_name="$(basename "${script_path}")"

export script_folder_path="$(dirname "${script_path}")"
export script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

# set -x

source "${script_folder_path}/scripts-helper-source.sh"

# Parse --init, --dry-run, --xpack, --xpack-dev-tools
# and leave variables in the environment.
parse_options "$@"

# -----------------------------------------------------------------------------

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

templates_folder_path="$(dirname "${script_folder_path}")/templates"

if [ -d "${project_folder_path}/website" ]
then
  website_folder_path="${project_folder_path}/website"
else
  website_folder_path=""
fi

export project_folder_path
export templates_folder_path
export website_folder_path

# -----------------------------------------------------------------------------

# Process package.json files and leave results in environment variables.
compute_context

# -----------------------------------------------------------------------------

if [ "${do_dry_run}" == "true" ]
then
  echo
  echo "Dry run!"
  echo
fi

# -----------------------------------------------------------------------------

cd "${templates_folder_path}"

echo
echo "Processing templates from $(pwd)..."
echo

# Main pass to copy/generate common files.
find . -type f -print0 | sort -zn | \
  xargs -0 -I '{}' bash "${script_folder_path}/process-top-template-item.sh" '{}' "${project_folder_path}"

# -----------------------------------------------------------------------------

echo
echo "${script_name} done"

# Completed successfully.
exit 0

# -----------------------------------------------------------------------------
