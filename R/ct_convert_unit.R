#' Convert values between different units
#'
#' @description
#' Convert a numeric value from one unit to another.
#' It supports **area**, **distance (length)**, and **angle** units.
#'
#' @param x Numeric. Value(s) to convert.
#' @param from Character. The unit to convert from. Can be any synonym
#' e.g. `"meter"`, `"m"`, `"metre"`, `"feet"`, `"°"`.
#' @param to Character. The unit to convert to. Can also be any synonym.
#' @param show_units Logical. If `TRUE`, returns the full table of supported units
#'   and their synonyms instead of performing a conversion.
#'
#' @return
#' A numeric vector of converted values.
#'
#' @examples
#' # Distance
#' ct_convert_unit(1000, "m", "km")     # 1 km
#' ct_convert_unit(1, "mile", "m")      # 1609.344
#' ct_convert_unit(12, "inches", "ft")  # 1
#'
#' # Area
#' ct_convert_unit(1, "acre", "m2")     # ≈ 4046.856
#' ct_convert_unit(2, "km2", "hectare") # 200
#'
#' # Angle
#' ct_convert_unit(180, "deg", "rad")   # π ≈ 3.141593
#' ct_convert_unit(pi, "rad", "deg")    # 180
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
    "m2"   = 1,                     # base unit
    "km2"  = 1e6,                   # 1 km² = 1,000,000 m²
    "cm2"  = 1e-4,                   # 1 cm² = 0.0001 m²
    "mm2"  = 1e-6,                   # 1 mm² = 0.000001 m²
    "µm2"  = 1e-12,                  # 1 µm² = 1e-12 m²
    "nm2"  = 1e-18,                  # 1 nm² = 1e-18 m²
    "ha"   = 1e4,                    # 1 hectare = 10,000 m²
    "are"  = 100,                    # 1 are = 100 m²
    "daa"  = 1000,                   # 1 decare = 1000 m²
    "ca"   = 1,                      # 1 centiare = 1 m²
    "acre" = 4046.8564224,           # 1 acre ≈ 4046.8564224 m²
    "mi2"  = 2.589988e6,             # 1 square mile ≈ 2,589,988 m²
    "yd2"  = 0.83612736,             # 1 square yard ≈ 0.83612736 m²
    "ft2"  = 0.09290304,             # 1 square foot ≈ 0.09290304 m²
    "in2"  = 0.00064516              # 1 square inch ≈ 0.00064516 m²
  )

  distance_factors <- c(
    "m"   = 1,                     # base unit
    "km"  = 1e3,                   # 1 km = 1000 m
    "cm"  = 1e-2,                   # 1 cm = 0.01 m
    "mm"  = 1e-3,                   # 1 mm = 0.001 m
    "µm"  = 1e-6,                   # 1 µm = 0.000001 m
    "nm"  = 1e-9,                   # 1 nm = 0.000000001 m

    "mi"  = 1609.344,              # 1 mile = 1609.344 m
    "yd"  = 0.9144,                # 1 yard = 0.9144 m
    "ft"  = 0.3048,                # 1 foot = 0.3048 m
    "in"  = 0.0254,                # 1 inch = 0.0254 m

    "nmi" = 1852,                  # 1 nautical mile = 1852 m
    "ly"  = 9.4607e15,             # 1 light-year ≈ 9.4607 × 10^15 m
    "au"  = 1.495978707e11,        # 1 astronomical unit ≈ 1.496 × 10^11 m
    "pc"  = 3.085677581e16         # 1 parsec ≈ 3.086 × 10^16 m
  )

  angle_factors <- c(
    "rad"   = 1,                      # base unit
    "deg"   = pi / 180,               # 1° = π/180 rad
    "grad"  = pi / 200,               # 1 grad = π/200 rad
    "turn"  = 2 * pi,                 # 1 turn = 2π rad
    "arcmin"= pi / (180 * 60),        # 1′ = π / 10800 rad
    "arcsec"= pi / (180 * 3600)       # 1″ = π / 648000 rad
  )

  unit_factors <- c(area_factors, distance_factors, angle_factors)


  # Conversion function process
  from_unit <- tolower(units_table() %>%
                    dplyr::filter(unit == from) %>% dplyr::pull(unit_name))
  to_unit <- tolower(units_table() %>%
                    dplyr::filter(unit == to) %>% dplyr::pull(unit_name))
  # Rise error for unknown unit
  if(length(from_unit) == 0){cli::cli_abort(sprintf("Unknown 'from' unit: %s", from))}
  if(length(to_unit) == 0){cli::cli_abort(sprintf("Unknown 'to' unit: %s", to))}

  from_cat <- tolower(units_table() %>%
                         dplyr::filter(unit == from) %>% dplyr::pull(category))
  to_cat <- tolower(units_table() %>%
                         dplyr::filter(unit == to) %>% dplyr::pull(category))
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
    "µm2"  = c("square micrometer", "square micrometre", "square micrometers", "square micrometres", "µm2", "μm2", "um2", "µm^2", "μm^2"),
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
    "µm"  = c("micrometer", "micrometre", "micron", "µm", "μm", "um"),
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
    "deg"   = c("degree", "degrees", "deg", "°"),
    "grad"  = c("gradian", "gradians", "grad", "gon"),   # 400 grads = 360°
    "turn"  = c("turn", "revolution", "circle", "rotation", "rev"),
    "arcmin"= c("arcminute", "arcminutes", "minute of arc", "arcmin", "′"),
    "arcsec"= c("arcsecond", "arcseconds", "second of arc", "arcsec", "″")
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

