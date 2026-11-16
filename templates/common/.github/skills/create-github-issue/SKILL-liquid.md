---
name: create-github-issue
description: 'Draft and open GitHub issues for bugs and enhancements in the {{ topConfig.descriptiveName | replace: "'", "''" }} repository ({{ githubProjectOrganization }}/{{ githubProjectName }}), following the project''s title, body, and label conventions. Use when the user asks to "add an issue", "open an issue", "file a bug", "create an enhancement", or to turn review findings into issues.'
argument-hint: 'Short description of the problem or improvement, or a list of findings; optionally the kind (bug or enhancement)'
---

<!--
DO NOT EDIT!
Automatically generated from template file: {{ fromFilePath }};
put the project rules in .github/skills/project.md (all the skills) or
in .github/skills/create-github-issue/project.md (this skill only);
see .github/skills/README.md.
-->

# Create Issue — {{ topConfig.descriptiveName }}

## When to Use

- The user asks to add, open, create or file a GitHub issue for a bug or an
  enhancement.
- The user asks to turn the findings of a review into issues, one issue
  per finding.

Issues are opened in `{{ githubProjectOrganization }}/{{ githubProjectName }}`
with the `gh` CLI, run from the repository root.

Read `.github/skills/project.md` first, and `project.md` in this
folder, if it exists; their rules extend these, and take precedence
where they differ.

## Procedure

1. **Establish the facts.** Read the code the issue refers to, at the
   current `HEAD`, and record the exact files and the function or
   member names, and, as a secondary pointer, the line numbers. Do not
   cite line numbers from memory or from an earlier version of the
   file. If the working tree has uncommitted changes in the cited
   files, cite the lines as they are in the committed version, or say
   so in the body.
2. **Reproduce, if it is a bug.** When it is practical, confirm the
   behaviour with a probe (see "Confirming Findings with Probes" in
   `.github/skills/review-common.md`), a test run, or the output of
   the sample programs, and keep the evidence (the command, the
   configuration name, and the relevant output) to show the user; the
   body of the issue has only the condensed form (see "Length"). State
   clearly what was measured and what was only estimated or inferred.
3. **Check for duplicates.** Search the open and closed issues:

   ```sh
   gh issue list --repo {{ githubProjectOrganization }}/{{ githubProjectName }} \
     --state all --limit 30 --search "<keywords>"
   ```

   If an issue already covers the problem, report it to the user
   instead of creating a new one, and offer to add a comment to it.
   If a related issue exists, reference it in the body (see below).
4. **Choose the labels** (see "Labels") **and the milestone, if the
   repository uses milestones** (see "Milestone").
5. **Draft the title and the body** (see "Title" and "Body"), and write
   the body to a file in the scratchpad folder.
6. **Show the draft to the user** — the title, the labels, the
   milestone, and the full body — and wait for explicit approval.
   Opening an issue is a public action; never create one, or a
   milestone, without approval. For several issues, present all drafts
   together and let the user approve, edit, or drop each of them.
7. **Create the issue:**

   ```sh
   gh issue create --repo {{ githubProjectOrganization }}/{{ githubProjectName }} \
     --title "<title>" \
     --label <label> [--label <label>] \
     [--milestone "<milestone>"] \
     --assignee @me \
     --body-file <scratchpad>/issue-body.md
   ```

   Always assign the issue to the current GitHub user (`--assignee
   @me`, the account `gh` is authenticated as). Omit `--milestone` only
   when the repository has no milestones, or when the user confirmed
   that none applies.
8. **Report** the issue number and URL. When several issues are created,
   list them as a table (number, title, labels, milestone).

## Labels

Use only the repository labels listed under "Labels" in
`.github/skills/project.md`, unless the user asks otherwise (the other
labels of the repository, such as `question` or `wontfix`, are applied
by the maintainer). The usual ones:

- `bug` — the code behaves incorrectly: wrong or invalid output,
  crashes, faults, undefined behaviour, compilation failures with a
  supported toolchain, or behaviour that contradicts the documentation
  (the issue is a `bug` whichever of the two is wrong; the proposed
  change says which one to correct).
- `enhancement` — the code works, but can be improved: refactorings,
  duplicated code, inconsistent naming or macros, performance, memory
  footprint, missing features, API additions, and documentation
  wording.
- Both `bug` and `enhancement` — when a defect can only be fixed by a
  new feature or a new public API (for example a missing extension
  point whose absence leads to a failure).

Unless `.github/skills/project.md` lists it, the `documentation` label
is not used; documentation issues are labelled `enhancement` when the
text is correct but can be improved, and `bug` when it is wrong or
contradicts the code. If the kind is uncertain, say so and ask the
user.

## Title

- State the **current problem**, not the fix: the title describes what
  is wrong or missing, in the present tense, as a full sentence.
  - Good: `The trace output is written one character at a time`
  - Good: `` `write()` returns after a partial write ``
  - Bad: `Refactor the trace output` (describes the fix).
  - Bad: `Fix stack overflow` (imperative, vague).
- Usually start with `The ...`, or with the code identifier in
  backticks.
- Capitalise the first word, unless it is a code identifier in
  backticks; do not end with a period.
- Keep it under 70 characters.
- Do not prefix it with the kind (`Bug:`, `[enhancement]`) or an issue
  number; the labels carry the kind.

## Body

Write the body as plain Markdown prose, kept short (see "Length"), in
British English, formal, with no contractions, the Oxford comma, and the
lines wrapped at 72 characters. Use backticks for file names,
identifiers, macros, options, configuration names, and commit hashes.
Do not use headings or templates (no "Steps to reproduce" / "Expected" /
"Actual" sections); the information is given as connected sentences, in
this order, merged into the two paragraphs allowed by "Length", with
only the parts that the issue needs:

1. **Location.** Open with the file and the function or member, and,
   when it helps, the line numbers, followed by a colon, for example:
   `` `src/<file>`, `<class>::<member>()`, lines 163 to 166: ``.
   The function or member name is required; the line numbers are not,
   because they change with the first edit of the file. Paths are
   relative to the repository root, unless "Paths" in
   `.github/skills/project.md` allows a shorter form.
2. **Observation.** What the code does, precisely: the configuration
   and the command, the observed output or fault, and the cause, if
   known. For a bug, include the evidence from the reproduction and
   mark estimates as estimates. Mention a related commit by its short
   hash only when it bears on the cause (it introduced the problem, or
   it is not the cause).
3. **Scope.** Only when it changes the decision: which other
   platforms, toolchains, or files are, or may be, affected, and why a
   passing case does not prove the absence of the problem.
4. **Proposed change.** In the imperative (`Remove it.`, `Add a
   helper ...`, `Measure ..., and then either ...`). When several
   solutions are possible, list them and state the trade-offs; do not
   pretend that one is obviously right. Mention any test to add, and
   any generated file whose source must be changed instead (see
   "Generated Files" in `.github/skills/project.md`).
5. **References**, if any, as a final short paragraph, for example
   `Found while fixing #134.` or `Decide together with #118.`

### Length

Issues are read by the maintainer, who knows the code: keep them short.

- The body has at most two paragraphs (the location and the observation
  together, then the proposed change), plus the final reference line,
  and normally no more than 12 lines of 72 characters.
- Cite the location once, with the primary file and the first line or
  the function name; do not list every affected line, file, or
  declaration.
- State the evidence in a clause (the failing expression and the
  result, with the configuration in brackets), not as a narrative; give
  the full output only when it is needed to understand the problem.
- Omit what the reader can see in the code or in the title, the
  background of the feature, the scope, and the trade-offs, unless they
  change the decision (the scope and the trade-offs of the proposed
  change are the only such cases); the proposal is a single sentence,
  or a short list when there are several solutions.
- Do not describe the work already done on the fix.

A simple finding is a single paragraph of two to four lines.

## Milestone

Follow "Milestones" in `.github/skills/project.md`. List the
milestones before drafting:

```sh
gh api 'repos/{{ githubProjectOrganization }}/{{ githubProjectName }}/milestones?state=all' \
  --jq '.[] | "\(.title)\t\(.state)\t\(.description)"'
```

- If the repository has no milestones, omit `--milestone` from the
  command, unless `.github/skills/project.md` says that they are used;
  then ask the user whether to create one.
- Otherwise, propose the appropriate one in the draft (usually the
  milestone of the next release; a breaking change belongs to the next
  major release), and assign it with `--milestone`.
- If no milestone applies, ask the user whether to proceed without one
  or to create one. Creating a milestone is a public action: show its
  title and description, wait for approval, and then create it with
  `gh api --method POST
  repos/{{ githubProjectOrganization }}/{{ githubProjectName }}/milestones
  -f title="<title>"`.

## Issues from Review Findings

When the findings of a review (a report in `maintenance/docs/`; see
"Report Files" in `.github/skills/review-common.md`) are turned into
issues:

- Write one issue per numbered finding, and do not group independent
  findings; each issue is self-contained and does not rely on the
  review file, which may be uncommitted. Do not cite the number of the
  finding in the title or in the body (it is not a GitHub number, and
  would be confused with one).
- Take the location, the evidence, and the proposed change from the
  finding, and check them against the current `HEAD` (step 1), because
  the review may be older than the code.
- Check for duplicates for each finding (step 3).
- After the issue is created, the number of the issue is recorded in
  the review document, as described under "Review Documents" in
  `.github/skills/github-commit/SKILL.md`; ask the user before editing
  the document.

## Example

A hypothetical example, which illustrates the format only; the project
may give real ones in `project.md` in this folder.

Title: `The trace write gives up after a partial write`

Labels: `bug`

```markdown
`src/trace.cpp`, `write()`: when the host accepts only part of the
buffer, the call returns the number of bytes not written, and the
function returns the shorter count, so the remaining bytes of the
trace line are lost. Repeat the call for the remaining bytes, and add
a test for the partial writes.

Found while fixing #NNN.
```

## After the Issue Is Fixed

The fix is committed with the `github-commit` skill, which also adds
the closing comment to the issue (see its "Issue Comment" section); the
issue is not closed by hand.
