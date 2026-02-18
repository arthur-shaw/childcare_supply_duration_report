keep_active_events <- function(paradata_df, names_computed_variables) {

  paradata_durations <- paradata_df |>
    # remove "passive" events of variables being computed
    tidytable::filter(!.data$variable %in% .env$names_computed_variables) |>
    # remove passive events currently not removed by `susopara`
    tidytable::filter(
      !.data$event %in%
      c("InterviewCreated", "InterviewModeChanged", "InterviewerAssigned")
    )

  return(paradata_durations)

}

compute_time_btw_events <- function(events_df) {

  event_duration_df <- events_df |>
    susopara::calc_time_btw_active_events() |>
    # # select completed interviews
    # tidytable::filter(
    #   interview__id %in% completed_interview_ids
    # ) |>
    # remove extreme durations
    tidytable::filter(
      # less than 99th percentile of duration
      (.data$elapsed_min < stats::quantile(
        x = .data$elapsed_min,
        probs = 0.99,
        na.rm = TRUE)
      ) &
      # non-negative
      (.data$elapsed_min > 0)
    )

  return(event_duration_df)

}
