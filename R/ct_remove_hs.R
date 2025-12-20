#' Remove hierarchical subject (hs) values from image metadata
#'
#' @description
#' Removes specific hierarchical subjects or clears the entire HierarchicalSubject
#' field from image metadata using ExifTool. Can remove one or multiple specific
#' parent|child hierarchies, or clear all hierarchical subjects at once.
#'
#' This function supports processing individual files or entire directories (with
#' optional recursion), applying the removal to all supported image files found.
#'
#' @param path A character string specifying the full path to an image file or
#'   directory. If a directory is provided, hierarchical subjects will be removed
#'   from all supported image files in that directory.
#' @param hierarchy A named character vector specifying hierarchies to remove.
#'   Names represent parent categories, values represent child categories.
#'   Example: `c("Species" = "Vulture")` removes "Species|Vulture".
#'   If `NULL` (default), removes all hierarchical subjects from the image(s).
#' @param recursive Logical. If `TRUE` and `path` is a directory, searches for
#'   images recursively in subdirectories. Default: `FALSE`.
#' @param intern Logical. If `TRUE`, returns output as a character vector.
#'   Default: `TRUE`.
#' @param quiet Logical. If `TRUE`, suppresses command output. Default: `TRUE`.
#' @param ... Additional arguments passed to [system2()].
#'
#' @return Invisibly returns `TRUE` on success, `FALSE` if specified hierarchy
#'   doesn't exist. Displays informative messages about the operation. Called
#'   primarily for side effects (modifying image metadata).
#'
#' @details
#' When removing specific hierarchies from a single file, the function validates
#' that they exist before attempting removal. If the last hierarchy is removed,
#' the entire HierarchicalSubject field is cleared from the metadata. The
#' function handles multiple hierarchies in a single call.
#'
#' When processing directories, the function applies the removal to all supported
#' image files found. Use `recursive = TRUE` to include subdirectories. Note that
#' validation of existing hierarchies is only performed for single files.
#'
#' @seealso
#' * [ct_get_hs()] to retrieve hierarchical subjects
#' * [ct_create_hs()] to add hierarchical subjects
#' * [ct_read_metadata()] to read image metadata
#'
#' @examples
#' \dontrun{
#' # Path to example image
#' image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")
#'
#' # Add some hierarchical subjects
#' ct_create_hs(image_path, c("Species" = "Vulture", "Location" = "Africa"))
#' ct_get_hs(image_path)
#'
#' # Remove a specific hierarchy
#' ct_remove_hs(image_path, hierarchy = c("Species" = "Vulture"))
#' ct_get_hs(image_path) # Only "Location|Africa" remains
#'
#' # Remove multiple hierarchies at once
#' ct_create_hs(image_path, c("Species" = "Eagle", "Status" = "Endangered"))
#' ct_remove_hs(
#'   image_path,
#'   hierarchy = c("Species" = "Eagle", "Status" = "Endangered")
#' )
#'
#' # Remove all hierarchical subjects
#' ct_remove_hs(image_path, hierarchy = NULL)
#' ct_get_hs(image_path) # Returns NULL
#'
#' # Attempting to remove non-existent hierarchy
#' ct_remove_hs(image_path, hierarchy = c("Species" = "NonExistent"))
#'
#' # Remove all hierarchical subjects from all images in a directory
#' image_dir <- system.file("img", package = "ct")
#' ct_remove_hs(path = image_dir, recursive = FALSE)
#'
#' # Remove recursively from directory and subdirectories
#' ct_remove_hs(path = image_dir, recursive = TRUE)
#'
#' # Remove specific hierarchy from all images in a directory
#' ct_remove_hs(
#'   path = image_dir,
#'   hierarchy = c("Species" = "Vulture"),
#'   recursive = TRUE
#' )
#'}
#' @export
ct_remove_hs <- function(path,
                         hierarchy = NULL,
                         recursive = FALSE,
                         intern = TRUE,
                         quiet = TRUE,
                         ...) {
  # Validate input
  if (missing(path) || is.null(path) || length(path) == 0) {
    cli::cli_abort("{.arg path} must be provided.")
  }

  if (!file.exists(path)) {
    cli::cli_abort("Path not found: {.path {path}}")
  }

  is_directory <- dir.exists(path)

  # Remove all hierarchical subjects if hierarchy is NULL
  if (is.null(hierarchy)) {
    #args <- "-HierarchicalSubject="
    args <- "-P -FileModifyDate<DateTimeOriginal -overwrite_original -HierarchicalSubject="

    # Add recursive flag if needed
    if (recursive && is_directory) {
      args <- paste("-r", args)
    }

    response <- ct_exiftool_call(
      args = args,
      path = path,
      intern = intern,
      quiet = quiet,
      ...
    )

    if (!quiet) {
      if (is_directory) {
        cli::cli_alert_success(
          "Removed all hierarchical subjects from images in {.path {basename(path)}}"
        )
      } else {
        cli::cli_alert_success(
          "Removed all hierarchical subjects from {.file {basename(path)}}"
        )
      }
    }
    return(invisible(TRUE))
  }

  # Validate hierarchy parameter
  if (is.null(names(hierarchy)) || any(names(hierarchy) == "")) {
    cli::cli_abort(
      c(
        "All hierarchies must have a parent category (name).",
        "i" = "Use: {.code c('Parent' = 'Child')}"
      )
    )
  }

  # For directories, we cannot validate existing hierarchies
  # Just apply the removal command with ExifTool
  if (is_directory) {
    # Format hierarchy to match stored format (Parent|Child)
    hierarchies_to_remove <- sprintf("%s|%s", names(hierarchy), hierarchy)

    # Build command to remove specific hierarchies
    cmd_args <- paste0(
      sprintf("-HierarchicalSubject-='%s'", hierarchies_to_remove),
      collapse = " "
    )

    # Add recursive flag if needed
    if (recursive) {
      cmd_args <- paste("-r", cmd_args)
    }

    # Execute ExifTool command
    response <- suppressMessages({
      ct_exiftool_call(
        args = noquote(cmd_args),
        path = path,
        intern = intern,
        quiet = quiet,
        ...
      )
    })

    if (!quiet) {
      cli::cli_alert_success(
        "Removed {length(hierarchies_to_remove)} hierarchy/hierarchies from images in {.path {basename(path)}}"
      )
    }
    return(invisible(TRUE))
  }

  # Single file processing with validation

  # Get current hierarchical subjects
  current_hs <- suppressMessages(ct_get_hs(path = path))

  if (is.null(current_hs)) {
    cli::cli_alert_info(
      "No hierarchical subjects found in {.file {basename(path)}}"
    )
    return(invisible(FALSE))
  }

  # Format hierarchy to match stored format (Parent|Child)
  hierarchies_to_remove <- sprintf("%s|%s", names(hierarchy), hierarchy)

  # Check which hierarchies exist
  existing_matches <- hierarchies_to_remove %in% current_hs

  if (!any(existing_matches)) {
    cli::cli_alert_warning(
      c(
        "None of the specified hierarchies exist in {.file {basename(path)}}:",
        "x" = "{.val {hierarchies_to_remove}}"
      )
    )
    return(invisible(FALSE))
  }

  # Inform about non-existent hierarchies
  if (!all(existing_matches)) {
    non_existent <- hierarchies_to_remove[!existing_matches]
    cli::cli_alert_info(
      "Skipping non-existent hierarchies: {.val {non_existent}}"
    )
  }

  # Remove specified hierarchies
  hierarchies_removed <- hierarchies_to_remove[existing_matches]
  updated_hs <- current_hs[!current_hs %in% hierarchies_removed]

  # Clear field entirely if no hierarchies remain
  if (length(updated_hs) == 0) {
    cmd_args <- "-HierarchicalSubject="
    cli::cli_alert_success(
      "Removed last hierarchy from {.file {basename(path)}}"
    )
  } else {
    # Update with remaining hierarchies
    cmd_args <- paste0(
      sprintf("-HierarchicalSubject='%s'", updated_hs),
      collapse = " "
    )
    cli::cli_alert_success(
      "Removed {length(hierarchies_removed)} hierarchy/hierarchies from {.file {basename(path)}}"
    )
  }

  # Execute ExifTool command
  response <- suppressMessages({
    ct_exiftool_call(
      args = noquote(cmd_args),
      path = path,
      intern = intern,
      quiet = quiet,
      ...
    )
  })

  invisible(TRUE)
}
