# Get Camtrap DP version Extracts the version number used by a Camera Trap Data Package object. This version number indicates what version of the [Camtrap DP standard](https://camtrap-dp.tdwg.org) was used.

Get Camtrap DP version Extracts the version number used by a Camera Trap
Data Package object. This version number indicates what version of the
[Camtrap DP standard](https://camtrap-dp.tdwg.org) was used.

## Usage

``` r
ct_dp_version(package)
```

## Arguments

- package:

  Camera trap data package object, as returned by ct_read_dp().

## Value

Camera Trap Data Package object.

## Details

The version number is derived as follows:

1.  The `version` attribute, if defined.

2.  A version number contained in `x$profile`, which is expected to
    contain the URL to the used Camtrap DP standard.

3.  `x$profile` in its entirety (can be `NULL`).

## Examples

``` r
dp <- ct_dp_example()
ct_dp_version(dp)
#> [1] "1.0.1"
```
