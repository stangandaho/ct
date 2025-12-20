# Download the current version of ExifTool

Download the current version of ExifTool

## Usage

``` r
download_exiftool(win_exe = FALSE, download_path = NULL, quiet = FALSE)
```

## Arguments

- win_exe:

  Logical, only used on Windows machines. Should we install the
  standalone ExifTool Windows executable or the ExifTool Perl library?
  (The latter relies, for its execution, on an existing installation of
  Perl being present on the user's machine.) If set to `NULL` (the
  default), the function installs the Windows executable on Windows
  machines and the Perl library on other operating systems.

- download_path:

  Path indicating the location to which ExifTool should be downloaded.

- quiet:

  Logical. Should function should be chatty?

## Value

A character string giving the path to the downloaded ExifTool.

## Author

Joshua O'Brien
