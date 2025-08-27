#' Convert values between different units
#'
#' @description
#' Convert a numeric value from one unit to another.
#' It supports **area**, **distance (length)**, and **angle** units.
#'
#' @param x Numeric. Value(s) to convert.
#' @param from Character. The unit to convert from. Can be any synonym
#' e.g. `"meter"`, `"m"`, `"metre"`, `"feet"`, "\eqn{^\circ}", "um" (i.e \eqn{\mu m}), etc.
#' @param to Character. The unit to convert to. Can also be any synonym.
#' @param show_units Logical. If `TRUE`, returns the full table of supported units
#'   and their synonyms instead of performing a conversion.
#'
#' @return
#' A numeric vector of converted values.
#'
#' @examples
#' # Distance
#' ct_convert_unit(1000, "m", "km")
#' ct_convert_unit(1, "mile", "m")
#' ct_convert_unit(12, "inches", "ft")
#'
#' # Area
#' ct_convert_unit(1, "acre", "m2")
#' ct_convert_unit(2, "km2", "hectare")
#'
#' # Angle
#' ct_convert_unit(180, "deg", "rad")
#' ct_convert_unit(pi, "rad", "deg")
#'
#' @seealso [units_table()] for supported units and synonyms.
#'
#' @export
ct_convert_unit <- function(x, from, to, show_units = FALSE) {

  if (show_units) {
    return(units_table())
  }

  # Define conversion factors
  area_factors <- c(
    "m2"   = 1,
    "km2"  = 1e6,
    "cm2"  = 1e-4,
    "mm2"  = 1e-6,
    "um2"  = 1e-12,
    "nm2"  = 1e-18,
    "ha"   = 1e4,
    "are"  = 100,
    "daa"  = 1000,
    "ca"   = 1,
    "acre" = 4046.8564224,
    "mi2"  = 2.589988e6,
    "yd2"  = 0.83612736,
    "ft2"  = 0.09290304,
    "in2"  = 0.00064516
  )

  distance_factors <- c(
    "m"   = 1,
    "km"  = 1e3,
    "cm"  = 1e-2,
    "mm"  = 1e-3,
    "um"  = 1e-6,
    "nm"  = 1e-9,

    "mi"  = 1609.344,
    "yd"  = 0.9144,
    "ft"  = 0.3048,
    "in"  = 0.0254,

    "nmi" = 1852,
    "ly"  = 9.4607e15,
    "au"  = 1.495978707e11,
    "pc"  = 3.085677581e16
  )

  angle_factors <- c(
    "rad"   = 1,
    "deg"   = pi / 180,
    "grad"  = pi / 200,
    "turn"  = 2 * pi,
    "arcmin"= pi / (180 * 60),
    "arcsec"= pi / (180 * 3600)
  )

  unit_factors <- c(area_factors, distance_factors, angle_factors)


  # Conversion function process
  from_unit <- tolower(units_table() %>%
                    dplyr::filter(.data$unit == from) %>% dplyr::pull("unit_name"))
  to_unit <- tolower(units_table() %>%
                    dplyr::filter(.data$unit == to) %>% dplyr::pull("unit_name"))
  # Rise error for unknown unit
  if(length(from_unit) == 0){cli::cli_abort(sprintf("Unknown 'from' unit: %s", from))}
  if(length(to_unit) == 0){cli::cli_abort(sprintf("Unknown 'to' unit: %s", to))}

  from_cat <- tolower(units_table() %>%
                         dplyr::filter(.data$unit == from) %>% dplyr::pull("category"))
  to_cat <- tolower(units_table() %>%
                         dplyr::filter(.data$unit == to) %>% dplyr::pull("category"))
  # Rise error for incompatible unit
  cli::cli_div(theme = list(span.emph = list(color = "#910800")))
  if (unique(from_cat) != unique(to_cat)) {
    cli::cli_abort(sprintf("'from' unit is {.strong {.field %s}}, while 'to' unit is {.strong {.emph %s}}",
                           unique(from_cat), unique(to_cat)))
  }

  # Convert: x * (from_unit) / (to_unit)
  result <- x * unit_factors[from_unit] / unit_factors[to_unit]

  return(as.numeric(result))
}

#' Units table
#' @noRd
units_table <- function() {
  area_units <- list(
    "m2"   = c("square meter", "square metre", "square meters", "square metres", "m2", "m^2"),
    "km2"  = c("square kilometer", "square kilometre", "square kilometers", "square kilometres", "km2", "km^2"),
    "cm2"  = c("square centimeter", "square centimetre", "square centimeters", "square centimetres", "cm2", "cm^2"),
    "mm2"  = c("square millimeter", "square millimetre", "square millimeters", "square millimetres", "mm2", "mm^2"),
    "um2"  = c("square micrometer", "square micrometre", "square micrometers", "square micrometres", "um2", "um^2"),
    "nm2"  = c("square nanometer", "square nanometre", "square nanometers", "square nanometres", "nm2", "nm^2"),
    "mi2"  = c("square mile", "square miles", "mi2", "mi^2", "sq mile", "sq mi"),
    "yd2"  = c("square yard", "square yards", "yd2", "yd^2", "sq yard", "sq yd"),
    "ft2"  = c("square foot", "square feet", "ft2", "ft^2", "sq foot", "sq ft"),
    "in2"  = c("square inch", "square inchs", "in2", "in^2", "sq inch", "sq in"),
    "ha"   = c("hectare", "hectares", "ha"),
    "acre" = c("acre", "acres", "ac"),
    "are"  = c("are", "ares", "a"),
    "daa"  = c("decare", "decares", "daa"),
    "ca"   = c("centiare", "centiares", "ca")
  )

  area_unit_names <- names(area_units)
  out1 <- lapply(area_unit_names, function(x){
    dplyr::tibble(unit = area_units[[x]],
                  unit_name = x,
                  category = "area")
  }) %>%
    dplyr::bind_rows()

  # Distance
  distance_units <- list(
    "m"   = c("meter", "metre", "meters", "metres", "m"),
    "km"  = c("kilometer", "kilometre", "kilometers", "kilometres", "km"),
    "cm"  = c("centimeter", "centimetre", "centimeters", "centimetres", "cm"),
    "mm"  = c("millimeter", "millimetre", "millimeters", "millimetres", "mm"),
    "um"  = c("micrometer", "micrometre", "micron", "um"),
    "nm"  = c("nanometer", "nanometre", "nanometers", "nanometres", "nm"),

    "mi"  = c("mile", "miles", "mi"),
    "yd"  = c("yard", "yards", "yd"),
    "ft"  = c("foot", "feet", "ft", "'"),   # ' is sometimes used for feet
    "in"  = c("inch", "inches", "in", "\""), # " is sometimes used for inches,

    "nmi" = c("nautical mile", "nautical miles", "nmi", "NM"),
    "ly"  = c("light year", "lightyear", "light-years", "ly"),
    "au"  = c("astronomical unit", "astronomical units", "au", "AU"),
    "pc"  = c("parsec", "parsecs", "pc")
  )

  dist_unit_names <- names(distance_units)
  out2 <- lapply(dist_unit_names, function(x){
    dplyr::tibble(unit = distance_units[[x]],
                  unit_name = x,
                  category = "distance")
  }) %>%
    dplyr::bind_rows()

  bind1 <- out1 %>% dplyr::bind_rows(out2)

  # Angle
  angle_units <- list(
    "rad"   = c("radian", "radians", "rad"),
    "deg"   = c("degree", "degrees", "deg"),
    "grad"  = c("gradian", "gradians", "grad", "gon"),
    "turn"  = c("turn", "revolution", "circle", "rotation", "rev"),
    "arcmin"= c("arcminute", "arcminutes", "minute of arc", "arcmin", "'"),
    "arcsec"= c("arcsecond", "arcseconds", "second of arc", "arcsec", "\"")
  )

  angle_unit_names <- names(angle_units)
  out3 <- lapply(angle_unit_names, function(x){
    dplyr::tibble(unit = angle_units[[x]],
                  unit_name = x,
                  category = "angle")
  }) %>%
    dplyr::bind_rows()

  bind2 <- bind1 %>% dplyr::bind_rows(out3)


  return(bind2)
}

