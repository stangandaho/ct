#' Camera trap dataset from Agbogon Community Biological Reserve (ACBR), Benin
#'
#' A curated camera trap dataset from the Agonve Community Wetland Reserve
#' in West Africa, adapted from Gandaho et al. (2026). The dataset contains
#' wildlife camera trap observations and associated deployment metadata.
#'
#' The object is provided as a named list with two elements:
#'
#' \describe{
#'   \item{`acbr_data`}{
#'   A tibble containing camera trap observations.
#'
#'   Variables include:
#'   \describe{
#'     \item{`image`}{Image file name.}
#'     \item{`deployment`}{Deployment identifier.}
#'     \item{`cam`}{Camera station identifier.}
#'     \item{`model`}{Camera model (`RD1003L` or `TC302445`).}
#'     \item{`dates`}{Observation date.}
#'     \item{`times`}{Observation time.}
#'     \item{`species`}{Recorded species name.}
#'     \item{`count`}{Number of individuals detected.}
#'     \item{`datetime`}{Combined date-time in POSIX format.}
#'   }}
#'
#'   \item{`deployment`}{
#'   A tibble containing deployment-level metadata.
#'
#'   Variables include:
#'   \describe{
#'     \item{`deployment`}{Deployment identifier.}
#'     \item{`cam`}{Camera station identifier.}
#'     \item{`model`}{Camera model.}
#'     \item{`start`}{Deployment start date-time.}
#'     \item{`end`}{Deployment end date-time.}
#'     \item{`radius`}{Camera detection radius (meters).}
#'     \item{`angle`}{Camera detection angle (degrees).}
#'     \item{`area`}{Estimated detection area (square meters).}
#'   }}
#' }
#'
#' The deployment table was reconstructed from the observation data using the
#' first and last timestamps recorded for each deployment.
#'
#' @format A named list with two tibbles:
#' \describe{
#'   \item{`acbr_data`}{Camera trap observations.}
#'   \item{`deployment`}{Deployment metadata.}
#' }
#'
#' @references
#' Gandaho, S. M., Agossou, H., Madokoun, D. L., Hounnouvi, E. F. K.,
#' Oussoukpevi, S. J. K., Akpona, H. A., Thompson, L., & Djagoun,
#' C. A. M. S. (2026). Habitat loss and species diel ecology in a West African community
#' wetland reserve. Zenodo. \doi{10.5281/zenodo.19662320}
#'
#' @examples
#' data(ACBR)
#'
#' # Access observation data
#' head(ACBR$acbr_data)
#'
#' # Access deployment metadata
#' head(ACBR$deployment)
#'
#' @keywords datasets
#' @name ACBR
NULL
