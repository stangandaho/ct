#' Estimate species spatial coverage from camera trap detections
#'
#' @description
#' Estimates spatial coverage
#' a species from camera-trap detection data using a kernel density approach.
#' The kernel bandwidth \eqn{\hat{\sigma}} is estimated from the
#' spatial spread of detection sites via **Silverman's reference bandwidth rule**
#' (Silverman 1986).
#'
#' @param data A data frame of species detection records.
#' @param site_column Column name of the camera-trap site identifier.
#' @param longitude Column name of site longitude (or UTM easting).
#' @param latitude Column name of site latitude (or UTM northing).
#' @param crs A vector of length two specifying the coordinate reference systems: `c(crs_in, crs_out)`.
#'  - `crs_in` represents the current CRS of the data (e.g., 4326 for latitude/longitude).
#'  - `crs_out` represents the CRS to transform into (e.g., "EPSG:32631", a UTM EPSG code) for accurate distance calculations.
#'  If `crs_out` is NULL, no transformation is applied. Defaults to `c(4326, NULL)`
#' @param study_area Optional `sf` polygon defining the full study extent.
#'   If provided, the raster grid is extended to cover the polygon.
#' @param mask Optional `sf` polygon (or multipolygon) of areas to **exclude**
#'   from the coverage estimate (e.g. water bodies, settlements, cliffs).
#'   Raster cells inside the mask are set to `NA` in the output. Note that
#'   Euclidean distances are used throughout; the mask filters the final surface
#'   but does not reroute distance calculations around barriers.
#' @param resolution Numeric. Side length of one grid cell in the units of the
#'   active CRS (metres if projected).
#' @param isopleth Numeric in `(0, 1]`. Isopleth level for home-range
#'   delineation. `0.95` (default) returns the smallest area containing 95 % of
#'   the total kernel density - the standard 95 % kernel home range.
#' @param n_boot Integer. Bootstrap resamples for the standard error of
#'   \eqn{\hat{\sigma}}. Set to `0` to skip (default `200`).
#'
#' @details
#' The term home range is typically associated with dynamic movement data, such as
#' those recorded by radio-tracking or GPS devices, which provide continuous or
#' near-continuous tracking of an individual animal's movements. Since camera traps
#' are static and only capture presence/absence or activity within their specific
#' locations, the concept of home range might not fully apply.
#'
#' ## Method
#'
#' Each camera station where the species was detected contributes equally (binary
#' detection). A Gaussian kernel is centred at each
#' detection site and the average surface is computed:
#'
#' \deqn{
#'   \hat{f}(\mathbf{x}) =
#'     \frac{1}{n} \sum_{i=1}^{n}
#'     \exp\!\left(-\frac{\|\mathbf{x} - \mathbf{x}_i\|^2}{2\,\hat{\sigma}^2}\right)
#' }
#'
#' ## Bandwidth estimation
#'
#' The bandwidth \eqn{\hat{\sigma}} is the **reference bandwidth** (Silverman
#' 1986, eq. 4.14, extended to 2-D):
#'
#' \deqn{\hat{\sigma} = \sqrt{\hat{\sigma}_x \, \hat{\sigma}_y} \; n^{-1/6}}
#'
#' where \eqn{\hat{\sigma}_x} and \eqn{\hat{\sigma}_y} are the standard
#' deviations of the detection-site coordinates and \eqn{n} is the number of
#' detection sites. This is the asymptotically MISE-optimal bandwidth under a
#' bivariate normal reference distribution. It shrinks with more sites and widens
#' when detections are spatially dispersed.
#'
#' The standard error of \eqn{\hat{\sigma}} is obtained by **nonparametric
#' bootstrap**: sites are resampled with replacement `n_boot` times and
#' \eqn{\hat{\sigma}} recomputed each time; the SE is the standard deviation
#' of those bootstrap estimates, and the 95 % CI is their 2.5th - 97.5th
#' percentiles.
#'
#' ## Home-range isopleth
#'
#' Cells are ranked by kernel density (descending). The `isopleth` isopleth
#' retains the smallest set of cells whose cumulative density equals
#' `isopleth` of the total - the standard minimum-volume contour estimator
#' (Worton 1989).
#'
#' @references
#' Silverman, B. W. (1986). *Density Estimation for Statistics and Data
#'   Analysis*. Chapman and Hall, London.
#'
#' Worton, B. J. (1989). Kernel methods for estimating the utilization
#'   distribution in home-range studies. *Ecology*, **70**(1), 164-168.
#'   \doi{10.2307/1938423}
#'
#' @return A named list with three elements:
#' \describe{
#'   \item{`Coverage raster`}{A `SpatRaster` (`terra`) containing the kernel
#'     density surface, clipped to the `isopleth` isopleth, with masked and
#'     out-of-isopleth cells set to `NA`.}
#'   \item{`Bandwidth`}{A named numeric vector: `sigma` (estimated bandwidth in
#'     CRS units), `SE` (bootstrap SE; `NA` if `n_boot = 0`), `CI_low` and
#'     `CI_high` (95 % bootstrap CI), `n_sites`, and `isopleth`.}
#'   \item{`Coverage stats`}{A one-row tibble: coverage area in km^2,
#'     \eqn{\hat{\sigma}} +/- SE, detection-site count, and isopleth level.}
#' }
#'
#' @examples
#' library(dplyr)
#' cam_data <- system.file("penessoulou_season2.csv", package = "ct") |>
#'   read.csv() %>%
#'   dplyr::filter(Species == "Erythrocebus patas", Count > 0)
#'
#' spc <- ct_spatial_coverage(
#'   data = cam_data,
#'   site_column = Camera,
#'   longitude = Longitude,
#'   latitude = Latitude,
#'   crs = "EPSG:32631",
#'   resolution = 30 # meter
#' )
#'
#' # Plot coverage raster
#' library(terra)
#' terra::plot(spc$`Coverage raster`)
#'
#' ## Bandwidth estimate with uncertainty
#' spc$Bandwidth
#'
#' ## Coverage area summary
#' spc$`Coverage stats`
#'
#' @export
ct_spatial_coverage <- function(data,
                                site_column,
                                longitude,
                                latitude,
                                crs = c(4326, NULL),
                                study_area = NULL,
                                mask = NULL,
                                resolution,
                                isopleth = 0.95,
                                n_boot = 200) {

  # Tidy-eval column names
  site_column <- tryCatch(rlang::enquo(site_column), error = function(e) NULL)
  longitude <- tryCatch(rlang::enquo(longitude), error = function(e) NULL)
  latitude <- tryCatch(rlang::enquo(latitude), error = function(e) NULL)

  if (is.null(site_column) || rlang::quo_is_null(site_column))
    rlang::abort("`site_column` must be provided.")
  if (is.null(longitude) || rlang::quo_is_null(longitude))
    rlang::abort("`longitude` column is required.")
  if (is.null(latitude) || rlang::quo_is_null(latitude))
    rlang::abort("`latitude` column is required.")

  # Scalar argument validation
  if (!is.numeric(isopleth) || length(isopleth) != 1L ||
      isopleth <= 0 || isopleth > 1)
    rlang::abort("`isopleth` must be a single number in (0, 1].")

  n_boot <- as.integer(n_boot)
  if (is.na(n_boot) || n_boot < 0L)
    rlang::abort("`n_boot` must be a non-negative integer.")

  # Prepare data: one row per unique detection site
  data <- data %>%
    dplyr::filter(!is.na(!!longitude), !is.na(!!latitude)) %>%
    dplyr::distinct(!!site_column, !!longitude, !!latitude)

  n_sites <- nrow(data)
  if (n_sites < 3L)
    rlang::abort(c(
      "At least 3 unique detection sites are required for bandwidth estimation.",
      i = paste0("Only ", n_sites, " site(s) with valid coordinates found.")
    ))

  # Build sf object and optionally reproject
  .parse_crs <- function(x) {
    if (grepl("^[0-9]+$", as.character(x))) as.integer(x) else x
  }

  active_crs <- .parse_crs(crs[1L])
  sf_data <- sf::st_as_sf(
    data,
    coords = c(rlang::as_name(longitude), rlang::as_name(latitude)),
    crs = active_crs
  )

  if (length(crs) > 1L && !is.null(crs[2L])) {
    crs_out <- .parse_crs(crs[2L])
    sf_data <- sf::st_transform(sf_data, crs = crs_out)
    active_crs <- crs_out
  }

  if (sf::st_is_longlat(sf_data))
    rlang::warn(c(
      "The active CRS is geographic (units: degrees).",
      i = "Provide a projected metric CRS via `crs` for accurate distance and area calculations."
    ))

  # Bandwidth estimation: Silverman's reference bandwidth (href)
  #
  #   sigma_hat = sqrt(sd_x * sd_y) * n^(-1/6)
  #
  # This is the asymptotically MISE-optimal isotropic Gaussian kernel bandwidth
  # under a bivariate normal reference distribution (Silverman 1986, eq. 4.14).
  coords  <- sf::st_coordinates(sf_data) # n x 2 matrix [X, Y]
  sigma_x <- sd(coords[, 1L])
  sigma_y <- sd(coords[, 2L])

  if (!is.finite(sigma_x) || !is.finite(sigma_y) ||
      sigma_x == 0 || sigma_y == 0)
    rlang::abort(c(
      "Bandwidth estimation failed.",
      i = "Detection sites may be collinear or share identical coordinates in one dimension."
    ))

  sigma_hat <- sqrt(sigma_x * sigma_y) * n_sites^(-1 / 6)

  # Bootstrap SE and 95 % CI for sigma_hat
  sigma_se  <- NA_real_
  sigma_ci  <- c(NA_real_, NA_real_)

  if (n_boot > 0L) {
    boot_sigma <- vapply(seq_len(n_boot), function(i) {
      idx <- sample.int(n_sites, replace = TRUE)
      cx <- coords[idx, 1L]
      cy <- coords[idx, 2L]
      sqrt(sd(cx) * sd(cy)) * n_sites^(-1 / 6)
    }, numeric(1L))

    boot_sigma <- boot_sigma[is.finite(boot_sigma)]
    sigma_se <- sd(boot_sigma)
    sigma_ci <- stats::quantile(boot_sigma, probs = c(0.025, 0.975),
                                  names = FALSE)
  }

  # Reference raster
  ref_rast <- terra::rast(terra::vect(sf_data), res = resolution)

  if (!is.null(study_area)) {
    valid_study_area(study_area)
    study_area <- sf::st_transform(study_area, crs = active_crs)
    ref_rast <- terra::extend(ref_rast, terra::ext(sf::st_bbox(study_area)))
  }

  # Kernel layers: one per detection site
  #
  #   K_i(x) = exp( -0.5 * ||x - x_i||^2 / sigma_hat^2 )
  #
  # All sites contribute equally (binary detection; no abundance weighting).
  kernel_layers <- vector("list", n_sites)

  for (i in seq_len(n_sites)) {
    dist_rast <- terra::rasterize(sf_data[i, ], ref_rast, field = 1) %>%
                            terra::distance()
    kernel_layers[[i]] <- exp(-0.5 * (dist_rast / sigma_hat)^2)
  }

  avg_kernel <- terra::mean(terra::rast(kernel_layers), na.rm = TRUE)
  names(avg_kernel) <- "kernel_density"

  # Isopleth: keep smallest area containing isopleth of cumulative density
  #
  # Cells are ranked by density (descending). The first set of cells whose
  # cumulative proportion >= isopleth defines the home-range contour
  # (Worton 1989 minimum-volume contour estimator).
  all_vals <- terra::values(avg_kernel, mat = FALSE)
  all_vals <- all_vals[is.finite(all_vals)]
  sorted <- sort(all_vals, decreasing = TRUE)
  cum_frac <- cumsum(sorted) / sum(sorted)
  threshold <- sorted[which(cum_frac >= isopleth)[1L]]

  avg_kernel[avg_kernel < threshold] <- NA

  # Apply exclusion mask
  if (!is.null(mask)) {
    if (!any(c("sf", "sfc_POLYGON", "sfc") %in% class(mask)) ||
        !any(c("MULTIPOLYGON", "POLYGON") %in%
             as.character(sf::st_geometry_type(mask))))
      rlang::abort(c(
        "`mask` must be an sf polygon or multipolygon.",
        i = "Supply the exclusion areas (e.g. water bodies, settlements) as an sf object."
      ))
    mask_proj <- sf::st_transform(mask, crs = active_crs)
    mask_rast <- terra::rasterize(terra::vect(mask_proj), ref_rast, field = 1)
    avg_kernel <- terra::mask(avg_kernel, mask_rast, inverse = TRUE)
  }

  coverage_rast <- avg_kernel

  # Coverage area in km^2
  coverage_area_km2 <- tryCatch({
    cov_union <- terra::as.polygons(coverage_rast, dissolve = TRUE) %>%
      sf::st_as_sf() %>%
      sf::st_union()
    as.numeric(sf::st_area(cov_union)) / 1e6
  }, error = function(e) NA_real_)

  # Return objects
  bandwidth_summary <- c(
    sigma = round(sigma_hat, 3),
    SE = round(sigma_se, 3),
    CI_low = round(sigma_ci[1L], 3),
    CI_high = round(sigma_ci[2L], 3),
    n_sites = n_sites,
    isopleth = isopleth
  )

  coverage_stats <- dplyr::tibble(
    `Spatial coverage` = round(coverage_area_km2, 4),
    `Sigma` = round(sigma_hat, 3),
    `Bandwidth SE` = round(sigma_se,  3),
    `Detection sites (n)` = n_sites,
    `Isopleth level` = isopleth
  )

  list(
    "Coverage raster" = coverage_rast,
    "Bandwidth" = bandwidth_summary,
    "Coverage stats" = coverage_stats
  )
}
