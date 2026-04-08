core_packages <- c(
  "readr",
  "dplyr",
  "tidyr",
  "stringr",
  "purrr",
  "rlang",
  "tibble",
  "gtools",
  "yaml"
)

optional_google_packages <- c("googlesheets4", "googledrive")

missing_core_packages <- core_packages[!vapply(core_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_core_packages) > 0) {
  stop(
    "Install required packages before running this script: ",
    paste(missing_core_packages, collapse = ", "),
    call. = FALSE
  )
}

invisible(lapply(core_packages, library, character.only = TRUE))

load_config <- function(config_path = "config/report_config.yml") {
  if (!file.exists(config_path)) {
    stop(
      paste(
        "Create a local config file at",
        config_path,
        "using config/report_config_template.yml as a starting point."
      ),
      call. = FALSE
    )
  }

  config <- yaml::read_yaml(config_path)

  required_fields <- c(
    "use_google_sheets",
    "google_sheet_id",
    "demographics_sheet_name",
    "source_codes_sheet_name",
    "wrangled_data_path",
    "cleaned_unfiltered_path",
    "source_codes_path",
    "output_dir"
  )

  missing_fields <- required_fields[!required_fields %in% names(config)]
  if (length(missing_fields) > 0) {
    stop(
      "Config is missing required fields: ",
      paste(missing_fields, collapse = ", "),
      call. = FALSE
    )
  }

  config
}

project_path <- function(...) {
  file.path(...)
}

summarize_section <- function(data, var, section_name) {
  var <- rlang::ensym(var)
  total_n <- nrow(data)

  data %>%
    dplyr::count(!!var, name = "count") %>%
    dplyr::mutate(
      count = tidyr::replace_na(count, 0),
      per = round(count / total_n, 2),
      total = total_n,
      section = section_name,
      variable = as.character(!!var)
    ) %>%
    dplyr::select(section, variable, count, per, total)
}

build_demographics_table <- function(wrangled) {
  tables <- list(
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

  blank_row <- tibble::tibble(
    section = NA_character_,
    variable = NA_character_,
    count = NA_real_,
    per = NA_real_,
    total = NA_real_
  )

  purrr::imap_dfr(
    tables,
    ~ if (.y < length(tables)) dplyr::bind_rows(.x, blank_row, blank_row) else .x
  )
}

build_entry_counts <- function(wrangled, cleaned_unfiltered) {
  tibble::tibble(
    label = c("Date", "All Responses", "Included Responses"),
    value = c(
      as.character(Sys.Date()),
      nrow(cleaned_unfiltered),
      paste0(
        nrow(wrangled),
        " (",
        round(nrow(wrangled) / nrow(cleaned_unfiltered) * 100, 1),
        "%)"
      )
    )
  )
}

build_source_codes_table <- function(wrangled, source_codes_lookup) {
  sourcecodes <- wrangled %>%
    dplyr::mutate(
      source = ifelse(stringr::str_detect(source, "^r"), "r", source),
      source = ifelse(stringr::str_detect(source, "^\\d+p"), stringr::str_sub(source, end = -2), source)
    ) %>%
    dplyr::group_by(source) %>%
    dplyr::summarise(count = dplyr::n(), .groups = "drop") %>%
    dplyr::mutate(
      per = round(count / sum(count), 2),
      total = sum(count)
    ) %>%
    dplyr::arrange(order(gtools::mixedorder(source))) %>%
    dplyr::left_join(source_codes_lookup, by = "source")

  dplyr::bind_rows(
    tibble::tibble(
      source = paste("Run Date:", Sys.Date(), "| Total N:", nrow(wrangled)),
      count = NA_real_,
      per = NA_real_,
      total = NA_real_,
      source_label = NA_character_,
      source_group = NA_character_
    ),
    sourcecodes
  )
}

write_local_outputs <- function(output_dir, entry_counts, demographics_table, source_codes_table) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  readr::write_csv(entry_counts, file.path(output_dir, "entry_counts.csv"))
  readr::write_csv(demographics_table, file.path(output_dir, "demographics_summary.csv"))
  readr::write_csv(source_codes_table, file.path(output_dir, "source_codes_summary.csv"))
}

check_google_dependencies <- function() {
  missing_google_packages <- optional_google_packages[
    !vapply(optional_google_packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing_google_packages) > 0) {
    stop(
      "Install Google packages to enable upload mode: ",
      paste(missing_google_packages, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(lapply(optional_google_packages, library, character.only = TRUE))
}

write_demographics_block <- function(sheet_id, sheet_name, entry_counts_row, block_to_write) {
  existing_sheet <- googlesheets4::read_sheet(
    sheet_id,
    sheet = sheet_name,
    col_names = FALSE
  )

  if (all(is.na(existing_sheet))) {
    start_col_index <- 1
  } else {
    start_col_index <- max(which(colSums(!is.na(existing_sheet)) > 0)) + 2
  }

  googlesheets4::range_write(
    ss = sheet_id,
    sheet = sheet_name,
    data = entry_counts_row,
    range = googlesheets4::cell_limits(ul = c(1, start_col_index)),
    col_names = FALSE
  )

  googlesheets4::range_write(
    ss = sheet_id,
    sheet = sheet_name,
    data = block_to_write,
    range = googlesheets4::cell_limits(ul = c(nrow(entry_counts_row) + 3, start_col_index)),
    col_names = FALSE
  )
}

append_source_codes_block <- function(sheet_id, sheet_name, block_to_write) {
  existing_sheet <- googlesheets4::read_sheet(sheet_id, sheet = sheet_name)
  start_row <- if (nrow(existing_sheet) == 0) 1 else nrow(existing_sheet) + 3

  googlesheets4::range_write(
    ss = sheet_id,
    sheet = sheet_name,
    data = block_to_write,
    range = googlesheets4::cell_limits(ul = c(start_row, 1)),
    col_names = TRUE
  )
}

upload_to_google_sheets <- function(config, entry_counts, demographics_table, source_codes_table) {
  check_google_dependencies()

  if (identical(config$google_sheet_id, "PASTE_YOUR_SHEET_ID_HERE")) {
    stop(
      "Replace PASTE_YOUR_SHEET_ID_HERE in config/report_config.yml before enabling Google Sheets upload.",
      call. = FALSE
    )
  }

  googledrive::drive_auth()
  googlesheets4::gs4_auth()

  write_demographics_block(
    sheet_id = config$google_sheet_id,
    sheet_name = config$demographics_sheet_name,
    entry_counts_row = entry_counts,
    block_to_write = demographics_table %>% dplyr::select(count, per)
  )

  append_source_codes_block(
    sheet_id = config$google_sheet_id,
    sheet_name = config$source_codes_sheet_name,
    block_to_write = source_codes_table
  )
}

run_report_automation <- function(config_path = "config/report_config.yml") {
  config <- load_config(config_path)

  wrangled <- readr::read_csv(config$wrangled_data_path, show_col_types = FALSE)
  cleaned_unfiltered <- readr::read_csv(config$cleaned_unfiltered_path, show_col_types = FALSE)
  source_codes_lookup <- readr::read_csv(config$source_codes_path, show_col_types = FALSE)

  entry_counts <- build_entry_counts(wrangled, cleaned_unfiltered)
  demographics_table <- build_demographics_table(wrangled)
  source_codes_table <- build_source_codes_table(wrangled, source_codes_lookup)

  write_local_outputs(
    output_dir = config$output_dir,
    entry_counts = entry_counts,
    demographics_table = demographics_table,
    source_codes_table = source_codes_table
  )

  if (isTRUE(config$use_google_sheets)) {
    upload_to_google_sheets(config, entry_counts, demographics_table, source_codes_table)
    message("Demo outputs written locally and uploaded to Google Sheets.")
  } else {
    message("Demo outputs written locally. Google Sheets upload is disabled in config/report_config.yml.")
  }
}

if (sys.nframe() == 0) {
  run_report_automation()
}
