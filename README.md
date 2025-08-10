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

Add top config before engines:

```json
  ...
  "topConfig": {
    "descriptiveName": "CLI application to convert Doxygen XMLs into Docusaurus docs",
    "permalinkName": "doxygen2docusaurus-ts"
  },
  "engines": {
    "node": " >=20.0.0"
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

```json
  ...
  "topConfig": {
    "descriptiveName": "µTest++ Testing Framework",
    "permalinkName": "micro-test-plus",
    "useDoxygen": "true"
  },
  "engines": {
    "node": " >=18.0.0"
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

Update license MIT, Copyright (c) 2025 Liviu Ionescu. All rights reserved.

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
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
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
  "topConfig": {},
  "engines": {
    "node": " >=18.0.0"
  }
}
```

For CLI project which have a preview site, update homepage.
Not for web deploy only.

```json
  "homepage": "https://xpack.github.io/XYZ-preview/",
  "homepagePreview": "https://xpack.github.io/XYZ-cli-ts/",
  ...
  "topConfig": {
    "hasTriggerPublish": "true",
    "isWebPreview": "true"
  }
```

The preview sites have a simplified configuration:

```json
  "topConfig": {
    "isWebDeployOnly": "true"
  },
  "engines": {
    "node": " >=18.0.0"
  }
```

For binary xPacks, define the long project name:

```json
  "topConfig": {
    "descriptiveName": "GNU AArch64 Embedded GCC"
  },
```

### For binary packages

Add the following:

```json
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
  "devDependencies": {
    "del-cli": "^6.0.0",
    "json": "^11.0.0",
    "liquidjs": "^10.19.1"
  },
  "topConfig": {
    "descriptiveName": "XYZ"
  },
```

and get the long name from `build-assets/package.json`
the value of `xpack.properties.appName`.

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
  ...
  "topConfig": {
    "descriptiveName": "The µOS++ Framework",
    "isOrganizationWeb": "true",
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
  "topConfig": {
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

```
  "homepage": "https://xpack.github.io/xpm/",
  "homepagePreview": "https://xpack.github.io/xpm-js/",

  "topConfig": {
    "hasTriggerPublish": "true",
    "isWebPreview": "true"
  }
```

### Web preview only

For Web preview only projects (`web-preview`), add:

```json
  "topConfig": {
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

```sh
"xpack_context": {
  "packageScopedName": "xpack.github.io",
  "packageScope": "",
  "packageName": "xpack.github.io",
  "packageVersion": "0.0.0",
  "releaseVersion": "0.0.0",
  "packageDescription": "The website for the xPack project",
  "githubProjectOrganization": "xpack",
  "githubProjectName": "xpack.github.io",
  "isTypeScript": "false",
  "isJavaScript": "false",
  "skipCiTests": "true",
  "hasBranchMaster": "true",
  "hasBranchDevelopment": "true",
  "hasBranchWebsite": "false",
  "hasBranchWebpreview": "false",
  "branchWebsite": "master",
  "branchWebpreview": "development",
  "packageEnginesNodeVersion": "18.0.0",
  "packageEnginesNodeVersionMajor": "18",
  "packageDependenciesTypescriptVersion": "",
  "packageHomepage": "https://xpack.github.io/",
  "baseUrl": "/",
  "packageHomepagePreview": "https://xpack.github.io/web-preview/",
  "baseUrlPreview": "/web-preview/",
  "releaseDate": "2025-01-06 21:19:55 +0200",
  "packageConfig": {
    "isOrganizationWeb": "true",
    "skipCiTests": "true",
    "hasTriggerPublishPreview": "true"
  },
  "packageBuildConfig": {},
  "packageWebsiteConfig": {
    "descriptiveName": "xPack Project",
    "title": "The xPack Reproducible Build Framework",
    "tagline": "Tools to manage, configure and build complex, package based, multi-target projects, in a reproducible way",
    "metadataDescription": "The xPack Framework",
    "metadataKeywords": "xpack, project, manage, build, test, dependencies, xpm, npm, reproducibility",
    "nodeVersion": "18.20.4",
    "hasCustomSidebar": "true",
    "hasCustomDocsNavbarItem": "true",
    "hasCustomDeveloper": "true",
    "hasCustomGettingStarted": "true",
    "hasCustomMaintainer": "true",
    "hasCustomAbout": "true",
    "skipInstallCommand": "true",
    "hasCustomHomepageFeatures": "true"
  }
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
- `packageWebsiteConfig` (see `docusaurus-template-liquid`)

#### In `packageConfig` (from `topConfig`)

Booleans (`true`/`false`):

- `isOrganizationWeb`
- `isWebDeployOnly`
- `skipCiTests`
- `showTestsResults`
- `hasTriggerPublish`
- `hasTriggerPublishPreview`
- `hasEmptyMaster`

Miscellaneous:

- `descriptiveName`: the multi word name, without _the_; used in page titles

#### From top folder & package.json

Booleans (`true`/`false`):

- `hasFolderWebsitePackage`
- `hasFolderBuildAssetsPackage`
- `hasBranchMaster`
- `hasBranchDevelopment`
- `hasBranchXpackDevelopment`
- `hasBranchWebsite`
- `hasBranchWebpreview`
- `hasWebsiteFolder`
- `isTypeScript`
- `isJavaScript`

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
  "hasWebsiteFolder": "true",
  "isTypeScript": "true",
  "isJavaScript": "false",
  "isNpmBinary": "true",
  "packageEnginesNodeVersion": "20.0.0",
  "packageEnginesNodeVersionMajor": "20",
  "packageDependenciesTypescriptVersion": "5.8.3",
  "packageHomepage": "https://xpack.github.io/doxygen2docusaurus-cli-ts/",
  "packageHomepagePreview": "https://xpack.github.io/doxygen2docusaurus-cli-ts/",
  "packageUsePrettier": "true",
  "packageUseTypeScriptEslint": "true",
  "packageUseApiExtractor": "true",
  "package": {
    ...
  },
  "packageConfig": {
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
  "packageWebsiteConfig": {
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
    "isOrganizationWeb": "true",
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

    web
    "programName": "aarch64-none-elf-gcc",

...

xpack-build-box
    "descriptiveName": "xPack Build Box",
    "permalinkName": "xbb"

xpack-dev-tools.github.io
    "descriptiveName": "Binary Development Tools",
    "permalinkName": "xpack-dev-tools.github.io",
    "isOrganizationWeb": "true",
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
