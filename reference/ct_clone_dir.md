# Clone directory structure

Clones the directory structure from a source directory (`from`) to a
destination directory (`to`). This function replicates the folder
hierarchy and subdirectories, but does not copy files, making it useful
for setting up empty directory templates when organizing camera trap
data.

## Usage

``` r
ct_clone_dir(from, to, recursive = TRUE)
```

## Arguments

- from:

  Character. The path to the source directory whose structure will be
  cloned. Must exist and be a directory.

- to:

  Character. The path to the destination directory where the structure
  will be cloned. Must exist and be a directory.

- recursive:

  Logical. Should the directory structure be cloned recursively,
  including all subdirectories? Default is `TRUE`.

## Value

Invisibly returns `NULL`. The function is called for its side-effect of
creating directories.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a temporary directory structure
src <- tempfile("source_dir")
dir.create(src)
dir.create(file.path(src, "site1"))
dir.create(file.path(src, "site1", "cameraA"))
dir.create(file.path(src, "site2"))

# Create destination directory
dst <- tempfile("destination_dir")
dir.create(dst)

# Clone the directory structure
ct_clone_dir(from = src, to = dst)

# Check that structure was cloned
list.files(dst, recursive = TRUE)

# Clean up
unlink(c(src, dst), recursive = TRUE)

} # }
```
