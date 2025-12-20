# Remove hierarchical subject (hs) values from image metadata

Removes specific hierarchical subjects or clears the entire
HierarchicalSubject field from image metadata using ExifTool. Can remove
one or multiple specific parent\|child hierarchies, or clear all
hierarchical subjects at once.

This function supports processing individual files or entire directories
(with optional recursion), applying the removal to all supported image
files found.

## Usage

``` r
ct_remove_hs(
  path,
  hierarchy = NULL,
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
  removed from all supported image files in that directory.

- hierarchy:

  A named character vector specifying hierarchies to remove. Names
  represent parent categories, values represent child categories.
  Example: `c("Species" = "Vulture")` removes "Species\|Vulture". If
  `NULL` (default), removes all hierarchical subjects from the image(s).

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

Invisibly returns `TRUE` on success, `FALSE` if specified hierarchy
doesn't exist. Displays informative messages about the operation. Called
primarily for side effects (modifying image metadata).

## Details

When removing specific hierarchies from a single file, the function
validates that they exist before attempting removal. If the last
hierarchy is removed, the entire HierarchicalSubject field is cleared
from the metadata. The function handles multiple hierarchies in a single
call.

When processing directories, the function applies the removal to all
supported image files found. Use `recursive = TRUE` to include
subdirectories. Note that validation of existing hierarchies is only
performed for single files.

## See also

- [`ct_get_hs()`](https://stangandaho.github.io/ct/reference/ct_get_hs.md)
  to retrieve hierarchical subjects

- [`ct_create_hs()`](https://stangandaho.github.io/ct/reference/ct_create_hs.md)
  to add hierarchical subjects

- [`ct_read_metadata()`](https://stangandaho.github.io/ct/reference/ct_read_metadata.md)
  to read image metadata

## Examples

``` r
if (FALSE) { # \dontrun{
# Path to example image
image_path <- file.path(system.file("img", package = "ct"), "large.jpeg")

# Add some hierarchical subjects
ct_create_hs(image_path, c("Species" = "Vulture", "Location" = "Africa"))
ct_get_hs(image_path)

# Remove a specific hierarchy
ct_remove_hs(image_path, hierarchy = c("Species" = "Vulture"))
ct_get_hs(image_path) # Only "Location|Africa" remains

# Remove multiple hierarchies at once
ct_create_hs(image_path, c("Species" = "Eagle", "Status" = "Endangered"))
ct_remove_hs(
  image_path,
  hierarchy = c("Species" = "Eagle", "Status" = "Endangered")
)

# Remove all hierarchical subjects
ct_remove_hs(image_path, hierarchy = NULL)
ct_get_hs(image_path) # Returns NULL

# Attempting to remove non-existent hierarchy
ct_remove_hs(image_path, hierarchy = c("Species" = "NonExistent"))

# Remove all hierarchical subjects from all images in a directory
image_dir <- system.file("img", package = "ct")
ct_remove_hs(path = image_dir, recursive = FALSE)

# Remove recursively from directory and subdirectories
ct_remove_hs(path = image_dir, recursive = TRUE)

# Remove specific hierarchy from all images in a directory
ct_remove_hs(
  path = image_dir,
  hierarchy = c("Species" = "Vulture"),
  recursive = TRUE
)
} # }
```
