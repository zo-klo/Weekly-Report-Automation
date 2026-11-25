# 1. Load the survey data ----
library(dplyr)
library(readr)
library(stringr)

# Run from the project folder. Use the demo settings unless a local config exists.
config_path <- "config/report_config.yml"
if (!file.exists(config_path)) {
  config_path <- "config/report_config_template.yml"
}
config <- yaml::read_yaml(config_path)

wrangled <- read_csv(
  config$wrangled_data_path, col_types = cols(source = col_character())
)
cleaned_unfiltered <- read_csv(config$cleaned_unfiltered_path, show_col_types = FALSE)
codes <- read_csv(config$source_codes_path, col_types = cols(source = col_character()))

# 2. Count all and included responses ----
run_date <- Sys.Date()
all_n <- nrow(cleaned_unfiltered)
included_n <- nrow(wrangled)
included_percent <- if (all_n > 0) {
  paste0(round(100 * included_n / all_n, 1), "%")
} else {
  "N/A"
}

entry_counts <- tibble(
  label = c("Date", "All Responses", "Included Responses"),
  value = c(as.character(run_date), all_n, paste0(included_n, " (", included_percent, ")"))
)

# 3. Build the demographic tables ----
summarize_section <- function(data, column, section_name) {
  # Each share uses all included responses, including missing answers.
  data %>%
    count({{ column }}, name = "count") %>%
    mutate(
      section = section_name,
      variable = as.character({{ column }}),
      per = round(count / nrow(data), 2),
      total = nrow(data)
    ) %>%
    select(section, variable, count, per, total)
}

demographic_sections <- list(
  summarize_section(wrangled, gender_2, "Gender"),
  summarize_section(wrangled, race_census, "Race"),
  summarize_section(wrangled, borough, "Borough"),
  summarize_section(wrangled, relig, "Religion"),
  summarize_section(wrangled, sch_level, "Education"),
  summarize_section(wrangled, income, "Income"),
  summarize_section(wrangled, below_poverty_bi, "Below Poverty / Low Income"),
  summarize_section(wrangled, hh_disability, "Household With a Disability"),
  summarize_section(wrangled, res_length, "Length of Time in NYC"),
  summarize_section(wrangled, res_type, "Housing"),
  summarize_section(wrangled, res_type_rent, "Renters"),
  summarize_section(wrangled, not_eng, "Another Language"),
  summarize_section(wrangled, lgbtq, "LGBTQIA+"),
  summarize_section(wrangled, senior, "Respondent Is a Senior"),
  summarize_section(wrangled, hh_elderly, "Household With Seniors"),
  summarize_section(wrangled, hh_child, "Household With Children"),
  summarize_section(wrangled, hh_child_young, "Household With Young Children"),
  summarize_section(wrangled, unemp_bi, "Respondent Is Unemployed")
)

# Leave two blank rows between sections for the report layout.
spacer <- tibble(section = c(NA_character_, NA_character_))
demographics <- demographic_sections[[1]]
for (section_table in demographic_sections[-1]) {
  demographics <- bind_rows(demographics, spacer, section_table)
}

# 4. Group and label the recruitment sources ----
source_counts <- wrangled %>%
  mutate(
    # Group Reddit codes and strip the "p" suffix from numeric team codes.
    source = if_else(str_detect(source, "^r"), "r", source),
    source = str_replace(source, "^(\\d+)p$", "\\1")
  ) %>%
  count(source, name = "count") %>%
  mutate(per = round(count / included_n, 2), total = included_n) %>%
  slice(gtools::mixedorder(source)) %>%
  left_join(codes, by = "source")

date_row <- tibble(source = paste("Run Date:", run_date, "| Total N:", included_n))
source_summary <- bind_rows(date_row, source_counts)

# 5. Save the reports as CSV files ----
output_dir <- config$output_dir
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(entry_counts, file.path(output_dir, "entry_counts.csv"))
write_csv(demographics, file.path(output_dir, "demographics_summary.csv"))
write_csv(source_summary, file.path(output_dir, "source_codes_summary.csv"))
message("Wrote reports to ", output_dir, "/")

# 6. Optionally append the reports to Google Sheets ----
if (isTRUE(config$use_google_sheets)) {
  # Set your own Google Sheet ID in config/report_config.yml.
  sheet_id <- config$google_sheet_id
  if (is.null(sheet_id) || !nzchar(trimws(sheet_id)) ||
      sheet_id == "PASTE_YOUR_SHEET_ID_HERE") {
    stop("Add your Google Sheet ID to config/report_config.yml.")
  }

  library(googlesheets4)
  gs4_auth()

  demographics_tab <- config$demographics_sheet_name
  source_tab <- config$source_codes_sheet_name
  missing_tabs <- setdiff(c(demographics_tab, source_tab), sheet_names(sheet_id))
  if (length(missing_tabs) > 0) {
    stop(
      paste0("Create these tabs in Google Sheets before uploading: ",
             paste(sQuote(missing_tabs), collapse = ", ")),
      call. = FALSE
    )
  }

  source("write_demographics_run.R", local = TRUE)
  write_demographics_run(sheet_id, demographics_tab, entry_counts, demographics)

  # Put the new source-code run below the existing runs.
  existing_sources <- read_sheet(sheet_id, sheet = source_tab, col_names = FALSE)
  start_row <- if (nrow(existing_sources) == 0) 1 else nrow(existing_sources) + 3

  range_write(
    sheet_id,
    sheet = source_tab,
    data = source_summary,
    range = cell_limits(ul = c(start_row, 1)),
    col_names = TRUE
  )
  message("Appended reports to Google Sheets.")
}
