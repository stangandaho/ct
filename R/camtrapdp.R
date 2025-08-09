#' Read camera trap data package
#'
#' Reads [Camera Trap Data Package](https://camtrap-dp.tdwg.org) (Camtrap DP)
#' dataset into memory.
#'
#' @inheritParams camtrapdp::read_camtrapdp
#' @inherit camtrapdp::read_camtrapdp return
#' @inheritSection camtrapdp::read_camtrapdp Assign taxonomic information
#' @inheritSection camtrapdp::read_camtrapdp Assign eventIDs
#'
#' @examples
#' \donttest{
#' file <- "https://raw.githubusercontent.com/tdwg/camtrap-dp/1.0/example/datapackage.json"
#' dp <- ct_dp_read(file)
#'}
#' @export
ct_dp_read <- function(file) {
  camtrapdp::read_camtrapdp(file = file)
}

#' Get core tables
#'
#' @description
#' Acess table like observations, deployement, and media from data package.
#'
#' @param package Camera trap data package object, as returned by
#' ct_read_dp().
#' @param table Character indicating the table to read - one "observations",
#' "deployments", or "media"
#'
#' @examples
#' \donttest{
#' dp <- ct_dp_example()
#' ct_dp_table(dp, "deployments")
#'}
#'
#' @return A tibble of table specified
#'
ct_dp_table <- function(package,
                        table = c("observations", "deployments",
                                  "media", "events", "taxa")
                        ) {

  table <- match_arg(table, c("observations", "deployments",
                              "media", "events", "taxa"))

  switch(table,
         observations = camtrapdp::observations(package),
         deployments = camtrapdp::deployments(package),
         media = camtrapdp::media(package),
         events = camtrapdp::events(package),
         taxa = camtrapdp::taxa(package)
  )

}

#' Read the Camtrap DP example dataset
#'
#' Reads the [Camtrap DP example dataset](https://camtrap-dp.tdwg.org/example/).
#' This dataset is maintained and versioned with the Camtrap DP standard.
#'
#' @return Camera Trap Data Package object.
#' @family sample data
#'
#' @export
ct_dp_example <- function() {
  camtrapdp::example_dataset()
}

#' Get Camtrap DP version
#' Extracts the version number used by a Camera Trap Data Package object.
#' This version number indicates what version of the [Camtrap DP standard](
#' https://camtrap-dp.tdwg.org) was used.
#'
#' @inheritParams ct_dp_table
#' @inherit camtrapdp::version details
#' @inherit camtrapdp::read_camtrapdp return
#' @examples
#' dp <- ct_dp_example()
#' ct_dp_version(dp)
#'
#' @export
ct_dp_version <- function(package) {
  camtrapdp::version(package)
}

#' Filter camera trap data package
#'
#' @description
#' Subsets observations in camera trap data package, retaining all rows that
#' satisfy the conditions.
#' @inheritParams ct_dp_read
#' @inheritParams ct_dp_table
#' @param ... Filtering conditions, see dplyr::filter()
#'
#' @examples
#' \donttest{
#' dp <- ct_dp_example()
#' ct_dp_filter(package = dp, table = "observation",
#' scientificName == "Vulpes vulpes", observationLevel == "event"
#' )
#'
#' ct_dp_filter(package = dp, table = "deployments",
#'              latitude > 51.0, longitude > 5.0)
#'
#'
#' ct_dp_filter(package = dp, table = "media",
#'              captureMethod == "activityDetection", filePublic == FALSE
#' )
#'}
#' @export
ct_dp_filter <- function(package,
                         table = c("observations", "deployments", "media"),
                         ...
                         ) {
  table <- match_arg(table, c("observations", "deployments", "media"))

  switch(table,
         observations = camtrapdp::filter_observations(package, ...),
         deployments = camtrapdp::filter_deployments(package, ...),
         media = camtrapdp::filter_media(package, ...)
  )

}


