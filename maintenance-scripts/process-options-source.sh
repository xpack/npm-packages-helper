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
