# Copilot Instructions

## Project Overview

This is the **{{packageConfig.descriptiveName}}** project, part of the
xPack Development Tools.

{%- if packageConfig.isWebDeployOnly != "true" %}

## Folder Structure

{% if packageConfig.isXpackBinary == "true" -%}
- `/build-assets`: Contains the build scripts, patches, etc
{%- endif %}
- `/website`: Contains the Docusaurus web site
{%- endif %}

## Language and style

- Use British English spelling and grammar.
- Use a professional tone.
- Prefer folder to directory.
