#' Check species name and retrieve Taxonomic Serial Number (TSN) from ITIS
#'
#' This function queries the **Integrated Taxonomic Information System (ITIS)**
#' to find taxonomic details for a given species name.  It can search using
#' either a **scientific name** or a **common name** and return relevant
#' taxonomic information, including the TSN.
#'
#' @param species_name A character string specifying the species name to search
#' for. Only a **single name** is allowed.
#' @param search_type A character string specifying the type of search. Options:
#'   - `"scientific_name"`: Search by scientific name.
#'   - `"common_name"`: Search by common name.
#' @param ask A logical value (`TRUE` or `FALSE`). If `TRUE`, allows interactive selection when multiple matches are found.
#'
#' @return A tibble containing taxonomic details:
#'   - `search`: The original species name queried.
#'   - `tsn`: The **Taxonomic Serial Number** (TSN) from ITIS.
#'   - `common_name`: The common name of the species (if available).
#'   - `scientific_name`: The scientific name of the species.
#'   - `author`: The author who classified the species.
#'   - `itis_url`: A direct link to the species report on ITIS.
#'   - `taxon_status`: The taxonomic status of the species.
#'
#' @details
#' - If the necessary packages (`httr2`, `xml2`) are not installed, the function prompts the user to install them.
#' - If multiple results are found and `ask = TRUE`, the user is prompted to select the correct match.
#' - If no exact match is found, all results are displayed for manual selection.
#'
#' @examples
#' \donttest{
#' # Search for a species by scientific name
#' ct_check_name("Panthera leo", search_type = "scientific_name")
#'
#' # Search by common name with interactive selection
#' ct_check_name("Lion", search_type = "common_name")
#' }
#'
#'
#' @seealso \url{https://www.itis.gov}
#'
#' @export
#'
ct_check_name <- function(species_name,
                          search_type = c("common_name", "scientific_name"),
                          ask = FALSE) {
  # Check early some package needed
  if (!checked_packages(c("httr2", "xml2"))) {return(invisible(NULL))}

  ## Start data retrieve
  search_type <- match_arg(search_type, c("common_name", "scientific_name"))
  if (length(species_name) >= 2) {
    cli::cli_abort("No search possible for {length(species_name)} species")
  }
  base_url_sci <- "https://www.itis.gov/ITISWebService/services/ITISService/getITISTermsFromScientificName?srchKey="
  search_url_sci <- paste0(base_url_sci, gsub("\\s+", "%20",  species_name))

  base_url_common <- "https://www.itis.gov/ITISWebService/services/ITISService/getITISTermsFromCommonName?srchKey="
  search_url_common <- paste0(base_url_common, gsub("\\s+", "%20",  species_name))

  URL <- switch (search_type,
                 "scientific_name" = search_url_sci,
                 "common_name" = search_url_common
  )

  # Fetch the XML response using httr2
  response <- httr2::request(URL) %>%
    httr2::req_perform() %>%
    httr2::resp_body_xml()

  nodes <- xml2::xml_find_all(response, ".//ax21:itisTerms")
  # Build rows with lapply
  rows <- lapply(nodes, function(n) {
    tsn_val  <- xml2::xml_text(xml2::xml_find_first(n, ".//ax21:tsn"))
    common   <- xml2::xml_text(xml2::xml_find_first(n, ".//ax21:commonNames"))
    sci_name <- xml2::xml_text(xml2::xml_find_first(n, ".//ax21:scientificName"))
    author   <- gsub("\\(|\\)", "", xml2::xml_text(xml2::xml_find_first(n, ".//ax21:author")))
    usage    <- xml2::xml_text(xml2::xml_find_first(n, ".//ax21:nameUsage"))

    dplyr::tibble(
      search = species_name,
      tsn = tsn_val,
      common_name = ifelse(common == "", NA, common),
      scientific_name = ifelse(sci_name == "", NA, sci_name),
      author = ifelse(author == "", NA, author),
      itis_url = paste0(
        "https://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value=", tsn_val
      ),
      taxon_status = ifelse(usage == "", NA, usage)
    )
  })

  # Combine all rows
  out_tbl <- dplyr::bind_rows(rows)

  # Filter to choose correct observation
  pre_filter <- switch (search_type,
                        "scientific_name" = out_tbl %>% dplyr::filter(grepl(species_name, scientific_name)),
                        "common_name" =  out_tbl %>% dplyr::filter(grepl(species_name, common_name))
  )

  if (ask && nrow(pre_filter) > 1) {
    msg <- sprintf("\n%d TSNs found for '%s'!\nSelect the row number of taxon you want (0 to exit):",
                   nrow(out_tbl), species_name)
    custom_cli(msg, color = "red")

    # Add option to cancel
    choices <- paste0(out_tbl$scientific_name, " (", out_tbl$common_name, ")")
    action <- utils::menu(choices = choices)

    # If user cancels (action == 0)
    if (action == 0) {
      cli::cli_alert_warning("No selection made. Returning all rows.")
    }else{
      out_tbl <- out_tbl %>% dplyr::slice(action)
    }

  }else if(nrow(pre_filter) == 1){
    out_tbl <- pre_filter
  }

  return(out_tbl)

}
