# Project Facts for the Skills — {{ topConfig.descriptiveName }}

This file is owned by the project; it was created once from the
template `{{ fromFilePath }}`, and it is never regenerated. Edit it to
match the project.

The skills in `.github/skills/` (generated from the template, and
regenerated with `npm run generate-top-commons`) read it for the facts
that are specific to this project, under the headings below; keep the
headings, since the skills refer to them by name. A skill folder may
also have its own `project.md`, for the rules of that skill only.
Where this file and a skill disagree, this file takes precedence, and
a `project.md` in a skill folder takes precedence over this file. See
`.github/skills/README.md` for the details.

## Tests

{%- if hasFolderTestsPackage %}
{%- if githubProjectOrganization == 'micro-os-plus' %}

- After major changes, run a minimal selection of tests:
  `xpm run test-selected -C tests`.
- After minor changes, run only the tests built with the system
  compiler: `xpm run test -C tests`.
- For a change that affects the embedded targets, also run the
  platform-specific actions of `tests/package.json` (for example
  `xpm run test-qemu-cortex-m7f-cmake-gcc -C tests`).
{%- else %}

- After each change, run `npm run compile` and `npm test`.
{%- endif %}
{%- else %}

- The project has no tests.
{%- endif %}

## Probes

{%- if githubProjectOrganization == 'micro-os-plus' %}

Build the probe programs in the scratchpad folder, against the sources
of the project, with no other dependency:

```sh
P=<scratch>/probe
W="-Wall -Wextra -Wpedantic"
for f in src/*.cpp
do
  c++ -std=c++20 $W -Iinclude -c "$f" -o "$P/$(basename "$f" .cpp).o"
done
c++ -std=c++20 $W -Iinclude "$P/p1.cpp" "$P"/*.o -o "$P/p1"
"$P/p1"
```
{%- else %}

Run `npm run compile`, so that `dist/` is current, and write an ES
module probe (`.mjs`) in the scratchpad folder, which imports the
absolute path of `dist/index.js`; run it with `node`.
{%- endif %}

## Generated Files

{%- if githubProjectOrganization == 'micro-os-plus' %}

- The top-level `CMakeLists.txt` and `meson.build` are generated from
  `xcdl-package.jsonc` with `xpm run xcdl-export`; they are never
  edited by hand.
{%- endif %}
- The files with a `DO NOT EDIT!` header are generated from templates
  (named in the header) and are fixed in their templates.

## Files Not to Commit

- The `node_modules/` and `xpacks/` folders, the build folders, and
  the `.tgz` packages.

## Labels

- `bug` and `enhancement`.

## Milestones

- The milestones are named after the version of the release (the
  `version` of `package.json` without the pre-release suffix).

## Review Documents

- None yet; the review reports are written to `maintenance/docs/`.

## Breaking Changes

- The public API{% if githubProjectOrganization == 'micro-os-plus' %} (the
  public headers in `include/`){% else %} (the names exported by the
  package){% endif %}, the behaviour that the documentation describes,
  and the minimum supported toolchains.

## Documentation Updates

{%- if hasFolderWebsitePackage %}

- The hand-written pages of the website are in `website/docs/`; the
  files with a `DO NOT EDIT!` header and the API reference pages under
  `website/docs/api/` are generated, and are not edited.
{%- else %}

- The project has no website.
{%- endif %}

## Paths

- The paths in the reports and in the issues are relative to the
  repository root.
