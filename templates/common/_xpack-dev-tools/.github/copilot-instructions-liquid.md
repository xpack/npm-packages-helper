# Copilot Instructions

## Project Overview

This is the **{{packageConfig.descriptiveName}}** project, part of the xPack Development Tools.

## Language and Tone

- Use British English spelling and grammar (e.g., "behaviour", "colour", "organise", "analyse", "favour", "innitialise", etc.)
- Maintain a professional and formal tone in all generated content
- Avoid colloquialisms, slang, or informal expressions
- Avoid humour, jokes, or casual remarks
- Use clear, precise, and professional language appropriate for technical documentation
- Avoid contractions (e.g., use "do not" instead of "don't")
- Use the Oxford comma in lists for clarity
- Maintain consistency in terminology throughout the codebase
- Prefer "folder" to "directory"

{%- if packageConfig.isWebDeployOnly != "true" %}

## Folder Structure

{% if isXpackBinary == "true" -%}
- `/build-assets`: Contains the build scripts, patches, etc
{%- endif %}
- `/website`: Contains the project Docusaurus website
{%- endif %}
