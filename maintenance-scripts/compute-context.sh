# Included in generate-common.sh & co.
# Requires project_folder_path.
# Sets context and a lot of other variables.

# set -x

# https://trentm.com/json/
export npm_package_scoped_name="$(json -f "${project_folder_path}/package.json" name)"

if echo "${npm_package_scoped_name}" | egrep -e '^@' >/dev/null
then
  export npm_package_scope="$(echo "${npm_package_scoped_name}" | sed -e 's|^@||' -e 's|/.*||' )"
else
  export npm_package_scope=""
fi

export npm_package_name="$(echo "${npm_package_scoped_name}" | sed -e 's|^@[a-zA-Z0-9-]*/||')"
export npm_package_version="$(json -f "${project_folder_path}/package.json" version)"
export npm_package_description="$(json -f "${project_folder_path}/package.json" description)"
export npm_package_homepage="$(json -f "${project_folder_path}/package.json" homepage)"
npm_package_homepage_preview="$(json -f "${project_folder_path}/package.json" homepagePreview)"
if [ -z "${npm_package_homepage_preview}" ]
then
  npm_package_homepage_preview="${npm_package_homepage}"
fi
export npm_package_homepage_preview

export base_url="/$(basename "${npm_package_homepage}")/"
export base_url_preview="/$(basename "${npm_package_homepage_preview}")/"

export release_version="$(echo "${npm_package_version}" | sed -e 's|[-].*||')"

github_full_name="$(json -f "${project_folder_path}/package.json"  repository.url | sed -e 's|^https://github.com/||' -e 's|^git+https://github.com/||' -e 's|[.]git$||')"

export github_project_organization="$(echo "${github_full_name}" | sed -e 's|/.*||')"
export github_project_name="$(echo "${github_full_name}" | sed -e 's|.*/||')"

if [[ ${github_project_name} == *-ts ]]
then
  is_typescript="true"
else
  is_typescript="false"
fi
export is_typescript

if [[ ${github_project_name} == *-js ]]
then
  is_javascript="true"
else
  is_javascript="false"
fi
export is_javascript

export npm_package_engines_node_version="$(json -f "${project_folder_path}/package.json" engines.node | sed -e 's|[^0-9]*||')"
export npm_package_engines_node_version_major="$(echo "${npm_package_engines_node_version}" | sed -e 's|[.].*||')"

export npm_package_dependencies_typescript_version="$(json -f "${project_folder_path}/package.json" devDependencies.typescript | sed -e 's|[^0-9]*||')"

export release_date="$(date '+%Y-%m-%d %H:%M:%S %z')"

# Top configuration.
npm_package_config="$(json -f "${project_folder_path}/package.json" -o json-0 config)"
if [ -z "${npm_package_config}" ]
then
  npm_package_config="{}"
  is_organization_web="false"
  is_web_deploy_only="false"
else
  is_organization_web="$(echo "${npm_package_config}" | json isOrganizationWeb)"
  is_web_deploy_only="$(echo "${npm_package_config}" | json isWebDeployOnly)"
fi
export npm_package_config
export is_organization_web
export is_web_deploy_only

# Build configuration, in the top. (perhaps move to build-assets?)
npm_package_build_config="$(json -f "${project_folder_path}/package.json" -o json-0 buildConfig)"
if [ -z "${npm_package_build_config}" ]
then
  npm_package_build_config="{}"
fi
export npm_package_build_config

# Web site configuration. Prefer the one in the dedicated folder to the top.
if [ ! -z "${website_folder_path:-""}" ] && [ -f "${website_folder_path}/package.json" ]
then
  npm_package_website_config="$(json -f "${website_folder_path}/package.json" -o json-0 websiteConfig)"
else
  npm_package_website_config="$(json -f "${project_folder_path}/package.json" -o json-0 websiteConfig)"
fi

if [ -z "${npm_package_website_config}" ]
then
  if [ "${do_init}" == "true" ] || [ "${is_web_deploy_only}" == "true" ]
  then
    npm_package_website_config="{}"
  else
    echo "Missing websiteConfig"
    exit 1
  fi
fi

export npm_package_website_config

export website_config_short_name="$(echo "${npm_package_website_config}" | json shortName)"
export website_config_long_name="$(echo "${npm_package_website_config}" | json longName)"

# Edit the empty json and add properties one by one.
export context=$(echo '{}' | json -o json-0 \
-e "this.packageScopedName=\"${npm_package_scoped_name}\"" \
-e "this.packageScope=\"${npm_package_scope}\"" \
-e "this.packageName=\"${npm_package_name}\"" \
-e "this.packageVersion=\"${npm_package_version}\"" \
-e "this.releaseVersion=\"${release_version}\"" \
-e "this.packageDescription=\"${npm_package_description}\"" \
-e "this.githubProjectOrganization=\"${github_project_organization}\"" \
-e "this.githubProjectName=\"${github_project_name}\"" \
-e "this.isTypeScript=\"${is_typescript}\"" \
-e "this.isJavaScript=\"${is_javascript}\"" \
-e "this.packageEnginesNodeVersion=\"${npm_package_engines_node_version}\"" \
-e "this.packageEnginesNodeVersionMajor=\"${npm_package_engines_node_version_major}\"" \
-e "this.packageDependenciesTypescriptVersion=\"${npm_package_dependencies_typescript_version}\"" \
-e "this.packageHomepage=\"${npm_package_homepage}\"" \
-e "this.baseUrl=\"${base_url}\"" \
-e "this.packageHomepagePreview=\"${npm_package_homepage_preview}\"" \
-e "this.baseUrlPreview=\"${base_url_preview}\"" \
-e "this.releaseDate=\"${release_date}\"" \
-e "this.packageConfig=${npm_package_config}" \
-e "this.packageBuildConfig=${npm_package_build_config}" \
-e "this.packageWebsiteConfig=${npm_package_website_config}" \
)

echo -n '"context": '
echo "${context}" | json
