##' Install the current version of ExifTool
##'
##' @title Install ExifTool, downloading (by default) the current version
##' @param install_location Path to the directory into which ExifTool should be
##'     installed. If \code{NULL} (the default), installation will be into the
##'     directory returned by \code{ct:::R_user_dir("ct")}.
##' @param win_exe Logical, only used on Windows machines. Should we install the
##'     standalone ExifTool Windows executable or the ExifTool Perl library?
##'     (The latter relies, for its execution, on an existing installation of
##'     Perl being present on the user's machine.)  If set to \code{NULL} (the
##'     default), the function installs the Windows executable on Windows
##'     machines and the Perl library on other operating systems.
##' @param local_exiftool If installing ExifTool from a local "*.zip" or
##'     ".tar.gz", supply the path to that file as a character string. With
##'     default value, `NULL`, the function downloads ExifTool from
##'     \url{https://exiftool.org} and then installs it.
##' @param quiet Logical.  Should function should be chatty?
##' @return Called for its side effect
##' @export
ct_install_exiftool <- function(install_location = NULL,
                             win_exe = NULL,
                             local_exiftool = NULL,
                             quiet = FALSE) {
  tmpdir <- tempdir()
  if (is.null(win_exe)) {
    win_exe <- is_windows()
  }

  ##------------------------------------------------##
  ## If needed, download ExifTool *.zip or *.tar.gz ##
  ##------------------------------------------------##
  if (is.null(local_exiftool)) {
    tmpfile <- file.path(tmpdir, "xx")
    on.exit(unlink(tmpfile))
    download_exiftool(win_exe = win_exe,
                      download_path = tmpfile,
                      quiet = quiet)
  } else {
    tmpfile <- local_exiftool
    win_exe <- (tools::file_ext(tmpfile) == "zip")
  }

  ##---------------------------##
  ## Install *.zip or *.tar.gz ##
  ##---------------------------##
  if (is.null(install_location)) {
    ## Default install location
    install_location <- R_user_dir("ct", which = "data")
    if (!dir.exists(install_location)) {
      dir.create(install_location, recursive = TRUE)
    }
  }

  ## Find writable locations
  write_dir <- install_location
  if (win_exe) {
    write_dir <- file.path(install_location, "win_exe")
  }

  ## Install
  if (win_exe) {
    ## Windows executable
    if(!dir.exists(write_dir)) {
      dir.create(write_dir)
    }
    ## This calls zip::unzip, not utils::unzip
    unzip(tmpfile, exdir = tmpdir)
    exif_dir <- dir(tmpdir, pattern = "exiftool-", full.names = TRUE)
    file.copy(dir(exif_dir, full.names = TRUE), write_dir, recursive = TRUE)
    file.rename(file.path(write_dir, "exiftool(-k).exe"),
                file.path(write_dir, "exiftool.exe"))
  } else {
    ## Perl library
    untar(tmpfile, exdir = tmpdir)
    dd <- dir(tmpdir, pattern = "Image-ExifTool-", full.names = TRUE)
    if(!dir.exists(file.path(write_dir, "lib"))) {
      dir.create(file.path(write_dir, "lib"))
    }
    ## Install the `lib` directory, main Perl script, and `README`
    file.copy(from = file.path(dd, c("lib", "exiftool", "README")),
              to = write_dir,
              recursive = TRUE,
              overwrite = TRUE)
  }

  return(invisible(NULL))
}

#' Download the current version of ExifTool
#'
#' @inheritParams ct_install_exiftool
#' @param download_path Path indicating the location to which
#'     ExifTool should be downloaded.
#' @return A character string giving the path to the downloaded
#'     ExifTool.
#' @author Joshua O'Brien
#' @keywords internal
download_exiftool <- function(win_exe = FALSE,
                              download_path = NULL,
                              quiet = FALSE) {
  base_url <- "https://exiftool.org"

  ver <- readLines("https://exiftool.org/ver.txt", warn=FALSE)
  exiftool_url <-
    if(win_exe & is_windows()) {
      platform <- ifelse(.Machine$sizeof.pointer == 8, "_64", "_32")
      file.path(base_url, paste0("exiftool-", ver, platform, ".zip"))
    } else {
      file.path(base_url, paste0("Image-ExifTool-", ver, ".tar.gz"))
    }
  if (is.null(download_path)) {
    download_path <- file.path(tempdir(), basename(exiftool_url))
  }

  ## Attempt to download the file
  download.file(url = exiftool_url, destfile = download_path, quiet = quiet, mode = "wb")

  return(download_path)
}


#' Call ExifTool
#'
#' Execute ExifTool with specified arguments
#'
#' @param args Character vector of arguments to pass to ExifTool
#' @param path Files or directories to process
#' @param quiet Suppress ExifTool output messages
#' @param intern Capture and return output as character vector
#' @param exiftool_path Path to ExifTool executable (auto-detected if NULL)
#' @return If intern=TRUE, returns output as character vector. Otherwise returns exit status.
#' @export
ct_exiftool_call <- function(path = NULL,
                             args = NULL,
                             quiet = TRUE,
                             intern = TRUE,
                             exiftool_path = NULL) {

  # Find ExifTool
  if (is.null(exiftool_path)) {
    exiftool_path <- find_exiftool()
  }

  if (is.null(exiftool_path)) {
    cli::cli_abort("ExifTool not found. Please install it using {.fn ct_install_exiftool}")
  }

  # Build command arguments
  cmd_args <- character(0)

  if (!is.null(args)) {
    cmd_args <- c(cmd_args, args)
  }

  if (quiet) {
    cmd_args <- c(cmd_args, "-q")
  }

  if (!is.null(path)) {
    # Normalize paths
    path <- normalizePath(path, winslash = "/", mustWork = FALSE)

    # Check if files exist
    missing_files <- path[!file.exists(path)]
    if (length(missing_files) > 0) {
      fls <- ifelse(missing_files > 1, "Files not found: ", "File not found: ")
      cli::cli_abort(paste0(fls, paste(basename(missing_files), collapse = ", ")))
    }

    cmd_args <- c(cmd_args, shQuote(path))
  }

  # Execute ExifTool
  if (intern) {
    result <- system2(
      command = exiftool_path,
      args = cmd_args,
      stdout = TRUE,
      stderr = TRUE,
      wait = TRUE
    )

    # Check for errors
    status <- attr(result, "status")
    if (!is.null(status) && status != 0) {
      # If there's an error, try to provide helpful info
      error_msg <- paste(result, collapse = "\n")
      cli::cli_abort(paste0("ExifTool error (status ", status, "): ", error_msg))
    }

    return(result)
  } else {
    result <- system2(
      command = exiftool_path,
      args = cmd_args,
      wait = TRUE
    )
    return(invisible(result))
  }
}


#' Read Image Metadata
#'
#' Extracts metadata from image files using ExifTool and returns the results
#' as a tibble.
#'
#' By default, all available tags are returned. You can limit the output to a
#' predefined set of tags or provide a custom list of tag names.
#'
#' @param path Character vector of image file paths or a directory path.
#' @param tags Character vector of tag names to extract. Use:
#'   \itemize{
#'     \item \code{NULL} or \code{"all"} to extract all tags
#'     \item \code{"standard"} to extract a predefined, commonly used set of tags
#'     \item a character vector of tag names to extract specific fields
#'   }
#' @param recursive Logical. If \code{TRUE}, searches directories recursively.
#'   Default is \code{FALSE}.
#' @param parse_hs Logical. If \code{TRUE}, parses the \code{HierarchicalSubject}
#'   field into separate columns where each parent category becomes a column name.
#'   Default is \code{FALSE}.
#' @param args Character vector of additional arguments passed directly to
#'   ExifTool (e.g., \code{"-fast"}).
#' @param exiftool_path Character. Path to the ExifTool executable. If
#'   \code{NULL}, the function attempts to auto-detect it.
#'
#' @return A tibble where each row represents one image file and each column
#'   represents a metadata field.
#'
#' @details
#' This function calls ExifTool with CSV output enabled and numeric values
#' returned where applicable. When \code{parse_hs = TRUE}, the
#' \code{HierarchicalSubject} field is split into structured columns.
#'
#' @examples
#' \donttest{
#' # Example image path
#' image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")
#'
#' # Extract all metadata
#' ct_read_metadata(path = image_path)
#'
#' # Extract a predefined standard set of metadata
#' ct_read_metadata(path = image_path, tags = "standard")
#'
#' # Extract custom tags
#' ct_read_metadata(path = image_path,
#'                  tags = c("DateTimeOriginal", "GPSLatitude", "GPSLongitude"))
#'
#' # Parse hierarchical subject fields into columns
#' ct_read_metadata(path = image_path,
#'                  tags = "standard",
#'                  parse_hs = TRUE)
#'}
#' @seealso
#' * [ct_get_hs()] to retrieve hierarchical subjects
#' * [ct_create_hs()] to add hierarchical subjects
#' * [ct_remove_hs()] to remove hierarchical subjects
#'
#' @export
ct_read_metadata <- function(path,
                             tags = NULL,
                             recursive = FALSE,
                             parse_hs = FALSE,
                             args = NULL,
                             exiftool_path = NULL) {
  if (!is.character(path) || length(path) == 0) {
    cli::cli_abort("path must be a non-empty character vector")
  }

  # Build ExifTool arguments
  exif_args <- c("-csv", "-n")  # CSV output, numeric values

  if (all(tags == "all") || is.null(tags)) {
    exif_args <- exif_args
  }else if (all(tags == "standard")) {
    useful_tags <- c("SourceFile", "FileName","Make","Model","DateTimeOriginal",
                     "FileModifyDate", "GPSLongitude","GPSLatitude", "GPSAltitude",
                     "GPSLongitudeRef", "GPSLatitudeRef",  "GPSImgDirection",
                     "Orientation", "HierarchicalSubject")
    tag_args <- paste0("-", useful_tags)
    exif_args <- c(exif_args, tag_args)
  }else if (!is.null(tags)) {
    # Add specific tags
    tag_args <- paste0("-", tags)
    exif_args <- c(exif_args, tag_args)
  }

  if (recursive) {
    exif_args <- c(exif_args, "-r")
  }

  # Add custom arguments
  if (!is.null(args)) {
    exif_args <- c(exif_args, args)
  }

  # Call ExifTool
  csv_output <- ct_exiftool_call(
    args = exif_args,
    path = path,
    quiet = TRUE,
    intern = TRUE,
    exiftool_path = exiftool_path
  )

  # Create a text connection from the output
  con <- textConnection(csv_output)
  on.exit(close(con))

  # Read CSV with read.csv
  metadata <- read.csv(
    con,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA", "-"),
    encoding = "UTF-8"
  )

  metadata <- dplyr::as_tibble(metadata)

  # Parse hierarchical subjects if requested
  if (parse_hs && "HierarchicalSubject" %in% colnames(metadata)) {
    # Process each row efficiently using the data we already have
    parsed_rows <- lapply(seq_len(nrow(metadata)), function(i) {
      row_data <- metadata[i, , drop = FALSE]
      hs_value <- row_data$HierarchicalSubject

      # Skip if no hierarchical subjects
      if (is.na(hs_value) || hs_value == "" || hs_value == "-") {
        return(row_data)
      }

      # Split multiple hierarchical subjects (comma-separated in CSV)
      hs_vector <- trimws(strsplit(as.character(hs_value), ",", fixed = TRUE)[[1]])

      # Parse hierarchical subjects using already-loaded data
      parsed_hs <- parse_hs(hs_vector)

      # If parsing resulted in NULL, return row as-is
      if (is.null(parsed_hs)) {
        return(row_data)
      }

      # Expand row for each parsed HS row (handles multiple values per parent)
      n_hs_rows <- nrow(parsed_hs)
      expanded_metadata <- row_data[rep(1, n_hs_rows), , drop = FALSE]

      # Combine with parsed hierarchical subjects
      result <- dplyr::bind_cols(expanded_metadata, parsed_hs)

      # Relocate parsed HS columns after HierarchicalSubject column
      hs_cols <- colnames(parsed_hs)
      result <- dplyr::relocate(result, dplyr::all_of(hs_cols), .after = HierarchicalSubject)

      result
    })

    # Combine all rows efficiently
    metadata <- dplyr::bind_rows(parsed_rows)
  }

  return(metadata)
}


#' Get Operating System
#' @keywords internal
get_os <- function() {
  if (.Platform$OS.type == "windows") {
    return("windows")
  } else if (Sys.info()["sysname"] == "Darwin") {
    return("macos")
  } else if (Sys.info()["sysname"] == "Linux") {
    return("linux")
  } else {
    return("unknown")
  }
}


#' Find ExifTool Path
#' @keywords internal
find_exiftool_path <- function(install_location, os, win_exe = TRUE) {
  if (os == "windows" && win_exe) {
    return(file.path(install_location, "exiftool.exe"))
  } else {
    return(file.path(install_location, "exiftool"))
  }
}


#' Find ExifTool Executable
#'
#' Locates the ExifTool executable on the system
#'
#' @param install_location Optional custom installation location to check first
#' @return Path to ExifTool executable or NULL if not found
#' @keywords internal
find_exiftool <- function(install_location = NULL) {

  os <- get_os()

  # Check custom install location first
  if (!is.null(install_location)) {
    custom_path <- find_exiftool_path(install_location, os, win_exe = TRUE)
    if (file.exists(custom_path)) {
      return(custom_path)
    }
  }

  # Check default install location
  default_location <- tryCatch({
    R_user_dir("ct", which = "data")
  }, error = function(e) {
    file.path(Sys.getenv("HOME"), ".ct")
  })

  # Check for Windows executable first
  if (os == "windows") {
    win_path <- file.path(default_location, "win_exe", "exiftool.exe")
    if (file.exists(win_path)) {
      return(win_path)
    }
  }

  # Check standard path
  default_path <- find_exiftool_path(default_location, os, win_exe = TRUE)
  if (file.exists(default_path)) {
    return(default_path)
  }

  # Check system PATH
  exiftool_path <- Sys.which("exiftool")
  if (exiftool_path != "") {
    return(as.character(exiftool_path))
  }

  return(NULL)
}


#' Get ExifTool Version
#'
#' Check the installed version of ExifTool
#'
#' @param exiftool_path Path to ExifTool executable (auto-detected if NULL)
#' @return Character string with version number
#' @keywords internal
exiftool_version <- function(exiftool_path = NULL) {
  version <- ct_exiftool_call(args = "-ver", exiftool_path = exiftool_path, intern = TRUE)
  cli::cat_line(trimws(version[1]),
                col = sample(c("#a41500", "#007e36", "#002b91", "#ffa73b"), 1))
}

#' @keywords internal
is_windows <- function() {.Platform$OS.type == "windows"}
