# npm-packages-helper

Common scripts and templates used by xPack node modules and web sites.

## To get the Git

```sh
rm -rf ~/Work/xpack/npm-packages-helper.git && \
mkdir -p ~/Work/xpack && \
git clone \
https://github.com/xpack/npm-packages-helper.git \
~/Work/xpack/npm-packages-helper.git

(cd ~/Work/xpack/npm-packages-helper.git; npm link)
```

```sh
git -C ~/Work/xpack/npm-packages-helper.git pull
```

## Add to xPack Node.js library & CLI projects

```sh
npm init --yes

npm install del-cli json liquidjs --save-dev
npm link @xpack/npm-packages-helper
```

```json
  "scripts": {
    "generate-top-commons-init": "bash node_modules/@xpack/npm-packages-helper/maintenance-scripts/generate-top-commons.sh --init --xpack",
    ...
  }
```

```sh
npm run generate-top-commons-init
```

The file `config/top-templates.json`:

```json
{
  "descriptiveName": "CLI application to convert Doxygen XMLs into Docusaurus docs",
  "permalinkName": "doxygen2docusaurus-ts"
}
```

## Add to micro-os-plus projects

```sh
npm install del-cli json liquidjs --save-dev
npm link @xpack/npm-packages-helper
```

```json
  "scripts": {
    "generate-top-commons-init": "bash node_modules/@xpack/npm-packages-helper/maintenance-scripts/generate-top-commons.sh --init --micro-os-plus",
    ...
  }
```

```sh
npm run generate-top-commons-init
```

The file `config/top-templates.json`:

```json
{
  "descriptiveName": "µTest++ Testing Framework",
  "permalinkName": "micro-test-plus"
}
```

## Getting started

- create the GitHub project
  - name
    - like `logger-ts`, or `xcdl-cli-ts` for Node.js modules
    - like `xpm-preview` for web sites (later to be renamed to `xpm`)
    - like `web-preview`
  - description
    - like 'A Node.js CommonJS/ES6 module with ...'
    - like 'The xPack project manager command line tool' (shown in CLI too)
    - like 'Web site for the xpm web; (preview for now, to be renamed as xpm)'
    - like 'Web site preview for https://micro-os-plus.github.io'
  - public
  - README
  - .gitignore Node
- edit Settings
  - disable Wikis
  - enable Sponsorship
    - ko_fi: ilegeul
  - enable Discussions
  - Pages: GitHub Actions
- edit About
  - enable Use your GitHub Pages website
  - remove Releases, etc
- clone locally into `www`
- open `node-modules.workspace` with TextEdit

## Initialise

```sh
npm init --yes
```

Update license MIT, Copyright (c) 2025-2026 Liviu Ionescu. All rights reserved.

## Update `package.json`

- remove `.git` from name
- check version; possibly make it "0.0.0" for packages not published to npmjs
- add properties to `package.json` (from `repository` on); replace XYZ

```json
{
  "name": "XYZ",
  "version": "0.0.0",
  "description": "Preview for the new xpm web; to be renamed as xpm",
  "main": "",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/xpack/XYZ.git"
  },
  "keywords": [
  ],
  "author": {
    "name": "Liviu Ionescu",
    "email": "ilg@livius.net",
    "url": "https://github.com/ilg-ul"
  },
  "contributors": [],
  "license": "MIT",
  "bugs": {
    "url": "https://github.com/xpack/XYZ/issues"
  },
  "homepage": "https://xpack.github.io/XYZ/",
  "dependencies": {},
  "devDependencies": {},
  "bundleDependencies": [],
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "engines": {
    "node": ">=20.0"
  }
}
```

For CLI project which have a preview site, update homepage.
Not for web deploy only.

```json
  "homepage": "https://xpack.github.io/XYZ-preview/",
  "homepagePreview": "https://xpack.github.io/XYZ-cli-ts/",
```

The file `config/top-templates.json`:

```json
{
  "hasTriggerPublish": "true",
  "isWebPreview": "true"
}
```

The preview sites have a simplified configuration:

```json
{
  "isWebDeployOnly": "true"
}
```

For binary xPacks, define the long project name:

```json
{
  "descriptiveName": "GNU AArch64 Embedded GCC"
}
```

### For binary packages

Add the following:

```json
  "devDependencies": {
    "del-cli": "^6.0.0",
    "json": "^11.0.0",
    "liquidjs": "^10.19.1"
  },
  "scripts": {
    "generate-top-commons": "bash node_modules/@xpack/npm-packages-helper/maintenance-scripts/generate-top-commons.sh --xpack-dev-tools",
    "npm-install": "npm install",
    "npm-link-helpers": "npm link @xpack/npm-packages-helper @xpack/docusaurus-template-liquid",
    "npm-outdated": "npm outdated",
    "npm-pack": "npm pack",
    "npm-link": "npm link",
    "deep-clean": "del-cli node_modules package-lock.json",
    "postversion": "git push origin --all && git push origin --tags"
  },
  "engines": {
    "node": ">=20.0"
  }
```

and get the long name from `build-assets/package.json`
the value of `xpack.properties.appName`.

```json
{
  "descriptiveName": "XYZ"
}
```

Run the `npm-link-helpers` and `generate-top-commons` actions.

### Top dependencies

Install `del-cli`, `json` and `liquidjs`:

```sh
npm install del-cli json liquidjs --save-dev
```

Link the local helper & template projects:

```sh
npm link @xpack/npm-packages-helper @xpack/docusaurus-template-liquid
```

### Top custom configurations

For the top web project, add to top `package.json`:

```json
  "version": "0.0.0",
  "homepagePreview": ".../web-preview/",
```

```json
{
  "descriptiveName": "The µOS++ Framework",
  "isOrganisationWeb": "true",
  "hasTriggerPublishPreview": "true",
  "hasEmptyMaster": "true"
}
```

### Web deployment only

For Web deployment only projects (`xpm`, `xcdl`)

- create Git project
- run npm init, install deps,
- add generate-top-commons-init script
- add isWebDeployOnly

```json
{
  "descriptiveName": "xxx website",
  "isWebDeployOnly": "true"
}
```

- run generate-top-commons-init
- add topConfig again
- run generate-top-commons

In the main project:

- add a webpreview branch
- Pages use Actions
- edit Environment to it
- add:

```json
  "homepage": "https://xpack.github.io/xpm/",
  "homepagePreview": "https://xpack.github.io/xpm-js/",
```

```json
{
  "hasTriggerPublish": "true",
  "isWebPreview": "true"
}
```

### Web preview only

For Web preview only projects (`web-preview`), add:

```json
{
  "isWebPreview": "true"
}
```

### Top scripts

Add two scripts to top `package.json` (remove dummy `test`).

For Web deployment only projects, the second is not necessary.

```json
    "generate-top-commons-init": "bash -x node_modules/@xpack/npm-packages-helper/maintenance-scripts/generate-top-commons.sh --init --xpack",
    "create-website-init": "bash -x node_modules/@xpack/docusaurus-template-liquid/maintenance-scripts/generate-commons.sh --micro-os-plus --init",
```

Run them. For Web deployment only projects, the second is not necessary.

```sh
npm run generate-top-commons-init
npm run create-website-init
```

Run the new `generate-top-commons` script.

When no longer needed:

- remove script `generate-top-commons-init`

## Website custom configurations

See the `README` file in `docusaurus-template-liquid.git` for details.

### Run actions once

In `website`:

```sh
npm install
npm run link-helpers
```

Update the `websiteConfig` and generate commons:

```sh
npm run generate-website-commons
```

### Example

The top `xpack.github.io` project:

```json
"xpack_context": {
  "hasFolderWebsitePackage": true,
  "hasFolderBuildAssetsPackage": false,
  "hasFolderTestsPackage": false,
  "hasBranchMaster": true,
  "hasBranchDevelopment": false,
  "hasBranchXpack": false,
  "hasBranchXpackDevelopment": false,
  "hasBranchWebsite": true,
  "hasBranchWebpreview": true,
  "branchDevelopment": "webpreview",
  "branchWebsite": "website",
  "branchWebpreview": "webpreview",
  "branchMain": "website",
  "releaseDate": "2026-05-21 12:55:07 +0300",
  "packageScopedName": "xpack.github.io",
  "packageScope": "",
  "packageName": "xpack.github.io",
  "packageVersion": "0.0.0",
  "packageType": "",
  "packageDescription": "The website for the xPack project",
  "releaseVersion": "0.0.0",
  "releaseSemver": "0.0.0",
  "releaseSubversion": "",
  "releaseNpmSubversion": "",
  "repositoryUrl": "https://github.com/xpack/xpack.github.io.git",
  "githubProjectOrganization": "xpack",
  "githubProjectName": "xpack.github.io",
  "isNpmExecutable": false,
  "packageEnginesNodeVersion": "20.0",
  "packageEnginesNodeVersionMajor": "20",
  "packageDependenciesTypescriptVersion": "",
  "packageHomepage": "https://xpack.github.io/",
  "packageHomepagePreview": "https://xpack.github.io/web-preview/",
  "packageKeywords": [
    "www",
    "website",
    "xpack"
  ],
  "topConfig": {
    "descriptiveName": "xPack Project",
    "permalinkName": "",
    "preferredName": "xPack Project",
    "programName": "",
    "hasCli": false,
    "hasEmptyMaster": true,
    "hasNoGithubReleases": false,
    "hasObjectLibrary": false,
    "hasTestAll": false,
    "hasTriggerPublish": false,
    "hasTriggerPublishPreview": true,
    "hasWebsite": true,
    "isJavascript": false,
    "isOrganisationWeb": true,
    "isTypescript": false,
    "isWebDeployOnly": false,
    "isWebPreview": false,
    "preferShortName": false,
    "showTestsResults": false,
    "skipCiTests": false,
    "testCoverage": false,
    "useApiExtractor": false,
    "useDoxygen": false,
    "useEslint": false,
    "usePrettier": false,
    "useSelfHostedRunners": false,
    "useStandard": false,
    "useTap": false,
    "useTypescriptEslint": false
  },
  "longXpackName": "xPack Project",
  "baseUrl": "/",
  "baseUrlPreview": "/web-preview/",
  "isXpack": false,
  "isXpackBinary": false,
  "platforms": "win32-x64,darwin-x64,darwin-arm64,linux-x64,linux-arm64",
  "isNpmPublished": false
}
```

## Cleanups

When no longer needed:

- Remove script `generate-top-commons-init`
- Remove script `create-website-init`.

### Variable

#### Objects

- `packageConfig` (see below)
- `packageBuildConfig` (avoid, to be migrated to websiteConfig)
- `websiteConfig` (see `docusaurus-template-liquid`)

#### In `topConfig` (from `top-templates.json`)

Strings:

- `descriptiveName`: the multi word name, without _the_; used in page titles
- `permalinkName`
- `preferredName`
- `programName`
- `upstreamDescriptiveName`

Arrays of strings:

- `githubActionsNodeVersions`
- `githubActionsOses` 
- `githubActionsXpmVersions`

Booleans (`true`/`false`):

- `hasCli` 
- `hasEmptyMaster`
- `hasNoGithubReleases` 
- `hasObjectLibrary`
- `hasTestAll` 
- `hasTriggerPublish` 
- `hasTriggerPublishPreview` 
- `hasWebsite`
- `isJavascript`
- `isOrganisationWeb` 
- `isTypescript`
- `isWebDeployOnly`
- `isWebPreview`
- `preferShortName` 
- `showTestsResults` 
- `skipCiTests` 
- `testCoverage`
- `useApiExtractor`
- `useDoxygen`
- `useEslint`
- `usePrettier`
- `useSelfHostedRunners`
- `useStandard`
- `useTap`
- `useTypescriptEslint`


#### From top folder & package.json

Booleans (`true`/`false`):

- `hasFolderWebsitePackage`
- `hasFolderBuildAssetsPackage`
- `hasBranchMaster`
- `hasBranchDevelopment`
- `hasBranchXpackDevelopment`
- `hasBranchWebsite`
- `hasBranchWebpreview`
- `isTypescript`
- `isJavascript`

Miscellaneous

- `branchWebsite`
- `branchWebpreview`
- `releaseDate`
- `packageScopedName`
- `packageScope`
- `packageName`
- `packageVersion`
- `releaseVersion`
- `packageDescription`
- `githubProjectOrganization`
- `githubProjectName`
- `packageEnginesNodeVersion`
- `packageEnginesNodeVersionMajor`
- `packageDependenciesTypescriptVersion`
- `packageHomepage`
- `packageHomepagePreview`
- `baseUrl`
- `baseUrlPreview`

## Example

```
"xpack_context": {
  "hasFolderWebsitePackage": "true",
  "hasFolderBuildAssetsPackage": "false",
  "hasFolderTestsPackage": "false",
  "hasBranchMaster": "true",
  "hasBranchDevelopment": "true",
  "hasBranchXpackDevelopment": "false",
  "hasBranchWebsite": "true",
  "hasBranchWebpreview": "false",
  "branchMain": "master",
  "branchDevelopment": "development",
  "branchWebsite": "website",
  "branchWebpreview": "development",
  "releaseDate": "2025-08-03 11:35:13 +0300",
  "packageScopedName": "@xpack/doxygen2docusaurus",
  "packageScope": "xpack",
  "packageName": "doxygen2docusaurus",
  "packageVersion": "1.0.2",
  "releaseVersion": "1.0.2",
  "releaseSemver": "1.0.2",
  "releaseSubversion": "",
  "releaseNpmSubversion": "",
  "packageDescription": "A Node.js CLI application to convert Doxygen XML files into Docusaurus documentation",
  "repositoryUrl": "https://github.com/xpack/doxygen2docusaurus-cli-ts.git",
  "githubProjectOrganization": "xpack",
  "githubProjectName": "doxygen2docusaurus-cli-ts",
  "packageKeywords": [
    "docusaurus",
    "doxygen",
    "cli"
  ],
  "isTypescript": "true",
  "isJavascript": "false",
  "isNpmExecutable": "true",
  "packageEnginesNodeVersion": "20.0.0",
  "packageEnginesNodeVersionMajor": "20",
  "packageDependenciesTypescriptVersion": "5.8.3",
  "packageHomepage": "https://xpack.github.io/doxygen2docusaurus-cli-ts/",
  "packageHomepagePreview": "https://xpack.github.io/doxygen2docusaurus-cli-ts/",
  "usePrettier": "true",
  "useTypescriptEslint": "true",
  "useApiExtractor": "true",
  "package": {
    ...
  },
  "topConfig": {
    "descriptiveName": "doxygen2docusaurus",
    "permalinkName": "doxygen2docusaurus",
    "skipCiTests": "true",
    "hasCli": "true",
    "useEslint": "true"
  },
  "longXpackName": "doxygen2docusaurus",
  "baseUrl": "/doxygen2docusaurus-cli-ts/",
  "baseUrlPreview": "/doxygen2docusaurus-cli-ts/",
  "showTestsResults": "",
  "packageBuildConfig": {},
  "websiteConfig": {
    "title": "doxygen2docusaurus - Doxygen Documentation Converter",
    "tagline": "A Node.js CLI application to convert Doxygen XML files into Docusaurus documentation",
    "hasCustomHomepageFeatures": "true",
    "hasTSDocDocusaurusApi": "true",
    "skipTests": "true",
    "preferShortName": "true",
    "nodeVersion": "20.18.0"
  },
  "isXpackBinary": "false",
  "isXpack": "false",
  "isNpmPublished": "true",
  "platforms": ""
}
```

## Config names summary

logger-ts
    -"packageScopedName": "@xpack/logger"
    "descriptiveName": "xPack Logger"

mock-console-ts
    -"packageScopedName": "@xpack/mock-console"
    "descriptiveName": "xPack Mock Console"

xpm-js
    -"packageScopedName": "xpm"
    "descriptiveName": "xPack Project Manager",
    "permalinkName": "xpm", <--- (without -js)
    "preferShortName": "true",

    web
    "programName": "xpm",

xcdl-cli-ts
    -"packageScopedName": "xcdl"
    "descriptiveName": "xPack Component Manager",
    "permalinkName": "xcdl" <--- (without -cli-ts)
    "preferShortName": "true",

    web
    "programName": "xcdl",

doxygen2docusaurus-cli-ts
    -"packageScopedName": "@xpack/doxygen2docusaurus"
    "descriptiveName": "Doxygen Documentation Converter",
    "permalinkName": "doxygen2docusaurus", <--- (without -cli-ts)
    "preferShortName": "true",

    web
    "programName": "doxygen2docusaurus",

xpack.github.io
    "descriptiveName": "xPack Project",
    "isOrganisationWeb": "true",
    "hasTriggerPublishPreview": "true",
    "hasEmptyMaster": "true"

web-preview
    "isWebDeployOnly": "true",
    "isWebPreview": "true"

xpm
    "isWebDeployOnly": "true"

xcdl
    "isWebDeployOnly": "true"

---

aarch64-none-elf-gcc
    -"packageScopedName": "@xpack-dev-tools/aarch64-none-elf-gcc"
    "descriptiveName": "xPack GNU AArch64 Embedded GCC",
    "upstreamDescriptiveName": "GNU AArch64 Embedded GCC",
    "permalinkName": "aarch64-none-elf-gcc",
    "useSelfHostedRunners": "true"

    web
    "programName": "aarch64-none-elf-gcc",

m4
    "descriptiveName": "xPack GNU M4",
    "upstreamDescriptiveName": "GNU M4",
    "permalinkName": "m4",
    "skipCiTests": "true",
    "useSelfHostedRunners": "false"

...

xpack-build-box
    "descriptiveName": "xPack Build Box",
    "permalinkName": "xbb"

xpack-dev-tools.github.io
    "descriptiveName": "Binary Development Tools",
    "permalinkName": "xpack-dev-tools.github.io",
    "isOrganisationWeb": "true",
    "hasTriggerPublishPreview": "true",
    "hasEmptyMaster": "true"

web-preview
    "isWebDeployOnly": "true",
    "isWebPreview": "true"

---

micro-test-plus-xpack
    -"packageScopedName": "@micro-os-plus/micro-test-plus"
    "descriptiveName": "µTest++ Testing Framework",
    "permalinkName": "micro-test-plus",

utils-lists-xpack
    -"packageScopedName": "@micro-os-plus/utils-lists"
    "descriptiveName": "µOS++ Intrusive Lists",
    "permalinkName": "utils-lists",
