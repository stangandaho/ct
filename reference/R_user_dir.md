# Determine the Per-User Directory for R Package Data, Config, or Cache

Determine the per-user directory where packages can store data,
configuration files, or caches.

## Usage

``` r
R_user_dir(package, which = c("data", "config", "cache"))
```

## Arguments

- package:

  Character string giving the package name.

- which:

  Character string specifying the directory type. Must be one of
  `"data"`, `"config"`, or `"cache"`.

## Value

A character string giving the full path to the package-specific per-user
directory.
