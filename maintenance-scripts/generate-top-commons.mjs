#!/usr/bin/env node

/*
 * This file is part of the xPack project (http://xpack.github.io).
 * Copyright (c) 2024-2026 Liviu Ionescu. All rights reserved.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose is hereby granted, under the terms of the MIT license.
 *
 * If a copy of the license was not distributed with this file, it can be
 * obtained from https://opensource.org/licenses/mit.
 */

// ----------------------------------------------------------------------------
// Generates (or refreshes) the top common files of a xpack/xpack-dev-tools/
// micro-os-plus project, from the liquid templates in the sibling
// `templates` folder. Invoked via the consuming project's
// `generate-top-commons` npm script.

import { existsSync, rmSync, statSync } from 'fs'
import path from 'path'
import { globSync } from 'glob'
import {
  parseOptions,
  checkIfShouldIgnorePath,
  prepareToPaths,
  computeContext,
  substitute,
  processFile,
} from './scripts-helper.mjs'

// ----------------------------------------------------------------------------

// Note: unlike `fileURLToPath(import.meta.url)`, `process.argv[1]` is not
// resolved through symlinks, matching the bash `$0` behaviour. This matters
// because `node_modules/@xpack/npm-packages-helper` is typically installed
// as a symlink to a shared checkout, and the project folder location is
// derived from the invocation path, not the real script location.
const scriptPath = path.resolve(process.argv[1])
const scriptName = path.basename(scriptPath)
const scriptFolderPath = path.dirname(scriptPath)

const templatesFolderPath = path.join(path.dirname(scriptFolderPath), 'templates')

// ----------------------------------------------------------------------------

// Removes the destination folder corresponding to a template folder
// named `_common`, replacing the `--remove-folder` branch of the bash
// `process-top-template-item.sh` script.
const removeCommonFolder = (relativeFolderPath, projectFolderPath, options) => {
  if (checkIfShouldIgnorePath(relativeFolderPath, options.acceptedPath)) {
    return
  }

  const fromRelativeFolderPath = relativeFolderPath.replace(/^\.\//, '')
  const fromAbsoluteFolderPath = path.join(templatesFolderPath, 'common', fromRelativeFolderPath)
  if (!statSync(fromAbsoluteFolderPath).isDirectory()) {
    console.log(`${fromRelativeFolderPath} not a folder`)
    process.exit(1)
  }

  // Note: unlike prepareToPaths(), _micro-os-plus is intentionally not
  // substituted here, matching the original bash behaviour.
  const toRelativeFolderPath = relativeFolderPath
    .replace('/_xpack/', '/')
    .replace('/_xpack-dev-tools/', '/')
    .replace(/^\.\//, '')
  const toAbsoluteFolderPath = path.join(projectFolderPath, toRelativeFolderPath)

  if (existsSync(toAbsoluteFolderPath)) {
    console.log(`rm ${toRelativeFolderPath}`)
    if (!options.doDryRun) {
      rmSync(toAbsoluteFolderPath, { recursive: true, force: true })
    }
  }
}

// Computes the destination paths to skip for this particular project
// configuration, then delegates to processFile() for the actual
// copy/liquid substitution. Replaces the default branch of the bash
// `process-top-template-item.sh` script.
const processTemplateItem = (relativeFilePath, projectFolderPath, params) => {
  const { context, options, doForce, fromAbsoluteFolderPath, substitutionPrefix } = params

  if (checkIfShouldIgnorePath(relativeFilePath, options.acceptedPath)) {
    return
  }

  const { fromRelativeFilePath, toRelativeFilePath, toAbsoluteFilePath } = prepareToPaths(
    relativeFilePath,
    projectFolderPath,
  )

  if (path.basename(fromRelativeFilePath) === '.DS_Store') {
    console.log(`${fromRelativeFilePath} ignored`) // Skip macOS specifics.
    return
  }

  // --------------------------------------------------------------------
  // Compute exclusions.

  const skipPages = ['.gitkeep']

  if (options.isXpack) {
    if (!context.topConfig.isTypescript) {
      skipPages.push(
        'tsconfig-common.json',
        'tsconfig.json',
        'src/tsconfig.json',
        'tsconfig.eslint.json',
        'tsconfig-original.json',
      )
    }

    if (context.topConfig.skipCiTests || context.packageVersion === '0.0.0') {
      skipPages.push('.github/workflows/test-ci.yml')
    }

    if (!context.topConfig.hasTriggerPublish) {
      skipPages.push('.github/workflows/trigger-publish-github-pages.yml')
    }

    if (!context.topConfig.hasTriggerPublishPreview) {
      skipPages.push('.github/workflows/trigger-publish-github-pages-preview.yml')
    }

    if (context.topConfig.isWebDeployOnly) {
      skipPages.push(
        'config/api-extractor.json',
        'src/tsconfig.json',
        'eslint.config.js',
        'config/eslint.config.js',
        'tsconfig-original.json',
        'config/tsconfig-original.json',
        'tsconfig.eslint.json',
        'config/tsconfig.eslint.json',
      )
    }

    if (!context.topConfig.useTypescriptEslint) {
      skipPages.push('.prettierignore')
      skipPages.push('eslint.config.js')
    }

    if (!context.topConfig.useApiExtractor) {
      skipPages.push('config/api-extractor.json')
    }
  } else if (options.isXpackDevTools) {
    let platformsWithCommas = `,${context.platforms},`
    if (platformsWithCommas === ',all,') {
      platformsWithCommas = ',linux-x64,linux-arm64,darwin-x64,darwin-arm64,win32-x64,'
    }

    if (
      context.topConfig.isOrganisationWeb ||
      context.topConfig.isWebDeployOnly ||
      !context.isXpack
    ) {
      skipPages.push(
        '.github/workflows/body-github-pre-releases-test.md',
        '.github/workflows/build-darwin-arm64.yml',
        '.github/workflows/build-darwin-x64.yml',
        '.github/workflows/build-linux-arm.yml',
        '.github/workflows/build-linux-arm64.yml',
        '.github/workflows/build-linux-x64.yml',
        '.github/workflows/build.yml',
        '.github/workflows/build-win32-x64.yml',
        '.github/workflows/copyright.yml',
        '.github/workflows/deep-clean.yml',
        '.github/workflows/publish-release.yml',
        '.github/workflows/test-docker-linux-arm.yml',
        '.github/workflows/test-docker-linux-intel.yml',
        '.github/workflows/test-prime.yml',
        '.github/workflows/test-xpm.yml',
        'build-assets/scripts/build.sh',
        'build-assets/scripts/test.sh',
      )
    } else {
      // Used internally.
      skipPages.push('.github/workflows/copyright.yml')
      // No longer used.
      skipPages.push('.github/workflows/build.yml')

      if (!platformsWithCommas.includes(',darwin-x64,')) {
        skipPages.push('.github/workflows/build-darwin-x64.yml')
      }
      if (!platformsWithCommas.includes(',darwin-arm64,')) {
        skipPages.push('.github/workflows/build-darwin-arm64.yml')
      }
      if (!platformsWithCommas.includes(',linux-x64,')) {
        skipPages.push(
          '.github/workflows/build-linux-x64.yml',
          '.github/workflows/test-docker-linux-intel.yml',
        )
      }
      if (!platformsWithCommas.includes(',linux-arm,')) {
        skipPages.push('.github/workflows/build-linux-arm.yml')
      }
      if (!platformsWithCommas.includes(',linux-arm64,')) {
        skipPages.push('.github/workflows/build-linux-arm64.yml')
      }
      if (!platformsWithCommas.includes(',win32-x64,')) {
        skipPages.push('.github/workflows/build-win32-x64.yml')
      }
      if (!platformsWithCommas.includes(',linux-arm64,')) {
        skipPages.push('.github/workflows/test-docker-linux-arm.yml')
      }
    }
  }

  if (!options.isMicroOsPlus || context.topConfig.isWebDeployOnly) {
    skipPages.push(
      'config/.clang-format',
      'config/.cmake-format.py',  

      'scripts/templates/CMakeLists-liquid.txt',
      'scripts/templates/meson-liquid.build',
      'scripts/clang-format.mjs',  
      'scripts/cmake-format.mjs',
      'scripts/jsonc-format.mjs',
      'scripts/xcdl-export.mjs',
    )
  }

  if (!context.hasFolderBuildAssetsPackage) {
    skipPages.push('build-assets/package.json')
  }

  if (!context.hasFolderWebsitePackage) {
    skipPages.push('.github/workflows/publish-github-pages.yml')
  }

  if (!context.topConfig.isWebDeployOnly) {
    skipPages.push('.github/workflows/publish-github-pages-from-remote.yml')
  } else {
    skipPages.push(
      '.clang-format',
      '.github/workflows/test-all.yml',
      '.github/workflows/test-ci.yml',
    )
  }

  if (context.packageVersion === '0.0.0') {
    skipPages.push('.npmignore')
  }

  if (!context.topConfig.hasTestAll) {
    skipPages.push('.github/workflows/test-all.yml')
  }

  if (!context.hasFolderTestsPackage) {
    skipPages.push(
      'tests/cmake/common-options.cmake',
      'tests/cmake/tests-main.cmake',
      'tests/meson/common-options/meson.build',
      'tests/package.json',
    )
  }

  if (context.baseUrlPreview === context.baseUrl) {
    skipPages.push('.github/workflows/trigger-publish-github-pages-preview.yml')
  }

  if (!context.topConfig.useSelfHostedRunners) {
    skipPages.push('.github/workflows/deep-clean.yml')
  }

  if (!context.topConfig.isTypescript) {
    skipPages.push('config/tsconfig-common.json', 'config/tsconfig-original.json')
  }

  if (!context.topConfig.useEslint) {
    skipPages.push('config/eslint.config.js')
  }

  // --------------------------------------------------------------------

  if (skipPages.includes(toRelativeFilePath)) {
    console.log(`skipped: ${toRelativeFilePath}`)
    return
  }

  processFile({
    context,
    fromAbsoluteFolderPath,
    fromRelativeFilePath,
    toRelativeFilePath,
    toAbsoluteFilePath,
    substitutionPrefix,
    doForce,
    doDryRun: options.doDryRun,
  })
}

// ----------------------------------------------------------------------------

const argv = process.argv.slice(2)

// Parse --init, --dry-run, --xpack, --xpack-dev-tools, --micro-os-plus.
const options = parseOptions(argv)

if (!options.isXpack && !options.isXpackDevTools && !options.isMicroOsPlus) {
  console.log('Unsupported configuration...')
  process.exit(1)
}

// The script is invoked via the following top npm script:
// "generate-top-commons": "node node_modules/@xpack/npm-packages-helper/maintenance-scripts/generate-top-commons.mjs"
const projectFolderPath = path.dirname(
  path.dirname(path.dirname(path.dirname(scriptFolderPath))),
)

let templatesRelativeFolderPath = templatesFolderPath.startsWith(`${projectFolderPath}/`)
  ? templatesFolderPath.slice(projectFolderPath.length + 1)
  : templatesFolderPath
templatesRelativeFolderPath = templatesRelativeFolderPath.replace(
  /^.*?node_modules\/@xpack\//,
  '',
)
templatesRelativeFolderPath = templatesRelativeFolderPath.replace(
  /^.*?node_modules\/@micro-os-plus\//,
  '',
)

// ----------------------------------------------------------------------------

// Process package.json files and leave results in the context object.
const context = computeContext({ projectFolderPath, options })

// ----------------------------------------------------------------------------

if (options.doDryRun) {
  console.log()
  console.log('Dry run!')
}

// ----------------------------------------------------------------------------

if (options.doInit) {
  let fromAbsoluteFolderPath
  if (options.isMicroOsPlus) {
    fromAbsoluteFolderPath = path.join(templatesFolderPath, 'common', '_micro-os-plus')
  } else if (options.isXpack) {
    fromAbsoluteFolderPath = path.join(templatesFolderPath, 'common', '_xpack')
  } else {
    console.log('--init not implemented yet')
    process.exit(1)
  }

  // Destructive, it does not merge.
  substitute({
    context,
    fromAbsoluteFolderPath,
    fromRelativeFilePath: 'package-merge-liquid.json',
    toAbsoluteFilePath: path.join(projectFolderPath, 'package.json'),
    substitutionPrefix: '',
    doDryRun: options.doDryRun,
  })
} else {
  console.log()
  console.log(`Processing template from ${templatesFolderPath}...`)

  console.log()
  console.log('Common files, cleanups...')

  const commonFolderPath = path.join(templatesFolderPath, 'common')

  // Preliminary pass to remove _common folders.
  const commonDirs = globSync('**/_common', { cwd: commonFolderPath, dot: true })
    .filter((entry) => statSync(path.join(commonFolderPath, entry)).isDirectory())
    .sort()

  for (const relativeFolderPath of commonDirs) {
    removeCommonFolder(`./${relativeFolderPath}`, projectFolderPath, options)
  }

  console.log()
  console.log('Common files, overridden...')

  const commonSubstitutionPrefix = `${templatesRelativeFolderPath}/common`

  // Main pass to copy/generate common files.
  const commonFiles = globSync('**/*', { cwd: commonFolderPath, dot: true, nodir: true }).sort()

  for (const relativeFilePath of commonFiles) {
    processTemplateItem(`./${relativeFilePath}`, projectFolderPath, {
      context,
      options,
      doForce: true,
      fromAbsoluteFolderPath: commonFolderPath,
      substitutionPrefix: commonSubstitutionPrefix,
    })
  }

  console.log()
  console.log('First time proposals...')

  const firstTimeFolderPath = path.join(templatesFolderPath, 'first-time')
  const firstTimeSubstitutionPrefix = `${templatesRelativeFolderPath}/first-time`

  const firstTimeFiles = existsSync(firstTimeFolderPath)
    ? globSync('**/*', { cwd: firstTimeFolderPath, dot: true, nodir: true }).sort()
    : []

  for (const relativeFilePath of firstTimeFiles) {
    processTemplateItem(`./${relativeFilePath}`, projectFolderPath, {
      context,
      options,
      doForce: false,
      fromAbsoluteFolderPath: firstTimeFolderPath,
      substitutionPrefix: firstTimeSubstitutionPrefix,
    })
  }
}

// ----------------------------------------------------------------------------

console.log()
console.log(`'${scriptName} ${argv.join(' ')}' done`)

process.exit(0)

// ----------------------------------------------------------------------------
