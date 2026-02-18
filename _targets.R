# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

# Set target options:
targets::tar_option_set(
  packages = c(
    "here",
    "fs",
    "susometa",
    "susopara",
    "tidytable",
    "data.table",
    "dplyr"
  )
)

# set paths
paradata_dir <- here::here("data", "01_paradata")
metadata_dir <- here::here("data", "02_metadata")
microdata_dir <- here::here("data", "03_microdata")

# Run the R scripts in the R/ folder with your custom functions:
targets::tar_source()

list(
  targets::tar_target(
    name = paradata_path,
    command = fs::dir_ls(
      path = paradata_dir,
      regexp = "\\.tab",
      type = "file"
    ),
    format = "file"
  ),
  targets::tar_target(
    name = qnr_json_path,
    command = fs::dir_ls(
      path = metadata_dir,
      regexp = "\\.json"
    ),
    format = "file"
  ),
  targets::tar_target(
    name = categories_paths,
    command = fs::dir_ls(
      path = fs::path(metadata_dir, "Categories"),
      regexp = "\\.xlsx"
    ),
    format = "file"
  ),
  # ingest metadata
  targets::tar_target(
    name = qnr_df,
    command = susometa::parse_questionnaire(path = qnr_json_path)
  ),
  # identify computed variables
  targets::tar_target(
    name = names_computed_variables,
    command = susometa::get_variables(qnr_df = qnr_df) |>
      dplyr::pull(varname)
  ),
  # create mapping of variables to sections
  targets::tar_target(
    name = variables_by_section,
    command = qnr_df |>
      susometa::get_questions_by_section() |>
      tidytable::select(section, variable) |>
      data.table::data.table()
  ),
  # ingest paradata
  targets::tar_target(
    name = paradata_df,
    command = susopara::read_paradata(file = paradata_path)
  ),
  # parse paradata
  targets::tar_target(
    name = paradata_active_events_df,
    command = susopara::parse_paradata(dt = paradata_df)
  ),
  # keep active events
  targets::tar_target(
    name = active_events,
    command = keep_active_events(
      paradata_df = paradata_active_events_df,
      names_computed_variables = names_computed_variables
    )
  ),
  # compute time between events
  targets::tar_target(
    name = event_durations,
    command = compute_time_btw_events(events_df = active_events)
  ),
  # add sections to duration data
  targets::tar_target(
    name = events_w_sections_df,
    command = event_durations |>
      tidytable::left_join(variables_by_section, by = "variable") |>
      tidytable::filter(!is.na(section))
  ),
  # create a data set of section names
  targets::tar_target(
    name = distinct_sections_df,
    command = variables_by_section |>
      dplyr::distinct(section) |>
      dplyr::mutate(order_num = dplyr::row_number())
  ),
  # compute duration stats
  targets::tar_target(
    name = duration_by_section,
    command = compute_stats_by_section(
      events_df = events_w_sections_df,
      sections_df = distinct_sections_df
    )
  ),
  # render the quarto report
  tarchetypes::tar_quarto(
    name = report,
    path = "inst/duration_report.qmd"
  ),
  # move rendered file from `inst/` to the project root
  targets::tar_target(
    name = move_report,
    command = fs::file_move(
      path = "inst/duration_report.html",
      new_path = "duration_report.html"
    )

  )

)
