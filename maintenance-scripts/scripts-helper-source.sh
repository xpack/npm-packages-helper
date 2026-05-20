# -----------------------------------------------------------------------------
#
# This file is part of the xPack project (http://xpack.github.io).
# Copyright (c) 2024-2026 Liviu Ionescu. All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose is hereby granted, under the terms of the MIT license.
#
# If a copy of the license was not distributed with this file, it can be
# obtained from https://opensource.org/licenses/mit.
#
# -----------------------------------------------------------------------------

# Receives $@ from caller.
function parse_options() {

  do_init="false"
  do_dry_run="false"
  is_xpack="false"
  is_xpack_dev_tools="false"
  is_micro_os_plus="false"
  accepted_path=""
  do_push="false"
  do_restart="false"

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

      --push )
        do_push="true"
        shift
        ;;

      --restart )
        do_restart="true"
        shift
        ;;

      --xpack )
        is_xpack="true"
        accepted_path="_xpack"
        shift
        ;;

      --xpack-dev-tools )
        is_xpack_dev_tools="true"
        accepted_path="_xpack-dev-tools"
        shift
        ;;

      --micro-os-plus )
        is_micro_os_plus="true"
        accepted_path="_micro-os-plus"
        shift
        ;;

      * )
        echo "Unsupported option $1"
        shift
    esac
  done

  echo
  echo "Configuration: ${accepted_path}"

  export do_init
  export do_dry_run
  export is_xpack
  export is_xpack_dev_tools
  export is_micro_os_plus
  export accepted_path
  export do_push
  export do_restart
}

# -----------------------------------------------------------------------------

# "$@"
function check_if_should_ignore_path() {

  # If one of the selector paths is present, but not the right one, return.
  if [[ "${1}" =~ .*/_xpack/.* ]] || [[ "${1}" =~ .*/_xpack-dev-tools/.* ]] || [[ "${1}" =~ .*/_micro-os-plus/.* ]]
  then
    if [[ ! "${1}" =~ .*/"${accepted_path}"/.* ]]
    then
      return 0 # True
    fi
  fi

  return 1 # False
}

# "$@"
function prepare_paths() {

  # The source file path.
  export from_relative_file_path="$(echo "${1}" | sed -e 's|^\.\/||')"

  # The destination file path.
  export to_relative_file_path="$(echo "${1}" | sed -e 's|/_xpack/|/|' -e 's|/_xpack-dev-tools/|/|' -e 's|/_micro-os-plus/|/|' -e 's|-merge-liquid||' -e 's|-liquid||' -e 's|^\.\/||')"

  export to_absolute_folder_path="${2}"
  export to_absolute_file_path="${to_absolute_folder_path}/${to_relative_file_path}"
}

# -----------------------------------------------------------------------------

function run_verbose()
{
  # Does not include the .exe extension.
  local _app_path="$1"
  shift

  echo
  echo "[${_app_path} $@]"
  "${_app_path}" "$@" 2>&1
}

# -----------------------------------------------------------------------------

# Requires the json application and project_folder_path.
# Sets xpack_context and a lot of other variables.

function compute_context()
{
  # set -x

  if [ -z "${project_folder_path}" ]
  then
    echo "missing mandatory project_folder_path..."
    exit 1
  fi

  if [ ! -f "${project_folder_path}/package.json" ]
  then
    echo "missing mandatory ${project_folder_path}/package.json..."
    exit 1
  fi

  # The goal is to create a json context with all the relevant information 
  # about the project, to be used in liquid templates.
  # At the same time create shell environment variables to be used in scripts.

  # Start by creating an empty json context and add properties to it later.
  export xpack_context=$(echo '{}' | json -o json-0)

  # ---------------------------------------------------------------------------

  inspect_environment

  # ---------------------------------------------------------------------------

  process_top_package_json
  process_top_config

  # The order is relevant, as some of the variables depend on top config.
  process_xpack

  # ---------------------------------------------------------------------------

  if [ ! -z ${website_folder_path+x} ]
  then
    process_website_config
  fi

  # ---------------------------------------------------------------------------

  if [ ! -z ${tests_folder_path+x} ]
  then
    process_tests_config
  fi

  # ---------------------------------------------------------------------------

  # Temporary, until all projects are updated to use config/*.json files.
  if [ ! -f "${project_folder_path}/config/top-templates.json" ]
  then
    write_top_template_config
  fi

  if [ ! -z ${website_folder_path+x} ] && [ -f "${website_folder_path}/package.json" ]
  then
    if [ ! -f "${website_folder_path}/config/website-templates.json" ]
    then
      write_website_template_config
    fi
  fi

  # ---------------------------------------------------------------------------

  echo
  echo -n '"xpack_context": '
  echo "${xpack_context}" | json

  export xpack_context

  echo
  echo "environment variables: "
  echo
  env | egrep '^xpack_' | sort

  echo
}

# -----------------------------------------------------------------------------

function inspect_environment()
{
  echo
  echo "Processing project $(basename "${project_folder_path}") properties..."

  serialise_boolean_property_to "xpack_context" "hasFolderWebsitePackage" \
    "$([ -f "${project_folder_path}/website/package.json" ] && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasFolderBuildAssetsPackage" \
    "$([ -f "${project_folder_path}/build-assets/package.json" ] && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasFolderTestsPackage" \
    "$([ -f "${project_folder_path}/tests/package.json" ] && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasBranchMaster" \
    "$(git branch -a | grep -q master && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasBranchDevelopment" \
    "$(git branch -a | grep -q development && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasBranchXpack" \
    "$(git branch -a | grep -q xpack && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasBranchXpackDevelopment" \
    "$(git branch -a | grep -q xpack-development && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasBranchWebsite" \
    "$(git branch -a | grep -q website && echo true || echo false)" "xpack_"

  serialise_boolean_property_to "xpack_context" "hasBranchWebpreview" \
    "$(git branch -a | grep -q webpreview && echo true || echo false)" "xpack_" 

  if [ "${xpack_has_branch_xpack_development}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchDevelopment" "xpack-development" "xpack_"
  elif [ "${xpack_has_branch_development}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchDevelopment" "development" "xpack_"
  elif [ "${xpack_has_branch_webpreview}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchDevelopment" "webpreview" "xpack_"
  else
    echo "No branch development?"
    serialise_string_property_to "xpack_context" "branchDevelopment" "none" "xpack_"
    # exit 1
  fi

  if [ "${xpack_has_branch_website}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchWebsite" "website" "xpack_"
  elif [ "${xpack_has_branch_master}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchWebsite" "master" "xpack_"
  else
    echo "Branch?"
    exit 1
  fi

  if [ "${xpack_has_branch_webpreview}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchWebpreview" "webpreview" "xpack_"
  elif [ "${xpack_has_branch_development}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchWebpreview" "development" "xpack_"
  elif [ "${xpack_has_branch_master}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchWebpreview" "master" "xpack_"
  else
    echo "Branch preview?"
    exit 1
  fi

  if [ "${xpack_has_branch_xpack}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchMain" "xpack" "xpack_"
  elif [ "${xpack_has_branch_development}" == "true" ] && [ "${xpack_has_branch_master}" == "true" ]
  then
    # This is tricky, if it has development, it must also have master.
    serialise_string_property_to "xpack_context" "branchMain" "master" "xpack_"
  elif [ "${xpack_has_branch_website}" == "true" ]
  then
    serialise_string_property_to "xpack_context" "branchMain" "website" "xpack_"
  elif [ "${xpack_has_branch_master}" == "true" ]
  then
    # This is tricky, if it has development, it must also have master.
    serialise_string_property_to "xpack_context" "branchMain" "master" "xpack_"
  else
    echo "Branch main?"
    exit 1
  fi

  serialise_string_property_to "xpack_context" "releaseDate" "$(date '+%Y-%m-%d %H:%M:%S %z')" "xpack_"
}

# -----------------------------------------------------------------------------

function process_top_package_json()
{
  echo
  echo "Processing top package.json..."

  # Read in top package.json.
  xpack_package_json="$(json -f "${project_folder_path}/package.json" -o json-0)"

  # Edit the json and add the entire package.json. Not needed for now.
  # export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
  #   -e "this.package=${xpack_npm_package}" \
  # )

  serialise_string_property_to "xpack_context" "packageScopedName" \
    "$(echo "${xpack_package_json}" | json name)" "xpack_"

  if echo "${xpack_package_scoped_name}" | egrep -e '^@' >/dev/null
  then
    serialise_string_property_to "xpack_context" "packageScope" \
      "$(echo "${xpack_package_scoped_name}" | sed -e 's|^@||' -e 's|/.*||' )" "xpack_"
  else
    serialise_string_property_to "xpack_context" "packageScope" \
      "" "xpack_"
  fi

  serialise_string_property_to "xpack_context" "packageName" \
      "$(echo "${xpack_package_scoped_name}" | sed -e 's|^@[a-zA-Z0-9-]*/||')" "xpack_"

  serialise_string_property_to "xpack_context" "packageVersion" \
    "$(echo "${xpack_package_json}" | json version)" "xpack_"

  serialise_string_property_to "xpack_context" "packageType" \
    "$(echo "${xpack_package_json}" | json type)" "xpack_"

  serialise_string_property_to "xpack_context" "packageDescription" \
    "$(echo "${xpack_package_json}" | json description)" "xpack_"

  # Remove the `pre` used during development.
  serialise_string_property_to "xpack_context" "releaseVersion" \
    "$(echo "${xpack_package_version}" | sed -e 's|[.-]pre.*||')" "xpack_"

  # Remove the pre-release.
  serialise_string_property_to "xpack_context" "releaseSemver" \
    "$(echo "${xpack_release_version}" | sed -e 's|[-].*||')" "xpack_"

  if [ "${xpack_release_version}" != "${xpack_release_semver}" ]
  then
    serialise_string_property_to "xpack_context" "releaseSubversion" \
      "$(echo "${xpack_release_version}" | sed -e 's|.*[-]||' -e 's|[.][0-9]*||')" "xpack_"

    # Use the package.json one, but remove the `pre` used during development.
    serialise_string_property_to "xpack_context" "releaseNpmSubversion" \
      "$(echo "${xpack_release_version}" | sed -e 's|[.-]pre.*||' -e 's|.*[.]||')" "xpack_"
  else
    serialise_string_property_to "xpack_context" "releaseSubversion" \
      "" "xpack_"

    # Use the package.json one, but remove the `pre` used during development.
    serialise_string_property_to "xpack_context" "releaseNpmSubversion" \
      "" "xpack_"
  fi

  serialise_string_property_to "xpack_context" "repositoryUrl" \
    "$(echo "${xpack_package_json}" | json repository.url | sed -e  's|^git+||')" "xpack_"

  xpack_github_full_name="$(echo "${xpack_repository_url}" | sed -e 's|^https://github.com/||' -e 's|[.]git$||')"

  serialise_string_property_to "xpack_context" "githubProjectOrganization" \
    "$(echo "${xpack_github_full_name}" | sed -e 's|/.*||')" "xpack_"

  serialise_string_property_to "xpack_context" "githubProjectName" \
    "$(echo "${xpack_github_full_name}" | sed -e 's|/$||' -e 's|.git$||' -e 's|.*/||')" "xpack_"

  serialise_boolean_property_to "xpack_context" "isNpmExecutable" \
    "$([ ! -z "$(echo "${xpack_package_json}" | json bin)" ] && echo true || echo false)" "xpack_"

  serialise_string_property_to "xpack_context" "packageEnginesNodeVersion" \
    "$(echo "${xpack_package_json}" | json engines.node | sed -e 's|[^0-9]*||')" "xpack_"

  serialise_string_property_to "xpack_context" "packageEnginesNodeVersionMajor" \
    "$(echo "${xpack_package_engines_node_version}" | sed -e 's|[.].*||')" "xpack_"

  serialise_string_property_to "xpack_context" "packageDependenciesTypescriptVersion" \
    "$(echo "${xpack_package_json}" | json devDependencies.typescript | sed -e 's|[^0-9]*||')" "xpack_"

  serialise_string_property_to "xpack_context" "packageHomepage" \
    "$(echo "${xpack_package_json}" | json homepage)" "xpack_"

  local _homepage_preview="$(echo "${xpack_package_json}" | json homepagePreview)"
  serialise_string_property_to "xpack_context" "packageHomepagePreview" \
    "${_homepage_preview:-${xpack_package_homepage}}" "xpack_"

  serialise_array_property_to "xpack_context" "packageKeywords" \
    "$(echo "${xpack_package_json}" | json keywords -o json-0)" "xpack_"

  # hasWebsiteFolder?

  # ---------------------------------------------------------------------------
  # TODO: remove after all projects are migrated to config/*.json files.

  if [ ! -f "${project_folder_path}/config/top-templates.json" ]
  then

    if [[ ${xpack_github_project_name} == *-ts ]]
    then
      xpack_top_config_is_typescript="true"
    else
      xpack_top_config_is_typescript="false"
    fi
    export xpack_top_config_is_typescript

    if [[ ${xpack_github_project_name} == *-js ]]
    then
      xpack_top_config_is_javascript="true"
    else
      xpack_top_config_is_javascript="false"
    fi
    export xpack_top_config_is_javascript

    if [ ! -z "$(echo "${xpack_package_json}" | json prettier)" ]
    then
      xpack_top_config_use_prettier="true"
    else
      xpack_top_config_use_prettier="false"
    fi
    export xpack_top_config_use_prettier

    if [ ! -z "$(echo "${xpack_package_json}" | json standard)" ]
    then
      xpack_top_config_use_standard="true"
    else
      xpack_top_config_use_standard="false"
    fi
    export xpack_top_config_use_standard

    if [ ! -z "$(echo "${xpack_package_json}" | json devDependencies.typescript-eslint)" ]
    then
      xpack_top_config_use_typescript_eslint="true"
    else
      xpack_top_config_use_typescript_eslint="false"
    fi
    export xpack_top_config_use_typescript_eslint

    if [ ! -z "$(echo "${xpack_package_json}" | json devDependencies.'@microsoft/api-extractor')" ]
    then
      xpack_top_config_use_api_extractor="true"
    else
      xpack_top_config_use_api_extractor="false"
    fi
    export xpack_top_config_use_api_extractor

    export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
      -e "this.topConfig={}" \
      -e "this.topConfig.isTypescript=${xpack_top_config_is_typescript}" \
      -e "this.topConfig.isJavascript=${xpack_top_config_is_javascript}" \
      -e "this.topConfig.usePrettier=${xpack_top_config_use_prettier}" \
      -e "this.topConfig.useStandard=${xpack_top_config_use_standard}" \
      -e "this.topConfig.useTypescriptEslint=${xpack_top_config_use_typescript_eslint}" \
      -e "this.topConfig.useApiExtractor=${xpack_top_config_use_api_extractor}" \
    )

  fi
}

# -----------------------------------------------------------------------------

function process_top_config()
{
  if [ -f "${project_folder_path}/config/top-templates.json" ]
  then
    echo
    echo "Processing config/top-templates.json..."

    xpack_top_config="$(json -f "${project_folder_path}/config/top-templates.json" -o json-0)"
  else
    echo
    echo "Processing top package.json topConfig..."

    xpack_top_config="$(json -f "${project_folder_path}/package.json" -o json-0 topConfig)"
  fi

  # Edit the json and add an empty topConfig object.
  export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
    -e "this.topConfig={}" \
  )

  top_config_string_properties=(
    descriptiveName 
    permalinkName
    preferredName
    programName
  )

  local _prop
  for _prop in "${top_config_string_properties[@]}"
  do
    _string_property_value="$(echo "${xpack_top_config}" | json "${_prop}")"
    serialise_string_property_to "xpack_context" "topConfig.${_prop}" \
      "${_string_property_value:-""}" "xpack_"
  done

  top_config_array_properties=(
    githubActionsNodeVersions
    githubActionsOses 
    githubActionsXpmVersions
    upstreamDescriptiveName
  )

  for _prop in "${top_config_array_properties[@]}"
  do
    _array_property_value="$(echo "${xpack_top_config}" | json "${_prop}" -o json-0)"
    serialise_array_property_to "xpack_context" "topConfig.${_prop}" \
      "${_array_property_value:-""}" "xpack_"
  done

  top_config_boolean_properties=(
    hasCli 
    hasEmptyMaster
    hasNoGithubReleases 
    hasObjectLibrary
    hasTestAll 
    hasTriggerPublish 
    hasTriggerPublishPreview 
    hasWebsite
    isJavascript
    isOrganisationWeb 
    isTypescript
    isWebDeployOnly
    isWebPreview
    preferShortName 
    showTestsResults 
    skipCiTests 
    testCoverage
    useApiExtractor
    useDoxygen
    useEslint
    usePrettier
    useSelfHostedRunners
    useStandard
    useTap
    useTypescriptEslint
  )

  for _prop in "${top_config_boolean_properties[@]}"
  do
    _boolean_property_value="$(echo "${xpack_top_config}" | json "${_prop}" | tr '[:upper:]' '[:lower:]')"
    serialise_boolean_property_to "xpack_context" "topConfig.${_prop}" \
      "${_boolean_property_value:-false}" "xpack_"
  done

  # Add some more top properties derived from the above ones, to avoid having  
  # to do it in liquid templates.

  # Located here because it depends on descriptiveName.
  local _xpack_long_xpack_name
  if [ ! -z "${xpack_top_config_descriptive_name}" ]
  then
    if [ "${xpack_top_config_descriptive_name:0:6}" != "xPack " ] &&
        [ "${xpack_github_project_organization:0:6}" == "xpack-" ]
    then
      _xpack_long_xpack_name="xPack ${xpack_top_config_descriptive_name}"
    else
      _xpack_long_xpack_name="${xpack_top_config_descriptive_name}"
    fi
  else
    echo "Missing descriptiveName in config/top-templates.json"
    _xpack_long_xpack_name=""
  fi
  serialise_string_property_to "xpack_context" "longXpackName" \
      "${_xpack_long_xpack_name}" "xpack_"

  # Located here becaue they depend on isOrganisationWeb.
  local _xpack_base_url="/$(basename "${xpack_package_homepage}")/"
  local _xpack_base_url_preview="/$(basename "${xpack_package_homepage_preview}")/"
  if [ "${xpack_top_config_is_organisation_web}" == "true" ]
  then
    _xpack_base_url="/"
    if [ -z "${xpack_package_homepage_preview}" ]
    then
      _xpack_base_url_preview="/"
    fi
  fi
  serialise_string_property_to "xpack_context" "baseUrl" \
    "${_xpack_base_url}" "xpack_"
  serialise_string_property_to "xpack_context" "baseUrlPreview" \
    "${_xpack_base_url_preview}" "xpack_"

  # ---------------------------------------------------------------------------

  # TODO: remove after all projects are migrated to config/*.json files, 
  # as this should be set in the json file, not derived from other properties.
  if [ ! -f "${project_folder_path}/config/top-templates.json" ]
  then
    local _xpack_preferred_name
    # Located here because it depends on descriptiveName and permalinkName.
    if [ "${xpack_top_config_prefer_short_name}" == "true" ]
    then
      _xpack_preferred_name="${xpack_top_config_permalink_name:-${xpack_package_name}}"
    else
      _xpack_preferred_name="${xpack_top_config_descriptive_name}"
    fi
    serialise_string_property_to "xpack_context" "topConfig.preferredName" \
        "${_xpack_preferred_name}" "xpack_"
  fi

  export xpack_top_config

  # Old code.
  # if [ -z "${xpack_top_config}" ]
  # then
  #   xpack_top_config="{}"
  #   xpack_is_organisation_web="false"
  #   xpack_is_web_deploy_only="false"
  #   xpack_skip_ci_tests="false"
  #   xpack_show_test_results="false"
  #   xpack_has_trigger_publish="false"
  #   xpack_has_trigger_publish_preview="false"
  #   xpack_has_empty_master="false"
  #   xpack_descriptive_name=""
  #   xpack_permalink_name=""
  #   xpack_prefer_short_name="false"
  #   xpack_preferred_name=""
  #   xpack_long_xpack_name=""
  #   xpack_use_self_hosted_runners=""
  #   xpack_has_test_all="true"
  #   xpack_has_no_github_releases=""
  #   xpack_has_cli=""
  # else
  #   xpack_is_organisation_web="$(echo "${xpack_top_config}" | json isOrganisationWeb)"
  #   xpack_is_web_deploy_only="$(echo "${xpack_top_config}" | json isWebDeployOnly)"
  #   xpack_skip_ci_tests="$(echo "${xpack_top_config}" | json skipCiTests)"
  #   xpack_show_test_results="$(echo "${xpack_top_config}" | json showTestsResults)"
  #   xpack_has_trigger_publish="$(echo "${xpack_top_config}" | json hasTriggerPublish)"
  #   xpack_has_trigger_publish_preview="$(echo "${xpack_top_config}" | json hasTriggerPublishPreview)"
  #   xpack_has_empty_master="$(echo "${xpack_top_config}" | json hasEmptyMaster)"
  #   xpack_descriptive_name="$(echo "${xpack_top_config}" | json descriptiveName)"
  #   xpack_permalink_name="$(echo "${xpack_top_config}" | json permalinkName)"
  #   xpack_prefer_short_name="$(echo "${xpack_top_config}" | json preferShortName)"
  #   xpack_use_self_hosted_runners="$(echo "${xpack_top_config}" | json useSelfHostedRunners)"
  #   xpack_has_test_all="$(echo "${xpack_top_config}" | json hasTestAll)"
  #   xpack_has_no_github_releases="$(echo "${xpack_top_config}" | json hasNoGithubReleases)"
  #   xpack_has_cli="$(echo "${xpack_top_config}" | json hasCli)"

  #   if [ ! -z "${xpack_descriptive_name}" ]
  #   then
  #     if [ "${xpack_descriptive_name:0:6}" != "xPack " ] &&
  #        [ "${xpack_github_project_organization:0:6}" == "xpack-" ]
  #     then
  #       xpack_long_xpack_name="xPack ${xpack_descriptive_name}"
  #     else
  #       xpack_long_xpack_name="${xpack_descriptive_name}"
  #     fi
  #   else
  #     echo "Missing descriptiveName in topConfig"
  #     xpack_long_xpack_name=""
  #   fi

  #   if [ "${xpack_prefer_short_name}" == "true" ]
  #   then
  #     xpack_preferred_name="${xpack_permalink_name:-${xpack_package_name}}"
  #   else
  #     xpack_preferred_name="${xpack_descriptive_name}"
  #   fi
  # fi

  # export xpack_is_organisation_web
  # export xpack_is_web_deploy_only
  # export xpack_skip_ci_tests
  # export xpack_show_test_results
  # export xpack_has_trigger_publish
  # export xpack_has_trigger_publish_preview
  # export xpack_has_empty_master
  # export xpack_descriptive_name
  # export xpack_permalink_name
  # export xpack_prefer_short_name
  # export xpack_preferred_name
  # export xpack_long_xpack_name
  # export xpack_use_self_hosted_runners
  # export xpack_has_test_all
  # export xpack_has_no_github_releases
  # export xpack_has_cli

  # xpack_base_url="/$(basename "${xpack_package_homepage}")/"
  # xpack_base_url_preview="/$(basename "${xpack_package_homepage_preview}")/"
  # if [ "${xpack_is_organisation_web}" == "true" ]
  # then
  #   xpack_base_url="/"
  #   if [ -z "${xpack_package_homepage_preview}" ]
  #   then
  #     xpack_base_url_preview="/"
  #   fi
  # fi
  # export xpack_base_url
  # export xpack_base_url_preview

  # # Edit the json and add properties one by one.
  # export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
  #   -e "this.packageConfig=${xpack_top_config}" \
  #   -e "this.longXpackName=\"${xpack_long_xpack_name}\"" \
  #   -e "this.topConfig.preferredName=\"${xpack_preferred_name}\"" \
  #   -e "this.baseUrl=\"${xpack_base_url}\"" \
  #   -e "this.baseUrlPreview=\"${xpack_base_url_preview}\"" \
  #   -e "this.showTestsResults=\"${xpack_show_test_results}\"" \
  # )
}

# TODO: remove after all projects are migrated to config/*.json files.
function write_top_template_config()
{
  echo
  echo "Writing top templates config..."

  # Start with an empty json and add properties to it.
  local _output_json="{}"

  local _prop
  for _prop in "${top_config_string_properties[@]}"
  do
    local _variable_snake_name="xpack_top_config_$(echo "${_prop}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    local _string_property_value="${!_variable_snake_name}"

    serialise_non_empty_string_property_to "_output_json" "${_prop}" \
      "${_string_property_value:-""}"
  done

  for _prop in "${top_config_array_properties[@]}"
  do
    local _array_property_value="$(echo "${xpack_context}" | json "topConfig.${_prop}" -o json-0)"

    serialise_array_property_to "_output_json" "${_prop}" \
      "${_array_property_value:-""}"
  done

  for _prop in "${top_config_boolean_properties[@]}"
  do
    local _variable_snake_name="xpack_top_config_$(echo "${_prop}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    local _boolean_property_value="${!_variable_snake_name}"

    if [ "${_prop}" == "useSelfHostedRunners" ]
    then
      serialise_boolean_property_to "_output_json" "${_prop}" \
      "${_boolean_property_value:-"false"}"
    else
      serialise_true_boolean_property_to "_output_json" "${_prop}" \
        "${_boolean_property_value:-"false"}"
    fi
  done

  mkdir -p "${project_folder_path}/config"
  echo "${_output_json}" | json > "${project_folder_path}/config/top-templates.json"

  local _output_count="$(echo "${_output_json}" | json -o json-0 -e "this._count=Object.keys(this).length" | json _count)"
  local _config_count="$(echo "${xpack_top_config}" | json -o json-0 -e "this._count=Object.keys(this).length" | json _count)"
  if [ "${_output_count}" != "$((${_config_count} + 1))" ]
  then
    echo "top-templates.json has ${_output_count} properties, but topConfig has ${_config_count} properties, plus preferredName"
    exit 1
  fi
}

# -----------------------------------------------------------------------------

function process_xpack()
{
  # Top xpack.
  local _xpack_package_xpack="$(echo "${xpack_package_json}" | json xpack)"

  local _xpack_platforms=""
  if [ -z "${_xpack_package_xpack}" ]
  then
    _xpack_package_xpack="{}"

    serialise_boolean_property_to "xpack_context" "isXpack" "false" "xpack_"
    serialise_boolean_property_to "xpack_context" "isXpackBinary" "false" "xpack_"
  else
    serialise_boolean_property_to "xpack_context" "isXpack" "true" "xpack_"

    local _xpack_npm_package_xpack_binaries="$(echo "${xpack_package_json}" | json xpack.binaries)"
    if [ ! -z "${_xpack_npm_package_xpack_binaries}" ]
    then
      serialise_boolean_property_to "xpack_context" "isXpackBinary" "true" "xpack_"

      # set -x
      local _xpack_platforms_array=()
      # The order is relevant, it is kept when generating tabs and lists.
      for _platform in win32-x64 darwin-x64 darwin-arm64 linux-x64 linux-arm64
      do
        local _platform_object="$(json -f "${project_folder_path}/package.json" -o json-0 xpack.binaries.platforms.${_platform})"
        if [ ! -z "${_platform_object}" ]
        then
          local _skip_value="$(echo "${_platform_object}" | json skip)"
          if [ "${_skip_value}" == "true" ]
          then
            continue
          fi
          _xpack_platforms_array+=("${_platform}")
        fi
      done
      # Convert array to comma-separated string
      _xpack_platforms="$(IFS=','; echo "${_xpack_platforms_array[*]}")"

    else
      serialise_boolean_property_to "xpack_context" "isXpackBinary" "false" "xpack_"
    fi
  fi

  # For top webs, to display the full list of platforms.
  if [ "${xpack_top_config_is_organisation_web}" == "true" ] && [ -z "${_xpack_platforms}" ]
  then
    _xpack_platforms="win32-x64,darwin-x64,darwin-arm64,linux-x64,linux-arm64"
  fi
  serialise_string_property_to "xpack_context" "platforms" "${_xpack_platforms}" "xpack_"

  local _xpack_is_npm_published="false"
  if [ "${xpack_is_xpack}" == "true" ] ||
     [ "${xpack_top_config_is_typescript}" == "true" ] ||
     [ "${xpack_top_config_is_javascript}" == "true" ]
  then
    if [ "${xpack_release_semver}" != "0.0.0" ]
    then
      _xpack_is_npm_published="true"
    fi
  fi
  serialise_boolean_property_to "xpack_context" "isNpmPublished" "${_xpack_is_npm_published}" "xpack_"


  # Note the ^ in the regex.
  if [ "${_xpack_package_xpack}" != "{}" ] && [[ ! "${xpack_release_semver}" =~ ^0[.]0[.0].*$ ]]
  then
    local _xpack_xpack_version
    if [ -f "${project_folder_path}/build-assets/scripts/VERSION" ]
    then
      # Prefer the VERSION content, if available.
      _xpack_xpack_version="$(cat "${project_folder_path}/build-assets/scripts/VERSION" | sed -e '2,$d')"
    else
      # Use the package.json one, but remove the `pre` used during development.
      _xpack_xpack_version="${xpack_release_version}"
    fi
    serialise_string_property_to "xpack_context" "xpackVersion" "${_xpack_xpack_version}" "xpack_"

    serialise_string_property_to "xpack_context" "xpackSemver" \
      "$(echo "${xpack_xpack_version}" | sed -e 's|[-].*||')" "xpack_"

    serialise_string_property_to "xpack_context" "xpackSubversion" \
      "$(echo "${xpack_xpack_version}" | sed -e 's|.*[-]||')" "xpack_"

    local _xpack_upstream_version
    if [ "${xpack_has_two_numbers_version:-}" == "true" ] && [[ "${xpack_release_semver}" =~ .*[.]0*$ ]]
    then
      # Remove the patch number, if zero.
      _xpack_upstream_version="$(echo ${xpack_release_semver} | sed -e 's|[.]0*$||')"
    else
      _xpack_upstream_version="${xpack_release_semver}"
    fi
    serialise_string_property_to "xpack_context" "upstreamVersion" "${_xpack_upstream_version}" "xpack_"
  fi
}

# -----------------------------------------------------------------------------

function process_website_config()
{
  if [ -f "${website_folder_path}/package.json" ]
  then

    echo
    echo "Processing website/package.json..."

    if [ -f "${website_folder_path}/config/website-templates.json" ]
    then
      xpack_website_config="$(json -f "${website_folder_path}/config/website-templates.json" -o json-0)"
    else
      xpack_website_config="$(json -f "${website_folder_path}/package.json" -o json-0 websiteConfig)"
    fi

    if [ -z "${xpack_website_config}" ]
    then
      if [ "${do_init}" == "true" ] || [ "${xpack_top_config_is_web_deploy_only}" == "true" ] || [ "${is_micro_os_plus}" == "true" ]
      then
        xpack_website_config="{}"
      else
        echo "Missing websiteConfig"
        exit 1
      fi
    fi

    # Edit the json and add an empty websiteConfig object.
    export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
      -e "this.websiteConfig={}" \
    )

    website_string_properties=(
      armMajorMinorRelease
      armReleaseDate
      armSubRelease
      bashReleaseDate
      binutilsVersionMajor
      binutilsVersionMinor
      bisonReleaseDate
      branding
      busyboxReleaseDate
      busyboxTag
      clangReleaseDate
      cmakeReleaseDate
      coreutilsReleaseDate
      customAboutTitle
      customDeveloperTitle
      customGettingStartedTitle
      customInstallLabel
      customInstallTitle
      customMaintainerTitle
      customUserTitle
      flexReleaseDate
      gdbVersionMajor
      gdbVersionMinor
      llvmMingwTag
      m4ReleaseDate
      makeReleaseDate
      mesonReleaseDate
      metadataKeywords
      mingwVersion
      newlibVersion
      ninjaReleaseDate
      openocdCommitDate
      openocdCommitId
      patchelfReleaseDate
      pkgconfigReleaseDate
      platforms
      programName
      pythonVersion
      qemuReleaseDate
      sedReleaseDate
      tagline
      texinfoReleaseDate
      title
      triplet
      userGuideDescription
      wineReleaseDate
    )

    local _prop
    for _prop in "${website_string_properties[@]}"
    do
      local _string_property_value="$(echo "${xpack_website_config}" | json "${_prop}")"
      serialise_string_property_to "xpack_context" "websiteConfig.${_prop}" \
        "${_string_property_value:-""}" "xpack_"
    done

    website_boolean_properties=(
      has100coverage
      hasCustomAbout
      hasCustomConfigDoxyfile
      hasCustomDeveloper
      hasCustomDocsNavbarItem
      hasCustomGettingStarted
      hasCustomGettingStartedSidebar
      hasCustomHomepageFeatures
      hasCustomInstall
      hasCustomMaintainer
      hasCustomSidebar
      hasCustomUser
      hasCustomUserSidebar
      hasDoxygenDocusaurusApi
      hasDoxygenReference
      hasHomepageTools
      hasMetadataMinimum
      hasPolicies
      hasToolsSidebar
      hasTopHomepageFeatures
      hasTSDocDocusaurusApi
      hasTwoNumbersVersion
      hasTypedocApi
      isArmToolchain
      isGccToolchain
      isInstallGlobally
      isOrganisationWeb
      isSecondaryTool
      isXpmDependency
      shareOnTwitter
      showDeprecatedGnuMcuAnalytics
      showDeprecatedRiscvGccAnalytics
      skipAlgolia
      skipContributorGuide
      skipFaq
      skipInstallCommand
      skipInstallGuide
      skipMaintainerGuide
      skipReleases
      skipTests
      useApiDocumenter
      usePluralGuides
    )

    for _prop in "${website_boolean_properties[@]}"
    do
      local _boolean_property_value="$(echo "${xpack_website_config}" | json "${_prop}" | tr '[:upper:]' '[:lower:]')"
      serialise_boolean_property_to "xpack_context" "websiteConfig.${_prop}" \
        "${_boolean_property_value:-false}" "xpack_"
    done

    export xpack_website_config

    # xpack_website_custom_fields="$(echo "${xpack_website_config}" | json -o json-0 customFields)"

    # if [ -z "${xpack_website_custom_fields}" ]
    # then
    #   xpack_website_custom_fields='{}'
    # fi
    # export xpack_website_custom_fields

    # -------------------------------------------------------------------------
    # Old code, to be removed.
    # export xpack_has_metadata_minimum="$(echo "${xpack_website_config}" | json hasMetadataMinimum)"
    # export xpack_has_custom_homepage_features="$(echo "${xpack_website_config}" | json hasCustomHomepageFeatures)"
    # export xpack_has_custom_sidebar="$(echo "${xpack_website_config}" | json hasCustomSidebar)"
    # export xpack_has_custom_developer="$(echo "${xpack_website_config}" | json hasCustomDeveloper)"
    # export xpack_has_custom_getting_started="$(echo "${xpack_website_config}" | json hasCustomGettingStarted)"
    # export xpack_has_custom_install="$(echo "${xpack_website_config}" | json hasCustomInstall)"
    # export xpack_has_custom_maintainer="$(echo "${xpack_website_config}" | json hasCustomMaintainer)"
    # export xpack_has_custom_about="$(echo "${xpack_website_config}" | json hasCustomAbout)"
    # export xpack_has_custom_user="$(echo "${xpack_website_config}" | json hasCustomUser)"
    # export xpack_has_custom_user_sidebar="$(echo "${xpack_website_config}" | json hasCustomUserSidebar)"
    # export xpack_has_custom_getting_started_sidebar="$(echo "${xpack_website_config}" | json hasCustomGettingStartedSidebar)"
    # export xpack_has_custom_config_doxyfile="$(echo "${xpack_website_config}" | json hasCustomConfigDoxyfile)"

    # export xpack_has_top_homepage_features="$(echo "${xpack_website_config}" | json hasTopHomepageFeatures)"
    # export xpack_has_homepage_tools="$(echo "${xpack_website_config}" | json hasHomepageTools)"

    # export xpack_has_policies="$(echo "${xpack_website_config}" | json hasPolicies)"
    # export xpack_skip_install_command="$(echo "${xpack_website_config}" | json skipInstallCommand)"
    # export xpack_skip_install_guide="$(echo "${xpack_website_config}" | json skipInstallGuide)"
    # export xpack_skip_releases="$(echo "${xpack_website_config}" | json skipReleases)"
    # export xpack_skip_faq="$(echo "${xpack_website_config}" | json skipFaq)"
    # export xpack_skip_contributor_guide="$(echo "${xpack_website_config}" | json skipContributorGuide)"
    # export xpack_skip_tests="$(echo "${xpack_website_config}" | json skipTests)"

    # export xpack_website_config_is_arm_toolchain="$(echo "${xpack_website_config}" | json isArmToolchain)"
    # export xpack_website_config_is_gcc_toolchain="$(echo "${xpack_website_config}" | json isGccToolchain)"

    # xpack_custom_fields="$(echo "${xpack_website_config}" | json -o json-0 customFields)"

    # if [ -z "${xpack_custom_fields}" ]
    # then
    #   xpack_custom_fields='{}'
    # fi
    # export xpack_custom_fields

    # # Edit the json and add more properties one by one.
    # export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
    # -e "this.packageWebsiteConfig=${xpack_website_config}" \
    # )

    # export xpack_has_two_numbers_version="$(echo "${xpack_website_config}" | json hasTwoNumbersVersion)"

    # Even older code, to be removed.
    # if [ "${xpack_custom_fields}" != '{}' ]
    # then
    #   export xpack_dt_has_two_numbers_version="$(echo "${xpack_website_config}" | json hasTwoNumbersVersion)"
    #   # export xpack_dt_is_organisation_web="$(echo "${xpack_custom_fields}" | json isOrganisationWeb)"

    #   if [ "${xpack_is_organisation_web}" == "true" ]
    #   then
    #     xpack_dt_version="0.0.0-0"
    #     xpack_dt_base_url="/"
    #   else
    #     xpack_dt_version="$(cat "${project_folder_path}/build-assets/scripts/VERSION" | sed -e '2,$d')"
    #     xpack_dt_base_url="/${xpack_top_config_permalink_name}-xpack/"
    #   fi

    #   export xpack_dt_version
    #   export xpack_dt_base_url

    #   # Remove pre-release.
    #   export xpack_dt_semver_version="$(echo ${xpack_dt_version} | sed -e 's|-.*||')"

    #   if [ "${xpack_dt_has_two_numbers_version}" == "true" ] && [[ "${xpack_dt_semver_version}" =~ .*[.]0*$ ]]
    #   then
    #     # Remove the patch number, if zero.
    #     xpack_dt_upstream_version="$(echo ${xpack_dt_semver_version} | sed -e 's|[.]0*$||')"
    #   else
    #     xpack_dt_upstream_version="${xpack_dt_semver_version}"
    #   fi
    #   export xpack_dt_upstream_version

    #   # TODO: adjust for top web.
    #   export xpack_dt_branch="xpack-development"

    #   # Edit the json and add more properties one by one.
    #   export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
    #   -e "this.branch=\"${xpack_dt_branch}\"" \
    #   )
    # fi
  fi
}

function write_website_template_config()
{
  echo
  echo "Writing website templates config..."

  # Start with an empty json and add properties to it.
  local _output_json="{}"

  local _prop
  for _prop in "${website_string_properties[@]}"
  do
    local _variable_snake_name="xpack_website_config_$(echo "${_prop}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    local _string_property_value="${!_variable_snake_name}"

    if [ "${_prop}" == 'branding' ]
    then
      serialise_string_property_to "_output_json" "${_prop}" \
        "${_string_property_value:-""}"
    else
      serialise_non_empty_string_property_to "_output_json" "${_prop}" \
        "${_string_property_value:-""}"
    fi
  done

  serialise_non_empty_string_property_to "_output_json" "\$link" \
        "$(echo "${xpack_website_config}" | json "\$link")"

  for _prop in "${website_boolean_properties[@]}"
  do
    local _variable_snake_name="xpack_website_config_$(echo "${_prop}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    local _boolean_property_value="${!_variable_snake_name}"

    serialise_true_boolean_property_to "_output_json" "${_prop}" \
      "${_boolean_property_value:-"false"}"
  done

  mkdir -p "${website_folder_path}/config"
  echo "${_output_json}" | json > "${website_folder_path}/config/website-templates.json"

  local _output_count="$(echo "${_output_json}" | json -o json-0 -e "this._count=Object.keys(this).length" | json _count)"
  local _config_count="$(echo "${xpack_website_config}" | json -o json-0 -e "this._count=Object.keys(this).length" | json _count)"
  if [ "${_output_count}" != "${_config_count}" ]
  then
    echo "website-templates.json has ${_output_count} properties, but websiteConfig has ${_config_count} properties"
    exit 1
  fi
}

# -----------------------------------------------------------------------------

function process_tests_config() 
{
  if [ -f "${tests_folder_path}/config/tests-templates.json" ]
  then
    echo
    echo "Processing tests/config/tests-templates.json..."

    # Tests configuration.
    xpack_tests_config="$(json -f "${tests_folder_path}/config/tests-templates.json" -o json-0)"  
  elif [ -f "${tests_folder_path}/package.json" ]
  then
    echo
    echo "Processing tests/package.json..."

    # Tests configuration.
    xpack_tests_config="$(json -f "${tests_folder_path}/package.json" -o json-0 testsConfig)"
  else
    echo
    echo "No tests configuration file found."
    xpack_tests_config="{}"
  fi

  if [ -z "${xpack_tests_config:-}" ]
  then
    xpack_tests_config="{}"
  fi

  # Edit the json and add an empty testsConfig object.
  export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
    -e "this.testsConfig={}" \
  )

  # export xpack_has_skip_micro_os_plus_trace="$(echo "${xpack_tests_config}" | json skipMICRO_OS_PLUS_TRACE)"

  tests_array_properties=(
    platforms
    tests 
  )

  local _prop
  for _prop in "${tests_array_properties[@]}"
  do
    local _array_property_value="$(echo "${xpack_tests_config}" | json "${_prop}" -o json-0)"
    serialise_array_property_to "xpack_context" "testsConfig.${_prop}" \
      "${_array_property_value:-""}" "xpack_"
  done

  export xpack_tests_config
}

# =============================================================================
# Utility functions.

# $1: variable name
# $2: json property name
# $3: value
# $4: optional prefix for environment variable to be exported.
function serialise_boolean_property_to()
{
  local _variable_name="$1"
  local _json_property_name="$2"
  local _current="${!_variable_name}"
  local _new_value

  if [ "$3" == "true" ]
  then
    _new_value="$(echo "${_current}" | json -o json-0  -e "this.${_json_property_name}=true")"
  else
    _new_value="$(echo "${_current}" | json -o json-0 -e "this.${_json_property_name}=false")"
  fi
  export "${_variable_name}=${_new_value}"

  if [ -n "${4:-}" ]
  then
    local _variable_snake_name="$(echo "${_json_property_name}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    if [ "$3" == "true" ]
    then
      export "${4}${_variable_snake_name}=true"
    else
      export "${4}${_variable_snake_name}=false"
    fi
  fi
}

# $1: variable name
# $2: json property name
# $3: value
function serialise_true_boolean_property_to()
{
  if [ "$3" == "true" ]
  then
    local _variable_name="$1"
    local _current="${!_variable_name}"
    local _json_property_name="$2"
    local _new_value
    _new_value="$(echo "${_current}" | json -o json-0 -e "this.${_json_property_name}=true")"
    export "${_variable_name}=${_new_value}"
  fi
}

# $1: variable name
# $2: json property name
# $3: value
# $4: optional prefix for environment variable to be exported.
function serialise_string_property_to()
{
  local _variable_name="$1"
  local _json_property_name="$2"
  local _string_value="$3"

  local _current="${!_variable_name}"
  local _new_value="$(echo "${_current}" | json -o json-0 -e "this.${_json_property_name}=\"${_string_value}\"")"
  export "${_variable_name}=${_new_value}"

  if [ -n "${4:-}" ]
  then
    local _variable_snake_name="$(echo "${_json_property_name}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    export "${4}${_variable_snake_name}=$(echo "${_string_value}")"
  fi

}

# $1: variable name
# $2: json property name
# $3: value
# $4: optional prefix for environment variable to be exported.
function serialise_non_empty_string_property_to()
{
  local _variable_name="$1"
  local _json_property_name="$2"
  local _string_value="$3"

  if [ ! -z "${_string_value}" ]
  then
    local _current="${!_variable_name}"
    local _new_value="$(echo "${_current}" | json -o json-0 -e "this.${_json_property_name}=\"${_string_value}\"")"
    export "${_variable_name}=${_new_value}"
  fi

  if [ -n "${4:-}" ]
  then
    local _variable_snake_name="$(echo "${_json_property_name}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    export "${4}${_variable_snake_name}=$(echo "${_string_value}")"
  fi
}

# $1: variable name
# $2: json property name
# $3: value
# $4: optional prefix for environment variable to be exported.
function serialise_array_property_to()
{
  local _variable_name="$1"
  local _json_property_name="$2"
  local _array_value="$3"

  if [ ! -z "${_array_value}" ]
  then
    local _current="${!_variable_name}"
    local _new_value
    _new_value="$(echo "${_current}" | json -o json-0 -e "this.${_json_property_name}=${_array_value}")"
    export "${_variable_name}=${_new_value}"
  fi

  if [ -n "${4:-}" ]
  then
    local _variable_snake_name="$(echo "${_json_property_name}" | sed -e 's|[A-Z]|_&|g' -e 's|[.]|_|g' | tr '[:upper:]' '[:lower:]')"
    local _string_value="$(echo "${_array_value}" | sed -e 's|^\[||' -e 's|\]$||' -e 's|"||g')"
    export "${4}${_variable_snake_name}=$(echo "${_string_value:-"[]"}")"
  fi
}

# -----------------------------------------------------------------------------

# xargs stops only for exit code 255.
function trap_handler()
{
  local _message="${1}"
  shift
  local _line_number="${1}"
  shift
  local _exit_code="${1}"
  shift

  echo "\007 FAIL ${_message} line: ${_line_number} exit: ${_exit_code}"

  if [ $# -ge 1 ]
  then
    rm -rfv "${1}"
  fi

  exit 255
}

function substitute()
{
  local _from_relative_file_path="$1" # liquid source
  local _to_relative_file_path="$2" # destination
  # $3 - destination absolute folder path

  local _to_absolute_file_path="${3}/${_to_relative_file_path}"
  mkdir -pv "$(dirname ${_to_absolute_file_path})"

  echo "liquidjs -> ${_to_relative_file_path}"
  # pwd

  if [ "${do_dry_run}" == "true" ]
  then
    liquidjs --context "${xpack_context}" --template "@${_from_relative_file_path}" --output /dev/null --strict-filters --strict-variables --lenient-if
  else
    liquidjs --context "${xpack_context}" --template "@${_from_relative_file_path}" --output "${_to_absolute_file_path}.new" --strict-filters --strict-variables --lenient-if

    rm -f "${_to_absolute_file_path}"
    mv "${_to_absolute_file_path}.new" "${_to_absolute_file_path}"
  fi
}

function substitute_and_merge()
{
  local _from_relative_file_path="$1" # liquid source
  local _to_relative_file_path="$2" # destination
  # $3 - destination absolute folder path

  local _to_absolute_file_path="${3}/${_to_relative_file_path}"
  mkdir -pv "$(dirname ${_to_absolute_file_path})"

  echo "liquidjs | merge -> ${_to_relative_file_path}"

  if [ "${do_dry_run}" == "true" ]
  then
    liquidjs --context "${xpack_context}" --template "@${_from_relative_file_path}" --output /dev/null --strict-filters --strict-variables --lenient-if
  else
    liquidjs --context "${xpack_context}" --template "@${_from_relative_file_path}" --output "${tmp_file_path}" --strict-filters --strict-variables --lenient-if

    # echo "${tmp_file_path}"
    # cat "${tmp_file_path}"
    # json -f "${tmp_file_path}"
    echo >> "${_to_absolute_file_path}"

    # https://trentm.com/json
    cat "${_to_absolute_file_path}" "${tmp_file_path}" | json --deep-merge >"${_to_absolute_file_path}.new"

    rm -f "${_to_absolute_file_path}"
    mv "${_to_absolute_file_path}.new" "${_to_absolute_file_path}"
  fi
}

# -----------------------------------------------------------------------------

# The paths are set by prepare_paths().
function process_file() {

  if [ -f "${to_absolute_file_path}" ]
  then
    if [ "${do_force}" != "true" ]
    then
      echo "${to_relative_file_path} exists"
      return 0
    fi

    # Be sure destination is writeable.
    chmod -f +w "${to_absolute_file_path}"
  fi

  # ---------------------------------------------------------------------------

  mkdir -pv "$(dirname ${to_absolute_file_path})"

  if [[ "$(basename "${from_relative_file_path}")" =~ .*-merge-liquid.* ]]
  then
    substitute_and_merge "${from_relative_file_path}" "${to_relative_file_path}" "${to_absolute_folder_path}"
  elif [[ "$(basename "${from_relative_file_path}")" =~ .*-liquid.* ]]
  then
    substitute "${from_relative_file_path}" "${to_relative_file_path}" "${to_absolute_folder_path}"
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
    if [ "$(basename "${to_absolute_file_path}")" != "package.json" ] && [ "${do_force}" == "true" ]
    then
      chmod -w "${to_absolute_file_path}"
    fi
  else
    if [ ! -f "${to_absolute_file_path}" ]
    then
      echo ">>>> ${to_relative_file_path} not present >>>>"
    fi
  fi
}

# -----------------------------------------------------------------------------

# $1 = name.git (project path)
function import_releases()
{
  (
    local _from_folder_path="${1}"

    cd "${_from_folder_path}"

    echo
    echo "----------------------------------------------------------------------------"
    pwd

    # set -x

    name="$(basename "$(pwd)")"

    export project_folder_path="${_from_folder_path}"
    export website_folder_path="${_from_folder_path}/website"

    export xpack_www_releases="${website_folder_path}/_xpack.github.io/_posts/releases"

    local _npm_package_name="$(echo "${name}" | sed -e 's|-xpack.git||')"
    export do_force="y"
    if [ ! -d "${xpack_www_releases}/${_npm_package_name}" ]
    then
      echo "No ${xpack_www_releases}/${_npm_package_name}, nothing to do..."
      return 0
    fi

    export xpack_website_config_short_name="$(json -f "${project_folder_path}/package.json" topConfig.permalinkName)"
    export xpack_website_config_long_name="xPack $(json -f "${project_folder_path}/package.json" topConfig.descriptiveName)"
    export xpack_repository_url="$(json -f "${project_folder_path}/package.json" repository.url)"
    export xpack_github_project_organization="$(echo "${xpack_repository_url}" | sed -e 's|.*github.com/||' | sed -e 's|/.*||')"

    cd "${xpack_www_releases}/${_npm_package_name}"

    echo
    echo "Release posts..."

    find . -type f -print0 | \
      xargs -0 -I '{}' bash "${script_folder_path}/website-convert-release-post.sh" '{}' "${website_folder_path}/blog"

    echo
    echo "Validating liquidjs..."

    if grep -r -e '{{' "${website_folder_path}/blog"/*.md* | grep -v '/website/blog/_' || \
      grep -r -e '{%' "${website_folder_path}/blog"/*.md* | grep -v '/website/blog/_'
    then
      exit 1
    fi

    echo
    echo "Showing descriptions..."

    egrep -h -e "(title:|description:)" "${website_folder_path}/blog"/*.md*

    echo
    echo "'${script_name}' done"

    return 0
  )
}

# -----------------------------------------------------------------------------

function download_binaries()
{
  local _destination_folder_path="${1:-"${HOME}/Downloads/xpack-binaries/${xpack_top_config_permalink_name}"}"

  local _version=${XBB_RELEASE_VERSION:-"${xpack_xpack_version}"}

  (
    rm -rf "${_destination_folder_path}-bak"
    if [ -d "${_destination_folder_path}" ]
    then
      mv "${_destination_folder_path}" "${_destination_folder_path}-bak"
    fi

    mkdir -pv "${_destination_folder_path}"
    cd "${_destination_folder_path}"

    # Extract the xpack.properties platforms. There are also in xpack.binaries.
    local _platforms=$(echo "${xpack_platforms}" | sed 's|,| |g')

    IFS=' '
    for _platform in ${_platforms}
    do

      # echo ${_platform}
      # https://github.com/xpack-dev-tools/pre-releases/releases/download/test/xpack-ninja-build-1.11.1-2-win32-x64.zip
      local _extension='tar.gz'
      if [ "${_platform}" == "win32-x64" ]
      then
        _extension='zip'
      fi

      archive_name="xpack-${xpack_top_config_permalink_name}-${_version}-${_platform}.${_extension}"
      archive_url="https://github.com/xpack-dev-tools/pre-releases/releases/download/test/${archive_name}"

      run_verbose curl --location --insecure --fail --location --silent \
        --output "${archive_name}" \
        "${archive_url}"

      run_verbose curl --location --insecure --fail --location --silent \
        --output "${archive_name}.sha" \
        "${archive_url}.sha"

    done

    rm -rf "${_destination_folder_path}-bak"
  )
}

# -----------------------------------------------------------------------------
