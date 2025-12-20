# Read a delimited file into a tibble

The `ct_read` function reads a delimited text file. It automatically
detects the delimiter if not specified and provides an easy-to-use
interface for importing data with additional customization options.

## Usage

``` r
ct_read(file_path, header = TRUE, sep, ...)
```

## Arguments

- file_path:

  A string specifying the path to the file to be read.

- header:

  A logical value indicating whether the file contains a header row.
  Defaults to `TRUE`.

- sep:

  The field separator character. If not provided, the function
  automatically detects the separator.

- ...:

  Additional arguments passed to the `read.table` function for
  fine-tuned control over file reading.

## Value

A tibble containing the data from the specified file.
