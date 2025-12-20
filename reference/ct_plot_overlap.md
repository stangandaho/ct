# Plot overlap between two species' activity patterns

This function visualizes the temporal overlap between two species'
activity patterns based on time-of-day data. It uses kernel density
estimation to estimate activity densities and highlights areas of
overlap between the two species.

## Usage

``` r
ct_plot_overlap(
  A,
  B,
  xscale = 24,
  xcenter = c("noon", "midnight"),
  n_grid = 128,
  kmax = 3,
  adjust = 1,
  rug = FALSE,
  overlap_color = "gray40",
  overlap_alpha = 0.8,
  line_type = c(1, 2),
  line_color = c("gray10", "gray0"),
  line_width = c(1, 1),
  overlap_only = FALSE,
  rug_lentgh = 0.018,
  rug_color = "gray30",
  extend = "lightgrey",
  extend_alpha = 0.8,
  ...
)
```

## Arguments

- A:

  A numeric vector of time-of-day observations (in radians, 0 to
  \\2\pi\\) for species A.

- B:

  A numeric vector of time-of-day observations (in radians, 0 to
  \\2\pi\\) for species B.

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

- overlap_color:

  A string specifying the color of the overlap area. Default is
  `"gray40"`.

- overlap_alpha:

  A numeric value (0 to 1) for the transparency of the overlap area.
  Default is 0.8.

- line_type:

  A vector of integers specifying the line types for species A and B
  density lines. Default is `c(1, 2)`.

- line_color:

  A vector of strings specifying the colors of the density lines for
  species A and B. Default is `c("gray10", "gray0")`.

- line_width:

  A vector of numeric values specifying the line widths for species A
  and B density lines. Default is `c(1, 1)`.

- overlap_only:

  A logical value indicating whether to plot only the overlap region
  without individual density lines. Default is `FALSE`.

- rug_lentgh:

  A numeric value specifying the length of the rug ticks. Default is
  0.018 (in normalized plot coordinates).

- rug_color:

  A string specifying the color of the rug ticks. Default is `"gray30"`.

- extend:

  A string specifying the color of the extended area beyond the activity
  period. Default is `"lightgrey"`.

- extend_alpha:

  A numeric value (0 to 1) for the transparency of the extended area.
  Default is 0.8.

- ...:

  Additional arguments passed to the `geom_rug` function.

## Value

A ggplot object representing the activity density curves and overlap
between the two species. If `overlap_only = TRUE`, only the overlap
region is displayed.

## Examples

``` r
if (FALSE) { # \dontrun{
  # Generate random data for two species
  set.seed(42)
  species_A <- runif(100, 0, 2 * pi)
  species_B <- runif(100, 0, 2 * pi)

  # Plot overlap with default settings
  ct_plot_overlap(A = species_A, B = species_B)

  # Customize plot with specific colors and line types
  ct_plot_overlap(A = species_A, B = species_B, overlap_color = "blue",
  line_color = c("red", "green"))

  # Include rug plots and change transparency
  ct_plot_overlap(A = species_A, B = species_B, rug = TRUE,
  overlap_alpha = 0.5)
} # }
```
