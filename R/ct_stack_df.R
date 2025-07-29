#' Stack a list of data frame
#'
#'The function takes a list of data frames and stacks them into a
#'single data frame. It ensures that all columns from the input data frames in the list are
#'included in the output, filling in missing columns with NA values where necessary.
#'
#' @param df_list list of data frame to be stacked
#'
#' @return data frame
#' @examples
#'
#' x <- data.frame(age = 15, fruit = "Apple", weight = 12)
#' y <- data.frame(age = 51, fruit = "Tomato")
#' z <- data.frame(age = 26, fruit = "Lemo", weight = 12, height = 45)
#' alldf <- list(x,y,z)
#' ct_stack_df(alldf)
#' @export
#'
ct_stack_df <- function(df_list) {
  dplyr::bind_rows(stack_list(df_list))
}
