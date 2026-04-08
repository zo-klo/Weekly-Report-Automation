# Report Automation Portfolio Piece

Back in February, I noticed an opportunity to streamline my organization's weekly data tracking system, which involved manually pasting data from R into Google Sheets.

This repository represents a sanitized version of the R automation workflow I developed- the original working version was built inside a larger internal survey analysis repository as an extension of an existing workflow. 

## Project Summary

This automation takes cleaned survey outputs, calculates recurring demographic summaries, groups source codes, and appends each reporting run to a Google Sheet used for weekly tracking.

The original working version was built inside a larger internal survey analysis repository. For portfolio use, this version focuses on the automation logic and removes machine-specific setup details, private IDs, and organization-specific naming.

## Files

- `report_automation_portfolio.R`: public-facing version of the automation workflow
- `config/report_config_template.yml`: template for local configuration
- `.gitignore`: keeps local credentials and generated artifacts out of version control

## Expected Inputs

The script expects these files to already exist in the survey project you point it to:

- `data/output/wrangled.csv`
- `data/processed/cleaned_unfiltered.csv`
- `data/input/f25_source_codes.csv`

Those files are produced upstream by the cleaning and wrangling steps in the main analysis workflow.

## How To Run

1. Copy `config/report_config_template.yml` to `config/report_config.yml`.
2. Fill in your local project path and Google Sheet ID.
3. Open `report_automation_portfolio.R` in RStudio or run it with `Rscript`.
4. Authenticate with Google when prompted.

## Notes For Reviewers

This repository version is intentionally sanitized:

- No private data is included
- No production Google Sheet IDs are exposed
- The script is designed to show workflow design and automation structure rather than provide runnable public data
