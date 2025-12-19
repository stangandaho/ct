#' Clone directory structure
#'
#' @description
#' Clones the directory structure from a source directory (`from`) to a destination directory (`to`).
#' This function replicates the folder hierarchy and subdirectories, but does not copy files,
#' making it useful for setting up empty directory templates when organizing camera trap data.
#'
#' @param from Character. The path to the source directory whose structure will be cloned.
#'   Must exist and be a directory.
#' @param to Character. The path to the destination directory where the structure will be cloned.
#'   Must exist and be a directory.
#' @param recursive Logical. Should the directory structure be cloned recursively, including all subdirectories?
#'   Default is `TRUE`.
#'
#' @return Invisibly returns \code{NULL}. The function is called for its side-effect of creating directories.
#'
#' @examples
#' \dontrun{
#' # Create a temporary directory structure
#' src <- tempfile("source_dir")
#' dir.create(src)
#' dir.create(file.path(src, "site1"))
#' dir.create(file.path(src, "site1", "cameraA"))
#' dir.create(file.path(src, "site2"))
#'
#' # Create destination directory
#' dst <- tempfile("destination_dir")
#' dir.create(dst)
#'
#' # Clone the directory structure
#' ct_clone_dir(from = src, to = dst)
#'
#' # Check that structure was cloned
#' list.files(dst, recursive = TRUE)
#'
#' # Clean up
#' unlink(c(src, dst), recursive = TRUE)
#'
#' }
#'
#' @export
ct_clone_dir <- function(from, to, recursive = TRUE) {

  from <- normalizePath(from, winslash = "/", mustWork = TRUE)
  to   <- normalizePath(to, winslash = "/", mustWork = FALSE)

  if (!dir.exists(paths = from)) {
    cli::cli_abort(sprintf("{.strong {.file %s}} does not exist", from))
  }
  if (!dir.exists(paths = to)) {
    cli::cli_abort(sprintf("{.strong {.file %s}} does not exist", to))
  }

  if (!file.info(from)$isdir) {
    cli::cli_abort(sprintf("{.strong {.file %s}} is not a directory.", from))
  }

  # From dir
  from_dir <- list.files(path = from, full.names = TRUE, all.files = TRUE,
                         recursive = recursive, include.dirs = TRUE)
  getdir <- function(path) {
    if (!file.info(path)$isdir) {
      return(dirname(path))
    }
    return(path)
  }
  from_dir <- unlist(lapply(from_dir, getdir))

  # Destination dir
  from_dir_child <- gsub(pattern = from, replacement = "", x = from_dir)
  dest_dir <- file.path(to, from_dir_child)

  for (d in dest_dir) {
    if (!dir.exists(d)) {
      dir.create(d, recursive = TRUE)
    }
  }

  invisible(NULL)
}
