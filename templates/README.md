# README

## Getting started

To use this template in a project, it must have a package.json.

Install `json`:

```
npm install json liquidjs --save-dev
```

Link the local helper project:

```sh
npm link @xpack/node-modules-helper @xpack/docusaurus-template-liquid
```

add to package.json:

```json
  "buildConfig": {
    "isOrganizationWeb": "true"
  }
```

```json
    "generate-top-commons": "bash node_modules/@xpack/node-modules-helper/maintenance-scripts/generate-top-commons.sh --init",
    "create-website": "bash node_modules/@xpack/docusaurus-template-liquid/maintenance-scripts/generate-commons.sh --init"
```

Run them:

```
npm run generate-top-commons
npm run create-website
```

Add `websiteConfig` to `website/package.json`:

```json
{
  "engines": {
    "node": ">=18.0"
  },
  "websiteConfig": {
    "name": "xPack",
    "longName": "xPack Project",
    "title": "The xPack Reproducible Build Framework",
    "tagline": "Tools to manage, configure and build complex, package based, multi-target projects, in a reproducible way.",
    "metadataDescription": "The xPack Reproducible Build Framework",
    "metadataKeywords": "xpack, project, manage, build, test, dependencies, xpm, npm, reproducibility",
    "nodeVersion": "18.20.4"
  }
}

```sh
npm install
npm run link-deps
npm run generate-website-commons
```

When no longer needed:

- Remove `-init` from `generate-top-commons`.
- Remove `create-website`.
