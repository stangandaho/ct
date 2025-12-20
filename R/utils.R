#' Path list
#' @keywords internal
#' @noRd
table_files <- function(){
  c(system.file("penessoulou_season1.csv", package = "ct"),
       system.file("penessoulou_season2.csv", package = "ct"))
}

#' Deep list
#'
#' @description
#' Convert list to tree object format for jstree library
#' @keywords internal
#' @noRd
#'
deep_list <- function(list_item){
  setlist <- list()
  listname <- names(list_item)

  for (n in listname) {
    val <- list_item[[n]]
    listed <- as.list(setNames(rep("", length(val)), val))

    setlist[[n]] <- listed
  }

  return(setlist)
}

#' Pair to list
#'
#' @description
#' Convert a vector into a list with pairs of elements (i.e., two-by-two)
#' @keywords internal
#' @noRd
#'
pair_to_list <- function(vec) {
  if (length(vec) %% 2 != 0) {
    stop("The length of the vector must be even.")
  }

  result_list <- list()
  for (i in seq(1, length(vec), by = 2)) {
    result_list[[vec[i]]] <- vec[i + 1]
  }

  return(result_list)
}


#' Check seperator
#' @description
#' Check and return the seperator in the file (dataset to read)
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
check_sep <- function(file_path){

  readed_line <- readLines(con = file_path, n = 1)

  seps <- c(",", ";", "\\|")
  separators_is_in <- list()
  for (sep in seps) {
    lgc <- grepl(sep, readed_line)
    separators_is_in[[sep]] <- lgc
  }
  separators_is_in <- unlist(separators_is_in)
  names(separators_is_in) <- NULL

  if (all(separators_is_in == FALSE)) {
    cli_abort("Unknow seperator in file")
  }

  sep <- seps[separators_is_in][1L]

  if (sep == "\\|") {
    sep <- "|"
  }
  return(sep)
}

#' Update list
#' @description
#' Update an existing list basing on item in second list.
#' If the element is in the list, append the value from second list
#' and ensure the values are unique. If the element is not in the list, add it with its value
#' @keywords internal
#' @noRd
#'
update_list <- function(first_list, second_list) {
  for (name in names(second_list)) {
    if (name %in% names(first_list)) {
      #
      combined_values <- unique(c(first_list[[name]], second_list[[name]]))
      first_list[[name]] <- combined_values
    } else {
      #
      first_list[[name]] <- second_list[[name]]
    }
  }
  return(first_list)
}


#' Pipe operator
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
#' @export
magrittr::`%>%`

#' Pipe operator
#'
#' @name %<>%
#' @rdname pipe
#' @keywords internal
#' @importFrom magrittr %<>%
#' @usage lhs \%<>\% rhs
#' @export
magrittr::`%<>%`

#' Pipe operator
#' use left if not NULL, else right
#' @name %||%
#' @noRd
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

################
#' Parse datetime
#'
#' @description
#' Parses an input vector into POSIXct date-time object.
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
parse_datetime <- function (datetime,
                            format,
                            time_zone,
                            check_na = TRUE,
                            check_empty = TRUE,
                            check_na_out = TRUE,
                            allow_empty_output = FALSE,
                            quiet = FALSE) {

  if (inherits(datetime, c("POSIXct", "POSIXlt"))) {
    datetime <- format(datetime, format = "%Y-%m-%d %H:%M:%S")
  }
  else {
    if (!inherits(datetime, "character"))
      cli_abort(paste("datetime must be a character:",
                 deparse(substitute(datetime))), call = NULL)
  }
  if (check_na & any(is.na(datetime)))
    cli_abort(paste("there are NAs in", deparse(substitute(datetime))), call = NULL)
  if (check_empty & any(datetime == ""))
    cli_abort(paste("there are blank values in", deparse(substitute(datetime))), call = NULL)
  if (all(datetime == "") & allow_empty_output)
    return(NA)
  datetime_char <- as.character(datetime)

  if (grepl(pattern = "%", x = format, fixed = TRUE)) {
    out <- as.POSIXct(datetime_char, tz = time_zone, format = format)
  }

  if (all(is.na(out)))
    cli_abort(paste0("Cannot read datetime format in ", deparse(substitute(datetime)),
                ". Output is all NA.\n", "expected:  ", format,
                "\nactual:    ", datetime[1]), call = NULL)
  if (check_na_out & any(is.na(out)))
    cli_abort(paste(sum(is.na(out)), "out of", length(out), "records in",
               deparse(substitute(datetime)), "cannot be interpreted using format:",
               format, "\n", "rows", paste(which(is.na(out)),
                                           collapse = ", ")), call = NULL)
  if (inherits(datetime, c("POSIXct", "POSIXlt")))
    cli_abort("couldn't interpret datetime using specified format. Output is not POSIX object")
  return(out)
}


#' Melt data
#'
#' @description
#' Convert a matrix into a molten data frame
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
#' @importFrom dplyr bind_rows

melt <- function(data){
  if (any(!class(data) %in% c("matrix", "array"))) {
    cli_abort("Data must be a matrix", call = NULL)
  }

  if (is.null(colnames(data))) {
    cli_abort("The data must have column names", call = NULL)
  }

  if (is.null(rownames(data))) {
    cli_abort("The data must have row names",  call = NULL)
  }

  tbl_list <- list()

  for (r in rownames(data)) {
    for (c in colnames(data)) {
      tbl <- tibble(Var1 = c, Var2 = r, value = data[r, c])
      tbl_list[[paste0(r,c)]] <- tbl
    }
  }
  melt_data <- bind_rows(tbl_list)

  return(melt_data)
}


#' Check density input
#'
#' @description
#' Make sure the input data to fit kernel density is suitable
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort

check_density_input <- function (y)
{
  if (!is.vector(y) || !is.numeric(y))
    cli_abort("The times of observations must be in a numeric vector.", call = NULL)
  if (length(unique(y)) < 2)
    cli_abort(paste0("At least 2 different observations are needed to fit a density. Not ",
                     length(unique(y)), "!"), call = NULL)
  if (any(is.na(y)))
    cli_abort("Your data have missing values.", call = NULL)
  if (any(y < 0 | y > 2 * pi))
    cli_abort("You have times < 0 or > 2*pi; make sure you are using radians.",
              call = NULL)
  return(NULL)
}

#' Time to hour
#'
#' @description
#' Convert time to hour
#' @keywords internal
#' @noRd
#'
convert_to_hour <- function(time_str) {

  h <- lapply(time_str, function(x){
    parts <- as.numeric(unlist(strsplit(x, ":")))
    return(parts[1] + parts[2]/60 + parts[3]/3600)
  })

  return(unlist(h))
}


#' Colored text
#'
#' @description
#' Colored text in console
#' @keywords internal
#' @noRd
custom_cli <- function(text, color = "red") {

  if (!is.null(color) && color %in% c("red", "blue", "green")) {
    if (color == "red") {
      txt <- paste0("\033[31m", text, "\033[0m")
    }else if(color == "green"){
      txt <- paste0("\033[32m", text, "\033[0m")

    }else if(color == "blue"){
      txt <- paste0("\033[34m", text, "\033[0m")
      }
    }else{
    color <- sample(as.character(1:4), size = 1)
    txt <- switch (color,
      "1" = paste0("\033[33m", text, "\033[0m"),
      "2" = paste0("\033[35m", text, "\033[0m"),
      "3" = paste0("\033[36m", text, "\033[0m"),
      "4" = paste0("\033[37m", text, "\033[0m")
    )
  }

  cat(txt)
}

#' Match argument
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
match_arg <- function(arg, choices, argname = deparse(substitute(arg))) {
  tryCatch(
    match.arg(arg, choices),
    error = function(e) {
      cli_abort("{.field {argname}} must be one of {.code {choices}}", call = NULL)
    }
  )
}

#' CRS
#'
#' @description
#' Get CRS type
#' @keywords internal
#' @noRd
#' @importFrom cli cli_abort
#' @importFrom sf st_crs

crs_type <- function(sf_object) {
  wkt <- st_crs(sf_object)$wkt
  if (is.na(wkt)) {
    obj_name <- deparse(substitute(sf_object))
    cli_abort(sprintf("Coordinate Reference System (CRS) of `%s` cannot be NA. Assign a CRS.",
                         obj_name), call = NULL)
  }

  if (grepl("PROJCRS", wkt)) {
    cr_sys <- "Projected"
  }else if(grepl("GEOGCRS", wkt)){
    cr_sys <- "Geographic"
  }
  return(cr_sys)
}

#' Validate study area
#'
#' @description
#' Make sure study area provided is sf object and represents a polygon
#' @keywords internal
#' @importFrom cli cli_abort
#' @importFrom sf st_geometry_type
#' @noRd
valid_study_area <- function(sf_object) {
  if (!any(c("sf", "sfc_POLYGON" ,"sfc") %in% class(sf_object))) {
    cli_abort("Area of study must be simple feature (sf) object", call = NULL)
  }

  if (!any(c("MULTIPOLYGON", "POLYGON") %in% st_geometry_type(sf_object))) {
    cli_abort("Area of study must be a polygon", call = NULL)
  }
}

#' Check column presence
#'
#' @description
#' Make sure column(s) provided is/are present in the data
#' @keywords internal
#' @importFrom rlang ensyms
#' @importFrom cli format_error cli_abort
#' @noRd
#'
missed_col_error <- function(data, ..., use_object = TRUE){

  if (use_object) {
    cols <- unlist(list(...))
  }else{
    cols <- sapply(ensyms(...), rlang::as_string)
  }

  if (any(!cols %in% colnames(data))) {
    not_in <- cols[!cols %in% colnames(data)];
    cli_abort(format_error("Column {not_in} not found in {deparse(substitute(data))}"), call = NULL)
  }
}

#' Calculate confidence interval
#'
#' Calculates the confidence interval for the mean of a numeric vector using the t-distribution.
#'
#' @param x A numeric vector of data values.
#' @param alpha Significance level for the confidence interval. Default is 0.05 (for 95% confidence).
#' @param side A character string indicating the type of interval:
#'   \describe{
#'     \item{"all"}{Two-sided confidence interval (default).}
#'     \item{"left"}{One-sided lower bound.}
#'     \item{"right"}{One-sided upper bound.}
#'   }
#'
#' @return A numeric vector containing the confidence interval bounds:
#'   \itemize{
#'     \item If \code{side = "all"}, returns a vector of length 2: \code{c(lower, upper)}.
#'     \item If \code{side = "left"} or \code{"right"}, returns a single numeric value.
#'   }
#'
#' @examples
#' x <- c(10, 12, 11, 14, 13, 15)
#' ct_ci(x)
#' ct_ci(x, alpha = 0.01)
#' ct_ci(x, side = "left")
#'
#' @export
ct_ci <- function(x, alpha = .05, side = 'all') {
  #Step 1: Calculate the mean
  sample_mean <- mean(x, na.rm = TRUE)

  #Step 2: Calculate the standard error of the mean
  sample_sd <- sd(x, na.rm = TRUE)
  sample_lenght <- length(x[!is.na(x)])
  se <- sample_sd/sqrt(sample_lenght)

  #Step 3: Find the t-score that corresponds to the confidence level
  degrees_freedom = sample_lenght - 1
  t_score = qt(p = alpha/2, df = degrees_freedom,lower.tail = FALSE)

  #Step 4. Calculate the margin of error and construct the confidence interval
  margin_error <- t_score * se
  lower_bound <- sample_mean - margin_error
  upper_bound <- sample_mean + margin_error

  ci <- switch (side,
                'all' = c(lower_bound, upper_bound),
                'left' = lower_bound,
                'right' = upper_bound
  )
  return(ci)
}


#' Log-normal confidence interval
#'
#' Calculates approximate log-normal confidence intervals given estimates
#' and their standard errors.
#'
#' @param estimate Numeric estimate value(s)
#' @param se Standard error(s) of the estimate
#' @param percent Percentage confidence level
#' @return A dataframe with a row per estimate input, and columns \code{lcl}
#'   and \code{ucl} (lower and upper confidence limits).
#'
#' @keywords internal
#' @importFrom cli cli_abort
lnorm_confint <- function(estimate, se, percent = 95){
  if(length(estimate) != length(se))
    cli_abort("estimate and se must have the same number of values")
  z <- qt((1 - percent/100) / 2, Inf, lower.tail = FALSE)
  w <- exp(z * sqrt(log(1 + (se/estimate)^2)))
  data.frame(lower_bound = estimate/w, upper_bound = estimate*w)
}

#' Get column name
#' @description
#' Get column name
#' @keywords internal
#' @noRd
#' @importFrom dplyr select all_of
get_column <- function(data, ...){
  colname <- data %>% select(all_of(...)) %>% colnames()
  if (length(colname) == 0) {
    return(NULL)
  }

  return(colname)
}

#' Common datetime formats for parsing
#'
#' A vector of common datetime formats used in parsing operations.
#'
#' @format A character vector
#' @keywords internal
#' @noRd
try_formats <- c("%Y-%m-%d %H:%M:%OS", "%Y/%m/%d %H:%M:%OS",
                 "%Y:%m:%d %H:%M:%OS", "%Y-%m-%d %H:%M",
                 "%Y/%m/%d %H:%M", "%Y:%m:%d %H:%M",
                 "%Y-%m-%d", "%Y/%m/%d", "%Y:%m:%d")

#' Get column name
#' @keywords internal
#' @noRd
#' @importFrom rlang is_symbol is_quosure as_name get_expr enquo
#' @importFrom cli cli_abort
as_colname <- function(arg) {
  if (is_symbol(arg) ||is_quosure(arg)) {
    as_name(get_expr(arg))
  } else if (is.character(arg)) {
    enquo(arg)
  } else {
    cli_abort("Column name must be a string or unquoted symbol.")
  }
}

#' Check package
#' @noRd
#' @importFrom cli cli_div cli_text
#' @importFrom utils menu
checked_packages <- function(packages) {
  # Check availability
  not_available <- !vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))

  if (any(not_available)) {
    to_install <- packages[not_available]
    cli_div(theme = list(span.emph = list(color = "#ef6d00")))
    cli_text("{ifelse(length(to_install) > 1, 'Packages', 'Package')} {.emph {to_install}} need to be installed.")
    action <- menu(choices = c("Install", "No"))
    if (action == 1) {
      for (pkg in to_install) {
        install.packages(pkg, dependencies = TRUE)
      }
    }
  }

  # Check again after installation
  still_missing <- !vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
  return(!any(still_missing))
}


#' Determine the Per-User Directory for R Package Data, Config, or Cache
#'
#' @description
#' Determine the per-user directory where packages can store data,
#' configuration files, or caches.
#'
#' @param package Character string giving the package name.
#' @param which Character string specifying the directory type.
#'   Must be one of `"data"`, `"config"`, or `"cache"`.
#'
#' @return
#' A character string giving the full path to the package-specific
#' per-user directory.
#' @keywords internal
R_user_dir <- function(package,
                       which = c("data", "config", "cache")) {
  which <- match.arg(which)
  os <- Sys.info()[["sysname"]]
  home <- Sys.getenv("HOME")

  if (os == "Windows") {
    appdata      <- Sys.getenv("APPDATA", unset = file.path(home, "AppData", "Roaming"))
    localappdata <- Sys.getenv("LOCALAPPDATA", unset = file.path(home, "AppData", "Local"))

    base_dir <- switch(which,
                       "data"   = file.path(appdata,      "R", "data", "R"),
                       "config" = file.path(appdata,      "R", "config", "R"),
                       "cache"  = file.path(localappdata, "R", "cache", "R")
    )
  } else if (os == "Darwin") {  # macOS
    base_dir <- switch(which,
                       "data"   = file.path(home, "Library", "Application Support", "org.R-project.R", "R", "data"),
                       "config" = file.path(home, "Library", "Preferences", "org.R-project.R", "R", "config"),
                       "cache"  = file.path(home, "Library", "Caches", "org.R-project.R", "R", "cache")
    )
  } else {  # Linux / Unix
    xdg_data   <- Sys.getenv("XDG_DATA_HOME",   file.path(home, ".local", "share"))
    xdg_config <- Sys.getenv("XDG_CONFIG_HOME", file.path(home, ".config"))
    xdg_cache  <- Sys.getenv("XDG_CACHE_HOME",  file.path(home, ".cache"))

    base_dir <- switch(which,
                       "data"   = file.path(xdg_data,   "R", "data"),
                       "config" = file.path(xdg_config, "R", "config"),
                       "cache"  = file.path(xdg_cache,  "R", "cache")
    )
  }

  ruser_dir <- suppressWarnings(normalizePath(file.path(base_dir, package),
                                              winslash = "/"))
  return(ruser_dir)
}

