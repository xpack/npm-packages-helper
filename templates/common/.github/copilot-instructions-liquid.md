# Copilot Instructions

## Project Overview

This is the **{{topConfig.descriptiveName}}** project, part of 
{%- if githubProjectOrganization == 'xpack' %}
the xPack Reproducible Build Framework.
{%- elsif githubProjectOrganization == 'xpack-dev-tools' %}
the xPack Binary Development Tools.
{%- elsif githubProjectOrganization == 'micro-os-plus' %}
µOS++.
{%- endif %}

## General

- Avoid sycophantic behaviour; for all conversation, never soften criticism
  to protect the person's ego.
- If something has a flaw, say so directly.
- When the meaning of a question is uncertain, say so and ask questions
  rather than guess.
- When multiple valid answers are possible, say so and ask questions to
  identify the most appropriate one, rather than assuming a single
  correct answer.
- This applies to every response.

## Language and Tone

- Use British English spelling and grammar (e.g., "behaviour", "colour",
  "organise", "analyse", "favour", "initialise", etc.)
- Maintain a professional and formal tone in all generated content
- Avoid colloquialisms, slang, or informal expressions
- Avoid humour, jokes, or casual remarks
- Use clear, precise, and professional language appropriate for technical
  documentation
- Avoid contractions (e.g., use "do not" instead of "don't")
- Use the Oxford comma in lists for clarity
- Maintain consistency in terminology throughout the codebase
- Prefer "folder" to "directory"

{%- if githubProjectOrganization == 'xpack' %}

## TypeScript Code Style

- Follow the existing ESlint TypeScript conventions (the rules defined by the `typescript-eslint` and `prettier` projects)
- Use consistent formatting and naming conventions based on prettier and ESLint configurations
- For TypeScript/JavaScript, the naming convention is camelCase 

## Documentation

- Add comprehensive TSDoc comments accepted by API Extractor
- Document all classes, methods, properties, parameters, and return types
- Document private and protected members as well
- Keep the line length below 80 characters
- If the code already includes documentation, review and possibly improve it
- Preserve the `// eslint-disable-next-line` comments when present
- Use `@remarks` for additional detailed notes or explanations within TSDoc comments; this should be placed after the summary and before any tags
- Use `@param` and `@returns` tags appropriately in TSDoc comments; place `@param` tags immediately after the summary and before `@returns`
- Use `@throws {@link ExceptionName}` for exceptions and place the descriptions on the next line; place these tags after `@returns`
- Precede `@throws` tags with an empty line, and place the description on the next line
- Do not documnent exceptions thrown by assertions
- Do not add `@public` or `@internal` tags 
- When generating lists in TSDoc `@remarks` comments, use html `<ol>` and `<li>` tags for ordered lists, and `<ul>` and `<li>` tags for unordered lists. 
- inside html lists, do not use markdown syntax for bold or italics, use `<b>`, `<i>` html tags instead
- inside html lists, do not use markdown syntax for code, use `<code>` html tags  instead 
- inside html lists, do not use `{@link name}` syntax for links, use `<code>` html tags  instead
- outside of html lists, use markdown syntax for code (`code`) and links (`{@link name}`)
- In the `@remarks` section, first explain why the method or property is useful, then explain how to use it, and finally provide any additional notes or details.

## Folder Structure

- `/src`: Contains the TypeScript source code
- `/tests`: Contains the test suites and test cases
- `/templates`: Contains any template files used for code generation or project scaffolding

{%- elsif githubProjectOrganization == 'xpack-dev-tools' %}

{%- unless topConfig.isWebDeployOnly %}

## Folder Structure

{% if isXpackBinary -%}
- `/build-assets`: Contains the build scripts, patches, etc
{%- endif %}
- `/website`: Contains the project Docusaurus website
{%- endunless %}

{%- elsif githubProjectOrganization == 'micro-os-plus' %}

## Code Style

- Follow the existing C++ code style defined in the .clang-format file.
- Use consistent formatting and naming conventions based on prettier and
  clang-format configurations.
- For C/C++, the naming convention is snake_case.
- For C++, write multiple level namespaces on the same line.

## Includes order

- Project-specific headers.
- µOS++ headers
- Third-party library headers.
- Standard library headers.
- Use alphabetical order within each group.
- Separate each group with a blank line.
- Brace the whole group of includes by separator lines

## Compiler pragmas

When needed to silence warnings, use separate groups of pragmas for each compiler.

Always use __GNUC__ guards, and, if necessary, __clang__ guards to apply 
compiler-specific pragmas.

```c
#if defined(__GNUC__)
#pragma GCC diagnostic ignored "-Waggregate-return"
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wc++98-compat"
#pragma clang diagnostic ignored "-Wc++98-compat-pedantic"
#endif // defined(__GNUC__)
#pragma GCC diagnostic ignored "-Wredundant-tags"
#endif // defined(__clang__)
#endif // defined(__GNUC__)
```

Brace the whole group of includes by separator lines.

## Documentation

- Add comprehensive documentation comments accepted by Doxygen
- Document all classes, methods, properties, parameters, and return types.
- The declarations should be in the headers, the definitions in the `src`
  folder, and the inline definitions in the `inlines` folder.
- Add @details sections to all declarations and definitions.
- The @brief and @details sections are displayed sequentially, so ensure the
  @details section expands on the @brief without repeating it. The @brief
  should be a concise summary of the member's purpose, whilst the @details
  should provide a more in-depth explanation, including any relevant
  information about the implementation, usage, or edge cases.
- Document private and protected members as well
- Keep the line length below 80 characters
- If the code already includes documentation, review and possibly improve it.

## Folder Structure

- `/src`: Contains the C++ source code
- `/include`: Contains the C++ header files
- `/tests`: Contains the test suites and test cases
- `/website`: Contains the project documentation and guides
- `/maintenance`: Contains the project maintenance resources, which are
  not published with the package: `/maintenance/config` (the formatter
  configuration files), `/maintenance/scripts` (the maintenance scripts
  and their templates), and `/maintenance/docs` (the developer notes)

When adding new source files, place them in the appropriate `src` or `include`
folder, and add corresponding entries in the top CMake and Meson configurations.

Avoid running `find /` commands that search the entire filesystem, as this 
always timeouts.

## Tools binaries

The tools binaries required for the project are located in the `xpacks/.bin`
folder within the build folders and the project root.

## Testing

After making changes, run in a terminal:

- `xpm run test -C tests` to execute the test with the system compiler
- `xpm run test-native-cmake-clang -C tests` to execute the test with clang
- `xpm run test-qemu-cortex-m7f-cmake-gcc -C tests` to execute the test with cross gcc

When using linked writable projects, it is necessary to run the linking step to ensure all dependencies are correctly resolved.

- `xpm run link-dependencies --config <name>`

When using non-native platforms, run one by one specific actions for the given configuration.

- `xpm run setup --config <name>`
- `xpm run build --config <name>`

For non-qemu plaforms, running the tests can be done only after confirming that the board is 
powered up, with the command:

- `xpm run test --config <name>`

QEMU tests can be done directly, without confirmation that the board is
powered up.

## Code Review

{%- if githubProjectOrganization == 'micro-os-plus' %}

- When asked for a code review, follow the separate instructions in
`.github/skills/code-review/SKILL.md` for a thorough and uncompromising
review of the codebase.
{%-else %}

- When asked for a code review, provide constructive feedback on all aspects,
  including the code's readability, maintainability, and adherence to the
  project's coding standards.
- Find every flaw, gap, or weak assumption. Focus on code structure, naming
  conventions, documentation quality, and potential bugs or performance issues.
- Be specific and direct. Do not soften criticism or balance it with positives.
- Mention what you did leave out because you were not certain enough to
  include it.
- Leave the code review result in a separate file named `CODE-REVIEW.md` in
  the root of the project, including a summary of the review findings and
  specific recommendations for improvements.
{%- endif %}

## Commit Message Guidelines

When making changes to the codebase, follow these guidelines for version control:

- Use the imperative mood in the subject line (e.g., "Fix bug" instead of "Fixed bug" or "Fixes bug").
- Limit the subject line to 50 characters.
- Capitalize the subject line.
- Do not end the subject line with a period.
- Use the body to explain what and why vs. how.
- Wrap the body at 72 characters.
- Include references to relevant issues or pull requests if applicable.

{%- if githubProjectOrganization == 'micro-os-plus' %}

## xcdl

The `xcdl` tool is not yet available; `xcdl-package.jsonc` is used only to
generate the top-level CMake and Meson files (`xpm run xcdl-export`). Only
`publicIncludeFolders`, `sourceFiles`, and `dependencies` affect the
generated files; all other properties (`generatedFile`, `activeIf`,
`defaultValue`, `implements`, and the commented-out `defaultDefine`
entries) are informative only.

In particular, no `*-defines.h` file is generated, so a commented-out
`defaultDefine` does not mean that the macro is disabled. Its name
documents the macro that the application must define itself, either in
`micro-os-plus/project-config.h` or in project specific header files 
(e.g., `micro-os-plus/startup-defines.h`).

{%- endif %}

{%- endif %}
