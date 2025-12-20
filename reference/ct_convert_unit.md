# Convert values between different units

Convert a numeric value from one unit to another. It supports **area**,
**distance (length)**, and **angle** units.

## Usage

``` r
ct_convert_unit(x, from, to, show_units = FALSE)
```

## Arguments

- x:

  Numeric. Value(s) to convert.

- from:

  Character. The unit to convert from. Can be any synonym e.g.
  `"meter"`, `"m"`, `"metre"`, `"feet"`, "\\^\circ\\", "um" (i.e \\\mu
  m\\), etc.

- to:

  Character. The unit to convert to. Can also be any synonym.

- show_units:

  Logical. If `TRUE`, returns the full table of supported units and
  their synonyms instead of performing a conversion.

## Value

A numeric vector of converted values.

## See also

[`units_table()`](https://rdrr.io/pkg/Distance/man/units_table.html) for
supported units and synonyms.

## Examples

``` r
# Distance
ct_convert_unit(1000, "m", "km")
#> [1] 1
ct_convert_unit(1, "mile", "m")
#> [1] 1609.344
ct_convert_unit(12, "inches", "ft")
#> [1] 1

# Area
ct_convert_unit(1, "acre", "m2")
#> [1] 4046.856
ct_convert_unit(2, "km2", "hectare")
#> [1] 200

# Angle
ct_convert_unit(180, "deg", "rad")
#> [1] 3.141593
ct_convert_unit(pi, "rad", "deg")
#> [1] 180
```
