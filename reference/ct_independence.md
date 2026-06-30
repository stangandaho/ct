# Evaluate independent detections

Filters camera trap data to ensure temporal independence between
detections, removing consecutive entry of the same species at the same
location within a specified time window.

## Usage

``` r
ct_independence(
  data = NULL,
  species_column,
  site_column,
  datetime,
  format,
  threshold = 30 * 60
)
```

## Arguments

- data:

  A `data.frame`, `tbl_df`, or `tbl` containing the event data. This
  should include a column with datetime values. If `NULL`, the function
  will use the `datetime` argument instead of the `data` argument.

- species_column:

  An optional column name specifying the species grouping. If provided,
  independence will be assessed separately within each species group.

- site_column:

  An optional column name specifying the site/camera grouping. If
  provided, independence will be assessed separately within each site
  group.

- datetime:

  A `character` string specifying the name of the column in `data` that
  contains the datetime values. This argument is required if `data` is
  provided.

- format:

  A `character` string defining the format used to parse the datetime
  values in the `datetime` column.

- threshold:

  A `numeric` value representing the time difference threshold (in
  seconds) to determine whether events are independent. Events are
  considered independent if the time difference between them is greater
  than or equal to this threshold. The default is 30 minutes (1800
  seconds).

## Value

- If `data` is provided and `only` is `TRUE`, a tibble of events
  identified as independent.

- If `data` is provided and `only` is `FALSE`, a tibble of the original
  data with additional columns indicating the `independent` status and
  `deltatime` differences (in second).

- If `data` is not provided, a tibble of the `deltatime` values with
  `independent` status.

## Details

Following Ridout & Linkie (2009), consecutive photos of the same species
at the same location within 30 minutes are considered non-independent
and removed.

The approach mirrors the methodology applied by Linkie & Ridout (2011)
for Sumatran tiger-prey interactions study and Ahmad et al. (2024) to
calculate activity levels where such filtering is essential for:

- Avoiding autocorrelation in activity pattern data

- Ensuring each record represents an independent observation

- Creating a random sample from the underlying activity distribution

The filtered data can then be used to estimate probability density
functions of daily activity patterns, assuming animals are equally
detectable during their active periods.

## References

Ridout, M.S., & Linkie, M. (2009). Estimating overlap of daily activity
patterns from camera trap data. Journal of Agricultural, Biological, and
Environmental Statistics, 14(3), 322-337.
[doi:10.1198/jabes.2009.08038](https://doi.org/10.1198/jabes.2009.08038)

Linkie, M., & Ridout, M.S. (2011). Assessing tiger-prey interactions in
Sumatran rainforests. Journal of Zoology, 284(3),
224-229.[doi:10.1111/j.1469-7998.2011.00801.x](https://doi.org/10.1111/j.1469-7998.2011.00801.x)

Ahmad, F., Mori, T., Rehan, M., Bosso, L., & Kabir, M. (2024). Applying
a Random Encounter Model to Estimate the Asiatic Black Bear (Ursus
thibetanus) Density from Camera Traps in the Hindu Raj Mountains,
Pakistan. Biology, 13(5), 341.
[doi:10.3390/biology13050341](https://doi.org/10.3390/biology13050341)

## Examples

``` r

library(dplyr)
data(penessoulou)

# Load example dataset
cam_data <- penessoulou %>%
  dplyr::filter(project == "Last")

# Independence without considering species
indep1 <- cam_data %>%
  ct_independence(data = ., datetime = datetimes, format = "%Y-%m-%d %H:%M:%S")

sprintf("Independent observations: %s", nrow(indep1))
#> [1] "Independent observations: 140"

# Independence considering species
indep2 <- cam_data %>%
  ct_independence(data = ., datetime = datetimes,
                  format = "%Y-%m-%d %H:%M:%S",
                  species_column = "species")

sprintf("Independent observations: %s", nrow(indep2))
#> [1] "Independent observations: 146"

# Use a standalone vector of datetime values
dtime <- cam_data$datetimes
ct_independence(datetime = dtime, format = "%Y-%m-%d %H:%M:%S")
#> # A tibble: 140 × 1
#>    datetime           
#>    <dttm>             
#>  1 2024-03-10 20:09:27
#>  2 2024-03-12 00:07:36
#>  3 2024-03-12 02:54:31
#>  4 2024-03-12 04:16:32
#>  5 2024-03-16 03:14:26
#>  6 2024-03-16 23:04:41
#>  7 2024-03-17 15:14:29
#>  8 2024-03-17 22:11:38
#>  9 2024-03-18 21:22:46
#> 10 2024-03-19 21:41:35
#> # ℹ 130 more rows
```
