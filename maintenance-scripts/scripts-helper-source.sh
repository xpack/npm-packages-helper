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

# Receives $@ from caller.
function parse_options() {

  do_init="false"
  do_dry_run="false"
  is_xpack="false"
  is_xpack_dev_tools="false"
  is_micro_os_plus="false"
  accepted_path=""
  do_push="false"

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
  local app_path="$1"
  shift

  echo
  echo "[${app_path} $@]"
  "${app_path}" "$@" 2>&1
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

  # Create an empty json context.
  export xpack_context=$(echo '{}' | json -o json-0)

  # ---------------------------------------------------------------------------

  echo
  echo "Processing project $(basename "${project_folder_path}") properties..."

  if [ -f "${project_folder_path}/website/package.json" ]
  then
    xpack_has_folder_website_package="true"
  else
    xpack_has_folder_website_package="false"
  fi
  export xpack_has_folder_website_package

  if [ -f "${project_folder_path}/build-assets/package.json" ]
  then
    xpack_has_folder_build_assets_package="true"
  else
    xpack_has_folder_build_assets_package="false"
  fi
  export xpack_has_folder_build_assets_package

  if [ -f "${project_folder_path}/tests/package.json" ]
  then
    xpack_has_folder_tests_package="true"
  else
    xpack_has_folder_tests_package="false"
  fi
  export xpack_has_folder_tests_package

  if (git branch -a | grep master) >/dev/null
  then
    xpack_has_branch_master="true"
  else
    xpack_has_branch_master="false"
  fi
  export xpack_has_branch_master

  if (git branch -a | grep development) >/dev/null
  then
    xpack_has_branch_development="true"
  else
    xpack_has_branch_development="false"
  fi
  export xpack_has_branch_development

  if (git branch -a | grep xpack) >/dev/null
  then
    xpack_has_branch_xpack="true"
  else
    xpack_has_branch_xpack="false"
  fi
  export xpack_has_branch_xpack

  if (git branch -a | grep xpack-development) >/dev/null
  then
    xpack_has_branch_xpack_development="true"
  else
    xpack_has_branch_xpack_development="false"
  fi
  export xpack_has_branch_xpack_development

  if (git branch -a | grep website) >/dev/null
  then
    xpack_has_branch_website="true"
  else
    xpack_has_branch_website="false"
  fi
  export xpack_has_branch_website

  if (git branch -a | grep webpreview) >/dev/null
  then
    xpack_has_branch_webpreview="true"
  else
    xpack_has_branch_webpreview="false"
  fi
  export xpack_has_branch_webpreview

  if [ "${xpack_has_branch_xpack_development}" == "true" ]
  then
    xpack_branch_development="xpack-development"
  elif [ "${xpack_has_branch_development}" == "true" ]
  then
    xpack_branch_development="development"
  elif [ "${xpack_has_branch_webpreview}" == "true" ]
  then
    xpack_branch_development="webpreview"
  else
    echo "Branch development?"
    xpack_branch_development="none"
    # exit 1
  fi
  export xpack_branch_development

  if [ "${xpack_has_branch_website}" == "true" ]
  then
    xpack_branch_website="website"
  elif [ "${xpack_has_branch_master}" == "true" ]
  then
    xpack_branch_website="master"
  else
    echo "Branch?"
    exit 1
  fi
  export xpack_branch_website

  if [ "${xpack_has_branch_webpreview}" == "true" ]
  then
    xpack_branch_webpreview="webpreview"
  elif [ "${xpack_has_branch_development}" == "true" ]
  then
    xpack_branch_webpreview="development"
  elif [ "${xpack_has_branch_master}" == "true" ]
  then
    xpack_branch_webpreview="master"
  else
    echo "Branch preview?"
    exit 1
  fi
  export xpack_branch_webpreview

  if [ "${xpack_has_branch_xpack}" == "true" ]
  then
    xpack_branch_main="xpack"
  elif [ "${xpack_has_branch_development}" == "true" ] && [ "${xpack_has_branch_master}" == "true" ]
  then
    # This is tricky, if it has development, it must also have master.
    xpack_branch_main="master"
  elif [ "${xpack_has_branch_website}" == "true" ]
  then
    xpack_branch_main="website"
  elif [ "${xpack_has_branch_master}" == "true" ]
  then
    # This is tricky, if it has development, it must also have master.
    xpack_branch_main="master"
  else
    echo "Branch main?"
    exit 1
  fi
  export xpack_branch_main

  export xpack_release_date="$(date '+%Y-%m-%d %H:%M:%S %z')"

  # Edit the json and add properties one by one.
  export xpack_context=$(echo '{}' | json -o json-0 \
  -e "this.hasFolderWebsitePackage=\"${xpack_has_folder_website_package}\"" \
  -e "this.hasFolderBuildAssetsPackage=\"${xpack_has_folder_build_assets_package}\"" \
  -e "this.hasFolderTestsPackage=\"${xpack_has_folder_tests_package}\"" \
  -e "this.hasBranchMaster=\"${xpack_has_branch_master}\"" \
  -e "this.hasBranchDevelopment=\"${xpack_has_branch_development}\"" \
  -e "this.hasBranchXpackDevelopment=\"${xpack_has_branch_xpack_development}\"" \
  -e "this.hasBranchWebsite=\"${xpack_has_branch_website}\"" \
  -e "this.hasBranchWebpreview=\"${xpack_has_branch_webpreview}\"" \
  -e "this.branchMain=\"${xpack_branch_main}\"" \
  -e "this.branchDevelopment=\"${xpack_branch_development}\"" \
  -e "this.branchWebsite=\"${xpack_branch_website}\"" \
  -e "this.branchWebpreview=\"${xpack_branch_webpreview}\"" \
  -e "this.releaseDate=\"${xpack_release_date}\"" \
  )

  # ---------------------------------------------------------------------------

  echo
  echo "Processing top package.json..."

  # https://trentm.com/json/
  export xpack_npm_package_scoped_name="$(json -f "${project_folder_path}/package.json" name)"

  if echo "${xpack_npm_package_scoped_name}" | egrep -e '^@' >/dev/null
  then
    export xpack_npm_package_scope="$(echo "${xpack_npm_package_scoped_name}" | sed -e 's|^@||' -e 's|/.*||' )"
  else
    export xpack_npm_package_scope=""
  fi

  export xpack_npm_package_name="$(echo "${xpack_npm_package_scoped_name}" | sed -e 's|^@[a-zA-Z0-9-]*/||')"
  export xpack_npm_package_version="$(json -f "${project_folder_path}/package.json" version)"
  export xpack_npm_package_description="$(json -f "${project_folder_path}/package.json" description)"

  export xpack_npm_package_keywords="$(json -f "${project_folder_path}/package.json" keywords)"
  if [ -z "${xpack_npm_package_keywords}" ]
  then
    xpack_npm_package_keywords="[]"
  fi
  export xpack_npm_package_keywords

  export xpack_npm_package_homepage="$(json -f "${project_folder_path}/package.json" homepage)"
  xpack_npm_package_homepage_preview="$(json -f "${project_folder_path}/package.json" homepagePreview)"
  if [ -z "${xpack_npm_package_homepage_preview}" ]
  then
    xpack_npm_package_homepage_preview="${xpack_npm_package_homepage}"
  fi
  export xpack_npm_package_homepage_preview

  # Remove the `pre` used during development.
  export xpack_release_version="$(echo "${xpack_npm_package_version}" | sed -e 's|[.-]pre.*||')"

  # Remove the pre-release.
  export xpack_release_semver="$(echo "${xpack_release_version}" | sed -e 's|[-].*||')"

  if [ "${xpack_release_version}" != "${xpack_release_semver}" ]
  then
    xpack_release_subversion="$(echo "${xpack_release_version}" | sed -e 's|.*[-]||' -e 's|[.][0-9]*||')"

    # Use the package.json one, but remove the `pre` used during development.
    xpack_release_npm_subversion="$(echo "${xpack_release_version}" | sed -e 's|[.-]pre.*||' -e 's|.*[.]||')"
  else
    xpack_release_subversion=""
    xpack_release_npm_subversion=""
  fi
  export xpack_release_subversion
  export xpack_release_npm_subversion

  xpack_github_repository_url="$(json -f "${project_folder_path}/package.json"  repository.url | sed -e  's|^git+||')"
  xpack_github_full_name="$(echo "${xpack_github_repository_url}" | sed -e 's|^https://github.com/||' -e 's|[.]git$||')"

  export xpack_github_project_organization="$(echo "${xpack_github_full_name}" | sed -e 's|/.*||')"
  export xpack_xpack_github_project_name="$(echo "${xpack_github_full_name}" | sed -e 's|/$||' -e 's|.git$||' -e 's|.*/||')"

  if [[ ${xpack_xpack_github_project_name} == *-ts ]]
  then
    xpack_is_typescript="true"
  else
    xpack_is_typescript="false"
  fi
  export xpack_is_typescript

  if [[ ${xpack_xpack_github_project_name} == *-js ]]
  then
    xpack_is_javascript="true"
  else
    xpack_is_javascript="false"
  fi
  export xpack_is_javascript

  export xpack_npm_package_engines_node_version="$(json -f "${project_folder_path}/package.json" engines.node | sed -e 's|[^0-9]*||')"
  export xpack_npm_package_engines_node_version_major="$(echo "${xpack_npm_package_engines_node_version}" | sed -e 's|[.].*||')"

  export xpack_npm_package_dependencies_typescript_version="$(json -f "${project_folder_path}/package.json" devDependencies.typescript | sed -e 's|[^0-9]*||')"

  if [ ! -z "$(json -f "${project_folder_path}/package.json" bin)" ]
  then
    xpack_npm_package_is_binary="true"
  else
    xpack_npm_package_is_binary="false"
  fi
  export xpack_npm_package_is_binary

  # Edit the json and add properties one by one.
  export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
  -e "this.packageScopedName=\"${xpack_npm_package_scoped_name}\"" \
  -e "this.packageScope=\"${xpack_npm_package_scope}\"" \
  -e "this.packageName=\"${xpack_npm_package_name}\"" \
  -e "this.packageVersion=\"${xpack_npm_package_version}\"" \
  -e "this.releaseVersion=\"${xpack_release_version}\"" \
  -e "this.releaseSemver=\"${xpack_release_semver}\"" \
  -e "this.releaseSubversion=\"${xpack_release_subversion}\"" \
  -e "this.releaseNpmSubversion=\"${xpack_release_npm_subversion}\"" \
  -e "this.packageDescription=\"${xpack_npm_package_description}\"" \
  -e "this.repositoryUrl=\"${xpack_github_repository_url}\"" \
  -e "this.githubProjectOrganization=\"${xpack_github_project_organization}\"" \
  -e "this.githubProjectName=\"${xpack_xpack_github_project_name}\"" \
  -e "this.packageKeywords=${xpack_npm_package_keywords}" \
  -e "this.hasWebsiteFolder=\"${xpack_has_folder_website_package}\"" \
  -e "this.isTypeScript=\"${xpack_is_typescript}\"" \
  -e "this.isJavaScript=\"${xpack_is_javascript}\"" \
  -e "this.isNpmBinary=\"${xpack_npm_package_is_binary}\"" \
  -e "this.packageEnginesNodeVersion=\"${xpack_npm_package_engines_node_version}\"" \
  -e "this.packageEnginesNodeVersionMajor=\"${xpack_npm_package_engines_node_version_major}\"" \
  -e "this.packageDependenciesTypescriptVersion=\"${xpack_npm_package_dependencies_typescript_version}\"" \
  -e "this.packageHomepage=\"${xpack_npm_package_homepage}\"" \
  -e "this.packageHomepagePreview=\"${xpack_npm_package_homepage_preview}\"" \
  )

  # ---------------------------------------------------------------------------

  # Top configuration (topConfig).
  xpack_npm_package="$(json -f "${project_folder_path}/package.json" -o json-0)"

  xpack_npm_package_top_config="$(json -f "${project_folder_path}/package.json" -o json-0 topConfig)"
  if [ -z "${xpack_npm_package_top_config}" ]
  then
    xpack_npm_package_top_config="{}"
    xpack_is_organization_web="false"
    xpack_is_web_deploy_only="false"
    xpack_skip_ci_tests="false"
    xpack_show_test_results="false"
    xpack_has_trigger_publish="false"
    xpack_has_trigger_publish_preview="false"
    xpack_has_empty_master="false"
    xpack_descriptive_name=""
    xpack_permalink_name=""
    xpack_long_xpack_name=""
    xpack_use_self_hosted_runners=""
    xpack_has_test_all="true"
  else
    xpack_is_organization_web="$(echo "${xpack_npm_package_top_config}" | json isOrganizationWeb)"
    xpack_is_web_deploy_only="$(echo "${xpack_npm_package_top_config}" | json isWebDeployOnly)"
    xpack_skip_ci_tests="$(echo "${xpack_npm_package_top_config}" | json skipCiTests)"
    xpack_show_test_results="$(echo "${xpack_npm_package_top_config}" | json showTestsResults)"
    xpack_has_trigger_publish="$(echo "${xpack_npm_package_top_config}" | json hasTriggerPublish)"
    xpack_has_trigger_publish_preview="$(echo "${xpack_npm_package_top_config}" | json hasTriggerPublishPreview)"
    xpack_has_empty_master="$(echo "${xpack_npm_package_top_config}" | json hasEmptyMaster)"
    xpack_descriptive_name="$(echo "${xpack_npm_package_top_config}" | json descriptiveName)"
    xpack_permalink_name="$(echo "${xpack_npm_package_top_config}" | json permalinkName)"
    xpack_use_self_hosted_runners="$(echo "${xpack_npm_package_top_config}" | json useSelfHostedRunners)"
    xpack_has_test_all="$(echo "${xpack_npm_package_top_config}" | json hasTestAll)"

    if [ ! -z "${xpack_descriptive_name}" ]
    then
      if [ "${xpack_descriptive_name:0:6}" != "xPack " ] &&
         [ "${xpack_github_project_organization:0:6}" == "xpack-" ]
      then
        xpack_long_xpack_name="xPack ${xpack_descriptive_name}"
      else
        xpack_long_xpack_name="${xpack_descriptive_name}"
      fi
    else
      echo "Missing descriptiveName in topConfig"
      xpack_long_xpack_name=""
    fi
  fi
  export xpack_npm_package_top_config
  export xpack_is_organization_web
  export xpack_is_web_deploy_only
  export xpack_skip_ci_tests
  export xpack_show_test_results
  export xpack_has_trigger_publish
  export xpack_has_trigger_publish_preview
  export xpack_has_empty_master
  export xpack_descriptive_name
  export xpack_permalink_name
  export xpack_long_xpack_name
  export xpack_use_self_hosted_runners
  export xpack_has_test_all

  xpack_base_url="/$(basename "${xpack_npm_package_homepage}")/"
  xpack_base_url_preview="/$(basename "${xpack_npm_package_homepage_preview}")/"
  if [ "${xpack_is_organization_web}" == "true" ]
  then
    xpack_base_url="/"
    if [ -z "${xpack_npm_package_homepage_preview}" ]
    then
      xpack_base_url_preview="/"
    fi
  fi
  export xpack_base_url
  export xpack_base_url_preview

  # Edit the json and add properties one by one.
  export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
  -e "this.packag=${xpack_npm_package}" \
  -e "this.packageConfig=${xpack_npm_package_top_config}" \
  -e "this.longXpackName=\"${xpack_long_xpack_name}\"" \
  -e "this.baseUrl=\"${xpack_base_url}\"" \
  -e "this.baseUrlPreview=\"${xpack_base_url_preview}\"" \
  -e "this.showTestsResults=\"${xpack_show_test_results}\"" \
  )

  # ---------------------------------------------------------------------------

  # Build configuration, in the top. (perhaps move to build-assets?)
  xpack_npm_package_build_config="$(json -f "${project_folder_path}/package.json" -o json-0 buildConfig)"
  if [ -z "${xpack_npm_package_build_config}" ]
  then
    xpack_npm_package_build_config="{}"
  fi
  export xpack_npm_package_build_config

  # Edit the empty json and add properties one by one.
  export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
  -e "this.packageBuildConfig=${xpack_npm_package_build_config}" \
  )

  # ---------------------------------------------------------------------------

  if [ ! -z ${website_folder_path+x} ] && [ -f "${website_folder_path}/package.json" ]
  then

    echo
    echo "Processing website/package.json..."

    xpack_npm_package_website_config="$(json -f "${website_folder_path}/package.json" -o json-0 websiteConfig)"

    if [ -z "${xpack_npm_package_website_config}" ]
    then
      if [ "${do_init}" == "true" ] || [ "${xpack_is_web_deploy_only}" == "true" ] || [ "${is_micro_os_plus}" == "true" ]
      then
        xpack_npm_package_website_config="{}"
      else
        echo "Missing websiteConfig"
        exit 1
      fi
    fi

    export xpack_has_metadata_minimum="$(echo "${xpack_npm_package_website_config}" | json hasMetadataMinimum)"
    export xpack_has_custom_homepage_features="$(echo "${xpack_npm_package_website_config}" | json hasCustomHomepageFeatures)"
    export xpack_has_custom_sidebar="$(echo "${xpack_npm_package_website_config}" | json hasCustomSidebar)"
    export xpack_has_custom_developer="$(echo "${xpack_npm_package_website_config}" | json hasCustomDeveloper)"
    export xpack_has_custom_getting_started="$(echo "${xpack_npm_package_website_config}" | json hasCustomGettingStarted)"
    export xpack_has_custom_install="$(echo "${xpack_npm_package_website_config}" | json hasCustomInstall)"
    export xpack_has_custom_maintainer="$(echo "${xpack_npm_package_website_config}" | json hasCustomMaintainer)"
    export xpack_has_custom_about="$(echo "${xpack_npm_package_website_config}" | json hasCustomAbout)"
    export xpack_has_custom_user="$(echo "${xpack_npm_package_website_config}" | json hasCustomUser)"
    export xpack_has_custom_user_sidebar="$(echo "${xpack_npm_package_website_config}" | json hasCustomUserSidebar)"
    export xpack_has_custom_getting_started_sidebar="$(echo "${xpack_npm_package_website_config}" | json hasCustomGettingStartedSidebar)"
    export xpack_has_custom_config_doxyfile="$(echo "${xpack_npm_package_website_config}" | json hasCustomConfigDoxyfile)"

    export xpack_has_top_homepage_features="$(echo "${xpack_npm_package_website_config}" | json hasTopHomepageFeatures)"
    export xpack_has_homepage_tools="$(echo "${xpack_npm_package_website_config}" | json hasHomepageTools)"

    export xpack_has_cli="$(echo "${xpack_npm_package_website_config}" | json hasCli)"
    export xpack_has_policies="$(echo "${xpack_npm_package_website_config}" | json hasPolicies)"
    export xpack_skip_install_command="$(echo "${xpack_npm_package_website_config}" | json skipInstallCommand)"
    export xpack_skip_install_guide="$(echo "${xpack_npm_package_website_config}" | json skipInstallGuide)"
    export xpack_skip_releases="$(echo "${xpack_npm_package_website_config}" | json skipReleases)"
    export xpack_skip_faq="$(echo "${xpack_npm_package_website_config}" | json skipFaq)"
    export xpack_skip_contributor_guide="$(echo "${xpack_npm_package_website_config}" | json skipContributorGuide)"

    export xpack_website_config_is_arm_toolchain="$(echo "${xpack_npm_package_website_config}" | json isArmToolchain)"
    export xpack_website_config_is_gcc_toolchain="$(echo "${xpack_npm_package_website_config}" | json isGccToolchain)"

    xpack_custom_fields="$(echo "${xpack_npm_package_website_config}" | json -o json-0 customFields)"

    if [ -z "${xpack_custom_fields}" ]
    then
      xpack_custom_fields='{}'
    fi
    export xpack_custom_fields

    # Edit the json and add more properties one by one.
    export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
    -e "this.packageWebsiteConfig=${xpack_npm_package_website_config}" \
    )

    export xpack_has_two_numbers_version="$(echo "${xpack_npm_package_website_config}" | json hasTwoNumbersVersion)"

    # if [ "${xpack_custom_fields}" != '{}' ]
    # then
    #   export xpack_dt_has_two_numbers_version="$(echo "${xpack_npm_package_website_config}" | json hasTwoNumbersVersion)"
    #   # export xpack_dt_is_organization_web="$(echo "${xpack_custom_fields}" | json isOrganizationWeb)"

    #   if [ "${xpack_is_organization_web}" == "true" ]
    #   then
    #     xpack_dt_version="0.0.0-0"
    #     xpack_dt_base_url="/"
    #   else
    #     xpack_dt_version="$(cat "${project_folder_path}/build-assets/scripts/VERSION" | sed -e '2,$d')"
    #     xpack_dt_base_url="/${xpack_permalink_name}-xpack/"
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

  # ---------------------------------------------------------------------------

  if [ ! -z ${tests_folder_path+x} ] && [ -f "${tests_folder_path}/package.json" ]
  then

    echo
    echo "Processing tests/package.json..."

    # Tests configuration.
    xpack_npm_package_tests_config="$(json -f "${tests_folder_path}/package.json" -o json-0 testsConfig)"

    if [ -z "${xpack_npm_package_tests_config}" ]
    then
      xpack_npm_package_tests_config="{}"
    fi

    export xpack_has_skip_micro_os_plus_trace="$(echo "${xpack_npm_package_tests_config}" | json skipMICRO_OS_PLUS_TRACE)"

    # Edit the json and add more properties one by one.
    export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
      -e "this.packageTestsConfig=${xpack_npm_package_tests_config}" \
    )
  fi

  # ---------------------------------------------------------------------------

  # Top xpack.
  xpack_platforms=""
  xpack_npm_package_is_xpack="false"
  xpack_npm_package_is_xpack_binary="false"

  xpack_npm_package_xpack="$(json -f "${project_folder_path}/package.json" -o json-0 xpack)"
  if [ -z "${xpack_npm_package_xpack}" ]
  then
    xpack_npm_package_xpack="{}"
  else
    xpack_npm_package_is_xpack="true"

    xpack_npm_package_xpack_binaries="$(json -f "${project_folder_path}/package.json" -o json-0 xpack.binaries)"
    if [ ! -z "${xpack_npm_package_xpack_binaries}" ]
    then
      xpack_npm_package_is_xpack_binary="true"

      # set -x
      xpack_platforms_array=()
      # The order is relevant, it is kept when generating tabs and lists.
      for platform in win32-x64 darwin-x64 darwin-arm64 linux-x64 linux-arm64 linux-arm
      do
        platform_object="$(json -f "${project_folder_path}/package.json" -o json-0 xpack.binaries.platforms.${platform})"
        if [ ! -z "${platform_object}" ]
        then
          skip_value="$(echo "${platform_object}" | json skip)"
          if [ "${skip_value}" == "true" ]
          then
            continue
          fi
          xpack_platforms_array+=("${platform}")
        fi
      done
      set +o nounset # Do not exit if variable not set (empty skip_pages_array).
      xpack_platforms="$(echo "${xpack_platforms_array[@]}" | tr ' ' ',')"
      set -o nounset # Exit if variable not set.
    fi
  fi

  # For top webs, to display the full list of platforms.
  if [ "${xpack_is_organization_web}" == "true" ] && [ -z "${xpack_platforms}" ]
  then
    xpack_platforms="win32-x64,darwin-x64,darwin-arm64,linux-x64,linux-arm64,linux-arm"
  fi

  export xpack_npm_package_xpack
  export xpack_npm_package_is_xpack
  export xpack_npm_package_is_xpack_binary
  export xpack_platforms

  xpack_is_npm_published="false"
  if [ "${xpack_npm_package_is_xpack}" == "true" ] ||
     [ "${xpack_is_typescript}" == "true" ] ||
     [ "${xpack_is_javascript}" == "true" ]
  then
    if [ "${xpack_release_semver}" != "0.0.0" ]
    then
      xpack_is_npm_published="true"
    fi
  fi
  export xpack_is_npm_published

  # Edit the json and add more properties one by one.
  export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
  -e "this.isXpackBinary=\"${xpack_npm_package_is_xpack_binary}\"" \
  -e "this.isXpack=\"${xpack_npm_package_is_xpack}\"" \
  -e "this.isNpmPublished=\"${xpack_is_npm_published}\"" \
  -e "this.platforms=\"${xpack_platforms}\"" \
  )

  # Note the ^ in the regex.
  if [ "${xpack_npm_package_xpack}" != "{}" ] && [[ ! "${xpack_release_semver}" =~ ^0[.]0[.0].*$ ]]
  then
    if [ -f "${project_folder_path}/build-assets/scripts/VERSION" ]
    then
      # Prefer the VERSION content, if available.
      xpack_xpack_version="$(cat "${project_folder_path}/build-assets/scripts/VERSION" | sed -e '2,$d')"
    else
      # Use the package.json one, but remove the `pre` used during development.
      xpack_xpack_version="${xpack_release_version}"
    fi

    xpack_xpack_semver="$(echo "${xpack_xpack_version}" | sed -e 's|[-].*||')"
    xpack_xpack_subversion="$(echo "${xpack_xpack_version}" | sed -e 's|.*[-]||')"

    export xpack_xpack_version
    export xpack_xpack_semver
    export xpack_xpack_subversion

    if [ "${xpack_has_two_numbers_version:-}" == "true" ] && [[ "${xpack_release_semver}" =~ .*[.]0*$ ]]
    then
      # Remove the patch number, if zero.
      xpack_upstream_version="$(echo ${xpack_release_semver} | sed -e 's|[.]0*$||')"
    else
      xpack_upstream_version="${xpack_release_semver}"
    fi
    export xpack_upstream_version

    # Edit the json and add more properties one by one.
    export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
    -e "this.xpackVersion=\"${xpack_xpack_version}\"" \
    -e "this.xpackSemver=\"${xpack_xpack_semver}\"" \
    -e "this.xpackSubversion=\"${xpack_xpack_subversion}\"" \
    -e "this.upstreamVersion=\"${xpack_upstream_version}\"" \
    )

  fi

  # ---------------------------------------------------------------------------

  echo
  echo -n '"xpack_context": '
  echo "${xpack_context}" | json

  echo
  echo "environment variables: "
  echo
  env | egrep '^xpack_' | sort

  echo
}

# -----------------------------------------------------------------------------

# xargs stops only for exit code 255.
function trap_handler()
{
  local message="${1}"
  shift
  local line_number="${1}"
  shift
  local exit_code="${1}"
  shift

  echo "\007 FAIL ${message} line: ${line_number} exit: ${exit_code}"

  if [ $# -ge 1 ]
  then
    rm -rfv "${1}"
  fi

  exit 255
}

function substitute()
{
  local from_relative_file_path="$1" # liquid source
  local to_relative_file_path="$2" # destination
  # $3 - destination absolute folder path

  local to_absolute_file_path="${3}/${to_relative_file_path}"
  mkdir -pv "$(dirname ${to_absolute_file_path})"

  echo "liquidjs -> ${to_relative_file_path}"
  # pwd

  if [ "${do_dry_run}" == "true" ]
  then
    liquidjs --context "${xpack_context}" --template "@${from_relative_file_path}" --output /dev/null --strict-filters --strict-variables --lenient-if
  else
    liquidjs --context "${xpack_context}" --template "@${from_relative_file_path}" --output "${to_absolute_file_path}.new" --strict-filters --strict-variables --lenient-if

    rm -f "${to_absolute_file_path}"
    mv "${to_absolute_file_path}.new" "${to_absolute_file_path}"
  fi
}

function substitute_and_merge()
{
  local from_relative_file_path="$1" # liquid source
  local to_relative_file_path="$2" # destination
  # $3 - destination absolute folder path

  local to_absolute_file_path="${3}/${to_relative_file_path}"
  mkdir -pv "$(dirname ${to_absolute_file_path})"

  echo "liquidjs | merge -> ${to_relative_file_path}"

  if [ "${do_dry_run}" == "true" ]
  then
    liquidjs --context "${xpack_context}" --template "@${from_relative_file_path}" --output /dev/null --strict-filters --strict-variables --lenient-if
  else
    liquidjs --context "${xpack_context}" --template "@${from_relative_file_path}" --output "${tmp_file_path}" --strict-filters --strict-variables --lenient-if

    # json -f "${tmp_file_path}"

    # https://trentm.com/json
    cat "${to_absolute_file_path}" "${tmp_file_path}" | json --deep-merge >"${to_absolute_file_path}.new"

    rm -f "${to_absolute_file_path}"
    mv "${to_absolute_file_path}.new" "${to_absolute_file_path}"
  fi
}

# -----------------------------------------------------------------------------

function process_file() {

  if [ -f "${to_absolute_file_path}" ]
  then
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
    local from_folder_path="${1}"

    cd "${from_folder_path}"

    echo
    echo "----------------------------------------------------------------------------"
    pwd

    # set -x

    name="$(basename "$(pwd)")"

    export project_folder_path="${from_folder_path}"
    export website_folder_path="${from_folder_path}/website"

    export xpack_www_releases="${website_folder_path}/_xpack.github.io/_posts/releases"

    npm_package_name="$(echo "${name}" | sed -e 's|-xpack.git||')"
    export do_force="y"
    if [ ! -d "${xpack_www_releases}/${npm_package_name}" ]
    then
      echo "No ${xpack_www_releases}/${npm_package_name}, nothing to do..."
      return 0
    fi

    export xpack_website_config_short_name="$(json -f "${project_folder_path}/package.json" topConfig.permalinkName)"
    export xpack_website_config_long_name="xPack $(json -f "${project_folder_path}/package.json" topConfig.descriptiveName)"
    export xpack_github_repository_url="$(json -f "${project_folder_path}/package.json" repository.url)"
    export xpack_github_project_organization="$(echo "${xpack_github_repository_url}" | sed -e 's|.*github.com/||' | sed -e 's|/.*||')"

    cd "${xpack_www_releases}/${npm_package_name}"

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
  local destination_folder_path="${1:-"${HOME}/Downloads/xpack-binaries/${xpack_permalink_name}"}"

  local version=${XBB_RELEASE_VERSION:-"${xpack_xpack_version}"}

  (
    rm -rf "${destination_folder_path}-bak"
    if [ -d "${destination_folder_path}" ]
    then
      mv "${destination_folder_path}" "${destination_folder_path}-bak"
    fi

    mkdir -pv "${destination_folder_path}"
    cd "${destination_folder_path}"

    # Extract the xpack.properties platforms. There are also in xpack.binaries.
    local platforms=$(echo "${xpack_platforms}" | sed 's|,| |g')

    IFS=' '
    for platform in ${platforms}
    do

      # echo ${platform}
      # https://github.com/xpack-dev-tools/pre-releases/releases/download/test/xpack-ninja-build-1.11.1-2-win32-x64.zip
      local extension='tar.gz'
      if [ "${platform}" == "win32-x64" ]
      then
        extension='zip'
      fi

      archive_name="xpack-${xpack_permalink_name}-${version}-${platform}.${extension}"
      archive_url="https://github.com/xpack-dev-tools/pre-releases/releases/download/test/${archive_name}"

      run_verbose curl --location --insecure --fail --location --silent \
        --output "${archive_name}" \
        "${archive_url}"

      run_verbose curl --location --insecure --fail --location --silent \
        --output "${archive_name}.sha" \
        "${archive_url}.sha"

    done

    rm -rf "${destination_folder_path}-bak"
  )
}

# -----------------------------------------------------------------------------
