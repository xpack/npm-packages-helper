---
name: website-api-review
description: 'Review the API reference pages of the {{ topConfig.descriptiveName | replace: "'", "''" }} website, as published under /docs/api/ (generated from the TSDoc comments in src/ by api-extractor, api-documenter, and tsdoc2docusaurus): structure, consistency, readability, language, and accuracy against the code, with examples and behaviour claims confirmed by probe programs. Report the numbered problems, with fixes in the generating sources. Use when the user asks to "review the API reference", "review the API pages", "check the TSDoc pages on the website", or to find stale, wrong, or placeholder content in docs/api.'
argument-hint: 'Optional: URL, page, or member to review; defaults to the whole API reference'
---

<!--
DO NOT EDIT!
Automatically generated from template file: {{ fromFilePath }};
put the project rules in .github/skills/project.md (all the skills) or
in .github/skills/website-api-review/project.md (this skill only);
see .github/skills/README.md.
-->

{%- if hasBranchWebpreview %}
{%- assign publishedBranch = branchWebpreview %}
{%- assign publishedUrl = packageHomepagePreview %}
{%- else %}
{%- assign publishedBranch = branchWebsite %}
{%- assign publishedUrl = packageHomepage %}
{%- endif %}

# Website API Reference Review — {{ topConfig.descriptiveName }}

## When to Use

- The user asks for a review of the API reference pages, or of some
  classes, members, or types in it.
- Before a release, to find stale examples and descriptions.
- After changes to the API or to the TSDoc comments, to check what the
  reader now sees.

This skill only reports problems and suggests improvements (see
"Procedure"); applying a finding is a separate request (for example
"fix #4").

Related skills, with different scopes:

- `website-review`: the rest of the website (excludes `docs/api/`);
- `design-review`: the design of the library, from the code alone;
- `code-review`: style, documentation, and correctness of a change.

This review looks at the API through the reference pages: what a
reader learns, in which order, and whether it is true. API design
problems belong to `design-review`; report them here only when they
affect the reference (for example a deprecated accessor that the pages
list before the supported members), and cross-reference the latest
`maintenance/docs/DESIGN-REVIEW-<n>.md`.

Read `.github/skills/website-api-review/common.md` (the published version,
reading the pages, the local build, numbering, and the procedure), and
`.github/skills/review-common.md` (the rules shared by the review
skills), `.github/skills/tsdoc-rules.md`, and `.github/skills/project.md`
first, and `project.md` in this folder, if it exists (for the pages,
the vocabulary, the claims to check, and the past findings of this
project); their rules extend these, and take precedence where they
differ.

## Scope

If the user specifies a URL, a page, or a member, review only that.
Otherwise review the whole API reference: the API home page, the
package page, the class pages with the page of each member, and the
pages of the functions, the type aliases, and the interfaces.

The list of the published pages is in the site's
[`sitemap.xml`]({{ publishedUrl }}sitemap.xml); filter the URLs that
contain `/docs/api/`. The published site is <{{ publishedUrl }}docs/api/>.

The review reads the rendered text, but reports every finding against
the source that produces it, since that is where the fixes go (see
"The Site Sources").

Each run is a fresh review: do not open the earlier
`WEBSITE-API-REVIEW-<n>.md` reports (list their names only, to choose
the next number). When a finding matches an earlier one, say so only if
the user asks for it.

## The Site Sources

For each page, find its sources in the following locations:

- the TSDoc comments in `src/`: the only hand-written source of the API
  pages;
- the api-extractor configuration (`api-extractor.json`, with its
  tsconfig, in `website/config/` or in `config/`), the scripts that
  patch the model, if any, and the converter configuration,
  `website/config/tsdoc2docusaurus.json`;
- the intermediate files, all generated: `website/tsdoc/dist/`
  (the compiled declarations), `website/tsdoc/doc-model/` (the
  api-extractor model), and `website/tsdoc/markdown/` (the
  api-documenter output);
- the generated pages, `website/docs/api/**/*.md`, and the API
  navigation, `website/sidebar-category-tsdoc.json` and
  `website/docusaurus-config-navbar-tsdoc.json`;
- the home page of the API reference, `website/docs/api/index.md`, which
  is generated too.

State the scope, the branch, the commit (`git rev-parse --short
HEAD`), and the commit of the published version (`git rev-parse --short
origin/{{ publishedBranch }}`) at the top of the report.

## How the Pages Are Made

```text
src/ ─ tsc ─> tsdoc/dist/*.d.ts ─ api-extractor ─> tsdoc/doc-model/*.api.json
 (TSDoc comments)          (api-extractor.json)                │
                                                               v
                     api-documenter markdown ─> tsdoc/markdown/*.md
                                                               │
                          tsdoc2docusaurus ─> docs/api/**/*.md, sidebar and navbar
                                                               │
          published HTML <─ docusaurus build <─ push to `{{ publishedBranch }}`
```

- `npm run generate-website-tsdoc` in `website/` runs all the steps; a
  push to the `{{ publishedBranch }}` branch publishes the result.
- Every generated Markdown file carries "DO NOT EDIT! Automatically
  generated via tsdoc2docusaurus by API Documenter"; never report a fix
  to be made in a generated page. Name the source instead, marked as one
  of:
  - **[tsdoc]**: a TSDoc comment in `src/` (the usual place);
  - **[config]**: an api-extractor, tsconfig, patch script, or
    tsdoc2docusaurus configuration file;
  - **[documenter]**: `@microsoft/api-extractor` or
    `@microsoft/api-documenter` (a model or rendering behaviour that
    the configuration cannot change; report it as an observation);
  - **[converter]**: the `@xpack/tsdoc2docusaurus-cli` package (a
    rendering problem present in the api-documenter Markdown but lost or
    garbled in the pages; shared with the other xPack sites);
  - **[code]**: a change to the library code or API (use the marks of
    `.github/skills/review-common.md`, **[breaking]** or
    **[internal]**, in addition).
- The rules for the TSDoc comments (coverage, structure, markup, and
  language) are in `.github/skills/tsdoc-rules.md`; a deviation is a
  finding against the comment.
- api-extractor reads the declaration files, so the members the pages
  show are those of `tsdoc/dist/`, with the access that TypeScript
  declares; ES private fields (`#name`) never appear, while the
  protected members and the deprecated accessors do.

## Step 1 — Baseline

Use the session scratchpad (shown as `<scratch>`) for every output; do
not write into the repository, except for the final report and the tool
caches that the commands below create (for example `website/.docusaurus/`,
which is not tracked).

1. **Freshness.** Besides the differences between the published version
   and the current branch ("The Published Version"), check that the
   committed pages are current with `src/`:

   ```sh
   git log -1 --format='%h %ci %s' -- website/docs/api
   git log --oneline <that hash>..HEAD -- src website/config
   ```

   Any commit listed means that the committed pages are stale (the TSDoc
   changed after the last regeneration); check whether its content
   appears in them (`grep` the pages for a sentence it added), and report
   it as the first defect. Do the same for the published pages.

   Do not regenerate the pages in the repository
   (`npm run generate-website-tsdoc` overwrites `website/docs/api/`,
   `website/tsdoc/`, and the navigation files). When the pages are stale,
   ask the user to regenerate them before the page-level checks
   (structure, links); until then, take the text of the stale pages from
   the sources and the structure from a regeneration in a copy of the
   repository in `<scratch>`, made with
   `git worktree add <scratch>/wt HEAD`, then `npm ci` and
   `npm run generate-website-tsdoc` in its `website/`, and removed
   afterwards with `git worktree remove --force <scratch>/wt`.

2. **TSDoc checks.** Run `npm run lint` (ESLint, with the
   `typescript-eslint` rules) and note the result. Run `api-extractor`
   in the copy of the previous step, and record the warnings that it
   prints (`ae-*` and `tsdoc-*` messages: unresolved `{@link}`,
   unsupported tags, missing release tags, forgotten exports); every
   warning is a candidate finding, against the comment or the
   configuration that causes it.

3. **Build the site** into the scratchpad, to find broken links and
   anchors (see "Reading the Local Build"; it checks the working tree,
   so it covers the published pages only when "The Published Version"
   found no differences). Run it in the background and continue.

## Step 2 — Read the Pages as the Reader Sees Them

Read the downloaded pages, as described in "Reading the Published
Pages", in this order (`project.md` in this folder may give the order
of the members of this library):

1. the API home page (`index.html`) and the API navigation (the sidebar
   and the "API Reference" menu of the navigation bar, and their
   sources): how many levels before the first useful content, which
   categories are collapsed, whether a new user lands on what they need
   first;
2. the package page;
3. each class page, then the page of every member, in the order the
   reader would use them (the constructor, the common methods, the
   properties, the static members, the protected extension points, and
   the deprecated members);
4. the pages of the functions, the type aliases, and the interfaces;
   list the files under `website/docs/api/` to find the current ones,
   since the set changes with the code;
5. the indices (the class, function, type alias, and interface
   indices).

For each page, note what the reader needs first (the supported members,
an example) and what stands in the way (deprecated members listed among
the supported ones, protected internals, members without an example or
with a placeholder description).

## Step 3 — Verify Against the Code

Read each TSDoc comment together with the code it describes, in full.
The text is right only if the code says so; do not check one page
against another.

### Sources of truth

The general ones, completed by `project.md` in this folder:

- signatures, types, defaults, and return types: `src/` and the
  declarations in `dist/`;
- behaviour: the bodies in `src/`, following the call chain;
- the intended behaviour: the tests, and a probe that confirms it;
- versions and deprecations: `git tag`, `git log -S'<text>'` to find
  when a deprecation was introduced, `package.json`, and the
  `@deprecated` tags (each must name the replacement and the release
  that removes it);
- packaging claims: `package.json` and its tests, if any.

### Probes

Confirm every claim about behaviour that is not obvious from the code,
and every example, with a probe program in `<scratch>/probe/`, built as
described in `.github/skills/review-common.md` ("Confirming Findings
with Probes"). Report a finding as confirmed only when the probe
reproduced it; otherwise say that it is derived from reading the code.

**Run every example** (`@example` blocks and the code in the
`@remarks`), completed with the imports it assumes, as an ES module
against `dist/`, and compare the output with the output that the text
shows. Examples of this kind fail, for example, for imports that do not
match the package (a default import, `require()` of the package from a
project that cannot load ES modules, a path inside `dist/`), for
placeholder names that are not declared, for outputs shown wrong, and
for calls of deprecated members; `project.md` in this folder lists the
reasons found in this library. Re-verify, and look for new kinds.

### Claims that need a probe or a code path

Words such as "immediately", "always", "never", "each", "by default",
"only", "ignored", "throws", "in order". `project.md` in this folder
lists the claims of this kind to check in this library (re-verify
before reporting; the code may have changed). The behaviour of the
deprecated members must be stated on the page as it is (the deprecated
code is not changed for a documentation finding).

### Completeness

For each member, check that the page gives what a user needs
(`project.md` in this folder lists the subjects specific to this
library):

- the purpose, in the single-line brief (which is the text of every
  index), and the details after `@remarks`;
- every parameter, with its type, default, and accepted values; the
  return value; the exceptions;
- the defaults;
- the extension points, and the deprecated members with their
  replacements;
- an example for each member that is not obvious, and for the whole
  class on its page.

## Checks

### 1. Defects

Problems a reader would notice as broken or wrong. Report these first.

- stale pages (Step 1);
- placeholders (`TODO`, empty descriptions, members shown only with
  their signature);
- examples that do not run, or do not print what the text says;
- wrong names, types, and defaults;
- statements contradicted by the code, by the probes, or by another
  statement of the reference;
- deprecation notes without the replacement or the release that removes
  the member;
- rendering defects: text that api-documenter or the converter garbles
  (a `{@link}` shown as text, an escaped character, an `@example` shown
  as plain text, a broken table, a stray HTML tag), links to pages that
  do not exist, and members that appear on a page with the wrong
  heading. Compare the page with the TSDoc comment and with the
  api-documenter Markdown to decide between **[tsdoc]**, **[config]**,
  **[documenter]**, and **[converter]**.

### 2. Missing information

The completeness list of Step 3; one item per missing subject.

### 3. Structure and presentation

- depth of the navigation and collapsed categories;
- the order of the members in the class page and in the sidebar
  (alphabetical, which puts the deprecated and the protected members
  among the supported ones; whether a `@remarks` or a TSDoc structure
  can improve it, or only a converter change);
- internal or protected members shown prominently; do not propose a
  change of the api-extractor configuration to improve the pages unless
  a value is wrong (for example a wrong entry point, or a missing
  `docModel` option); fix the comments or report an observation;
- the pages of the individual members, many of which hold one line: is
  the reader helped by it, or does it only multiply the pages;
- pages and sidebar entries left from an earlier tool (for example
  typedoc).

### 4. API design, as seen in the reference

Only what the reference exposes and cannot explain well: deprecated
members that outnumber the supported ones on a page, protected members
that are an implementation detail, names that differ for the same
concept, and types that appear in signatures but have no page. Read the
latest `maintenance/docs/DESIGN-REVIEW-<n>.md` first, and write "Same as
DESIGN-REVIEW-<n> #m" or "Overlaps DESIGN-REVIEW-<n> #m" instead of
repeating its analysis; when there is none, report only what the
reference exposes. These items are decisions for the maintainer; say so.

### 5. Consistency

Build a table of the names used for the same thing and propose one:

- the vocabulary of the project (listed in `project.md` in this folder,
  or in `CLAUDE.md`);
- the mood of the briefs (third person: "Logs", "Returns", "Checks");
- the structure of the comments (brief, `@remarks`, `@example`,
  `@param`, `@returns`, `@throws`, `@deprecated`, in this order), the
  order of the content of `@remarks` (why, how, notes), the format of the
  `@throws` tags, and the markup of the lists (see
  `.github/skills/tsdoc-rules.md`);
- the wording of the parameter descriptions for the same parameter in
  the constructor, the interface, and the accessors;
- the format of the deprecation notes;
- the same example conventions (import form, variable names, the output
  shown);
- stale files that no longer belong to the API pages.

### 6. Language and style

The rules are those of `.github/copilot-instructions.md` (Language and
Tone, and the Documentation rules): British English, formal tone, no
contractions, the Oxford comma, "folder" rather than "directory", and
lines shorter than 80 characters in the TSDoc comments. In addition:

- count the boilerplate sentences repeated in every comment and the
  inflated words ("seamless", "advanced", "enhance", "facilitate",
  "comprehensive", "robust", "professional"):

  ```sh
  grep -rio '<phrase>' src | wc -l
  ```

- promotional or evaluative sentences, and unverified claims;
- sentences that describe the text instead of informing;
- briefs of more than one sentence (they appear in every index);
- `@remarks` that repeat the brief;
- long lines in the comments:

  ```sh
  find src -name '*.ts' -exec \
    awk 'length > 80 {print FILENAME":"FNR": "length}' {} +
  ```

Report a style problem only when it hinders understanding or breaks a
project rule.

### 7. Incidental observations in the code

Code defects found while verifying the reference (for example a getter
whose behaviour differs from its description, a deprecated member with
a different result, an exported type that is not documented). Say
whether the page or the code needs changing; cross-reference the latest
`DESIGN-REVIEW-<n>.md` when it already lists the problem. The
deprecated code stays as it is until the next major version: a defect
in it is a finding about the page, which must state the actual
behaviour, not a change of the code, unless the maintainer decides
otherwise.

## Report

Write the report to a new file, `maintenance/docs/WEBSITE-API-REVIEW-<n>.md`
(see "Report Files" in `.github/skills/review-common.md`), with lines
shorter than 80 characters (tables excepted):

```markdown
# Website API reference review

Date: <date from `date '+%Y-%m-%d %H:%M'`>, on branch `<branch>`,
commit `<hash>`; published site built from `{{ publishedBranch }}` commit
`<hash>` (or: local build of the working tree).

Scope: <pages and sources reviewed; the rest of the website is in
the latest WEBSITE-REVIEW-<n>.md, the library design in the latest
DESIGN-REVIEW-<n>.md>.

Method: <the published pages downloaded and read, or the local build;
whether the committed pages were current with `src/`; the results of
the lint and api-extractor checks; the Node.js version used for the
probes; the examples run>.

Summary: <n> problems (<open> open, <fixed> fixed, <withdrawn>
withdrawn). <The most serious problems, by number, and the suggested
order of work: regenerate, defects, missing information, presentation,
language; the API design decisions last.>

## Note on generated pages

<how the pages are generated and regenerated; the meaning of the
markers [tsdoc], [config], [documenter], [converter], [code]>

## 1. Defects

- **#1 — <short title>.** [tsdoc|config|documenter|converter|code]
  `<source file>` line <n>: <what is wrong, the evidence (code path,
  probe, output), and the suggested replacement text>

## 2. Missing information

## 3. Structure and presentation

## 4. API design

## 5. Consistency

| #   | Concept | Variants found (where) | Suggested |
| --- | ------- | ---------------------- | --------- |
| #n  | <name>  | <variant (file), ...>  | <choice>  |

## 6. Language and style

## 7. Incidental observations in the code

## 8. Reviewed and found correct

- <pages, members, and claims checked without problems, so that the
  next review knows what was covered>
```

Each item names the source file to change (never only the generated
page), states the problem directly, gives the evidence, and proposes
the concrete replacement text or action. When the fix is a decision
for the maintainer, say so and offer the options, rather than choosing
silently.
