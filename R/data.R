#' Pendjari national park and surrounding areas
#'
#' A dataset containing spatial boundaries of Pendjari National Park and its surrounding hunting zones in Benin.
#'
#' @format A tibble with 3 rows and 2 columns:
#'   - `NOM`: The name of the protected area or hunting zone.
#'   - `geometry`: The spatial geometry of the area, stored in decimal degrees (EPSG:4326).
#'
#' @examples
#' # Load the dataset
#' data("pendjari")
#'
#' # Plot the data
#' library(sf)
#' plot(pendjari, main = "Pendjari National Park and Surrounding Areas")
#' legend("topright", legend = pendjari$NAME, fill = c("gray10", "gray50", "gray90"))
#'
"pendjari"


#' @title Camera trap data package example
#'
#' @description
#' Data and metadata from an example study exported from the Agouti camera trap
#' data management platform in camtrap-DP format. Metadata includes study name,
#' authors, location and other details. Data is held in element data, itself a
#' list holding dataframes deployments, media and observations.
#' See [https://tdwg.github.io/camtrap-dp](https://camtrap-dp.tdwg.org/) for details.
#'
#' @author Marcus Rowcliffe
#'
#' @format A list holding study data and metadata.
"ctdp"


#' Simulated camera-trap detections for the REST / RAD-REST workflow
#'
#' A small simulated dataset illustrating the inputs needed by [ct_fit_rest()]
#' and the `ct_rest_*` preparation helpers. It contains detections of a focal
#' species (`"Red duiker"`) recorded at 8 stations over roughly one month,
#' together with two background species.
#'
#' @format A tibble with one row per video (detection) and columns:
#'   - `Station`: Camera station ID.
#'   - `Species`: Detected species name.
#'   - `DateTime`: Capture time as a `"YYYY-MM-DD HH:MM:SS"` string.
#'   - `y`: Number of passes through the focal area in that video
#'     (`NA` for background species).
#'   - `Stay`: Staying time within the focal area in seconds
#'     (`NA` when the animal did not enter).
#'   - `Cens`: Right-censoring flag for `Stay` (1 = censored, 0 = observed).
#'
#' @seealso [rest_station], [ct_fit_rest()]
#' @examples
#' data(rest_detection)
#' head(rest_detection)
"rest_detection"


#' Camera-station table for the REST / RAD-REST example
#'
#' Per-station information to accompany [rest_detection], with one row per
#' station and a habitat covariate that can be used in `density_formula` or
#' `stay_formula`.
#'
#' @format A tibble with one row per station and columns:
#'   - `Station`: Camera station ID.
#'   - `Habitat`: Habitat type at the station (`"forest"` or `"savanna"`).
#'
#' @seealso [rest_detection], [ct_fit_rest()]
#' @examples
#' data(rest_station)
#' rest_station
"rest_station"


#' Camera-trap detections from the Penessoulou Classified Forest
#'
#' Camera-trap image records in the Penessoulou
#' Classified Forest, Benin. One row per recorded image in 2024.
#'
#' @format A tibble with 4724 rows and 12 columns, including:
#' \describe{
#'   \item{`project`}{Survey/project name.}
#'   \item{`image_name`}{Source image file name.}
#'   \item{`camera`}{Camera station identifier.}
#'   \item{`make`, `model`}{Camera mak and mode}
#'   \item{`species`}{Recorded species name.}
#'   \item{`number`}{Number of individuals in the record.}
#'   \item{`dates`, `times`}{Date and time parts of the record.}
#'   \item{`datetimes`}{Record date-time as a `"YYYY-MM-DD HH:MM:SS"` string.}
#'   \item{`longitude`, `latitude`}{Station coordinates in decimal degrees.}
#' }
#'
#' @source Ayegnon, D.T.D., Nobim\enc{è}{e}, G., Azihou, F., Houinato, M., &
#'   Djagoun, C.A.M.S. (2026). Seasonal variation in the diversity, abundance,
#'   and spatial distribution of terrestrial mammals in the
#'   P\enc{é}{e}n\enc{é}{e}ssoulou Classified Forest. \emph{Wild}, 3(1), 2.
#'   \doi{10.3390/wild3010002}
#' @examples
#' head(penessoulou)
"penessoulou"


#' Camera trap survey of the Lama Classified Forest
#'
#' Detection-level camera-trap records and camera deployment intervals from a
#' multispecies survey of terrestrial mammals in the Lama Classified Forest, a
#' semi-deciduous forest remnant in the Dahomey Gap, southern Benin. Twenty-three
#' camera traps operated from June to December 2024 (about 4,256 trap-days),
#' recording 18 mammal taxa. The survey was designed for camera-trap distance
#' sampling, so each detection carries a radial `distance` and detection `angle`
#' alongside station coordinates and anthropogenic-gradient covariates.
#'
#' @format A list with two tibbles that share the `camera` column:
#' \describe{
#'   \item{`observation`}{One row per recorded image (7,963 rows, 11 columns):
#'     `camera` (station identifier), `species` (scientific name), `datetime`
#'     (detection date-time, UTC), `distance` (radial distance to the animal, m),
#'     `angle` (detection angle, degrees), `size` (group size), `x`/`y` (station
#'     coordinates, UTM zone 31N, EPSG:32631), `region` (survey stratum),
#'     `d_villages` and `d_track` (distance to the nearest village and track, m).}
#'   \item{`deployment`}{One row per camera (23 rows, 11 columns): `camera`,
#'     `start` and `end` (install and pull-out date-times, UTC), `x`/`y`,
#'     `fov` (field of view, degrees), `radius` (maximum detection distance, m),
#'     `height` (camera height, m), `region`, `d_villages`, `d_track`.}
#' }
#'
#' @source Adounk\enc{é}{e}, G.R.M., Lecompte, E., Gandaho, S.M., Toyi, M.S.,
#'   Azihou, A.F., Hugueny, B., Sinsin, B.A., Gaubert, P., & Djagoun, C.A.M.S.
#'   (submitted). Camera-trap distance sampling reveals density patterns and
#'   anthropogenic drivers of terrestrial mammals in a remnant forest refuge in
#'   West Africa. \emph{Ecology and Evolution}.
#'
#' @examples
#' data(lama)
#' str(lama, max.level = 2)
#' sort(table(lama$observation$species), decreasing = TRUE)
"lama"
