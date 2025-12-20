# Correct camera trap datetime records

This function corrects datetime stamps in camera trap data using a
reference correction table. It applies time adjustments based on known
timing errors for each camera deployment.

## Usage

``` r
ct_correct_datetime(data, datetime, deployment, corrector, format = NULL)
```

## Arguments

- data:

  A data.frame or tibble containing camera trap records with datetime
  information that needs correction.

- datetime:

  Column name (unquoted) in `data` containing the datetime values to be
  corrected. Can be character or POSIXct format.

- deployment:

  Column name (unquoted) in both `data` and `corrector` that identifies
  unique camera deployments (e.g., camera ID, site name, or deployment
  identifier).

- corrector:

  A data.frame containing correction information with columns:

  - deployment column matching the deployment parameter

  - `sign` - character indicating correction direction ("+" or "-")

  - `datetimes` - reference datetime showing the correct time

- format:

  Optional datetime format specification. Can be:

  - `NULL` (default) - attempts multiple common formats

  - Single format string - used for both `data` and `corrector`
    datetimes

  - Vector of 2 format strings - first for data, second for corrector

## Value

A data.frame with the original data plus additional columns:

- `corrected_datetime` - corrected datetime as POSIXct

- `correction_applied` - sign of correction applied

- `time_offset_seconds` - magnitude of correction in seconds

- `corrector_reference` - reference datetime used for correction

## Examples

``` r
# Load camera trap data
library(dplyr)

camtrap_data <- read.csv(ct:::table_files()[1]) %>%
  dplyr::filter(project == "Last")

# Create correction table
# CAMERA 1 was running slow (+), CAMERA 2 was running fast (-)
crtor <- data.frame(
  camera = c("CAMERA 1", "CAMERA 2"),
  sign = c("+", "-"),
  datetimes = c("2025-03-14 8:17:00", "2024-11-14 10:02:03")
)

# Apply datetime corrections
ct_correct_datetime(
  data = camtrap_data,
  datetime = datetimes,
  deployment = camera,
  corrector = crtor
) %>%
  dplyr::select(datetimes,
                corrected_datetime,
                time_offset_seconds) %>%
  dplyr::slice_head(n = 10)
#>              datetimes  corrected_datetime time_offset_seconds
#> 1   2024-03-24 8:03:07 2025-03-14 08:17:00            30672833
#> 2   2024-03-24 8:03:07 2025-03-14 08:17:00            30672833
#> 3   2024-03-24 8:03:08 2025-03-14 08:17:01            30672833
#> 4  2024-03-24 20:19:35 2025-03-14 20:33:28            30672833
#> 5  2024-03-24 20:19:35 2025-03-14 20:33:28            30672833
#> 6  2024-03-24 20:19:35 2025-03-14 20:33:28            30672833
#> 7  2024-03-24 20:20:02 2025-03-14 20:33:55            30672833
#> 8  2024-03-24 20:20:02 2025-03-14 20:33:55            30672833
#> 9  2024-03-24 20:20:03 2025-03-14 20:33:56            30672833
#> 10 2024-03-24 20:20:24 2025-03-14 20:34:17            30672833
```
