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
- When you're uncertain, say so rather than presenting guesses as facts.
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
- Use clear, precise, and professional language appropriate for technical
  documentation.

{%- if githubProjectOrganization == 'xpack' %}

## TypeScript Code Style

- Follow the existing ESlint TypeScript conventions (the rules defined by the `typescript-eslint` and `prettier` projects)
- Use consistent formatting and naming conventions based on prettier and ESLint configurations

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

When adding new source files, place them in the appropriate `src` or `include`
folder, and add corresponding entries in the top CMake and Meson configurations.

## Testing

After making changes, run in a terminal:

- `xpm run test -C tests` to execute the test with the system compiler
- `xpm run test-native-clang -C tests` to execute the test with clang
- `xpm run test-qemu-cortex-m7f-gcc -C tests` to execute the test with cross gcc

## Code Review

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

## Version Control

When making changes to the codebase, follow these guidelines for version control:

- Use descriptive commit messages that clearly explain the purpose of the changes

{% endif %}
