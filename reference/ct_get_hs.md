# Retrieve hierarchical subject (hs) values from image metadata

Extracts hierarchical subject metadata from image files using ExifTool.
Hierarchical subjects follow a parent\|child structure (e.g.,
"Species\|Vulture") and are commonly used for taxonomic or categorical
image classification.

## Usage

``` r
ct_get_hs(path, hs_delimitor = "|", into_tibble = FALSE)
```

## Arguments

- path:

  A character string specifying the full path to the image file. Must be
  a valid file path to an image with EXIF metadata support.

- hs_delimitor:

  The character delimiting hierarchy levels in image metadata tags in
  field "HierarchicalSubject"

- into_tibble:

  Logical. Parse hierarchical subjects into tibble.

## Value

A character vector or tibble of unique hierarchical subjects if they
exist, otherwise `NULL`. Each element represents one hierarchical
subject in "parent\|child" format.

## See also

- [`ct_create_hs()`](https://stangandaho.github.io/ct/reference/ct_create_hs.md)
  to add hierarchical subjects

- [`ct_remove_hs()`](https://stangandaho.github.io/ct/reference/ct_remove_hs.md)
  to remove hierarchical subjects

- [`ct_read_metadata()`](https://stangandaho.github.io/ct/reference/ct_read_metadata.md)
  to read image metadata

## Examples

``` r
if (FALSE) { # \dontrun{
# Path to example image
image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")

# Retrieve hierarchical subjects (returns NULL if none exist)
hs <- ct_get_hs(path = image_path)
print(hs)

# After adding hierarchical subjects
ct_create_hs(path = image_path, value = c("Species" = "Vulture"))
ct_get_hs(path = image_path)  # Returns: "Species|Vulture"

# Multiple hierarchical subjects
ct_create_hs(
  path = image_path,
  value = c("Species" = "Eagle", "Location" = "Mountains")
)
ct_get_hs(path = image_path)  # Returns vector with both subjects
} # }
```
