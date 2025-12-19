#' Retrieve hierarchical subject (hs) values from image metadata
#'
#' @description
#' Extracts hierarchical subject metadata from image files using ExifTool.
#' Hierarchical subjects follow a parent|child structure (e.g., "Species|Vulture")
#' and are commonly used for taxonomic or categorical image classification.
#'
#' @param path A character string specifying the full path to the image file.
#'   Must be a valid file path to an image with EXIF metadata support.
#' @param hs_delimitor The character delimiting hierarchy levels in image metadata
#' tags in field "HierarchicalSubject"
#' @param into_tibble Logical. Parse hierarchical subjects into tibble.
#'
#' @return A character vector or tibble of unique hierarchical subjects if they exist,
#'   otherwise `NULL`. Each element represents one hierarchical subject in
#'   "parent|child" format.
#'
#' @seealso
#' * [ct_create_hs()] to add hierarchical subjects
#' * [ct_remove_hs()] to remove hierarchical subjects
#' * [ct_read_metadata()] to read image metadata
#'
#' @examples
#' # Path to example image
#' image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")
#'
#' # Retrieve hierarchical subjects (returns NULL if none exist)
#' hs <- ct_get_hs(path = image_path)
#' print(hs)
#'
#' # After adding hierarchical subjects
#' ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
#' ct_get_hs(path = image_path)  # Returns: "Species|Vulture"
#'
#' # Multiple hierarchical subjects
#' ct_create_hs(
#'   path = image_path,
#'   value = c("Species" = "Eagle", "Location" = "Mountains")
#' )
#' ct_get_hs(path = image_path)  # Returns vector with both subjects
#'
#' @export
ct_get_hs <- function(path, hs_delimitor = "|", into_tibble = FALSE) {
  # Validate input
  if (missing(path) || is.null(path) || length(path) == 0) {
    cli::cli_abort("{.arg path} must be provided.")
  }

  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.path {path}}")
  }

  # Check if HierarchicalSubject field exists in metadata
  metadata <- ct_read_metadata(path)

  if (!"HierarchicalSubject" %in% colnames(metadata)) {
    return(NULL)
  }

  # Read hierarchical subject values using ExifTool
  hs_output <- suppressMessages({
    ct_exiftool_call(
      args = "-HierarchicalSubject",
      path = path,
      intern = TRUE,
      quiet = TRUE
    )
  })

  # Parse ExifTool output
  if (length(hs_output) == 0) {
    return(NULL)
  }

  # Extract and clean hierarchical subjects
  subjects <- lapply(hs_output, function(line) {
    # Remove "Hierarchical Subject : " prefix and split by comma
    cleaned <- sub("^.*:\\s*", "", line)
    values <- strsplit(cleaned, ",", fixed = TRUE)[[1]]
    trimws(values)
  })

  # Flatten list and remove duplicates
  all_subjects <- unique(unlist(subjects))

  # Return NULL if no subjects found after processing
  if (length(all_subjects) == 0) {
    return(NULL)
  }

  if (into_tibble) {
    # Parse hierarchical subjects using already-loaded data
    parse_hs(gsub("'", "", all_subjects), hs_delimitor = hs_delimitor)
  }else{
    gsub("'", "", all_subjects)
  }
}


#' Parse Hierarchical Subjects into a Tibble
#' @keywords internal
parse_hs <- function(hs_vector, hs_delimitor = "|") {
  # Handle NULL or empty input
  if (is.null(hs_vector) || length(hs_vector) == 0) {
    return(NULL)
  }

  # Split each hierarchical subject on hs_delimitor
  split_hs <- strsplit(hs_vector, hs_delimitor, fixed = TRUE)

  # Check for invalid format (missing hs_delimitor)
  invalid_format <- lengths(split_hs) != 2

  if (any(invalid_format)) {
    cli::cli_warn(
      c(
        "Some hierarchical subjects don't contain '{hs_delimitor}' separator:",
        "x" = "{.val {hs_vector[invalid_format]}}",
        "i" = "These will be skipped."
      )
    )
    split_hs <- split_hs[!invalid_format]
    hs_vector <- hs_vector[!invalid_format]
  }

  # Handle case where all entries were invalid
  if (length(split_hs) == 0) {
    return(NULL)
  }

  # Extract parents and children
  parents <- sapply(split_hs, `[`, 1)
  children <- sapply(split_hs, `[`, 2)

  # Create long format tibble
  long_df <- dplyr::tibble(
    parent = parents,
    child = children
  )

  # Get unique parents to determine number of rows needed
  unique_parents <- unique(parents)

  # Count max occurrences of any parent
  max_count <- max(table(parents))

  # Create wide format - each parent becomes a column
  wide_list <- lapply(unique_parents, function(p) {
    values <- children[parents == p]
    # Pad with NA if needed
    if (length(values) < max_count) {
      values <- c(values, rep(NA_character_, max_count - length(values)))
    }
    values
  })

  # Create tibble with parent names as column names
  names(wide_list) <- unique_parents
  result <- dplyr::as_tibble(wide_list)

  fill_na_ <- function(x) {
    for (i in 1:length(x)) {
      if(is.na(x[i])){
        x[i] <- x[i-1]
      }
    }
    return(x)
  }

  result <- result %>%
    dplyr::mutate(across(.cols = everything(), .fns = fill_na_))

  return(result)
}
