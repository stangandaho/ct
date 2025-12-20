# Create or add hierarchical subject (hs) values in image metadata

Adds hierarchical subject metadata to image files. Hierarchical subjects
follow a parent\|child structure, allowing for organized taxonomic or
categorical classification of images.

## Usage

``` r
ct_create_hs(
  path,
  value = NULL,
  overwrite = FALSE,
  recursive = FALSE,
  intern = TRUE,
  quiet = TRUE,
  ...
)
```

## Arguments

- path:

  A character string specifying the full path to an image file or
  directory. If a directory is provided, hierarchical subjects will be
  added to all supported image files in that directory.

- value:

  A named character vector specifying hierarchical subjects to add.
  Names represent parent categories, values represent child categories.

  **Simple format:** `c("Species" = "Vulture", "Location" = "Africa")`
  creates "Species\|Vulture" and "Location\|Africa".

  **Multiple values format:**
  `c("Species" = "Mammal, Bird", "Count" = "2, 3")` creates
  "Species\|Mammal", "Species\|Bird", "Count\|2", and "Count\|3". All
  parents must have equal number of comma-separated values.

- overwrite:

  Logical. If `TRUE`, replaces existing hierarchical subjects. If
  `FALSE` (default), adds to existing subjects. Default: `FALSE`.

- recursive:

  Logical. If `TRUE` and `path` is a directory, searches for images
  recursively in subdirectories. Default: `FALSE`.

- intern:

  Logical. If `TRUE`, returns output as a character vector. Default:
  `TRUE`.

- quiet:

  Logical. If `TRUE`, suppresses command output. Default: `TRUE`.

- ...:

  Additional arguments passed to
  [`system2()`](https://rdrr.io/r/base/system2.html).

## Value

Invisibly returns `TRUE` on success. Called primarily for side effects
(modifying image metadata).

## Details

Two input formats are supported:

1.  Simple format: One child per parent, e.g.,
    `c("Species" = "Vulture")`

2.  Multiple values format: Multiple children per parent using
    comma-separated values, e.g.,
    `c("Species" = "Mammal, Bird, Reptile")`. When using this format,
    all parents must have the same number of comma-separated values.

The function validates that all values have parent categories (names)
and preserves existing hierarchical subjects unless `overwrite = TRUE`.
Duplicate parent\|child combinations are automatically removed.

When processing directories, the function applies hierarchical subjects
to all supported image files found. Use `recursive = TRUE` to include
subdirectories.

When using comma-separated values, the function splits each value string
and creates separate hierarchical subjects for each position across all
parents.

## See also

- [`ct_get_hs()`](https://stangandaho.github.io/ct/reference/ct_get_hs.md)
  to retrieve hierarchical subjects

- [`ct_remove_hs()`](https://stangandaho.github.io/ct/reference/ct_remove_hs.md)
  to remove hierarchical subjects

- [`ct_read_metadata()`](https://stangandaho.github.io/ct/reference/ct_read_metadata.md)
  to read image metadata

## Examples

``` r
if (FALSE) { # \dontrun{
# Path to example image
image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")

# Simple format: single child per parent
ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
ct_get_hs(path = image_path) # Returns: "Species|Vulture"

# Simple format: multiple parents, one child each
ct_create_hs(
  path = image_path,
  value = c("Species" = "Vulture",
            "Location" = "Africa",
            "Status" = "Endangered")
)
ct_get_hs(path = image_path, into_tibble = TRUE)

# Multiple values format: recording multiple observations
ct_create_hs(
  path = image_path,
  value = c(
    "Species" = "Gyps_africanus, Kobus_kob",
    "Sex" = "Male, Female",
    "Count" = "3, 2"
  ),
  overwrite = TRUE
)
ct_get_hs(path = image_path)

# Parse Hierarchical Subject to tibble
ct_get_hs(path = image_path, into_tibble = TRUE)

# Overwrite existing hierarchical subjects
ct_create_hs(
  path = image_path,
  value = c("Species" = "Eagle"),
  overwrite = TRUE
)
} # }
```
