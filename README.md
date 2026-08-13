# Weekly Report Automation

An R workflow that automates recurring survey reporting, replacing manual data transfer with a reproducible pipeline for demographic summaries and stakeholder-ready outputs.

## Overview

This project grew out of a recurring reporting workflow that required manually transferring survey results from R into Google Sheets. I developed an automation workflow to reduce repetitive reporting work and make weekly updates more consistent and reproducible.

The workflow:

- processes cleaned survey outputs
- calculates recurring demographic summaries
- groups and standardizes source codes
- generates shareable reporting files
- optionally appends results directly to Google Sheets

## Why I Built It

The original reporting process involved manually copying results from R into shared spreadsheets each week. Because the same transformations and summaries were repeated across reporting cycles, the workflow was a good candidate for automation.

I translated those recurring steps into a configurable R script that could reproduce the required summaries and prepare them for stakeholder reporting.

## Workflow

1. Load cleaned survey data and configuration settings
2. Calculate recurring demographic summaries
3. Group source codes into reporting categories
4. Generate standardized output files
5. Optionally append results to a shared Google Sheet

## Portfolio Version

The original workflow was developed within a larger internal survey-analysis repository using private organizational data.

This public version preserves the automation logic while removing private IDs, organization-specific naming, credentials, and machine-specific configuration. Synthetic demo data matching the required input structure is included so the workflow can be run end-to-end.


## Files

- `report_automation_portfolio.R` — main automation workflow
- `config/report_config_template.yml` — configuration template
- `data/demo/` — synthetic example inputs
- `output/` — example generated outputs
- `.gitignore` — excludes credentials, local configuration, and generated artifacts

## How to Run

1. Copy `config/report_config_template.yml` to `config/report_config.yml`.
2. Leave the demo file paths unchanged for a reproducible local run.
3. Run `report_automation_portfolio.R` in RStudio or with `Rscript`.
4. Review the generated reporting files in `output/`.

## Optional Google Sheets Integration

To connect the workflow to your own Google Sheet:

1. Set `use_google_sheets: true` in `config/report_config.yml`.
2. Add your Google Sheet ID.
3. Install `googlesheets4` and `googledrive` if needed.
4. Run the script and authenticate with Google when prompted.

## Tools

- R
- tidyverse
- YAML
- googlesheets4
- googledrive
