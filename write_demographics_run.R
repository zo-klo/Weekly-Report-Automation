write_demographics_run <- function(sheet_id, tab, entry_counts, demographics) {
  # Fixed labels start in A4. The first data row is row 6.
  labels <- demographics %>%
    transmute(
      section,
      variable = if_else(is.na(section), NA_character_, coalesce(variable, "Missing / not applicable"))
    )
  labels <- bind_rows(tibble(section = NA_character_, variable = NA_character_), labels)

  existing_cells <- range_read_cells(sheet_id, sheet = tab)
  if (nrow(existing_cells) == 0) {
    range_write(sheet_id, sheet = tab, data = labels, range = "A4")
    start_col <- 3L
  } else {
    existing_labels <- read_sheet(
      sheet_id,
      sheet = tab,
      range = cell_limits(ul = c(4, 1), lr = c(nrow(labels) + 4, 2)),
      col_types = "cc"
    )
    extra_labels <- any(existing_cells$col <= 2 & existing_cells$row > nrow(labels) + 4)
    if (extra_labels || !identical(names(existing_labels), names(labels)) ||
        !identical(unname(as.matrix(existing_labels)), unname(as.matrix(labels)))) {
      stop(
        paste0("The section and category rows in ", tab,
               " differ from this report. Use a blank tab so existing runs stay aligned."),
        call. = FALSE
      )
    }

    run_columns <- existing_cells$col[existing_cells$col > 2]
    start_col <- if (length(run_columns) == 0) 3L else max(run_columns) + 2L
  }

  range_write(
    sheet_id, sheet = tab, data = entry_counts,
    range = cell_limits(ul = c(1, start_col)), col_names = FALSE
  )
  range_write(
    sheet_id, sheet = tab, data = select(demographics, Count = count, Share = per),
    range = cell_limits(ul = c(5, start_col))
  )
  message("Wrote response counts and demographics to ", tab,
          " starting in column ", start_col, ".")
}
