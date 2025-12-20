# Call ExifTool

Execute ExifTool with specified arguments

## Usage

``` r
ct_exiftool_call(
  path = NULL,
  args = NULL,
  quiet = TRUE,
  intern = TRUE,
  exiftool_path = NULL
)
```

## Arguments

- path:

  Files or directories to process

- args:

  Character vector of arguments to pass to ExifTool

- quiet:

  Suppress ExifTool output messages

- intern:

  Capture and return output as character vector

- exiftool_path:

  Path to ExifTool executable (auto-detected if NULL)

## Value

If intern=TRUE, returns output as character vector. Otherwise returns
exit status.
