# Report Automation Portfolio Piece

Back in February, I noticed an opportunity to streamline my organization's weekly data tracking system, which involved manually pasting data from R into Google Sheets.

This repository represents a sanitized version of the R automation workflow I developed. The original working version was built inside a larger internal survey analysis repository as an extension of an existing workflow, and this public version is also runnable with synthetic demo data.

## Project Summary

This automation takes cleaned survey outputs, calculates recurring demographic summaries, groups source codes, and writes each run to shareable output files. It can also optionally append results to a Google Sheet.

The original working version was built inside a larger internal survey analysis repository. For portfolio use, this version focuses on the automation logic and removes machine-specific setup details, private IDs, and organization-specific naming.

## What This Demonstrates

- Translating a manual reporting workflow into a repeatable script
- Connecting R analysis outputs to Google Sheets for stakeholder reporting
- Structuring demographic rollups for recurring operational updates
- Refactoring a one-off local script into a shareable, configurable project artifact

## Portfolio-Friendly Improvements

- Added synthetic demo inputs so the project can run out of the box
- Replaced hard-coded local paths with a config file template
- Isolated the report automation into a standalone script
- Removed live credentials and private spreadsheet identifiers
- Added local CSV outputs so reviewers can run the workflow without external services
## Files

- `report_automation_portfolio.R`: public-facing version of the automation workflow
- `config/report_config_template.yml`: template for local configuration
- `data/demo/`: synthetic example inputs that mirror the required structure
- `output/`: generated results from the demo workflow
- `.gitignore`: keeps local credentials and generated artifacts out of version control

## Demo Inputs

The repository includes synthetic demo versions of the three required inputs:

- `data/demo/wrangled_demo.csv`
- `data/demo/cleaned_unfiltered_demo.csv`
- `data/demo/source_codes_demo.csv`

These files are fake but structurally similar to the real reporting inputs, so reviewers can run the workflow without access to private survey data.

## Using Real Data

To point the project at your real survey files, update the paths in `config/report_config.yml` after copying from the template.

## How To Run

1. Copy `config/report_config_template.yml` to `config/report_config.yml`.
2. Leave the demo file paths as-is for a reproducible local run.
3. Open `report_automation_portfolio.R` in RStudio or run it with `Rscript`.
4. Check the generated CSVs in `output/`.

## Optional Google Sheets Upload

If you want to write to your own Google Sheet:

1. Set `use_google_sheets: true` in `config/report_config.yml`.
2. Replace `PASTE_YOUR_SHEET_ID_HERE` with your sheet ID.
3. Install `googlesheets4` and `googledrive` if needed.
4. Re-run the script and authenticate with Google when prompted.

## Notes For Reviewers

This repository version is intentionally sanitized but runnable:

- No private data is included
- No production Google Sheet IDs are exposed
- The demo data is synthetic and intended only to demonstrate the workflow

## Suggested GitHub Framing

If you publish this as a portfolio repo, a good subtitle would be:

`R automation workflow for recurring survey reporting, demographic summaries, and Google Sheets delivery`
