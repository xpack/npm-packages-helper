# npm-packages-helper

Common scripts and templates used by xPack node modules and web sites.

## Getting started

- create the GitHub project
  - name
    - like `logger-ts`, or `xcdl-cli-ts` for Node.js modules
    - like `xpm-preview` for web sites (later to be renamed to `xpm`)
  - description
    - like 'A Node.js CommonJS/ES6 module with ...'
    - like 'The xPack project manager command line tool' (shown in CLI too)
    - like 'Web site for the xpm web; (preview for now, to be renamed as xpm)'
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

Update license MIT, Copyright (c) 2024 Liviu Ionescu. All rights reserved.

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
  "config": {},
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
```

### Top dependencies

Install `json` and `liquidjs`:

```sh
npm install json liquidjs --save-dev
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
  "config": {
    "isOrganizationWeb": "true",
    "hasTriggerPublishPreview": "true",
    "hasEmptyMaster": "true"
  }
```

For Web deployment only projects (`web-preview`, `xpm`, `xcdl`), add:

```json
  "config": {
    "isWebDeployOnly": "true",
    "isWebPreview": "true"
  }
```

### Top scripts

Add two scripts to top `package.json` (remove dummy `test`).

For Web deployment only projects, the second is not necessary.

```json
    "generate-top-commons-init": "bash -x node_modules/@xpack/npm-packages-helper/maintenance-scripts/generate-top-commons.sh --init --xpack",
    "create-website-init": "bash -x node_modules/@xpack/docusaurus-template-liquid/maintenance-scripts/generate-commons.sh --init"
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

Add `websiteConfig` to `website/package.json`, after `engines`;
see the `README` file in `docusaurus-template-liquid.git` for details.

### Run actions once

In `website`:

```sh
npm install
npm run link-deps
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
  "skipTests": "true",
  "hasBranchMaster": "true",
  "hasBranchDevelopment": "true",
  "hasBranchWebsite": "false",
  "hasBranchWebpreview": "false",
  "websiteBranch": "master",
  "websiteBranchPreview": "development",
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
    "skipTests": "true",
    "hasTriggerPublishPreview": "true"
  },
  "packageBuildConfig": {},
  "packageWebsiteConfig": {
    "longName": "xPack Project",
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
