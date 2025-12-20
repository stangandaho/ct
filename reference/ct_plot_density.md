# Plot species' activity patterns

This function visualizes species' activity patterns based on time-of-day
data. It uses kernel density estimation to estimate activity density.

## Usage

``` r
ct_plot_density(
  time_of_day,
  xscale = 24,
  xcenter = c("noon", "midnight"),
  n_grid = 128,
  kmax = 3,
  adjust = 1,
  rug = FALSE,
  line_type = 2,
  line_color = "gray10",
  line_width = 1,
  rug_lentgh = 0.018,
  rug_color = "gray30",
  extend = "lightgrey",
  extend_alpha = 0.8,
  ...
)
```

## Arguments

- time_of_day:

  A numeric vector of time-of-day observations (in radians, 0 to
  \\2\pi\\).

- xscale:

  A numeric value to scale the x-axis. Default is 24 for representing
  time in hours.

- xcenter:

  A string indicating the center of the x-axis. Options are `"noon"`
  (default) or `"midnight"`.

- n_grid:

  An integer specifying the number of grid points for density
  estimation. Default is 128.

- kmax:

  An integer indicating the maximum number of modes allowed in the
  activity pattern. Default is 3.

- adjust:

  A numeric value to adjust the bandwidth of the kernel density
  estimation. Default is 1.

- rug:

  A logical value indicating whether to include a rug plot of the
  observations. Default is `FALSE`.

- line_type:

  A numeric specifying the line types. Default is 2.

- line_color:

  A string specifying the colors of the density lines. Default is
  "gray10".

- line_width:

  A numeric value specifying the line width. Default is 1.

- rug_lentgh:

  A numeric value specifying the length of the rug ticks. Default is
  `0.018` (in normalized plot coordinates).

- rug_color:

  A string specifying the color of the rug ticks. Default is `"gray30"`.

- extend:

  A string specifying the color of the extended area beyond the activity
  period. Default is `"lightgrey"`.

- extend_alpha:

  A numeric value (0 to 1) for the transparency of the extended area.
  Default is `0.8`.

- ...:

  Additional arguments passed to the `geom_rug` function.

## Value

A ggplot object representing the activity density curves of the species.

## Examples

``` r
 # Generate random data for two species
 set.seed(42)
 A <- runif(100, 0, 2 * pi)

 # Plot overlap with default settings
 ct_plot_density(A)

 # Customize plot with specific colors and line types
 ct_plot_density(A, line_color = "gray10", line_width = 0.8,
                 xcenter = "midnight", rug = TRUE,
                 rug_color = 'red', extend_alpha = 0)



```
