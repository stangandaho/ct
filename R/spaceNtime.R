# MOST FUNCTION FROM https://github.com/annam21/spaceNtime

#' Internal utility: Modern exp_logl_fn
#' @param x list
#' @param param parameter
#' @keywords internal
#' @noRd
exp_logl_fn <- function(x, param) {
  # param: beta parameter for lambda
  lambda <- exp(param)
  logL <- 0
  for (i in 1:nrow(x$toevent)) {
    for (j in 1:ncol(x$toevent)) {
      if (!is.na(x$toevent[i, j])) {
        tmp <- dexp(x$toevent[i, j], lambda)
      } else {
        tmp <- pexp(x$censor[j], lambda, lower.tail = F)
      }
      logL <- logL + log(tmp)
    }
  }
  return(logL)
}

#' Internal utility: Modern STE encounter history builder
#' @noRd
#' @keywords internal
ste_build_eh <- function(df, deploy, occ, quiet = FALSE) {
  if (!quiet) cli::cli_progress_step("Running data checks")
  df <- validate_df(df)
  deploy <- validate_deploy(deploy)
  occ <- validate_occ(occ)

  d1 <- min(occ$start)
  d2 <- max(occ$end)
  df_s <- study_subset(df, "datetime", NULL, d1, d2)
  deploy_s <- study_subset(deploy, "start", "end", d1, d2)

  validate_df_deploy(df_s, deploy_s)

  if (!quiet) cli::cli_progress_step("Building effort for each camera")
  eff <- effort_fn(deploy_s, occ)

  if (!quiet) cli::cli_progress_step("Calculating censors")
  censor <- ste_calc_censor(eff)

  if (!quiet) cli::cli_progress_step("Calculating STE at each occasion")
  out <- ste_calc_toevent(df_s, occ, eff) %>%
    dplyr::mutate(censor = censor$censor)

  if (!quiet) cli::cli_progress_done()
  return(out)
}

#' Internal utility: Modern TTE encounter history builder
#' @noRd
#' @keywords internal
tte_build_eh <- function(df, deploy, occ, samp_per, quiet = FALSE) {
  if (!quiet) cli::cli_progress_step("Running data checks")
  df <- validate_df(df)
  deploy <- validate_deploy(deploy)
  occ <- validate_occ(occ)

  d1 <- min(occ$start)
  d2 <- max(occ$end)
  df_s <- study_subset(df, "datetime", NULL, d1, d2)
  deploy_s <- study_subset(deploy, "start", "end", d1, d2)

  validate_df_deploy(df_s, deploy_s)

  if (!quiet) cli::cli_progress_step("Building effort for each camera")
  eff <- effort_fn(deploy_s, occ)

  if (!quiet) cli::cli_progress_step("Calculating TTE and censor")
  out <- tte_calc_toevent(df_s, eff, samp_per)

  if (!quiet) cli::cli_progress_done()
  return(out)
}

#' Internal utility: Modern ISE encounter history builder
#' @noRd
#' @keywords internal
#' @importFrom lubridate "%within%"
#'
ise_build_eh <- function(df, deploy, occ, quiet = FALSE) {
  if (!quiet) cli::cli_progress_step("Running data checks")
  df <- validate_df(df)
  deploy <- validate_deploy(deploy)
  occ <- validate_occ(occ)
  validate_df_deploy(df, deploy)

  d1 <- min(occ$start)
  d2 <- max(occ$end)
  df_s <- study_subset(df, "datetime", NULL, d1, d2)
  deploy_s <- study_subset(deploy, "start", "end", d1, d2)

  validate_df_deploy(df_s, deploy_s)

  if (!quiet) cli::cli_progress_step("Building effort for each camera")
  eff <- effort_fn(deploy_s, occ)

  if (!quiet) cli::cli_progress_step("Building encounter history")
  ise <- eff %>%
    dplyr::left_join(., df_s, by = "cam") %>%
    dplyr::filter(datetime %within% int) %>%
    dplyr::select(occ, cam, count) %>%
    dplyr::left_join(eff, ., by = c("occ", "cam")) %>%
    dplyr::select(-int) %>%
    dplyr::mutate(count = replace(count, is.na(count) & area > 0, 0))

  if (!quiet) cli::cli_progress_done()
  return(ise)
}


# Functions to validate the required data

#' Validate df
#'
#' Make sure df fits all requirements
#'
#' @param df object df
#'
#' @return df if it passes all tests. Otherwise returns error
#' @import assertr
#' @noRd
#' @keywords internal
#' @examples validate_df(df)
validate_df <- function(df) {
  df %>%
    assertr::verify(assertr::has_all_names("cam", "datetime", "count")) %>%
    assertr::verify(lubridate::is.POSIXct(datetime)) %>%
    assertr::verify(is.numeric(count)) %>%
    assertr::verify(count >= 0)
}


#' Validate start and end columns
#'
#' Validate any object with start and end columns
#' @param x a dataframe or tibble with columns start and end
#'
#' @return x if it passes all tests, an error otherwise

#' @import assertr
#' @noRd
#' @keywords internal
#' @examples validate_start_end(deploy)
validate_start_end <- function(x) {
  x %>%
    assertr::verify(assertr::has_all_names("start", "end")) %>%
    assertr::verify(lubridate::is.POSIXct(start)) %>%
    assertr::verify(lubridate::is.POSIXct(end)) %>%
    # Make sure start and end work together
    assertr::verify(lubridate::tz(start) == lubridate::tz(end)) %>%
    assertr::verify(end - start >= 0)
}

#' Validate deploy object
#'
#' @param deploy deploy object
#'
#' @return deploy if it passes all tests, error otherwise
#' @import assertr
#' @keywords internal
#' @noRd
#' @examples validate_deploy(deploy)
validate_deploy <- function(deploy) {
  deploy %>%
    assertr::verify(assertr::has_all_names("cam", "start", "end", "area")) %>%
    # Check class of all columns
    assertr::verify(is.numeric(area)) %>%
    assertr::verify(area >= 0) %>%
    # Check start and end
    validate_start_end(.)

  # See if start to end are length 0 (It's a timelapse effort)
  tl <- deploy %>%
    dplyr::filter(start != end)
  if (nrow(tl) == 0) {
    # It's timelapse, so make sure there is only 1 effort for each time
    deploy <- deploy %>%
      dplyr::distinct() # Force it for the user
    deploy %>%
      dplyr::group_by(cam, start, end) %>%
      dplyr::count() %>%
      dplyr::filter(n != 1) %>%
      assertr::verify(nrow(.) == 0)
  } else {
    # Make sure rows non-overlapping
    ov <- find_overlap(deploy)
    if (nrow(ov) != 0) {
      print(ov)
      rlang::abort("There are overlapping time intervals in deploy")
    }
  }
  return(deploy)
}

#' Validate df and deploy together
#'
#' @param df df object
#' @param deploy deploy object
#'
#' @return error if any check fails, nothing otherwise
#' @noRd
#' @keywords internal
#' @examples validate_df_deploy(df, deploy)
validate_df_deploy <- function(df, deploy) {
  if (lubridate::tz(deploy$start) != lubridate::tz(df$datetime)) {
    rlang::abort("Timezones in data and deployment_data must match.")
  }

  # # Fail if a camera in df is not in deploy
  if (class(df$cam) != class(deploy$cam)) {
    rlang::abort("Camera column class in data and deployment_data must match.")
  }
  if (!all(unique(df$cam) %in% deploy$cam)) {
    rlang::abort("All cameras in data must exist in deployment_data.")
  }

  # Fail if a camera took a photo but that time is not in deploy
  # Very similar function to find_overlap. Work on that in future
  pic_in_deploy <- dplyr::left_join(df, deploy, by = "cam") %>%
    dplyr::mutate(wthn = datetime >= start & datetime <= end) %>%
    dplyr::group_by(cam) %>%
    dplyr::summarise(allgood = any(wthn)) %>%
    dplyr::filter(allgood == F | is.na(allgood))

  if (nrow(pic_in_deploy) > 0) {
    rlang::abort(paste(
      "There are photos at cam",
      pic_in_deploy$cam,
      "outside intervals specified in deploy"
    ))
  }
}


#' Validate occ
#'
#' @param occ occ object
#'
#' @return occ if passes all tests, error otherwise
#' @noRd
#' @keywords internal
#' @examples validate_occ(occ)
validate_occ <- function(occ) {
  occ %>%
    assertr::verify(is.numeric(occ)) %>%
    # Check start and end
    validate_start_end(.)
}

#' Subset camera-related data
#'
#' Keep rows of data where start_col and (optional) end_col lie within an
#' inclusive interval defined by study_start and study_end
#'
#' @param x a dataframe or tibble with start and end columns
#' @param start_col the name of the start column in x
#' @param end_col the name of the end column in x. Default = NULL
#' @param study_start the first part of the interval you want to subset by
#' @param study_end the end of the interval to subset by
#'
#' @return a filtered dataframe or tibble
#' @noRd
#' @keywords internal
#' @examples
#' df <- data.frame(
#'   cam = c(1, 1, 2, 2),
#'   datetime = as.POSIXct(
#'     c(
#'       "2016-01-02 12:00:00",
#'       "2016-01-03 13:12:00",
#'       "2016-01-02 14:00:00",
#'       "2016-01-03 16:53:42"
#'     ),
#'     tz = "GMT"
#'   ),
#'   a = c(850, 850, 1100, 1100),
#'   count = c(1, 0, 0, 2)
#' )
#' d <- as.POSIXct(c("2016-01-01 00:00:00", "2016-01-02 23:59:59"), tz = "GMT")
#' study_subset(df, "datetime", NULL, d[1], d[2])
#'
study_subset <- function(x, start_col, end_col = NULL, study_start, study_end) {
  # x is a data.frame with start_col and end_col; study_start and _end are study edges,
  # we want to only keep deployments that are within these
  if (is.null(end_col)) {
    x %>%
      dplyr::filter(dplyr::between(!!as.name(start_col), study_start, study_end))
  } else {
    x %>%
      dplyr::filter(
        !!as.name(start_col) <= study_end,
        !!as.name(end_col) >= study_start
      )
  }
}

### Checks: does this work for dates, times, and numbers?
# What happens if start and end are the same (for either start and end)? (should return 0)
# Does it fail when the study end is before the study_start?  (Should return 0)
# Remember: this is a hard subset (must be fully WITHIN)


### Currently UNUSED
#' Calculate STE on each occasion
#'
#' @param df df object
#' @param occ occasions
#' @param effort effort from effort_fn()
#' @importFrom lubridate "%within%"
#' @return a dataframe with the same rows as occ, with a STE column
#'
#' @noRd
#' @keywords internal
#'
#' @examples
#' occ <- build_occ(
#'   samp_freq = 3600,
#'   samp_length = 10,
#'   study_start = study_dates[1],
#'   study_end = study_dates[2]
#' )
#' eff <- effort_fn(deploy, occ)
#' ste_calc_toevent(df, occ, eff)
ste_calc_toevent <- function(df, occ, effort) {
  # If deploy said the camera was on and there is no photo, I'm assuming a count of 0.

  # THIS IS A PATCH THAT CAN BE CLEANED UP
  # I'm including the fast and slow way to find which occasion a picture is in

  # Calculate the lowest common denominator for samp_freq
  ss <- lcd_fn(occ)

  if (ss == 0) {
    rlang::warn("Occasions are not evenly spaced, so ste_calc_toevent must go the slow
            route")
    # Find sampling occasions where counts exist
    # This captures any count within the occasion. Later, I take only the first
    count_at_occ <- df %>%
      dplyr::filter(count > 0) %>%
      dplyr::left_join(effort, ., by = "cam") %>%
      dplyr::filter(datetime %within% int) %>%
      # Take only the first at each camera at each occasion
      dplyr::distinct(occ, cam, .keep_all = T) %>%
      dplyr::select(occ, cam, count)
  } else {
    # Do it with rounding instead of intervals!!!
    count_at_occ <- df %>%
      dplyr::filter(count > 0) %>%
      # round down to the nearest interval
      dplyr::mutate(
        timefromfirst = as.numeric(datetime) - as.numeric(min(effort$start)),
        nearest = floor(timefromfirst / ss) * ss,
        nearestpos = as.POSIXct(nearest,
                                origin = min(effort$start),
                                tz = lubridate::tz(effort$start)
        )
      ) %>%
      # Join by the start time of that interval
      dplyr::left_join(., effort, by = c("nearestpos" = "start", "cam")) %>%
      # But then keep only if within the end date of that interval
      dplyr::filter(datetime <= end) %>%
      dplyr::select(occ, cam, count) %>%
      # Only keep the first one at each camera on each occasion
      dplyr::distinct(occ, cam, .keep_all = T)
  }

  tmp <- effort %>%
    # Randomly order cameras at each occasion
    dplyr::group_by(occ) %>%
    dplyr::sample_n(dplyr::n()) %>%
    # Join up our counts
    dplyr::left_join(., count_at_occ, by = c("occ", "cam")) %>%
    # Here NAs are pictures that didn't exist. 0s are counts of 0
    # count should be NA if area = 0.

    # Find the area until the first count, at each occasion
    dplyr::mutate(STE = cumsum(area)) %>%
    # If the area is 0, it's just adding 0 to the STE. That's good.
    dplyr::filter(count > 0) %>%
    # Here I'm filtering NAs too, so if a photo doesn't exist, its count is 0
    dplyr::filter(!duplicated(occ)) %>%
    # Add back NAs on all other sampling occasions
    dplyr::select(occ, STE) %>%
    dplyr::left_join(occ, ., by = "occ")

  if (all(is.na(tmp$STE))) rlang::warn("No animals detected in any sampling occasion")

  return(tmp)
}
#' Calculate censor for each time step
#'
#' @param effort dataframe built from effort_fn()
#'
#' @return summarised dataframe with occ and censor columns
#' @noRd
#'
#' @keywords internal
#'
#' @examples
#' occ <- build_occ(
#'   samp_freq = 3600,
#'   samp_length = 10,
#'   study_start = study_dates[1],
#'   study_end = study_dates[2]
#' )
#' eff <- effort_fn(deploy, occ)
#' calc_censor(eff)
ste_calc_censor <- function(effort) {
  # Just requires effort
  effort %>%
    dplyr::group_by(occ) %>%
    dplyr::summarise(censor = sum(area))
}
#' Calculate time-to-event
#'
#' @param df df object
#' @param effort effort from effort_fn()
#' @param samp_per sampling period length. The mean length of time for an animal
#' to pass through a camera viewshed
#' @importFrom lubridate "%within%"
#' @return a dataframe with the same rows as occ, with a TTE column
#'
#' @noRd
#' @keywords internal
#' @examples
#' df <- data.frame(
#'   cam = c(1, 1, 2, 2, 2),
#'   datetime = as.POSIXct(
#'     c(
#'       "2016-01-02 12:00:00",
#'       "2016-01-03 13:12:00",
#'       "2016-01-02 12:00:00",
#'       "2016-01-02 14:00:00",
#'       "2016-01-03 16:53:42"
#'     ),
#'     tz = "GMT"
#'   ),
#'   count = c(1, 0, 2, 1, 2)
#' )
#' eff <- effort_fn(deploy, occ)
#' tte_calc_toevent(df, eff)
tte_calc_toevent <- function(df, effort, samp_per) {
  out <- df %>%
    dplyr::filter(count > 0) %>%
    dplyr::left_join(effort, ., by = "cam") %>%
    dplyr::filter(datetime %within% int) %>%
    # Take only the first event in the sampling occasion
    dplyr::group_by(cam, occ) %>%
    dplyr::filter(!duplicated(occ)) %>%
    # Join back up with all cams and occasions
    dplyr::select(cam, occ, datetime, count) %>%
    dplyr::left_join(effort, ., by = c("occ", "cam")) %>%
    # select(cam, occ, start, end, int, area) %>%
    dplyr::arrange(cam, occ) %>%
    # Calculate TTE
    dplyr::mutate(
      TTE = as.numeric(datetime) - as.numeric(start),
      TTE = TTE / samp_per * area
    ) %>%
    # Calculate censor
    dplyr::mutate(
      censor = as.numeric(end) - as.numeric(start),
      censor = censor / samp_per * area
    )
  return(out)
}
#' Log confidence intervals
#'
#' Returns confidence intervals for abundance that do not go below 0
#'
#' @param estimate parameter estimate
#' @param se estimate parameter standard error
#'
#' @return a data frame with LCI and UCI
#' @noRd
#' @keywords internal
#'
#' @examples logCI(32, 25)
logCI <- function(estimate, se) {
  ci <- exp(1.96 * sqrt(log(1 + (se / estimate)^2)))
  LCI <- estimate / ci
  UCI <- estimate * ci
  out <- data.frame(LCI = LCI, UCI = UCI)
  return(out)
}
#' Determine effort at each camera on each occasion
#'
#' @param deploy deploy object
#' @param occ occasions dataframe or tibble
#'
#' @return a dataframe or tibble the with the area at each camera and occasion
#' @details If any occasion is missing from deploy for a camera, it is assumed
#' that the camera was not working at that time.
#' @noRd
#' @keywords internal
#'
#' @examples effort_fn(deploy, occ)
effort_fn <- function(deploy, occ) {
  # Create intervals in deploy
  deploy <- deploy %>%
    add_int(.)

  # Create occasions by camera
  occ_by_cam <- build_occ_cam(deploy, occ) %>%
    add_int(.)

  # Try interval overlap to combine the two
  effort <- occ_by_cam %>%
    dplyr::rename(occ_int = int) %>% # .02s
    dplyr::left_join(., deploy, by = "cam") %>% # 2s
    dplyr::filter(lubridate::int_overlaps(occ_int, int)) %>% # 5s
    dplyr::select(occ, cam, area) %>% # 5s
    dplyr::left_join(occ_by_cam, ., by = c("occ", "cam")) %>% # 18s #### big time suck
    dplyr::mutate(area = replace(area, is.na(area), 0)) %>% # 19s

    # get rid of duplicate rows (if area changed during occasion)
    dplyr::distinct(occ, cam, .keep_all = T) %>% # 23s
    dplyr::ungroup()

  return(effort)
}
#' Find the lowest common denominator between occasions
#'
#' @param occ occasions, a dataframe
#'
#' @return Returns a value: either the lowest common denominator between occasions
#' if they are evenly spaced (equal to samp_freq if occ is built by build_occ)
#' or 0 if occasions are not evenly spaced
#' @noRd
#' @keywords internal
#'
#' @examples
#' occ <- build_occ(
#'   samp_freq = 3600,
#'   samp_length = 10,
#'   study_start = study_dates[1],
#'   study_end = study_dates[2]
#' )
#' findfrq <- lcd_fn(occ)
lcd_fn <- function(occ) {
  t <- occ %>%
    dplyr::mutate(
      d = as.numeric(difftime(start, dplyr::lag(start), units = "secs")),
      m = min(d, na.rm = T),
      r = d %% m
    )

  if (any(t$r != 0, na.rm = T)) {
    return(0)
  } else {
    return(t$m[1])
  }
}

# I know, I know. This takes a dataframe and returns a value. Can clean in future.
#' Add interval column
#'
#' @param x a dataframe or tibble with columns "start" and "end"
#'
#' @return a dataframe or tibble
#' @noRd
#' @keywords internal
#'
#' @examples add_int(deploy)
add_int <- function(x) {
  x %>%
    dplyr::mutate(int = lubridate::interval(start, end))
}
# Functions to find overlapping intervals in a dataframe

#' Find if a single interval overlaps multiple intervals
#'
#' @param one_int a single lubridate::interval
#' @param n_int a vector of lubridate::intervals
#'
#' @return a single value, the number of intervals that one_int overlaps
#' @noRd
#' @keywords internal
#'
#' @examples
#' s <- Sys.time()
#' a <- lubridate::interval((s - 5), (s))
#' b <- lubridate::int_diff(c((s - 4), (s + 1), (s + 5)))
#' overl(a, b)
overl <- function(one_int, n_int) {
  # Finds out if any single interval overlaps multiple intervals
  sum(lubridate::int_overlaps(one_int, n_int)) != 1
  # non-overlapping intervals will have sum = 1
}

#' Find cameras with overlapping intervals
#'
#' @param x a dataframe or tibble, with columns cam, start and end
#'
#' @return a dataframe with any records that are overlapping (grouped by cam)
#' should be 0 if everything is good.
#' @import dplyr
#' @noRd
#' @keywords internal
#'
#' @examples
#' find_overlap(deploy) # validation step
find_overlap <- function(x) {
  out <- x %>%
    assertr::verify(assertr::has_all_names("cam", "start", "end")) %>%
    dplyr::mutate(int = lubridate::interval(start, end)) %>%
    dplyr::group_by(cam) %>%
    dplyr::filter(dplyr::n() > 1)
  # If there is more than one row per camera, check overlap
  if (nrow(out) != 0) {
    out <- out %>%
      dplyr::mutate(chk = list(int)) %>%
      dplyr::rowwise() %>% # If this returns empty dataframe, the next step fails.
      dplyr::mutate(overlap = overl(int, chk)) %>%
      dplyr::filter(overlap) %>%
      dplyr::select(-c(int, chk, overlap))
  }
  return(out)
}

#' Sampling occasions by camera
#'
#'
#' @param deploy deploy object
#' @param occ dataframe of sampling occasions
#'
#' @return dataframe
#' @noRd
#' @keywords internal
#'
#' @examples
#' study_dates <- as.POSIXct(c("2016-01-01 00:00:00", "2016-01-04 23:59:59"), tz = "GMT")
#' occ <- build_occ(
#'   samp_freq = 3600,
#'   samp_length = 10,
#'   study_start = study_dates[1],
#'   study_end = study_dates[2]
#' )
#' build_occ_cam(deploy, occ)
build_occ_cam <- function(deploy, occ) {
  tidyr::crossing(
    occ = occ$occ,
    cam = deploy$cam
  ) %>%
    dplyr::left_join(., occ, by = "occ")
}
#' Create sequence of start times
#'
#' Create a sequence of start times by defining the amount of time between each, in seconds.
#' E.g., samp_freq = 3600 for sampling once per hour.
#'
#' @param samp_freq The number of seconds between each sampling period
#' @param date_lim A vector of length 2 of class POSIXct. The first and last date of the
#' desired sampling period.
#'
#'
#' @return A sequence of dates
#' @noRd
#' @keywords internal
#'
#' @examples
#' d <- c(Sys.time() - 43200, Sys.time())
#' sampling_start(3600, d)
#'
sampling_start <- function(samp_freq, date_lim) {
  # Make sure date_lim is the right dimension and class
  if (!is.null(date_lim) && length(date_lim) != 2) rlang::abort("date_lim must be of length 2")
  if (!inherits(date_lim, "POSIXct")) rlang::abort("date_lim must be POSIXct")

  # Vector of all the start times
  s <- seq(from = date_lim[1], to = date_lim[2], by = paste(samp_freq, "sec"))

  # Take out the last time in s, because it will almost never be a full sampling period.
  s <- s[1:(length(s) - 1)]

  # Output
  return(s)
}
#' tte_build_occ
#'
#' @param per_length numeric. Length of the TTE sampling period.
#' @param nper numeric. Number of TTE sampling periods per sampling occasion.
#' @param time_btw numeric. Length of time between sampling occasions,
#' allowing animals to re-randomize.
#' @param study_start POSIXct. The start of the study.
#' @param study_end POSIXct. The end of the study.
#'
#' @return a dataframe
#' @noRd
#' @keywords internal
#'
#' @examples
#' deploy <- data.frame(
#'   cam = c(1, 2, 2, 2),
#'   start = as.POSIXct(
#'     c(
#'       "2015-12-01 15:00:00",
#'       "2015-12-08 00:00:00",
#'       "2016-01-01 00:00:00",
#'       "2016-01-02 00:00:00"
#'     ),
#'     tz = "GMT"
#'   ),
#'   end = as.POSIXct(
#'     c(
#'       "2016-01-05 00:00:00",
#'       "2015-12-19 03:30:00",
#'       "2016-01-01 05:00:00",
#'       "2016-01-05 00:00:00"
#'     ),
#'     tz = "GMT"
#'   ),
#'   area = c(300, 200, 200, 450)
#' )
#' per <- tte_samp_per(deploy, lps = 30 / 3600)
#' study_dates <- as.POSIXct(c("2016-01-01 00:00:00", "2016-01-04 23:59:59"), tz = "GMT")
#' occ2 <- tte_build_occ(
#'   per_length = per,
#'   nper = 24,
#'   time_btw = 2 * 3600,
#'   study_start = study_dates[1],
#'   study_end = study_dates[2]
#' )
tte_build_occ <- function(per_length, nper, time_btw,
                          study_start, study_end) {
  # Occasions without camera
  # (study_end - study_start)/per_length * nper
  occ_length <- per_length * nper
  samp_freq <- occ_length + time_btw

  data.frame(
    start = sampling_start(
      samp_freq = samp_freq,
      date_lim = c(study_start, study_end)
    )
  ) %>%
    dplyr::mutate(
      end = start + occ_length,
      occ = 1:dplyr::n()
    ) %>%
    dplyr::select(occ, start, end)
}


#' Build sampling occasions
#'
#' @param samp_freq numeric, The number of seconds between the start of each sampling occasion
#' @param samp_length numeric. The number of seconds to sample at each sampling occasion
#' @param study_start POSIXct. The start of the study
#' @param study_end POSIXct. The end of the study
#'
#' @return a dataframe
#' @noRd
#' @keywords internal
#'
#' @examples
#' study_dates <- as.POSIXct(c("2016-01-01 00:00:00", "2016-01-04 23:59:59"), tz = "GMT")
#' build_occ(
#'   samp_freq = 3600,
#'   samp_length = 10,
#'   study_start = study_dates[1],
#'   study_end = study_dates[2]
#' )
build_occ <- function(samp_freq, samp_length, study_start, study_end) {
  # Occasions without camera
  data.frame(
    start = sampling_start(
      samp_freq = samp_freq,
      date_lim = c(study_start, study_end)
    )
  ) %>%
    dplyr::mutate(
      end = start + samp_length,
      occ = 1:dplyr::n()
    ) %>%
    dplyr::select(occ, start, end)
}
