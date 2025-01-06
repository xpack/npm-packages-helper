# Included in generate-common.sh & co.
# Requires project_folder_path.
# Sets xpack_context and a lot of other variables.

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

echo
echo "Processing package.json from ${project_folder_path}..."

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
export xpack_npm_package_homepage="$(json -f "${project_folder_path}/package.json" homepage)"
xpack_npm_package_homepage_preview="$(json -f "${project_folder_path}/package.json" homepagePreview)"
if [ -z "${xpack_npm_package_homepage_preview}" ]
then
  xpack_npm_package_homepage_preview="${xpack_npm_package_homepage}"
fi
export xpack_npm_package_homepage_preview

export xpack_release_version="$(echo "${xpack_npm_package_version}" | sed -e 's|[-].*||')"

xpack_github_full_name="$(json -f "${project_folder_path}/package.json"  repository.url | sed -e 's|^https://github.com/||' -e 's|^git+https://github.com/||' -e 's|[.]git$||')"

export xpack_github_project_organization="$(echo "${xpack_github_full_name}" | sed -e 's|/.*||')"
export xpack_github_project_name="$(echo "${xpack_github_full_name}" | sed -e 's|/$||' -e 's|.git$||' -e 's|.*/||')"

if [[ ${xpack_github_project_name} == *-ts ]]
then
  xpack_is_typescript="true"
else
  xpack_is_typescript="false"
fi
export xpack_is_typescript

if [[ ${xpack_github_project_name} == *-js ]]
then
  xpack_is_javascript="true"
else
  xpack_is_javascript="false"
fi
export xpack_is_javascript

export xpack_npm_package_engines_node_version="$(json -f "${project_folder_path}/package.json" engines.node | sed -e 's|[^0-9]*||')"
export xpack_npm_package_engines_node_version_major="$(echo "${xpack_npm_package_engines_node_version}" | sed -e 's|[.].*||')"

export xpack_npm_package_dependencies_typescript_version="$(json -f "${project_folder_path}/package.json" devDependencies.typescript | sed -e 's|[^0-9]*||')"

export xpack_release_date="$(date '+%Y-%m-%d %H:%M:%S %z')"

# -----------------------------------------------------------------------------

# Top configuration.
xpack_npm_package_config="$(json -f "${project_folder_path}/package.json" -o json-0 config)"
if [ -z "${xpack_npm_package_config}" ]
then
  xpack_npm_package_config="{}"
  xpack_is_organization_web="false"
  xpack_is_web_deploy_only="false"
  xpack_skip_tests="false"
  xpack_is_not_npm_module="false"
  xpack_has_trigger_publish="false"
  xpack_has_trigger_publish_preview="false"
else
  xpack_is_organization_web="$(echo "${xpack_npm_package_config}" | json isOrganizationWeb)"
  xpack_is_web_deploy_only="$(echo "${xpack_npm_package_config}" | json isWebDeployOnly)"
  xpack_skip_tests="$(echo "${xpack_npm_package_config}" | json skipTests)"
  xpack_is_not_npm_module="$(echo "${xpack_npm_package_config}" | json isNotNpmModule)"
  xpack_has_trigger_publish="$(echo "${xpack_npm_package_config}" | json hasTriggerPublish)"
  xpack_has_trigger_publish_preview="$(echo "${xpack_npm_package_config}" | json hasTriggerPublishPreview)"
fi
export xpack_npm_package_config
export xpack_is_organization_web
export xpack_is_web_deploy_only
export xpack_skip_tests
export xpack_is_not_npm_module
export xpack_has_trigger_publish
export xpack_has_trigger_publish_preview

xpack_has_branch_master="false"
xpack_has_branch_development="false"
xpack_has_branch_website="false"
xpack_has_branch_webpreview="false"

if (git branch | grep master) >/dev/null
then
  xpack_has_branch_master="true"
fi
if (git branch | grep development) >/dev/null
then
  xpack_has_branch_development="true"
fi
if (git branch | grep website) >/dev/null
then
  xpack_has_branch_website="true"
fi
if (git branch | grep webpreview) >/dev/null
then
  xpack_has_branch_webpreview="true"
fi

export xpack_has_branch_master
export xpack_has_branch_development
export xpack_has_branch_website
export xpack_has_branch_webpreview

if [ "${xpack_has_branch_website}" == "true" ]
then
  xpack_website_branch="website"
elif [ "${xpack_has_branch_master}" == "true" ]
then
  xpack_website_branch="master"
else
  echo "Branch?"
  exit 1
fi
export xpack_website_branch

if [ "${xpack_has_branch_webpreview}" == "true" ]
then
  xpack_website_branch_preview="webpreview"
elif [ "${xpack_has_branch_development}" == "true" ]
then
  xpack_website_branch_preview="development"
elif [ "${xpack_has_branch_master}" == "true" ]
then
  xpack_website_branch_preview="master"
else
  echo "Branch preview?"
  exit 1
fi
export xpack_website_branch_preview

# -----------------------------------------------------------------------------

# Build configuration, in the top. (perhaps move to build-assets?)
xpack_npm_package_build_config="$(json -f "${project_folder_path}/package.json" -o json-0 buildConfig)"
if [ -z "${xpack_npm_package_build_config}" ]
then
  xpack_npm_package_build_config="{}"
fi
export xpack_npm_package_build_config

# Edit the empty json and add properties one by one.
export xpack_context=$(echo '{}' | json -o json-0 \
-e "this.packageScopedName=\"${xpack_npm_package_scoped_name}\"" \
-e "this.packageScope=\"${xpack_npm_package_scope}\"" \
-e "this.packageName=\"${xpack_npm_package_name}\"" \
-e "this.packageVersion=\"${xpack_npm_package_version}\"" \
-e "this.releaseVersion=\"${xpack_release_version}\"" \
-e "this.packageDescription=\"${xpack_npm_package_description}\"" \
-e "this.githubProjectOrganization=\"${xpack_github_project_organization}\"" \
-e "this.githubProjectName=\"${xpack_github_project_name}\"" \
-e "this.isTypeScript=\"${xpack_is_typescript}\"" \
-e "this.isJavaScript=\"${xpack_is_javascript}\"" \
-e "this.skipTests=\"${xpack_skip_tests}\"" \
-e "this.hasBranchMaster=\"${xpack_has_branch_master}\"" \
-e "this.hasBranchDevelopment=\"${xpack_has_branch_development}\"" \
-e "this.hasBranchWebsite=\"${xpack_has_branch_website}\"" \
-e "this.hasBranchWebpreview=\"${xpack_has_branch_webpreview}\"" \
-e "this.websiteBranch=\"${xpack_website_branch}\"" \
-e "this.websiteBranchPreview=\"${xpack_website_branch_preview}\"" \
-e "this.packageEnginesNodeVersion=\"${xpack_npm_package_engines_node_version}\"" \
-e "this.packageEnginesNodeVersionMajor=\"${xpack_npm_package_engines_node_version_major}\"" \
-e "this.packageDependenciesTypescriptVersion=\"${xpack_npm_package_dependencies_typescript_version}\"" \
-e "this.packageHomepage=\"${xpack_npm_package_homepage}\"" \
-e "this.packageHomepagePreview=\"${xpack_npm_package_homepage_preview}\"" \
-e "this.releaseDate=\"${xpack_release_date}\"" \
-e "this.packageConfig=${xpack_npm_package_config}" \
-e "this.packageBuildConfig=${xpack_npm_package_build_config}" \
)

# -----------------------------------------------------------------------------

if [ -f "${website_folder_path}/package.json" ]
then

  echo
  echo "Processing package.json from ${website_folder_path}..."

  # Web site configuration. Prefer the one in the dedicated folder to the top.
  if [ ! -z "${website_folder_path:-""}" ] && [ -f "${website_folder_path}/package.json" ]
  then
    xpack_npm_package_website_config="$(json -f "${website_folder_path}/package.json" -o json-0 websiteConfig)"
  else
    xpack_npm_package_website_config="$(json -f "${project_folder_path}/package.json" -o json-0 websiteConfig)"
  fi

  if [ -z "${xpack_npm_package_website_config}" ]
  then
    if [ "${do_init}" == "true" ] || [ "${xpack_is_web_deploy_only}" == "true" ]
    then
      xpack_npm_package_website_config="{}"
    else
      echo "Missing websiteConfig"
      exit 1
    fi
  fi

  export xpack_has_metadata_minimum="$(echo "${xpack_npm_package_website_config}" | json hasMetadataMinimum)"
  export xpack_has_custom_homepage_features="$(echo "${xpack_npm_package_website_config}" | json hasCustomHomepageFeatures)"
  export xpack_has_top_homepage_features="$(echo "${xpack_npm_package_website_config}" | json hasTopHomepageFeatures)"
  export xpack_has_cli="$(echo "${xpack_npm_package_website_config}" | json hasCli)"
  export xpack_has_policies="$(echo "${xpack_npm_package_website_config}" | json hasPolicies)"
  export xpack_skip_install_command="$(echo "${xpack_npm_package_website_config}" | json skipInstallCommand)"
  export xpack_skip_contributor_guide="$(echo "${xpack_npm_package_website_config}" | json skipContributorGuide)"
  export xpack_website_config_short_name="$(echo "${xpack_npm_package_website_config}" | json shortName)"
  export xpack_website_config_long_name="$(echo "${xpack_npm_package_website_config}" | json longName)"

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

  # Edit the json and add more properties one by one.
  export xpack_context=$(echo "${xpack_context}" | json -o json-0 \
  -e "this.baseUrl=\"${xpack_base_url}\"" \
  -e "this.baseUrlPreview=\"${xpack_base_url_preview}\"" \
  -e "this.packageWebsiteConfig=${xpack_npm_package_website_config}" \
  )

fi

echo
echo -n '"xpack_context": '
echo "${xpack_context}" | json

echo
echo "environment: "
echo
env | egrep '^xpack_' | sort

echo
