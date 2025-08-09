#' Fit detection functions and estimate density/abundance
#'
#' `ct_fit_ds` fits detection functions to camera trap distance sampling data and estimates
#' animal density or abundance using bootstrap variance estimation. Supports both
#' single model fitting and automated model selection procedures.
#'
#' @param data A data frame containing distance sampling observations. Must include
#'   columns for distance measurements and can include covariates for detection function modeling.
#'   See [Distance::flatfile] for details.
#'
#' @param estimate Character string specifying the parameter to estimate. Either
#'   `"density"` (animals per km^2) or `"abundance"` (total number of animals). Default is `"density"`.
#'
#' @inheritParams Distance::ds
#'
#' @param select_model Logical. If `TRUE`, performs automated model selection
#'   using the procedure in Howe et al. (2019). If `FALSE` (default),
#'   fits a single model with specified parameters. When `TRUE`, `model_param`
#'   defines the candidate model set.
#' @param model_params Named list defining candidate models for selection when
#'   `select_model = TRUE`. Elements can include:
#'   - `key` - List of key functions to test
#'   - `adjustment` - List of adjustment types
#'   - `nadj` - List of adjustment term numbers
#'   - `order` - List vector of adjustment orders (must match `nadj`)
#' @param field_of_view Numeric. Camera field of view angle in degrees. Default is 42 deg,
#' ued to calculate the sampling fraction.
#' @param availability A list containing availability rate corrections (output from
#'   [ct_availability()]). Must include elements availability rate (0-1) and/or
#' standard error of availability rate
#' @param n_bootstrap Integer. Number of bootstrap replicates for variance estimation
#'   of density/abundance. Default is 100. Larger values provide more precise
#'   confidence intervals but increase computation time.
#' @param n_cores Integer. Number of CPU cores to use for parallel bootstrap computation.
#' Default is 1.
#'
#' @return A named list containing:
#' A list containing:
#'
#' - `QAIC`: (Only if `select_model = TRUE`) QAIC comparison table.
#' - `Chi2`: (Only if `select_model = TRUE`) Chi-squared goodness-of-fit comparison.
#' - `best_model`: The best fitted detection function model selected.
#' - `rho`: Estimated effective detection radius (in meters).
#' - `density` or `abundance`: A tibble with density or abundance estimates containing:
#' `median`, `mean`, `se`: standard error, `lcl`: lower confidence limit,
#' `ucl`: upper confidence limit
#'
#' @inheritDotParams Distance::ds scale dht_group monotonicity method mono_method
#' debug_level initial_values max_adjustments er_method dht_se optimizer winebin
#' @inherit Distance::ds details
#' @inheritSection Distance::ds Truncation
#' @inheritSection Distance::ds Monotonicity
#' @inheritSection Distance::ds Data format
#' @inheritSection Distance::ds Clusters/groups
#'
#' @examples
#' \dontrun{
#' data("duikers")
#'
#' # Calculates animal availability adjustment factor
#' trigger_events <- duikers$VideoStartTimesFullDays
#' avail <- ct_availability(times = trigger_events$time,
#'                          format = "%H:%M", n_bootstrap = 100)
#'
#' # Estimate density, building multiple models
#' flat_data <- duikers$DaytimeDistances %>%
#'   dplyr::slice_sample(prop = .2) # sample 20% of rows
#'
#' duiker_density <- ct_fit_ds(data = flat_data,
#'                             estimate = "density",
#'                             select_model = TRUE,
#'                             model_params = list(key = list("hn", "hr"),
#'                                                 adjustment = list("cos"),
#'                                                 nadj = list(2, 3),
#'                                                 order = NULL),
#'                             availability = avail,
#'                             truncation = list(left = 2, right = 15),
#'                             field_of_view = 42,
#'                             n_bootstrap = 2,
#'                             cutpoints = c(seq(2, 8, 1), 10, 12, 15)
#' )
#'
#' # View density
#' duiker_density$density
#' }
#'
#' @seealso [ct_availability()], [ct_select_model()], [ct_QAIC()], [ct_chi2_select()]
#'
#' @references
#' Buckland, S.T., Anderson, D.R., Burnham, K.P., Laake, J.L., Borchers, D.L.,
#' and Thomas, L. (2001). Distance Sampling. Oxford University Press. Oxford, UK.
#'
#' Howe, E. J., Buckland, S. T., Després-Einspenner, M., & Kühl, H. S. (2017).
#' Distance sampling with camera traps. Methods in Ecology and Evolution, 8(11),
#' 1558-1565. \doi{10.1111/2041-210X.12790}
#'
#' Howe, E. J., Buckland, S. T., Després‐Einspenner, M., & Kühl, H. S. (2019).
#' Model selection with overdispersed distance sampling data. Methods in Ecology and Evolution,
#' 10(1), 38–47.  \doi{10.1111/2041-210X.13082}
#'
#' Rowcliffe, J. M., Kays, R., Kranstauber, B., Carbone, C., & Jansen, P. A. (2014).
#' Quantifying levels of animal activity using camera trap data.
#' Methods in Ecology and Evolution, 5(11), 1170–1179.  \doi{10.1111/2041-210X.12278}
#'
#' @export
ct_fit_ds <- function(data,
                      estimate = c("density", "abundance"),
                      cutpoints = NULL,
                      truncation = set_truncation(data = data, cutpoints = cutpoints),
                   formula = ~ 1,
                   key = c("hn", "hr", "unif"),
                   adjustment = c("cos", "herm", "poly"),
                   nadj = NULL,
                   order = NULL,
                   select_model = FALSE,
                   model_params = list(key = list("hn", "hr", "unif"),
                                      adjustment = list("cos", "herm", "poly"),
                                      nadj = list(0, 1, 2),
                                      order = NULL),
                   field_of_view = 42,
                   availability,
                   n_bootstrap = 100,
                   n_cores = 1,
                   ...
                   ) {

  # Check early some package for bootstrap
    if (!checked_packages(c('parallel', 'foreach', 'doParallel', 'doRNG'))) {
      return(invisible(NULL))
    }
  # Set number bootstrap
  if(is.na(n_bootstrap) || is.null(n_bootstrap)){
    n_bootstrap <- 100
  }else if(n_bootstrap < 0){
    n_bootstrap <- abs(n_bootstrap)
  }
  # Set estimate
  estimate <- match_arg(estimate, c("density", "abundance"))
  # Convert unit
  convert_units <- Distance::convert_units("meter", NULL, "square kilometer")

  if (select_model) {
    at_least <- !c("key", "adjustment", "nadj", "order") %in% names(model_params)
    if (any(at_least)) {
      cli::cli_abort("model_params must be named list with `key`, `adjustment`, `nadj`, and/or `order`")
    }

    model_params[['formula']] <- combine_formula(formula = formula)
    # expand.grid can not keep NULL.
    expand.grid.null <- function(lst) {
      # Replace NULL with list(NULL) and expand manually
      lst <- lapply(lst, function(x) if (is.null(x)) list(NULL) else x)
      # Cartesian product manually
      do.call(expand.grid, c(lst, stringsAsFactors = FALSE))
    }
    param_grid <- expand.grid.null(model_params) %>%
      dplyr::mutate(nadj2 = unlist(lapply(adjustment, is.null)),
                    nadj = ifelse(nadj2, list(NULL), nadj)) %>%
      dplyr::distinct(.keep_all = TRUE) %>%
      dplyr::select(-nadj2)

    models <- list()
    # Start message
    start_msg <- "Total of {nrow(param_grid)} model{?s} will be fitted."
    cli::cli_alert_info(start_msg)
    sb <- cli::cli_status("Starting model fitting...")

    for (i in seq_len(nrow(param_grid))) {
      params <- param_grid[i, ]

      # Create progress message
      param_names <- colnames(params)
      param_value <- lapply(param_names, function(x){
        pv <- unlist(params[[x]])
        ifelse(is.null(pv), "NULL", pv)}
        ) %>% unlist()

      formula <- as.formula(unlist(params$formula))
      key <- unlist(params$key)
      adjustment <- unlist(params$adjustment)
      nadj <- unlist(params$nadj)
      order <- unlist(params$order)

      onrow <- paste0(paste(param_names, param_value, sep = ":"), collapse = " - ")
      msg <- paste0("Progress: ", {round(i*100/nrow(param_grid), 1)}, "% ", {onrow})
      # Call Distance::ds with values from params
      models[[i]] <- tryCatch({
        suppressMessages({
          Distance::ds(
            data = data,
            transect = "point",
            #er_var = "P2",
            convert_units = convert_units,
            cutpoints = cutpoints,
            truncation = truncation,
            formula = formula,
            key = key,
            adjustment = adjustment,
            nadj = nadj,
            order = order,
            ...
          )
        })
      }, error = function(e){cli::cli_warn(e$message)})
      models[[i]]$id <- i # uniquely ID for each model
      cli::cli_status_update(id = sb, msg = msg)

    }
    models <- Filter(Negate(is.character), models) # Filter failure models

    # End message
    cli::cli_status_clear(id = sb)
    cli::cli_alert_success(text = "Total of {length(models)} model{?s} fitted.")

    # Process to model selection
    if(length(models) == 0){return(invisible(NULL))}

    # Selection
    sel_sb <- cli::cli_status("Selecting model ...")
    selected <- ct_select_model(models)
    # Final message
    cli::cli_status_clear(id = sel_sb)
    cli::cli_alert_success(text = "Model selection complete!")

    ds_model <- selected$`Final model`
    QAIC <- selected$QAIC
    Chi2 <- selected$Chi2

    # No model selection
  }else{
    models <- NULL
    QAIC <- NULL
    Chi2 <- NULL
    df_sb <- cli::cli_status("Fiting detection function ...")
    ds_model <- suppressMessages({
      Distance::ds(data,
                   transect = "point",
                   er_var = "P2",
                   convert_units = convert_units,
                   cutpoints = cutpoints,
                   truncation = truncation,
                   formula = formula,
                   key = key,
                   adjustment = adjustment,
                   nadj = nadj,
                   order = order,
                   ...
      )
    })
    cli::cli_status_clear(id = df_sb)
    cli::cli_alert_success("Fitting complete!")

  }

    ## Estimate detection radius
    p_a <- summary(ds_model)$ds$average.p
    w <- diff(ds_model$ddf$meta.data$int.range)
    rho <- sqrt(p_a * w^2)

    # Density estimate
    samfrac <- field_of_view / 360

    # Bootstrap for variance estimation
    cli::cli_inform("Bootstrapping ...")
    boot_result <- suppressMessages({
      Distance::bootdht(model = ds_model,
                        flatfile = data,
                        resample_transects = TRUE,
                        nboot = n_bootstrap,
                        cores = n_cores,
                        summary_fun = ifelse(estimate == "density",
                                             Distance::bootdht_Dhat_summarize,
                                             Distance::bootdht_Nhat_summarize),
                        sample_fraction = samfrac,
                        convert_units = convert_units,
                        multipliers = availability,
                        progress_bar = "base")
    })

    estimated <- summary(boot_result)
    estimated <- dplyr::as_tibble(estimated$tab)
    cli::cli_alert_success("Bootstrap complete!")
    cli::cli_end()

    # Final Result
    density_result <- list(QAIC = QAIC,
                           Chi2 = Chi2, # detection function model object.
                           best_model = ds_model,
                           rho = rho,
                           estimate = estimated)

    density_result <- Filter(Negate(is.null), density_result)
    # Change 'estimate' to density or abundance
    estimate_name <- as.character(quote(estimate))
    names(density_result)[names(density_result) == estimate_name] <- estimate

  return(density_result)
}


#' Truncation
#' @noRd
set_truncation <- function(data, cutpoints = NULL) {

  if (!is.null(cutpoints)) {
    trunc <- c(min(cutpoints, na.rm = TRUE), max(cutpoints, na.rm = TRUE))
    possible_warn <- "cutpoints"

  } else if (!is.null(data$distend)) {
    if (!is.null(data$diststart)) {
      start <- min(data$diststart, na.rm = TRUE)
      warn4start <- "diststart"
    } else {
      start <- min(data$distance, na.rm = TRUE)
      warn4start <- "minimum distance"
    }
    trunc <- c(start, max(data$distend, na.rm = TRUE))
    possible_warn <- paste0(warn4start, " and distend")
  } else {
    trunc <- c(min(data$distance, na.rm = TRUE), max(data$distance, na.rm = TRUE))
    possible_warn <- "distance"
  }

  # Warn only if outside recommended range
  if (any(trunc < 2 | trunc > 15)) {
    cli::cli_warn(
      "Truncation {paste0(trunc[1], '-', trunc[2], ' m')} outside recommended 2–15 m range (Howe et al. 2017) - {possible_warn} should be reviewed."
    )
  }

  trunc <- list(left = trunc[1], right = trunc[2])
  return(trunc)
}

#' Generate all combinations of n variable
#' @noRd
#' @keywords internal
combine_formula <- function(formula) {
  all_variables <- all.vars(formula)
  if (length(all_variables) == 0) {
    return(list('~1'))
  }
  indep_var <- all_variables[-1]
  dep_var <- all_variables[1]

  mdl_names <- list()
  for (i in 1:length(indep_var)) {
    acom <- utils::combn(indep_var, m = i)
    for (pred in 1:ncol(acom)) {
      formula <- paste0(dep_var, " ~ ", paste0(acom[, pred], collapse = " + "))
      mdl_names[[paste0(i,pred)]] <- formula
    }
  }

  return(mdl_names)
}

#'  Temporal availability adjustment
#'
#' Calculates availability correction factors by accounting for
#' temporal variation in animal activity patterns and camera deployment effort.
#' The availability rate represents the proportion of time animals are available
#' for detection (Rowcliffe, et al., 2014; Howe et al., 2017) given their activity patterns
#' and camera sampling effort.
#'
#' @param times Vector of detection times, either in radians (0 - \eqn{2*pi}) or formatted times
#'              (see `format` parameter).
#' @param format Time format string (e.g., "%H:%M:%S", "%H:%M") if times need conversion
#'               to radians. Set to NULL if times are already in radians.
#' @inheritParams ct_fit_activity
#' @param cam_daily_effort Daily operational hours of cameras (default = 24 for continuous operation).
#' @inheritDotParams ct_fit_activity weights bandwidth adjustment bounds show
#'
#' @return A list containing data frame with:
#'   - `rate`: Estimated availability rate (0-1)
#'   - `SE`: Standard error of the availability rate
#'
#' @examples
#' \donttest{
#' # Example with times already in radians
#' radian_times <- c(1.2, 3.4, 5.1, 0.5, 2.8)
#' ct_availability(radian_times, sample = "data")
#'
#' # Example with formatted times
#' time_strings <- c("06:30", "18:15", "12:00", "23:45")
#' ct_availability(time_strings, sample = "data", format = "%H:%M")
#'
#' # With bootstrap resampling
#' ct_availability(radian_times, sample = "data", n_bootstrap = 100)
#'}
#'
#' @seealso [ct_fit_activity()]
#'
#' @references
#'
#' Howe, E. J., Buckland, S. T., Després-Einspenner, M. L., & Kühl, H. S. (2017).
#' Distance sampling with camera traps. Methods in Ecology and Evolution, 8(11), 1558–1565.
#'  \doi{10.1111/2041-210X.12790}
#'
#' Rowcliffe, J. M., Kays, R., Kranstauber, B., Carbone, C., & Jansen, P. A. (2014).
#' Quantifying levels of animal activity using camera trap data. Methods in Ecology
#' and Evolution, 5(11), 1170–1179.  \doi{doi:10.1111/2041-210X.12278}
#' @export
ct_availability <- function(times, format = NULL,
                            sample = c("data", "model"),
                            n_bootstrap = 1000,
                            cam_daily_effort = 24,
                            ...) {

  sample <- match_arg(sample, choices = c("data", "model"))
  if (!is.null(format)) { # not need to convert to radian
    radian_time <- ct_to_radian(times = times,
                                    format = format)
  }else{
    radian_time <- times
  }
  # Fit activity
  act_result <- ct_fit_activity(time_of_day = radian_time,
                                sample = sample,
                                n_bootstrap = n_bootstrap,
                                ...)

  prop_camera_time <- cam_daily_effort / 24
  avail <- list(creation = data.frame(rate = act_result$activity[['act']]/prop_camera_time,
                                      SE = act_result$activity[['se']]/prop_camera_time))
  return(avail)
}

##
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

#' Retreive detection function key
#' @noRd
get_ddf_names <- function(model){
  key <- model$ddf$name.message
  key_name <- c("hazard-rate", "half-normal", "uniform")
  checker <- c(grepl("hazard-rate", key), grepl("half-normal", key), grepl("uniform", key))
  return(key_name[checker])
}

#' Chat function
#' @noRd
compute_chat <- function(model) {
  test <- Distance::gof_ds(model, plot = FALSE, chisq = TRUE)
  test$chisquare$chi1$chisq/test$chisquare$chi1$df
}

#' Compute QAIC
#' @noRd
qaic <- function(model, chat, k) {
  (-2 * model$ddf$lnl/chat) + k * (length(model$ddf$par)+1)
}


#' Compute QAIC for a set of detection function models
#'
#' Calculates the quasi-Akaike Information Criterion (QAIC) for one or more
#' detection function models within the same key function family.
#' If multiple models are provided, all must have the same key function.
#' This function is typically used as the first step of a two-step model selection
#' approach (Howe et al., 2019).
#'
#' @inheritParams ct_select_model
#'
#' @return A tibble with one row per model containing:
#' - `model`: The model name
#' - `df`: The degrees of freedom for the model.
#' - `QAIC`: The computed QAIC value.
#'
#' @details
#' If only one model is supplied and \code{chat} is not provided, the function
#' estimates \eqn{\hat{c}} using the provided model and issues a warning that
#' model selection cannot be performed. For multiple models, All models must use the same key function.
#'
#' QAIC is calculated as:
#' \deqn{QAIC = -2 \times \log(L) / \hat{c} + 2k}
#' where \eqn{L} is the likelihood, \eqn{\hat{c}} is the estimated
#' overdispersion, and \eqn{k} is the number of parameters.
#'
#' @inherit ct_select_model references
#' @inherit ct_select_model examples
#'
#' @export
ct_QAIC <- function(models, chat = NULL, k = 2) {
  # Compute chat if Only 1 model specified
  if (length(models) < 2 & is.null(chat)) {
    models <- models[[1]]
    cli::cli_warn("1 {get_ddf_names(models)} model specified, no model selection can be performed!")
    chat <- compute_chat(models)
    qaics <- dplyr::tibble(model = unique(models$ddf$name.message),
                           df = length(models$ddf$par),
                           QAIC = qaic(models, chat = chat, k = k))
    return(qaics)
  }

  keys <- unlist(lapply(models, function(x) x$ddf$ds$aux$ddfobj$type))
  if (length(unique(keys)) != 1) {
    cli::cli_abort("All key functions must be the same")
  }

  npar <- unlist(lapply(models, function(x) length(x$ddf$par)))
  model_names <- unlist(lapply(models, function(x)x$ddf$name.message))
  if (is.null(chat)) {
    chat <- compute_chat(models[[which.max(npar)]])
  }

  qaics <- dplyr::tibble(model = model_names,
                         df = npar,
                         QAIC = unlist(lapply(models, qaic, chat = chat, k = k)))

  return(qaics)
}

#' Select best detection function model by Chi-squared Goodness-of-fit
#'
#' Compares detection function models with different key functions
#' using the ratio of the chi-squared statistic to its degrees of freedom.
#' This method selects the best model among different key functions after
#' the best adjustment term model is chosen for each key function.
#'
#' @inheritParams ct_select_model
#'
#' @return A tibble with one row per model containing:
#' - `key`: The key function of the model.
#' - `model`: The model name.
#' - `criteria`: The chi-squared goodness-of-fit statistic
#'   divided by its degrees of freedom, i.e. \eqn{\chi^2/\mathrm{df}}.
#'   Lower values indicate better fit.
#'
#' @details
#' If only one model is supplied, the function returns the chi-squared
#' goodness-of-fit ratio for that model and issues a warning that model
#' selection cannot be performed. For multiple models, each must have a unique key function.
#' This step is designed to be applied after selecting the best model within
#' each key function family using QAIC (see [ct_QAIC()]).
#' The model with the smallest chi-squared/df ratio is typically preferred.
#'
#' @inherit ct_select_model references
#' @inherit ct_select_model examples
#'
#'
#' @export
ct_chi2_select <- function(models) {

  if (length(models) < 2) {
    models <- models[[1]]
    cli::cli_warn("1 {get_ddf_names(models)} model specified, no model selection can be performed!")
    chi2_table <- dplyr::tibble(key = get_ddf_names(models),
                           model = unique(models$ddf$name.message),
                           criteria = compute_chat(models))
    return(chi2_table)
  }

  keys <- unlist(lapply(models, function(x) x$ddf$ds$aux$ddfobj$type))

  if (length(unique(keys)) != length(keys)) {
    cli::cli_abort("All key functions must be different")
  }

  res <- dplyr::tibble(key = sapply(models, get_ddf_names),
                       model = unlist(lapply(models, function(x)x$ddf$name.message)),
                       criteria = unlist(lapply(models, compute_chat))
                       )

  return(res)
}


#' Model selection for Distance Sampling detection functions
#'
#' Implements a two-step model selection procedure for distance sampling detection functions
#' following the approach of Howe et al (2019).
#'
#' @details
#'
#' **Step 1:**
#' Within each key function family (e.g., half-normal, hazard-rate), models are compared
#' using the quasi-Akaike Information Criterion (QAIC). Overdispersion (\eqn{\hat{c}})
#' is estimated if not provided. The best model per key function family is identified as
#' the one with the lowest QAIC.
#'
#' **Step 2:**
#' The best models from each key function family are compared using overall goodness-of-fit
#' statistics based on chi-squared divided by degrees of freedom (\eqn{\chi^2 / df}).
#' The model with the lowest \eqn{\chi^2 / df} is selected as the final detection function model.
#'
#' @param models A list of fitted detection function models (objects returned by
#'   [Distance::ds()] or [ct_fit_ds()]).
#' @param chat Optional numeric value of overdispersion (\eqn{\hat{c}}). If not provided,
#'   it is estimated from the most parameterised model in each key function set.
#' @param k Numeric. The penalty term used in QAIC (default is \code{2}).
#'
#' @return A named list with the following elements:
#' - `QAIC`: A tibble summarizing QAIC results for each model within key function families.
#' - `Best QAIC models`: A subset of models, one per key function, that minimize QAIC.
#' - `Chiq2`: A tibble comparing the best models by chi-squared goodness-of-fit criteria.
#' - `Final model`: The selected detection function model with the lowest chi-squared/df.
#'
#' @examples
#' \donttest{
#' library(Distance)
#' library(dplyr)
#'
#' data("duiker")
#' duiker_data <- duikers$DaytimeDistances %>%
#'   dplyr::slice_sample(prop = .3) # sample 30% of rows
#' truncation <- list(left = 2, right = 15) # Keep only distance between 2-15 m
#'
#' # fit hazard-rate key models
#' w3_hr0 <- ds(duiker_data, transect = "point", key = "hr", adjustment = NULL,
#'              truncation = truncation)
#' w3_hr1 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
#'              order = 2, truncation = truncation)
#' w3_hr2 <- ds(duiker_data, transect = "point", key = "hr", adjustment = "cos",
#'              order = c(2, 4), truncation = truncation)
#' # fit half-normal key models
#' w3_hn0 <- ds(duiker_data, transect = "point", key = "hn", adjustment = NULL,
#'              truncation = truncation)
#' w3_hn1 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
#'              order = 2, truncation = truncation)
#' w3_hn2 <- ds(duiker_data, transect = "point", key = "hn", adjustment = "cos",
#'              order = c(2, 4), truncation = truncation)
#' # fit uniform key models
#' w3_u0 <- ds(duiker_data, transect = "point", key = "unif", adjustment = NULL,
#'             truncation = truncation)
#' w3_u1 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
#'             order = 2, truncation = truncation)
#' w3_u2 <- ds(duiker_data, transect = "point", key = "unif", adjustment = "cos",
#'             order = c(2, 4), truncation = truncation)
#'
#' # Create model list
#' model_list <- list(w3_hn0, w3_hn1, w3_hn2,
#'                    w3_hr0, w3_hr1, w3_hr2,
#'                    w3_u0, w3_u1, w3_u2)
#'
#' # Compute model QAICs
#' ct_QAIC(list(w3_hr0, w3_hr1, w3_hr2)) # All key functions must be the same
#' ct_QAIC(list(w3_hn0, w3_hn1, w3_hn2)) # All key functions must be the same
#'
#' # Compute Chi-squared Goodness-of-fit
#' ct_chi2_select(list(w3_hn0, w3_hr0, w3_u0)) # All key functions must be different
#' ct_chi2_select(list(w3_hn2, w3_hr1, w3_u0)) # All key functions must be different
#'
#' # Two-step model selection
#' ct_select_model(model_list)
#'}
#'
#' @seealso [ct_QAIC()], [ct_chi2_select()]
#'
#' @references
#' Howe, E. J., Buckland, S. T., Després‐Einspenner, M., & Kühl, H. S. (2019).
#' Model selection with overdispersed distance sampling data. **Methods in Ecology and Evolution**,
#' 10(1), 38-47. \doi{10.1111/2041-210X.13082}
#'
#' @export
ct_select_model <- function(models,
                            chat = NULL,
                            k = 2
                            ) {

  # Create id for each model (not need when using ct_fit_ds()) for easy index
  models <- lapply(1:length(models), function(x){
    mdl <- models[[x]]
    mdl$id <- x
    return(mdl)
  })
  keys <- sapply(models, get_ddf_names)
  splited_model <- split(seq_along(models), keys)


  qaic_results <- lapply(splited_model, function(idx) {
    name_of_key <- names(splited_model)[sapply(splited_model, function(el) {identical(el, idx)})]
    ct_QAIC(models[idx]) %>%
      dplyr::mutate(key = name_of_key,
                    id = unlist(lapply(models[idx], function(x){x$id})))
  }) %>% dplyr::bind_rows() %>%
    dplyr::relocate(id, key, .before = 1) %>%
    dplyr::group_by(key) %>%
    dplyr::mutate(best = QAIC == min(QAIC)) %>%
    dplyr::ungroup()

  ## Retrieve best model
  bm_id <- qaic_results %>%
    dplyr::filter(best == TRUE) %>%
    dplyr::pull(id)

  model_ids <- unlist(lapply(models, function(x){x$id}))
  best_models <- models[model_ids %in% c(bm_id)]

  ## Select
  selected_model <- ct_chi2_select(best_models) %>%
    dplyr::mutate(best = criteria == min(criteria))

  ## Retrieve Final model
  final_model_name <- selected_model %>%
    dplyr::filter(best == TRUE) %>%
    dplyr::pull(model)
  model_names <- unlist(lapply(best_models, function(x){x$ddf$name.message}))
  final_model <- best_models[model_names %in% c(final_model_name)][[1]]
  #

  return(list(QAIC = qaic_results,
              `Best QAIC models` = best_models,
              `Chi2` = selected_model,
              `Final model` = final_model))
}

#' Maxwell's duiker camera‑trap distance & video‑start data
#'
#' The **`duikers`** dataset is a **named list** of three tibbles derived from
#' Maxwell's duiker (_Philantomba maxwellii_) camera‑trap and distance‑sampling
#' data collected in Taï National Park, Côte d'Ivoire (2014), and archived as
#' the Dryad dataset *Distance sampling with camera traps* (Howe et al., 2018)
#'
#' @format A named list with these tibbles:
#' **DaytimeDistances**: A tibble of all Maxwell's‑duiker distance
#'  observations (including non-peak periods) recorded at camera stations
#'  during daytime deployments. It has the following columns:
#'  - `distance`: the midpoint (m) of the assigned distance interval between animal and camera.
#'  - `Sample.Label`: camera‑station identifier.
#'  - `Effort`: number of active 2 second time steps the camera operated (i.e. temporal effort).
#'  - `Region.Label`: stratum name (only a single stratum in this dataset).
#'  - `Area`: study area size (km^2; in this dataset, 40.4).
#'  - `multiplier`: spatial effort: fraction of a full circle covered, based on
#'  the camera's 42 deg field of view (42/360).
#'  - `utm.e`: UTM easting (metres) of the camera station.
#'  - `utm.n`: UTM northing (metres) of the camera station.
#'  - `object`: a unique identifier for each observation
#'
#'
#'  **PeakDistances**: A tibble with the **same column structure** as
#'  **DaytimeDistances**, but includes **only** observations during the
#'  species' peak activity periods (no dawn or late day records).
#'
#'  **VideoStartTimesFullDays**: A tibble of camera‑trigger times for duiker
#'  videos that were recorded on **full day deployments** (i.e. days without
#'  researcher visits). Columns include:
#'  - `order`: sequential order of video events at each
#'         station/day.
#'  - `folder`: local folder (e.g. `"A1"`) for grouping
#'         videos by station or session.
#'  - `vid.no`: unique video identifier number.
#'  - `ek.no`: event key number (original trigger event id).
#'  - `easting`: UTM easting (metres) for the video event.
#'  - `northing`: UTM northing (metres) for the video event.
#'  - `month`: calendar month (1 to 12) of the video event.
#'  - `day`: day of the month (1 to 31).
#'  - `hour`: hour (24h clock) when the video started.
#'  - `minute`: minute of that hour when the video started.
#'  - `date`: Date of the record
#'  - `time`: Time of the record
#'  - `datetime`: date pasted with time
#'
#' @references
#' Howe, E. J., Buckland, S. T., Després-Einspenner, M. L., Kühl, H. S., & Buckland, S. T. (2018).
#' Data from: Distance sampling with camera traps. \doi{10.5061/dryad.b4c70}
"duikers"
