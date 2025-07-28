#' Create or add hierarchical subject values in image metadata
#'
#' @inheritParams ct_get_hs
#' @param value named character vector specifying the new hierarchical subjects to add.
#' Each value must have a parent specified as the name, e.g c("Species" = "Vulture").
#'
#' @inheritParams ct_remove_hs
#' @export
#'
#' @examples
#'
#' # Image path
#' image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")
#'
#' # Get Hierarchical Subject from the image - Before use ct_create_hs()
#' ct_get_hs(path = image_path) #==> NULL
#'
#' ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
#'
#' # Get Hierarchical Subject from the image - Before use ct_create_hs()
#' ct_get_hs(path = image_path) #==> "Species|Vulture"
#'
ct_create_hs <- function(path,
                         value = c(),
                         intern = TRUE,
                         quiet = TRUE, ...) {

  if (is.null(value)) {
    stop("Value must be provided, e.g c('Species' = 'Vulture')")
  }

  havenot_name <- is.null(names(value)) | any(names(value) == "")
  if (length(value) > 1) {
    empty_name <- names(value) == ""
  }else{
    empty_name <- is.null(names(value))
  }

  if (havenot_name) {
    stop(sprintf("Hierarchy must have a parent. Give a name to %s. For example, c(\"Parent\" = \"%s\") for %s",
                 paste(value[empty_name], collapse = ", "), value[empty_name][1L], value[empty_name][1L][1L]))
  }

  if (!is.null(ct_get_hs(path = path))) {
    existing <- noquote(paste0(" -HierarchicalSubject=", ct_get_hs(path = path)))
  }else{existing <- NULL}

  if (length(value)> 1) {
    if (!is.null(existing)) {
      parse_value <- paste0(
          unique(c(
            paste0(sprintf(" -HierarchicalSubject='%s|%s' ", names(value), value), collapse = " "),
            existing
          )), collapse = " ")

      parse_value <- noquote(parse_value)
    }else{
      parse_value <- unique(noquote(paste0(sprintf(" -HierarchicalSubject='%s|%s'", names(value), value), collapse = "")))
    }
  }else{

    if (!is.null(existing)) {
      parse_value <- unique(c(sprintf(" -HierarchicalSubject='%s|%s'", names(value), value), existing))
    }else{
      parse_value <- unique(sprintf(" -HierarchicalSubject='%s|%s'", names(value), value))
    }
  }

  response <- suppressMessages({
    exifr::exiftool_call(args = noquote(parse_value),
                         fnames = path,
                         intern = intern,
                         quiet = quiet,
                         ...)
  })

  return(trimws(noquote(response)))

}


