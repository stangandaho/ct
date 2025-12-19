#' Create or add hierarchical subject (hs) values in image metadata
#'
#' @description
#' Adds hierarchical subject metadata to image files. Hierarchical
#' subjects follow a parent|child structure, allowing for organized taxonomic or
#' categorical classification of images.
#'
#' @param path A character string specifying the full path to an image file or
#'   directory. If a directory is provided, hierarchical subjects will be added
#'   to all supported image files in that directory.
#' @param value A named character vector specifying hierarchical subjects to add.
#'   Names represent parent categories, values represent child categories.
#'
#'   **Simple format:** `c("Species" = "Vulture", "Location" = "Africa")`
#'   creates "Species|Vulture" and "Location|Africa".
#'
#'   **Multiple values format:** `c("Species" = "Mammal, Bird", "Count" = "2, 3")`
#'   creates "Species|Mammal", "Species|Bird", "Count|2", and "Count|3".
#'   All parents must have equal number of comma-separated values.
#' @param overwrite Logical. If `TRUE`, replaces existing hierarchical subjects.
#'   If `FALSE` (default), adds to existing subjects. Default: `FALSE`.
#' @param recursive Logical. If `TRUE` and `path` is a directory, searches for
#'   images recursively in subdirectories. Default: `FALSE`.
#' @inheritParams ct_remove_hs
#'
#' @return Invisibly returns `TRUE` on success. Called primarily for side effects
#'   (modifying image metadata).
#'
#' @details
#'
#' Two input formats are supported:
#' 1. Simple format: One child per parent, e.g., `c("Species" = "Vulture")`
#' 2. Multiple values format: Multiple children per parent using comma-separated
#'    values, e.g., `c("Species" = "Mammal, Bird, Reptile")`. When using this
#'    format, all parents must have the same number of comma-separated values.
#'
#' The function validates that all values have parent categories (names) and
#' preserves existing hierarchical subjects unless `overwrite = TRUE`. Duplicate
#' parent|child combinations are automatically removed.
#'
#' When processing directories, the function applies hierarchical subjects to all
#' supported image files found. Use `recursive = TRUE` to include subdirectories.
#'
#' When using comma-separated values, the function splits each value string and
#' creates separate hierarchical subjects for each position across all parents.
#'
#' @seealso
#' * [ct_get_hs()] to retrieve hierarchical subjects
#' * [ct_remove_hs()] to remove hierarchical subjects
#' * [ct_read_metadata()] to read image metadata
#'
#' @examples
#' \donttest{
#' # Path to example image
#' image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")
#'
#' # Simple format: single child per parent
#' ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
#' ct_get_hs(path = image_path) # Returns: "Species|Vulture"
#'
#' # Simple format: multiple parents, one child each
#' ct_create_hs(
#'   path = image_path,
#'   value = c("Species" = "Vulture",
#'             "Location" = "Africa",
#'             "Status" = "Endangered")
#' )
#' ct_get_hs(path = image_path, into_tibble = TRUE)
#'
#' # Multiple values format: recording multiple observations
#' ct_create_hs(
#'   path = image_path,
#'   value = c(
#'     "Species" = "Gyps africanus, Kobus kob",
#'     "Sex" = "Male, Female",
#'     "Count" = "3, 2"
#'   ),
#'   overwrite = TRUE
#' )
#' ct_get_hs(path = image_path)
#'
#' # Parse Hierarchical Subject to tibble
#' ct_get_hs(path = image_path, into_tibble = TRUE)
#'
#' # Overwrite existing hierarchical subjects
#' ct_create_hs(
#'   path = image_path,
#'   value = c("Species" = "Eagle"),
#'   overwrite = TRUE
#' )
#'}
#' @export
ct_create_hs <- function(path,
                         value = NULL,
                         overwrite = FALSE,
                         recursive = FALSE,
                         intern = TRUE,
                         quiet = TRUE,
                         ...) {
  # Input validation
  if (missing(path) || is.null(path) || length(path) == 0) {
    cli::cli_abort("{.arg path} must be provided.")
  }

  if (!file.exists(path)) {
    cli::cli_abort("Path not found: {.path {path}}")
  }

  if (is.null(value) || length(value) == 0) {
    cli::cli_abort(
      c(
        "{.arg value} must be a named character vector.",
        "i" = "Example: {.code c('Species' = 'Vulture')}"
      )
    )
  }

  # Check for missing names (parents)
  has_missing_names <- is.null(names(value)) || any(names(value) == "")

  if (has_missing_names) {
    unnamed_values <- if (is.null(names(value))) {
      value
    } else {
      value[names(value) == ""]
    }

    cli::cli_abort(
      c(
        "All hierarchical subjects must have a parent name.",
        "x" = "Missing parent for: {.val {unnamed_values}}",
        "i" = "Use: {c('Parent' = '{unnamed_values[1]}')}"
      )
    )
  }

  # Check if values contain commas (multiple values format)
  has_commas <- grepl(",", value, fixed = TRUE)

  if (any(has_commas)) {
    # Multiple values format - split by comma and validate lengths
    split_values <- lapply(value, function(x) {
      trimws(strsplit(x, ",", fixed = TRUE)[[1]])
    })

    # Check that all parents have the same number of values

    value_lengths <- lengths(split_values)

    if (length(unique(value_lengths)) > 1) {
      cli::cli_abort(
        c(
          "When using comma-separated values, all parents must have equal number of values.",
          "x" = "Current lengths: {.val {setNames(value_lengths, names(value))}}",
          "i" = "Example: {c('Species' = 'Mammal, Bird', 'Count' = '2, 3')}"
        )
      )
    }

    # Create hierarchical subjects for each position
    n_values <- value_lengths[1]
    new_hs <- character(0)

    for (i in seq_len(n_values)) {
      for (parent in names(split_values)) {
        child <- split_values[[parent]][i]
        new_hs <- c(new_hs, sprintf("%s|%s", parent, child))
      }
    }
  } else {
    # Simple format - one child per parent
    new_hs <- sprintf("%s|%s", names(value), value)
  }

  # Get existing hierarchical subjects (only for single files)
  # For directories, we use -addtagsfromfile approach or rely on ExifTool's behavior
  is_directory <- dir.exists(path)
  existing_hs <- if (!overwrite && !is_directory) {
    ct_get_hs(path = path)
  } else {
    NULL
  }

  # Combine with existing (if not overwriting)
  all_hs <- if (!is.null(existing_hs)) {
    unique(c(new_hs, existing_hs))
  } else {
    unique(new_hs)
  }

  # Format for ExifTool command
  hs_args <- paste0(
    sprintf("-P -FileModifyDate<DateTimeOriginal -HierarchicalSubject=%s -overwrite_original", noquote(all_hs)),
    collapse = " "
  )

  # Add recursive flag if needed
  if (recursive && is_directory) {
    hs_args <- paste("-r", hs_args)
  }

  # Execute ExifTool command
  response <- suppressMessages({
    ct_exiftool_call(
      args = noquote(hs_args),
      path = path,
      intern = intern,
      quiet = quiet,
      ...
    )
  })

  if (!quiet) {
    if (is_directory) {
      cli::cli_alert_success(
        "Added {length(new_hs)} hierarchical subject{?s} to images in {.path {basename(path)}}"
      )
    } else {
      cli::cli_alert_success(
        "Added {length(new_hs)} hierarchical subject{?s} to {.file {basename(path)}}"
      )
    }
  }

  invisible(TRUE)
}
