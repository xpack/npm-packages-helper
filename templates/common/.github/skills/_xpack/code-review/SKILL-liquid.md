---
name: code-review
description: 'Perform a thorough, uncompromising code review of a change (uncommitted changes, a set of commits, or a path) in the {{ topConfig.descriptiveName | replace: "'", "''" }} project ({{ packageScopedName }}): style, naming, TSDoc documentation, API and packaging, tests, and correctness. Report the problems found in a new numbered report, each with a permanent number. Use when the user asks for a "code review", to "review the code", to "review changes", or to check a file, folder, or diff before a commit.'
argument-hint: 'Optional: path, commit range, or "staged"; defaults to the uncommitted changes, or to the commits on {{ branchDevelopment }} not yet on {{ branchMain }}'
---

<!--
DO NOT EDIT!
Automatically generated from template file: {{ fromFilePath }};
put the project rules in .github/skills/project.md (all the skills) or
in .github/skills/code-review/project.md (this skill only);
see .github/skills/README.md.
-->

# Code Review — {{ topConfig.descriptiveName }}

## When to Use

- The user asks for a code review of a file, folder, diff, or set of
  commits.
- The user asks to check adherence to the project's coding standards
  before a commit.

This skill reviews a change against the project's conventions. The
design of the library as a whole (the public API, the packaging, the
structure) is reviewed by the `design-review` skill; suggest it when a
change raises a question of that kind, rather than extending this
review.

Read `.github/skills/review-common.md` (the rules shared by the review
skills) and `.github/skills/project-defaults.md`, `.github/skills/project.md` first, and `project.md` in this
folder, if it exists (for the checks specific to this library); their
rules extend these, and take precedence where they differ. The project
conventions are also in `.github/copilot-instructions.md`.

## Review Scope

- If the user specifies a path, review that path in full.
- If the user specifies commits or a range, review their diff
  (`git diff <range>`), reading the changed files in full for context.
- Otherwise, review the uncommitted changes (`git diff HEAD`); if the
  working tree is clean, review the commits on `{{ branchDevelopment }}`
  that are not on `{{ branchMain }}`
  (`git diff {{ branchMain }}...{{ branchDevelopment }}`).

Include the tests that exercise the changed code, and the parts of
`package.json` that depend on it (`exports`, `main`, `types`,
`dependencies`, `scripts`, `engines`).

Do not review `dist/` (the compiled output; review the sources that
produce it), `node_modules/`, `website/`, or the generated common files
(the workflows, and the `_common` folders under `website/`), which are
produced by `generate-top-commons`.

State the scope, the branch, and the commit (`git rev-parse --short
HEAD`) at the top of the report.

## Checklist

Review every item below, with file and line references.

### Naming and style

- The code passes `npm run lint` (ESLint, with the `typescript-eslint`
  rules) and is formatted by Prettier with the project configuration
  (in `maintenance/config/`); no line exceeds 80 characters, including
  comments, except for URLs.
- Classes, interfaces, and types are `PascalCase`; functions, methods,
  properties, and variables are `camelCase`; constants follow the style
  already used in the file.
- Member names that are not public follow the convention already used
  in the project (see `project.md` in this folder); flag a new member
  that does not.
- Method names start with a verb that states their effect; getters
  have no side effects.
- Relative imports use the `.js` extension (Node.js ES module
  resolution).
- The sections of a file use the existing separator comments
  (`// ----` and `// ====`).
- The change follows the patterns already used elsewhere in the code
  base, or has a visible reason not to.

### Documentation (TSDoc)

- Check every comment against `.github/skills/tsdoc-rules.md` (coverage,
  structure, markup, and language), and report each deviation where it
  is found.
- The file header carries the xPack MIT licence block, with a plausible
  copyright year range.

### API and packaging

- A new public member is exported through `src/index.ts`; nothing that
  should be private is exported.
- A change to the contract with the users, as listed under "Breaking
  Changes" in `.github/skills/project.md`, is flagged **[breaking]**.
- `package.json` stays consistent with the code: `exports`, `main`, and
  `types` point to files that exist after `npm run compile`, and the
  compiled entry point exports everything that `src/index.ts` does.
- The package is ES module only (`"type": "module"`); flag any CommonJS
  construct (`require`, `__dirname`, `module.exports`), and any change
  that reintroduces a CommonJS entry point.
- A new runtime import in `src/` is in `dependencies`; a dependency
  that `src/` no longer imports is removed; the tools used only by the
  tests and the build are in `devDependencies`.

### Correctness and robustness

- The behaviour of the library (the rules listed in `project.md` in
  this folder) is preserved, or changed on purpose and documented.
- Arguments: `undefined`, `null`, empty values, and unexpected types are
  handled as documented.
- `assert()` is used for programming errors only, with a message that
  tells the caller what was wrong.
- Type safety: no `any` where a type is possible, no non-null
  assertions without justification, and no casts instead of guards.
- Errors: the exceptions thrown are those documented, with messages
  that tell the caller what to do; asynchronous errors are not lost
  (every promise is awaited or returned).
- The change adds no dead code and does not duplicate logic that
  already exists.

### Tests

- Every behaviour added or changed has a test; a defect fix has a test
  that fails without the fix.
- Tests follow the existing files (the framework, the file names, the
  helpers), and check the exact results.
- The tests would still pass if the implementation were wrong in the
  obvious way.
- The coverage required by the project (see "Tests" in
  `.github/skills/project.md`) still holds.

## Tooling Verification

Verify by running rather than by reading only:

```sh
npm run compile
npm run lint
npm test
```

Report the failures and every uncovered line. Do not run `npm run fix`,
which modifies the files. Do not accept inline `eslint-disable` comments
that silence a finding without a stated reason.

The release notes (`CHANGELOG.md`) are written during the release
preparation, not with each change; do not report their absence from a
change.

## Evidence

Probe the suspected defects as described under "Confirming Findings
with Probes" in `.github/skills/review-common.md`, and tag the
confirmed ones **[confirmed]**.

## Report

Write the report to a new file, `maintenance/docs/CODE-REVIEW-<n>.md`
(see "Report Files" in `.github/skills/review-common.md`):

```markdown
# Code review

Date: <YYYY-MM-DD HH:MM>, on branch `<branch>`, commit `<hash>`.

Scope: <the path, the range, or the uncommitted changes>.

Tooling: <the results of compile, lint, and test, with the coverage>.

Summary: <n> problems. <The most serious, by number.>

## Naming and style

- **#1 — <short title>.** [internal] **[confirmed]**
  `<file>` line <n>: <what is wrong, the evidence, and the suggested
  change>

## Documentation

## API and packaging

## Correctness and robustness

## Tests

## Not reported

<anything left out because it was not certain enough to include>
```

## Procedure

1. Identify the review scope, and the number of the new report.
2. Read the changed files fully; do not review from partial context.
3. Go through the checklist section by section, collecting concrete
   findings (file, line, description, why it matters).
4. Probe the suspected defects that can be probed.
5. Run the tooling, and include the results.
6. Write the report to the new file, and check the numbering.
7. Give the user a short summary: the counts and the most serious
   problems by number.
8. Do not fix the issues unless the user asks for that separately; see
   "Acting on an Item" in `.github/skills/review-common.md`.
