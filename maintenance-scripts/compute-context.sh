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

export base_url="/$(basename "${npm_package_homepage}")/"

export release_version="$(echo "${npm_package_version}" | sed -e 's|[-].*||')"

github_full_name="$(json -f "${project_folder_path}/package.json"  repository.url | sed -e 's|^https://github.com/||' -e 's|^git+https://github.com/||' -e 's|[.]git$||')"

export github_project_organization="$(echo "${github_full_name}" | sed -e 's|/.*||')"
export github_project_name="$(echo "${github_full_name}" | sed -e 's|.*/||')"


export npm_package_engines_node_version="$(json -f "${project_folder_path}/package.json" engines.node | sed -e 's|[^0-9]*||')"
export npm_package_engines_node_version_major="$(echo "${npm_package_engines_node_version}" | sed -e 's|[.].*||')"

export npm_package_dependencies_typescript_version="$(json -f "${project_folder_path}/package.json" devDependencies.typescript | sed -e 's|[^0-9]*||')"

export release_date="$(date '+%Y-%m-%d %H:%M:%S %z')"

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
  export npm_package_website_config="$(json -f "${website_folder_path}/package.json" -o json-0 websiteConfig)"
else
  export npm_package_website_config="$(json -f "${project_folder_path}/package.json" -o json-0 websiteConfig)"
fi

if [ -z "${npm_package_website_config}" ]
then
  echo "Missing websiteConfig"
  exit 1
fi

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
-e "this.packageEnginesNodeVersion=\"${npm_package_engines_node_version}\"" \
-e "this.packageEnginesNodeVersionMajor=\"${npm_package_engines_node_version_major}\"" \
-e "this.packageDependenciesTypescriptVersion=\"${npm_package_dependencies_typescript_version}\"" \
-e "this.packageHomepage=\"${npm_package_homepage}\"" \
-e "this.baseUrl=\"${base_url}\"" \
-e "this.releaseDate=\"${release_date}\"" \
-e "this.packageBuildConfig=${npm_package_build_config}" \
-e "this.packageWebsiteConfig=${npm_package_website_config}" \
)

echo -n "context="
echo "${context}" | json
