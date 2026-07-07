#' Descriptive statistic on dataset
#'
#' This function provides a summary of a dataset, including both numeric and
#' non-numeric variables. For numeric variables, it calculates basic descriptive
#' statistics such as minimum, maximum, median, mean, and count of non-missing
#' values. Additionally, users can pass custom functions via the `fn` argument to
#' compute additional statistics for numeric variables. For non-numeric variables,
#' it provides frequency counts and proportions for each unique value.
#'
#' @param data A data frame containing the dataset to be summarized.
#' @param ... (Optional) Columns to include in the summary. If no column
#' is specified, all columns in the data will be included.
#' @param fn A list of functions to apply to numeric variables. Each function
#' must accept `x` as a vector of numeric values and return a single value or a
#' named vector. Additional arguments for these functions can be specified as a list.
#' For example: `fn = list('sum' = list(na.rm = TRUE), 'sd')`.
#' @param by_group Logical, default `TRUE`. When `TRUE` and both categorical and
#' numeric variables are selected, each numeric variable is summarised within the
#' groups defined by the categorical variable(s). When `FALSE`, numeric and categorical variables are
#' summarised independently and stacked into a single table. If only one variable
#' type is present, `by_group` has no effect.
#'
#' @return A tibble whose shape depends on `by_group`.
#'
#' With `by_group = TRUE` (and at least one categorical and one numeric variable),
#' the data are grouped by the selected categorical variable(s) and each numeric
#' variable is summarised within every group. The result has one row per numeric
#' variable and group combination, with columns:
#' \describe{
#'   \item{`Variable`}{Name of the numeric variable being summarised.}
#'   \item{grouping column(s)}{One column per selected categorical variable, each
#'     holding the group value.}
#'   \item{`N`}{Number of non-missing values of `Variable` in the group.}
#'   \item{`Min`, `Max`, `Median`, `Mean`}{Descriptive statistics of `Variable`
#'     within the group.}
#'   \item{`CI Left`, `CI Right`}{Lower and upper bounds of the 95% t-based
#'     confidence interval for the group mean (see [ct_ci()]).}
#' }
#'
#' With `by_group = FALSE` (also used as a fallback when only numeric or only
#' categorical variables are selected), numeric and categorical summaries are
#' stacked into one tibble with one row per numeric variable and one row per
#' distinct value of each categorical variable; columns that do not apply to a row
#' are `NA`:
#' \describe{
#'   \item{`Variable`}{Name of the summarised column.}
#'   \item{`Group`}{For a categorical variable, the distinct value described;
#'     `NA` for numeric variables.}
#'   \item{`Prop`}{For a categorical variable, the percentage of its non-missing
#'     records falling in `Group`; `NA` for numeric variables.}
#'   \item{`N`}{Non-missing count: values for a numeric variable, or records in
#'     `Group` for a categorical variable.}
#'   \item{`Min`, `Max`, `Median`, `Mean`}{Numeric statistics; `NA` for
#'     categorical variables.}
#'   \item{`CI Left`, `CI Right`}{95% t-based confidence interval bounds for the
#'     mean (see [ct_ci()]); `NA` for categorical variables.}
#' }
#'
#' In both modes, supplying `fn` appends one extra column per named function,
#' holding that statistic for each numeric variable (or group).
#'
#' @examples
#' df <- data.frame(x = c(1:3, NA),
#'                  y = c(3:4, NA, NA),
#'                  z = c("A", "A", "B", "A"))
#'
#' # Numeric variables summarised within each group of the categorical variable
#' ct_describe_df(df, y, x, z)
#'
#' # Summarise every variable independently
#' ct_describe_df(df, y, x, z, by_group = FALSE)
#'
#' # Add custom statistics for the numeric variables
#' ct_describe_df(df, y, x, z,
#'                fn = list('sum' = list(na.rm = TRUE), 'sd' = list(na.rm = TRUE)))
#'
#' @seealso parse_list_fn
#'
#' @export
ct_describe_df <- function(data, ..., fn = NULL, by_group = TRUE) {
  if (...length() == 0) {
    col_oi <- colnames(data)
  }else{
    col_oi <- suppressWarnings(colnames(data %>% dplyr::select(...)))
  }

  if (any(!col_oi %in% colnames(data))) {
    missed <- col_oi[!col_oi %in% colnames(data)]
    rlang::abort(paste0("Some column missed: ", paste0(missed, collapse = ", ")))
  }

  # Split the selected columns into numeric and categorical.
  is_numeric <- vapply(col_oi, function(x) is.numeric(data[[x]]), logical(1))
  num_var <- col_oi[is_numeric]
  cat_var <- col_oi[!is_numeric]

  # Descriptive statistics for a single numeric vector, shared by both modes.
  # A confidence interval needs at least two non-missing values; smaller groups
  # get NA rather than a NaN from the t-quantile.
  num_stats <- function(vec) {
    n <- length(vec[!is.na(vec)])
    summ <- summary(vec)
    dit <- dplyr::tibble(N = n,
                         Min = summ[[1]],
                         Max = summ[[6]],
                         Median = summ[[3]],
                         Mean = summ[[4]],
                         `CI Left` = if (n >= 2) ct_ci(vec, side = "left") else NA_real_,
                         `CI Right` = if (n >= 2) ct_ci(vec, side = "right") else NA_real_)
    if (!is.null(fn)) {
      dit <- dit %>% dplyr::bind_cols(parse_list_fn(fn = fn, data = vec))
    }
    dit
  }

  # Grouped mode: summarise each numeric variable within the groups defined by
  # the categorical variable(s), like dplyr::group_by() %>% summarise(). Only
  # possible when both a grouping variable and a numeric variable are present;
  # otherwise fall through to the stacked (independent) summary below.
  if (isTRUE(by_group) && length(cat_var) > 0 && length(num_var) > 0) {
    grouped <- data %>% dplyr::group_by(dplyr::across(dplyr::all_of(cat_var)))
    keys <- dplyr::group_keys(grouped)
    rows <- dplyr::group_rows(grouped)

    toreturn <- lapply(num_var, function(v) {
      lapply(seq_len(nrow(keys)), function(g) {
        vec <- data[[v]][rows[[g]]]
        dplyr::bind_cols(dplyr::tibble(Variable = v),
                         keys[g, , drop = FALSE],
                         num_stats(vec))
      }) %>% dplyr::bind_rows()
    }) %>% dplyr::bind_rows()

    return(dplyr::tibble(toreturn))
  }

  # Stacked mode (by_group = FALSE, or only one variable type is present):
  # numeric and categorical variables summarised independently.
  alltab <- list()

  if (length(num_var) > 0) {
    for_num <- lapply(num_var, function(x){
      dplyr::bind_cols(dplyr::tibble(Variable = x), num_stats(data[[x]]))
    }) %>% dplyr::bind_rows()
    alltab[[length(alltab) + 1]] <- for_num
  }

  if (length(cat_var) > 0) {
    for_char <- lapply(cat_var, function(x){
      data %>%
        dplyr::filter(!is.na(.data[[x]])) %>%
        dplyr::count(.data[[x]], name = "N") %>%
        dplyr::mutate(
          Prop = round(100 * .data$N / sum(.data$N), 1),
          Variable = x,
          Group = .data[[x]]
        ) %>%
        dplyr::select(Variable, Group, Prop, N)
    }) %>% dplyr::bind_rows()
    alltab[[length(alltab) + 1]] <- for_char
  }

  # Stack and return result
  if (length(alltab) == 2) {
    toreturn <- ct_stack_df(df_list = alltab)
  }else{
    toreturn <- alltab[[1]]
  }

  # Arrange column
  if ("Group" %in% colnames(toreturn)) {
    toreturn <- toreturn %>% dplyr::relocate(Group, Prop, N, .before = 2)
  }

  return(dplyr::tibble(toreturn))
}

#' @noRd
parse_list_fn <- function(fn, data){
  args_names <- fn
  ori_names <- names(fn)

  if (is.null(ori_names)) {
    ori_names <- lapply(fn, function(x)x) %>% unlist()
  }
  if (any(ori_names %in% c(''))) {
    fn_ <- lapply(fn, function(x)x) %>% unlist()
    ori_names[names(fn) %in% c('')] <- fn_[names(fn) %in% c('')]
    fn_names <- ori_names
  }

  all_parser <- list()
  for (nm in ori_names) {
    if (is.null(fn[[nm]])) {
      args <- list('x' = data)
    }else{

      fn[[nm]][['x']] <- data
      args <- fn[[nm]]
    }

    all_parser[[nm]] <- do.call(what = nm, args = args)
  }

  return(dplyr::bind_cols(all_parser))
}
