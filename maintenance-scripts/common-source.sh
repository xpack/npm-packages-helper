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
