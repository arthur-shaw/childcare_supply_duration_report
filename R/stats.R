#' Compute statistics
#'
#' @param df Data frame
#'
#' @importFrom tidytable summarise n
compute_stats <- function(
  df
) {

  stats <- df |>
    tidytable::summarise(
      med = median(x = elapsed_min, na.rm = TRUE),
      mean = mean(x = elapsed_min, na.rm = TRUE),
      sd = sd(x = elapsed_min, na.rm = TRUE),
      min = min(elapsed_min, na.rm = TRUE),
      max = max(elapsed_min, na.rm = TRUE),
      n_obs = tidytable::n()
    )

  return(stats)

}

#' Compute common statistics by grouping variable
#'
#' @param df Data frame
#' @param by_var Character vector
#'
#' @return Data frame
#'
#' @importFrom tidytable group_by summarise n ungroup
compute_stats_grouped <- function(
  df,
  by_var
) {

  stats_by <- df |>
    tidytable::group_by({{by_var}}) |>
    compute_stats() |>
    tidytable::ungroup()

  return(stats_by)

}

#' Compute statistics overall
#'
#' @param df Data frame
#' @param group_name Bare variable name of group column to create.
#' @param group_txt Character. Text to populate the group description.
#'
#' @importFrom dplyr mutate
compute_stats_overall <- function(
  df,
  group_name,
  group_txt
) {

  stats_overall <- df |>
    compute_stats() |>
    dplyr::mutate(
      {{group_name}} := group_txt,
      .before = 1
    )

  return(stats_overall)

}

compute_stats_by_section <- function(
  events_df,
  sections_df
) {

  duration_overall_by_interview <- events_df |>
    # compute total by interview-questionnaire
    tidytable::group_by(interview__id) |>
    tidytable::summarise(
      elapsed_min = sum(elapsed_min, na.rm = TRUE)
    ) |>
    tidytable::ungroup() |>
    # compute statistics by questionnaire
    compute_stats_overall(
      group_name = section,
      group_txt = "Total interview duration"
    )

  duration_overall_by_section <- events_df |>
    # remove empty section
    tidytable::filter(!is.na(section)) |>	
    # compute total by interview-section
    tidytable::group_by(interview__id, section) |>
    tidytable::summarise(
      elapsed_min = sum(elapsed_min, na.rm = TRUE)
    ) |>
    tidytable::ungroup() |>
    # compute statistics by questionnaire
    compute_stats_grouped(by_var = section) |>
    # order sections
    dplyr::left_join(sections_df, by = "section") |>
    dplyr::arrange(order_num) |>
    dplyr::select(-order_num)

  duration_overall <- dplyr::bind_rows(
    duration_overall_by_interview,
    duration_overall_by_section
  )

  return(duration_overall)

}