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
// Reusable helper functions for the xPack top-commons template generator.
// Shared across the xpack/xpack-dev-tools/micro-os-plus family of projects,
// intentionally kept independent of any single consuming repository.

import { execFileSync } from 'child_process'
import {
  existsSync,
  readFileSync,
  writeFileSync,
  copyFileSync,
  mkdirSync,
  statSync,
  chmodSync,
  rmSync,
  renameSync,
  constants,
} from 'fs'
import path from 'path'
import { globSync } from 'glob'
import { Liquid } from 'liquidjs'

// ----------------------------------------------------------------------------
// Generic utilities.

// Runs an external command, echoing it first, similar to the bash
// `run_verbose()` helper.
export const runVerbose = (appPath, args = [], options = {}) => {
  console.log()
  console.log(`[${appPath} ${args.join(' ')}]`)
  execFileSync(appPath, args, { stdio: 'inherit', ...options })
}

// Equivalent of bash's `basename`, including the trailing slashes
// handling, used to derive base URLs from homepage-like properties.
const bashBasename = (value) => {
  const trimmed = String(value ?? '').replace(/\/+$/, '')
  const index = trimmed.lastIndexOf('/')
  return index >= 0 ? trimmed.slice(index + 1) : trimmed
}

// Formats a date similar to bash's `date '+%Y-%m-%d %H:%M:%S %z'`.
const formatReleaseDate = (date) => {
  const pad = (value) => String(value).padStart(2, '0')
  const offsetMinutes = -date.getTimezoneOffset()
  const sign = offsetMinutes >= 0 ? '+' : '-'
  const offsetHours = pad(Math.floor(Math.abs(offsetMinutes) / 60))
  const offsetRemainder = pad(Math.abs(offsetMinutes) % 60)

  return (
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ` +
    `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())} ` +
    `${sign}${offsetHours}${offsetRemainder}`
  )
}

// Deep-merges `source` into `target` (nested plain objects are merged
// recursively, everything else, including arrays, is overwritten),
// replacing the bash `json --deep-merge` invocation.
const deepMerge = (target, source) => {
  for (const key of Object.keys(source)) {
    const sourceValue = source[key]
    const targetValue = target[key]
    const bothPlainObjects =
      sourceValue !== null &&
      typeof sourceValue === 'object' &&
      !Array.isArray(sourceValue) &&
      targetValue !== null &&
      typeof targetValue === 'object' &&
      !Array.isArray(targetValue)

    target[key] = bothPlainObjects ? deepMerge(targetValue, sourceValue) : sourceValue
  }
  return target
}

// ----------------------------------------------------------------------------
// Command line options.

// Parses --init, --dry-run, --push, --restart, --xpack, --xpack-dev-tools
// and --micro-os-plus, and returns an options object (replacing the bash
// `parse_options()` helper, which left the same values as exported
// environment variables).
export const parseOptions = (argv) => {
  const options = {
    doInit: false,
    doDryRun: false,
    isXpack: false,
    isXpackDevTools: false,
    isMicroOsPlus: false,
    acceptedPath: '',
    doPush: false,
    doRestart: false,
  }

  for (const arg of argv) {
    switch (arg) {
      case '--init':
        options.doInit = true
        break
      case '--dry-run':
        options.doDryRun = true
        break
      case '--push':
        options.doPush = true
        break
      case '--restart':
        options.doRestart = true
        break
      case '--xpack':
        options.isXpack = true
        options.acceptedPath = '_xpack'
        break
      case '--xpack-dev-tools':
        options.isXpackDevTools = true
        options.acceptedPath = '_xpack-dev-tools'
        break
      case '--micro-os-plus':
        options.isMicroOsPlus = true
        options.acceptedPath = '_micro-os-plus'
        break
      default:
        console.log(`Unsupported option ${arg}`)
    }
  }

  console.log()
  console.log(`Configuration: ${options.acceptedPath}`)

  return options
}

// ----------------------------------------------------------------------------
// Template item path helpers.

// Returns true if the relative path selects a category folder (_xpack,
// _xpack-dev-tools, _micro-os-plus) other than the accepted one, in
// which case the item must be skipped.
export const checkIfShouldIgnorePath = (relativePath, acceptedPath) => {
  const hasCategoryFolder =
    relativePath.includes('/_xpack/') ||
    relativePath.includes('/_xpack-dev-tools/') ||
    relativePath.includes('/_micro-os-plus/')

  return hasCategoryFolder && !relativePath.includes(`/${acceptedPath}/`)
}

// Computes the destination relative/absolute paths for a source
// relative file path, replacing the bash `prepare_paths()` helper.
export const prepareToPaths = (relativeFilePath, toAbsoluteFolderPath) => {
  const fromRelativeFilePath = relativeFilePath.replace(/^\.\//, '')

  // Each replacement below removes only the first occurrence, matching
  // the non-global bash `sed` substitutions this logic is derived from.
  const toRelativeFilePath = relativeFilePath
    .replace('/_xpack/', '/')
    .replace('/_xpack-dev-tools/', '/')
    .replace('/_micro-os-plus/', '/')
    .replace('-merge-liquid', '')
    .replace('-liquid', '')
    .replace('-rawliquid', '-liquid')
    .replace(/^\.\//, '')

  const toAbsoluteFilePath = path.join(toAbsoluteFolderPath, toRelativeFilePath)

  return { fromRelativeFilePath, toRelativeFilePath, toAbsoluteFolderPath, toAbsoluteFilePath }
}

// ----------------------------------------------------------------------------
// Context computation.
//
// Requires the project's package.json and, optionally, its website and
// tests package.json/config files. Builds a plain JS object (`context`)
// with all the properties used by the liquid templates. Unlike the bash
// source, there is no need to also export a flat set of `xpack_*`
// environment variables, since everything now runs in a single process.

const gitBranches = (projectFolderPath) => {
  try {
    return execFileSync('git', ['branch', '-a'], {
      cwd: projectFolderPath,
      encoding: 'utf8',
    })
  } catch {
    return ''
  }
}

const inspectEnvironment = (context, projectFolderPath) => {
  context.hasFolderWebsitePackage = existsSync(
    path.join(projectFolderPath, 'website', 'package.json'),
  )
  context.hasFolderBuildAssetsPackage = existsSync(
    path.join(projectFolderPath, 'build-assets', 'package.json'),
  )
  context.hasFolderTestsPackage = existsSync(
    path.join(projectFolderPath, 'tests', 'package.json'),
  )

  const branches = gitBranches(projectFolderPath)
  context.hasBranchMaster = branches.includes('master')
  context.hasBranchDevelopment = branches.includes('development')
  context.hasBranchXpack = branches.includes('xpack')
  context.hasBranchXpackDevelopment = branches.includes('xpack-development')
  context.hasBranchWebsite = branches.includes('website')
  context.hasBranchWebpreview = branches.includes('webpreview')

  if (context.hasBranchXpackDevelopment) {
    context.branchDevelopment = 'xpack-development'
  } else if (context.hasBranchDevelopment) {
    context.branchDevelopment = 'development'
  } else if (context.hasBranchWebpreview) {
    context.branchDevelopment = 'webpreview'
  } else {
    console.log('No branch development?')
    context.branchDevelopment = 'none'
  }

  if (context.hasBranchWebsite) {
    context.branchWebsite = 'website'
  } else if (context.hasBranchMaster) {
    context.branchWebsite = 'master'
  } else {
    console.log('Branch?')
    process.exit(1)
  }

  if (context.hasBranchWebpreview) {
    context.branchWebpreview = 'webpreview'
  } else if (context.hasBranchDevelopment) {
    context.branchWebpreview = 'development'
  } else if (context.hasBranchMaster) {
    context.branchWebpreview = 'master'
  } else {
    console.log('Branch preview?')
    process.exit(1)
  }

  if (context.hasBranchXpack) {
    context.branchMain = 'xpack'
  } else if (context.hasBranchDevelopment && context.hasBranchMaster) {
    // This is tricky, if it has development, it must also have master.
    context.branchMain = 'master'
  } else if (context.hasBranchWebsite) {
    context.branchMain = 'website'
  } else if (context.hasBranchMaster) {
    context.branchMain = 'master'
  } else {
    console.log('Branch main?')
    process.exit(1)
  }

  context.releaseDate = formatReleaseDate(new Date())
}

const processTopPackageJson = (context, packageJson) => {
  context.packageScopedName = packageJson.name ?? ''

  if (context.packageScopedName.startsWith('@')) {
    context.packageScope = context.packageScopedName.replace(/^@/, '').replace(/\/.*/, '')
  } else {
    context.packageScope = ''
  }

  context.packageName = context.packageScopedName.replace(/^@[a-zA-Z0-9-]*\//, '')
  context.packageVersion = packageJson.version ?? ''
  context.packageType = packageJson.type ?? ''
  context.packageDescription = packageJson.description ?? ''

  // Remove the `pre` used during development.
  context.releaseVersion = context.packageVersion.replace(/[.-]pre.*/, '')

  // Remove the pre-release.
  context.releaseSemver = context.releaseVersion.replace(/-.*/, '')

  if (context.releaseVersion !== context.releaseSemver) {
    context.releaseSubversion = context.releaseVersion.replace(/.*-/, '').replace(/\.[0-9]*/, '')
    // Use the package.json one, but remove the `pre` used during development.
    context.releaseNpmSubversion = context.releaseVersion
      .replace(/[.-]pre.*/, '')
      .replace(/.*\./, '')
  } else {
    context.releaseSubversion = ''
    context.releaseNpmSubversion = ''
  }

  context.repositoryUrl = (packageJson.repository?.url ?? '').replace(/^git\+/, '')

  const githubFullName = context.repositoryUrl
    .replace(/^https:\/\/github\.com\//, '')
    .replace(/\.git$/, '')
  context.githubProjectOrganization = githubFullName.replace(/\/.*/, '')
  context.githubProjectName = githubFullName
    .replace(/\/$/, '')
    .replace(/\.git$/, '')
    .replace(/.*\//, '')

  context.isNpmExecutable = Boolean(packageJson.bin)

  context.packageEnginesNodeVersion = (packageJson.engines?.node ?? '').replace(/[^0-9]*/, '')
  context.packageEnginesNodeVersionMajor = context.packageEnginesNodeVersion.replace(/\..*/, '')

  context.packageDependenciesTypescriptVersion = (
    packageJson.devDependencies?.typescript ?? ''
  ).replace(/[^0-9]*/, '')

  context.packageHomepage = packageJson.homepage ?? ''
  context.packageHomepagePreview = packageJson.homepagePreview || context.packageHomepage

  context.packageKeywords = packageJson.keywords ?? []

  // Note: the legacy heuristic that used to derive topConfig.isTypescript,
  // isJavascript, usePrettier, useStandard, useTypescriptEslint and
  // useApiExtractor from the github project name/package.json here has
  // been dropped: in the bash source it was always immediately
  // overwritten by processTopConfig() resetting `topConfig`, so it had
  // no observable effect for projects lacking config/top-templates.json.
}

export const topConfigStringProperties = [
  'descriptiveName',
  'permalinkName',
  'preferredName',
  'programName',
  'upstreamDescriptiveName',
]

export const topConfigArrayProperties = [
  'githubActionsNodeVersions',
  'githubActionsOses',
  'githubActionsXpmVersions',
]

export const topConfigBooleanProperties = [
  'hasCli',
  'hasEmptyMaster',
  'hasNoGithubReleases',
  'hasObjectLibrary',
  'hasTestAll',
  'hasTriggerPublish',
  'hasTriggerPublishPreview',
  'hasWebsite',
  'isJavascript',
  'isOrganisationWeb',
  'isTypescript',
  'isWebDeployOnly',
  'isWebPreview',
  'preferShortName',
  'showTestsResults',
  'skipCiTests',
  'testCoverage',
  'useApiExtractor',
  'useDoxygen',
  'useEslint',
  'usePrettier',
  'useSelfHostedRunners',
  'useStandard',
  'useTap',
  'useTypescriptEslint',
]

const topConfigArrayDefaults = {
  githubActionsNodeVersions: ['24'],
  githubActionsOses: [
    'ubuntu-24.04',
    'ubuntu-24.04-arm',
    'macos-15-intel',
    'macos-15',
    'windows-2025',
  ],
  githubActionsXpmVersions: ['0.23.2'],
}

const processTopConfig = (context, rawTopConfig, hasConfigFile) => {
  context.topConfig = {}

  for (const prop of topConfigStringProperties) {
    let value = rawTopConfig[prop] ?? ''
    if (!value) {
      if (prop === 'descriptiveName') {
        value = '???'
      } else if (prop === 'permalinkName') {
        value = context.packageName
      } else if (prop === 'preferredName') {
        value = '???'
      }
    }
    context.topConfig[prop] = value
  }

  for (const prop of topConfigArrayProperties) {
    const value = rawTopConfig[prop]
    context.topConfig[prop] =
      Array.isArray(value) && value.length > 0 ? value : topConfigArrayDefaults[prop]
  }

  for (const prop of topConfigBooleanProperties) {
    context.topConfig[prop] = rawTopConfig[prop] === true
  }

  // Located here because it depends on descriptiveName.
  if (context.topConfig.descriptiveName) {
    if (
      !context.topConfig.descriptiveName.startsWith('xPack ') &&
      context.githubProjectOrganization.startsWith('xpack-')
    ) {
      context.longXpackName = `xPack ${context.topConfig.descriptiveName}`
    } else {
      context.longXpackName = context.topConfig.descriptiveName
    }
  } else {
    console.log('Missing descriptiveName in config/top-templates.json')
    context.longXpackName = '?'
  }

  // Located here because they depend on isOrganisationWeb.
  let baseUrl = `/${bashBasename(context.packageHomepage)}/`
  let baseUrlPreview = `/${bashBasename(context.packageHomepagePreview)}/`
  if (context.topConfig.isOrganisationWeb) {
    baseUrl = '/'
    if (!context.packageHomepagePreview) {
      baseUrlPreview = '/'
    }
  }
  context.baseUrl = baseUrl
  context.baseUrlPreview = baseUrlPreview

  // TODO: remove after all projects are migrated to config/*.json files,
  // as this should be set in the json file, not derived from other
  // properties.
  if (!hasConfigFile) {
    context.topConfig.preferredName = context.topConfig.preferShortName
      ? context.topConfig.permalinkName || context.packageName
      : context.topConfig.descriptiveName
  }
}

const writeTopTemplateConfig = (context, projectFolderPath, rawTopConfig) => {
  console.log()
  console.log('Writing top templates config...')

  const output = {}

  for (const prop of topConfigStringProperties) {
    const value = context.topConfig[prop]
    if (value) {
      output[prop] = value
    }
  }

  for (const prop of topConfigArrayProperties) {
    output[prop] = context.topConfig[prop]
  }

  for (const prop of topConfigBooleanProperties) {
    if (prop === 'useSelfHostedRunners') {
      output[prop] = context.topConfig[prop]
    } else if (context.topConfig[prop]) {
      output[prop] = true
    }
  }

  const configFolderPath = path.join(projectFolderPath, 'config')
  mkdirSync(configFolderPath, { recursive: true })
  writeFileSync(
    path.join(configFolderPath, 'top-templates.json'),
    `${JSON.stringify(output, undefined, 2)}\n`,
  )

  const outputCount = Object.keys(output).length
  const configCount = Object.keys(rawTopConfig).length
  if (outputCount !== configCount + 1) {
    console.log(
      `top-templates.json has ${outputCount} properties, but topConfig has ` +
        `${configCount} properties, plus preferredName`,
    )
    process.exit(1)
  }
}

const xpackBinaryPlatformsOrder = [
  'win32-x64',
  'darwin-x64',
  'darwin-arm64',
  'linux-x64',
  'linux-arm64',
]

const processXpack = (context, packageJson, projectFolderPath) => {
  const packageXpack = packageJson.xpack

  let platforms = []
  if (!packageXpack) {
    context.isXpack = false
    context.isXpackBinary = false
  } else {
    context.isXpack = true

    const binaries = packageXpack.binaries
    if (binaries) {
      context.isXpackBinary = true

      // The order is relevant, it is kept when generating tabs and lists.
      for (const platform of xpackBinaryPlatformsOrder) {
        const platformObject = binaries.platforms?.[platform]
        if (platformObject && platformObject.skip !== true) {
          platforms.push(platform)
        }
      }
    } else {
      context.isXpackBinary = false
    }
  }

  // For top webs, to display the full list of platforms.
  if (context.topConfig.isOrganisationWeb && platforms.length === 0) {
    platforms = [...xpackBinaryPlatformsOrder]
  }
  context.platforms = platforms.join(',')

  let isNpmPublished = false
  if (context.isXpack || context.topConfig.isTypescript || context.topConfig.isJavascript) {
    if (context.releaseSemver !== '0.0.0') {
      isNpmPublished = true
    }
  }
  context.isNpmPublished = isNpmPublished

  if (packageXpack && !/^0\.0[.0].*$/.test(context.releaseSemver)) {
    const versionFilePath = path.join(projectFolderPath, 'build-assets', 'scripts', 'VERSION')

    // Prefer the VERSION content, if available.
    const xpackVersion = existsSync(versionFilePath)
      ? readFileSync(versionFilePath, 'utf8').split('\n')[0]
      : context.releaseVersion

    context.xpackVersion = xpackVersion
    context.xpackSemver = xpackVersion.replace(/-.*/, '')
    context.xpackSubversion = xpackVersion.replace(/.*-/, '')

    if (context.hasTwoNumbersVersion && /\.0*$/.test(context.releaseSemver)) {
      // Remove the patch number, if zero.
      context.upstreamVersion = context.releaseSemver.replace(/\.0*$/, '')
    } else {
      context.upstreamVersion = context.releaseSemver
    }
  }
}

export const websiteStringProperties = [
  'armMajorMinorRelease',
  'armReleaseDate',
  'armSubRelease',
  'bashReleaseDate',
  'binutilsVersionMajor',
  'binutilsVersionMinor',
  'bisonReleaseDate',
  'branding',
  'busyboxReleaseDate',
  'busyboxTag',
  'clangReleaseDate',
  'cmakeReleaseDate',
  'coreutilsReleaseDate',
  'customAboutTitle',
  'customDeveloperTitle',
  'customGettingStartedTitle',
  'customInstallLabel',
  'customInstallTitle',
  'customMaintainerTitle',
  'customUserTitle',
  'flexReleaseDate',
  'gdbVersionMajor',
  'gdbVersionMinor',
  'llvmMingwTag',
  'm4ReleaseDate',
  'makeReleaseDate',
  'mesonReleaseDate',
  'metadataKeywords',
  'mingwVersion',
  'newlibVersion',
  'ninjaReleaseDate',
  'openocdCommitDate',
  'openocdCommitId',
  'patchelfReleaseDate',
  'pkgconfigReleaseDate',
  'platforms',
  'programName',
  'pythonVersion',
  'qemuReleaseDate',
  'sedReleaseDate',
  'tagline',
  'texinfoReleaseDate',
  'title',
  'triplet',
  'userGuideDescription',
  'wineReleaseDate',
]

export const websiteBooleanProperties = [
  'has100coverage',
  'hasCustomAbout',
  'hasCustomConfigDoxyfile',
  'hasCustomDeveloper',
  'hasCustomDocsNavbarItem',
  'hasCustomGettingStarted',
  'hasCustomGettingStartedSidebar',
  'hasCustomHomepageFeatures',
  'hasCustomInstall',
  'hasCustomMaintainer',
  'hasCustomSidebar',
  'hasCustomUser',
  'hasCustomUserSidebar',
  'hasDoxygenDocusaurusApi',
  'hasDoxygenReference',
  'hasHomepageTools',
  'hasMetadataMinimum',
  'hasPolicies',
  'hasToolsSidebar',
  'hasTopHomepageFeatures',
  'hasTSDocDocusaurusApi',
  'hasTwoNumbersVersion',
  'hasTypedocApi',
  'isArmToolchain',
  'isGccToolchain',
  'isInstallGlobally',
  'isOrganisationWeb',
  'isSecondaryTool',
  'isXpmDependency',
  'shareOnTwitter',
  'showDeprecatedGnuMcuAnalytics',
  'showDeprecatedRiscvGccAnalytics',
  'skipAlgolia',
  'skipContributorGuide',
  'skipFaq',
  'skipInstallCommand',
  'skipInstallGuide',
  'skipMaintainerGuide',
  'skipReleases',
  'skipTests',
  'useApiDocumenter',
  'usePluralGuides',
]

const processWebsiteConfig = (context, websiteFolderPath, options) => {
  const websitePackageJsonPath = path.join(websiteFolderPath, 'package.json')
  if (!existsSync(websitePackageJsonPath)) {
    return undefined
  }

  console.log()
  console.log('Processing website/package.json...')

  const websiteTemplatesConfigPath = path.join(
    websiteFolderPath,
    'config',
    'website-templates.json',
  )

  let rawWebsiteConfig
  if (existsSync(websiteTemplatesConfigPath)) {
    rawWebsiteConfig = JSON.parse(readFileSync(websiteTemplatesConfigPath, 'utf8'))
  } else {
    const websitePackageJson = JSON.parse(readFileSync(websitePackageJsonPath, 'utf8'))
    rawWebsiteConfig = websitePackageJson.websiteConfig
  }

  if (!rawWebsiteConfig) {
    if (options.doInit || context.topConfig.isWebDeployOnly || options.isMicroOsPlus) {
      rawWebsiteConfig = {}
    } else {
      console.log('Missing websiteConfig')
      process.exit(1)
    }
  }

  context.websiteConfig = {}
  for (const prop of websiteStringProperties) {
    context.websiteConfig[prop] = rawWebsiteConfig[prop] ?? ''
  }
  for (const prop of websiteBooleanProperties) {
    context.websiteConfig[prop] = rawWebsiteConfig[prop] === true
  }

  return rawWebsiteConfig
}

const writeWebsiteTemplateConfig = (context, websiteFolderPath, rawWebsiteConfig) => {
  console.log()
  console.log('Writing website templates config...')

  const output = {}

  for (const prop of websiteStringProperties) {
    const value = context.websiteConfig[prop]
    if (prop === 'branding') {
      output[prop] = value ?? ''
    } else if (value) {
      output[prop] = value
    }
  }

  if (rawWebsiteConfig.$link) {
    output.$link = rawWebsiteConfig.$link
  }

  for (const prop of websiteBooleanProperties) {
    if (context.websiteConfig[prop]) {
      output[prop] = true
    }
  }

  const configFolderPath = path.join(websiteFolderPath, 'config')
  mkdirSync(configFolderPath, { recursive: true })
  writeFileSync(
    path.join(configFolderPath, 'website-templates.json'),
    `${JSON.stringify(output, undefined, 2)}\n`,
  )

  const outputCount = Object.keys(output).length
  const configCount = Object.keys(rawWebsiteConfig).length
  if (outputCount !== configCount) {
    console.log(
      `website-templates.json has ${outputCount} properties, but websiteConfig has ` +
        `${configCount} properties`,
    )
    process.exit(1)
  }
}

const processTestsConfig = (context, testsFolderPath) => {
  const testsTemplatesConfigPath = path.join(testsFolderPath, 'config', 'tests-templates.json')
  const testsPackageJsonPath = path.join(testsFolderPath, 'package.json')

  let rawTestsConfig
  if (existsSync(testsTemplatesConfigPath)) {
    console.log()
    console.log('Processing tests/config/tests-templates.json...')
    rawTestsConfig = JSON.parse(readFileSync(testsTemplatesConfigPath, 'utf8'))
  } else if (existsSync(testsPackageJsonPath)) {
    console.log()
    console.log('Processing tests/package.json...')
    const testsPackageJson = JSON.parse(readFileSync(testsPackageJsonPath, 'utf8'))
    rawTestsConfig = testsPackageJson.testsConfig
  } else {
    console.log()
    console.log('No tests configuration file found.')
    rawTestsConfig = {}
  }

  rawTestsConfig ??= {}

  context.testsConfig = {
    useStaticLibrary: rawTestsConfig.useStaticLibrary === true,
    useObjectsLibrary: rawTestsConfig.useObjectsLibrary === true,
    platforms: rawTestsConfig.platforms ?? [],
    tests: rawTestsConfig.tests ?? [],
  }
}

// Requires the project's package.json. Builds and returns the `context`
// object used when rendering the liquid templates, replacing the bash
// `compute_context()` helper.
export const computeContext = ({
  projectFolderPath,
  websiteFolderPath,
  testsFolderPath,
  options,
}) => {
  if (!projectFolderPath) {
    console.error('missing mandatory projectFolderPath...')
    process.exit(1)
  }

  const packageJsonPath = path.join(projectFolderPath, 'package.json')
  if (!existsSync(packageJsonPath)) {
    console.error(`missing mandatory ${packageJsonPath}...`)
    process.exit(1)
  }

  const context = {}

  console.log()
  console.log(`Processing project ${path.basename(projectFolderPath)} properties...`)
  inspectEnvironment(context, projectFolderPath)

  console.log()
  console.log('Processing top package.json...')
  const packageJson = JSON.parse(readFileSync(packageJsonPath, 'utf8'))
  processTopPackageJson(context, packageJson)

  const topTemplatesConfigPath = path.join(projectFolderPath, 'config', 'top-templates.json')
  const hasTopTemplatesConfigFile = existsSync(topTemplatesConfigPath)

  console.log()
  console.log(
    hasTopTemplatesConfigFile
      ? 'Processing config/top-templates.json...'
      : 'Processing top package.json topConfig...',
  )
  const rawTopConfig = hasTopTemplatesConfigFile
    ? JSON.parse(readFileSync(topTemplatesConfigPath, 'utf8'))
    : (packageJson.topConfig ?? {})
  processTopConfig(context, rawTopConfig, hasTopTemplatesConfigFile)

  // The order is relevant, as some of the variables depend on top config.
  processXpack(context, packageJson, projectFolderPath)

  let rawWebsiteConfig
  if (websiteFolderPath) {
    rawWebsiteConfig = processWebsiteConfig(context, websiteFolderPath, options)
  }

  if (testsFolderPath) {
    processTestsConfig(context, testsFolderPath)
  }

  // Temporary, until all projects are updated to use config/*.json files.
  if (!hasTopTemplatesConfigFile) {
    writeTopTemplateConfig(context, projectFolderPath, rawTopConfig)
  }

  if (websiteFolderPath && existsSync(path.join(websiteFolderPath, 'package.json'))) {
    const websiteTemplatesConfigPath = path.join(
      websiteFolderPath,
      'config',
      'website-templates.json',
    )
    if (!existsSync(websiteTemplatesConfigPath)) {
      writeWebsiteTemplateConfig(context, websiteFolderPath, rawWebsiteConfig)
    }
  }

  console.log()
  console.log('"context": ')
  console.log(JSON.stringify(context, undefined, 2))

  return context
}

// ----------------------------------------------------------------------------
// Liquid substitution and file processing.

// `partialsFolderPath` defaults to `fromAbsoluteFolderPath` (the item's own
// source folder), matching most callers; some scripts (e.g. tests commons)
// use a fixed, separate partials folder instead.
const createLiquidEngine = (fromAbsoluteFolderPath, partialsFolderPath = fromAbsoluteFolderPath) =>
  new Liquid({
    root: [fromAbsoluteFolderPath],
    partials: [partialsFolderPath],
    extname: '.liquid',
    strictFilters: true,
    strictVariables: true,
    lenientIf: true,
  })

// Renders a liquid template file and writes the result to the
// destination, replacing the bash `substitute()` helper.
export const substitute = ({
  context,
  fromAbsoluteFolderPath,
  partialsFolderPath,
  fromRelativeFilePath,
  toRelativeFilePath,
  toAbsoluteFilePath,
  substitutionPrefix,
  doDryRun,
}) => {
  const fromProjectRelativeFilePath = `${substitutionPrefix}/${fromRelativeFilePath}`

  mkdirSync(path.dirname(toAbsoluteFilePath), { recursive: true })

  // Prefer the caller-supplied, destination-root-relative path (as
  // computed by prepareToPaths()); fall back to a cwd-relative path for
  // callers (such as `--init` entry points) that only have the absolute
  // destination path available.
  console.log(`liquidjs -> ${toRelativeFilePath ?? path.relative(process.cwd(), toAbsoluteFilePath)}`)

  const localContext = { ...context, fromFilePath: fromProjectRelativeFilePath }
  const engine = createLiquidEngine(fromAbsoluteFolderPath, partialsFolderPath)
  // Read the template content directly (as the liquidjs CLI does for its
  // `@path` template option), rather than renderFileSync()/Loader.lookup(),
  // which mis-resolves extension-less dotfiles such as `.gitignore-liquid`.
  const templateContent = readFileSync(
    path.join(fromAbsoluteFolderPath, fromRelativeFilePath),
    'utf8',
  )

  if (doDryRun) {
    engine.parseAndRenderSync(templateContent, localContext)
    return
  }

  const rendered = engine.parseAndRenderSync(templateContent, localContext)
  const newFilePath = `${toAbsoluteFilePath}.new`
  writeFileSync(newFilePath, rendered)
  rmSync(toAbsoluteFilePath, { force: true })
  renameSync(newFilePath, toAbsoluteFilePath)
}

// Renders a liquid template file and deep-merges the result (expected
// to be JSON) into the destination file, replacing the bash
// `substitute_and_merge()` helper.
export const substituteAndMerge = ({
  context,
  fromAbsoluteFolderPath,
  partialsFolderPath,
  fromRelativeFilePath,
  toRelativeFilePath,
  toAbsoluteFilePath,
  substitutionPrefix,
  doDryRun,
}) => {
  const fromProjectRelativeFilePath = `${substitutionPrefix}/${fromRelativeFilePath}`

  mkdirSync(path.dirname(toAbsoluteFilePath), { recursive: true })

  // See the equivalent comment in substitute() above.
  console.log(`liquidjs | merge -> ${toRelativeFilePath ?? path.relative(process.cwd(), toAbsoluteFilePath)}`)

  const localContext = { ...context, fromFilePath: fromProjectRelativeFilePath }
  const engine = createLiquidEngine(fromAbsoluteFolderPath, partialsFolderPath)
  const templateContent = readFileSync(
    path.join(fromAbsoluteFolderPath, fromRelativeFilePath),
    'utf8',
  )
  const rendered = engine.parseAndRenderSync(templateContent, localContext)

  if (doDryRun) {
    return
  }

  const existing = existsSync(toAbsoluteFilePath)
    ? JSON.parse(readFileSync(toAbsoluteFilePath, 'utf8'))
    : {}
  const merged = deepMerge(existing, JSON.parse(rendered))

  const newFilePath = `${toAbsoluteFilePath}.new`
  writeFileSync(newFilePath, `${JSON.stringify(merged, undefined, 2)}\n`)
  rmSync(toAbsoluteFilePath, { force: true })
  renameSync(newFilePath, toAbsoluteFilePath)
}

// Copies, or renders and copies, a single template item to its
// destination, replacing the bash `process_file()` helper. The
// from/to paths are expected to have been computed by `prepareToPaths()`.
export const processFile = ({
  context,
  fromAbsoluteFolderPath,
  partialsFolderPath,
  fromRelativeFilePath,
  toRelativeFilePath,
  toAbsoluteFilePath,
  substitutionPrefix,
  doForce,
  doDryRun,
}) => {
  if (existsSync(toAbsoluteFilePath)) {
    if (!doForce) {
      console.log(`${toRelativeFilePath} exists`)
      return
    }

    // Be sure destination is writeable.
    chmodSync(toAbsoluteFilePath, statSync(toAbsoluteFilePath).mode | constants.S_IWUSR)
  }

  mkdirSync(path.dirname(toAbsoluteFilePath), { recursive: true })

  const fromBasename = path.basename(fromRelativeFilePath)
  const fromAbsoluteFilePath = path.join(fromAbsoluteFolderPath, fromRelativeFilePath)

  if (fromBasename.includes('-rawliquid')) {
    console.log(`raw -> ${toRelativeFilePath}`)
    if (!doDryRun) {
      copyFileSync(fromAbsoluteFilePath, toAbsoluteFilePath)
    }
  } else if (fromBasename.includes('-merge-liquid')) {
    substituteAndMerge({
      context,
      fromAbsoluteFolderPath,
      partialsFolderPath,
      fromRelativeFilePath,
      toRelativeFilePath,
      toAbsoluteFilePath,
      substitutionPrefix,
      doDryRun,
    })
  } else if (fromBasename.includes('-liquid')) {
    substitute({
      context,
      fromAbsoluteFolderPath,
      partialsFolderPath,
      fromRelativeFilePath,
      toRelativeFilePath,
      toAbsoluteFilePath,
      substitutionPrefix,
      doDryRun,
    })
  } else {
    console.log(`cp -> ${toRelativeFilePath}`)
    if (!doDryRun) {
      copyFileSync(fromAbsoluteFilePath, toAbsoluteFilePath)
    }
  }

  if (!doDryRun) {
    // Except package.json which may need frequent updates,
    // make everything else read only.
    if (path.basename(toAbsoluteFilePath) !== 'package.json' && doForce) {
      const mode = statSync(toAbsoluteFilePath).mode
      chmodSync(
        toAbsoluteFilePath,
        mode & ~constants.S_IWUSR & ~constants.S_IWGRP & ~constants.S_IWOTH,
      )
    }
  } else if (!existsSync(toAbsoluteFilePath)) {
    console.log(`>>>> ${toRelativeFilePath} not present >>>>`)
  }
}

// ----------------------------------------------------------------------------
// Miscellaneous project maintenance helpers.

// Converts the release posts of a project into website blog entries,
// replacing the bash `import_releases()` helper. The per-post rendering
// still delegates to the (not yet converted) website-convert-release-post.sh
// sibling script.
export const importReleases = (projectFolderPath, scriptFolderPath) => {
  console.log()
  console.log(
    '----------------------------------------------------------------------------',
  )
  console.log(projectFolderPath)

  const name = path.basename(projectFolderPath)
  const websiteFolderPath = path.join(projectFolderPath, 'website')
  const xpackWwwReleasesFolderPath = path.join(
    websiteFolderPath,
    '_xpack.github.io',
    '_posts',
    'releases',
  )

  const npmPackageName = name.replace(/-xpack\.git$/, '')
  const releasesFolderPath = path.join(xpackWwwReleasesFolderPath, npmPackageName)
  if (!existsSync(releasesFolderPath)) {
    console.log(`No ${releasesFolderPath}, nothing to do...`)
    return
  }

  console.log()
  console.log('Release posts...')

  const files = globSync('**/*', { cwd: releasesFolderPath, dot: true, nodir: true }).sort()
  for (const file of files) {
    execFileSync(
      'bash',
      [
        path.join(scriptFolderPath, 'website-convert-release-post.sh'),
        file,
        path.join(websiteFolderPath, 'blog'),
      ],
      { cwd: releasesFolderPath, stdio: 'inherit' },
    )
  }

  console.log()
  console.log('Validating liquidjs...')

  const blogFolderPath = path.join(websiteFolderPath, 'blog')
  const blogFiles = globSync('*.md*', { cwd: blogFolderPath }).filter(
    (file) => !path.basename(file).startsWith('_'),
  )

  for (const file of blogFiles) {
    const content = readFileSync(path.join(blogFolderPath, file), 'utf8')
    if (content.includes('{{') || content.includes('{%')) {
      process.exit(1)
    }
  }

  console.log()
  console.log('Showing descriptions...')

  for (const file of blogFiles) {
    const content = readFileSync(path.join(blogFolderPath, file), 'utf8')
    for (const line of content.split('\n')) {
      if (/(title:|description:)/.test(line)) {
        console.log(line)
      }
    }
  }
}

// Downloads the pre-release binaries of a xPack Dev Tools project,
// replacing the bash `download_binaries()` helper.
export const downloadBinaries = (context, destinationFolderPath) => {
  const targetFolderPath =
    destinationFolderPath ??
    path.join(process.env.HOME ?? '', 'Downloads', 'xpack-binaries', context.topConfig.permalinkName)

  const version = process.env.XBB_RELEASE_VERSION ?? context.xpackVersion
  const backupFolderPath = `${targetFolderPath}-bak`

  rmSync(backupFolderPath, { recursive: true, force: true })
  if (existsSync(targetFolderPath)) {
    renameSync(targetFolderPath, backupFolderPath)
  }

  mkdirSync(targetFolderPath, { recursive: true })

  const platforms = context.platforms ? context.platforms.split(',') : []
  for (const platform of platforms) {
    const extension = platform === 'win32-x64' ? 'zip' : 'tar.gz'
    const archiveName = `xpack-${context.topConfig.permalinkName}-${version}-${platform}.${extension}`
    const archiveUrl =
      `https://github.com/xpack-dev-tools/pre-releases/releases/download/test/${archiveName}`

    runVerbose(
      'curl',
      ['--location', '--insecure', '--fail', '--location', '--silent', '--output', archiveName, archiveUrl],
      { cwd: targetFolderPath },
    )
    runVerbose(
      'curl',
      [
        '--location',
        '--insecure',
        '--fail',
        '--location',
        '--silent',
        '--output',
        `${archiveName}.sha`,
        `${archiveUrl}.sha`,
      ],
      { cwd: targetFolderPath },
    )
  }

  rmSync(backupFolderPath, { recursive: true, force: true })
}

// ----------------------------------------------------------------------------
