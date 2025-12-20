# Read Image Metadata

Extracts metadata from image files using ExifTool and returns the
results as a tibble.

## Usage

``` r
ct_read_metadata(
  path,
  tags = NULL,
  recursive = FALSE,
  parse_hs = FALSE,
  args = NULL,
  exiftool_path = NULL
)
```

## Arguments

- path:

  Character vector of image file paths or a directory path.

- tags:

  Character vector of tag names to extract. Use:

  - `NULL` or `"all"` to extract all tags

  - `"standard"` to extract a predefined, commonly used set of tags

  - a character vector of tag names to extract specific fields

- recursive:

  Logical. If `TRUE`, searches directories recursively. Default is
  `FALSE`.

- parse_hs:

  Logical. If `TRUE`, parses the `HierarchicalSubject` field into
  separate columns where each parent category becomes a column name.
  Default is `FALSE`.

- args:

  Character vector of additional arguments passed directly to ExifTool
  (e.g., `"-fast"`).

- exiftool_path:

  Character. Path to the ExifTool executable. If `NULL`, the function
  attempts to auto-detect it.

## Value

A tibble where each row represents one image file and each column
represents a metadata field.

## Details

By default, all available tags are returned. You can limit the output to
a predefined set of tags or provide a custom list of tag names.

This function calls ExifTool with CSV output enabled and numeric values
returned where applicable. When `parse_hs = TRUE`, the
`HierarchicalSubject` field is split into structured columns.

## See also

- [`ct_get_hs()`](https://stangandaho.github.io/ct/reference/ct_get_hs.md)
  to retrieve hierarchical subjects

- [`ct_create_hs()`](https://stangandaho.github.io/ct/reference/ct_create_hs.md)
  to add hierarchical subjects

- [`ct_remove_hs()`](https://stangandaho.github.io/ct/reference/ct_remove_hs.md)
  to remove hierarchical subjects

## Examples

``` r
if (FALSE) { # \dontrun{
# Example image path
image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")

# Extract all metadata
ct_read_metadata(path = image_path)

# Extract a predefined standard set of metadata
ct_read_metadata(path = image_path, tags = "standard")

# Extract custom tags
ct_read_metadata(path = image_path,
                 tags = c("DateTimeOriginal", "GPSLatitude", "GPSLongitude"))

# Parse hierarchical subject fields into columns
ct_read_metadata(path = image_path,
                 tags = "standard",
                 parse_hs = TRUE)
} # }
```
