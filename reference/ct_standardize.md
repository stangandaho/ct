# Standardize community data matrix

This function standardizes a given data matrix using different methods
such as total sum scaling, max normalization, frequency scaling,
standardization, presence-absence transformation, chi-square
transformation, Hellinger transformation, log transformation, and
others.

## Usage

``` r
ct_standardize(
  data,
  method,
  margin,
  range_global,
  logbase = 2,
  na.rm = FALSE,
  ...
)
```

## Arguments

- data:

  A numeric matrix or data frame to be standardized.

- method:

  A character string specifying the standardization method (see
  details). Available methods are:

  - `"total"`: Divides each entry by the total sum in the given margin.

  - `"max"`: Divides each entry by the maximum value in the given
    margin.

  - `"frequency"`: Frequency transformation.

  - `"normalize"`: Normalization by Euclidean norm.

  - `"range"`: Standardizes by range (min-max scaling).

  - `"rank"`: Converts values to ranks.

  - `"rrank"`: Relative rank transformation.

  - `"standardize"`: Standardization (z-score normalization).

  - `"pa"`: Presence-absence transformation (binary).

  - `"chi.square"`: Chi-square standardization.

  - `"hellinger"`: Hellinger transformation.

  - `"log"`: Log transformation.

  - `"clr"`: Centered log-ratio transformation.

  - `"rclr"`: Robust centered log-ratio transformation.

  - `"alr"`: Additive log-ratio transformation.

- margin:

  An integer specifying the margin for standardization:

  - `1`: Rows

  - `2`: Columns

- range_global:

  A matrix specifying the range for standardization (optional, used with
  `"range"` method).

- logbase:

  The base for logarithmic transformation (default is 2).

- na.rm:

  Logical. If `TRUE`, missing values (`NA`) are removed before
  calculations.

- ...:

  Additional arguments passed to transformation functions.

## Value

A standardized matrix or tibble with attributes specifying the
transformation applied.

## Details

The function provides the following standardization methods for
community data:

- `"total"`: Divides by margin total (default `margin = 1`).

- `"max"`: Divides by margin maximum (default `margin = 2`).

- `"frequency"`: Divides by margin total and multiplies by the number of
  non-zero items, ensuring the average of non-zero entries is one
  (Oksanen 1983; default `margin = 2`).

- `"normalize"`: Scales data so that the sum of squares along the
  specified margin equals one (default `margin = 1`).

- `"range"`: Standardizes values into the range `[0,1]` (default
  `margin = 2`). If all values are constant, they will be transformed to
  0.

- `"rank"`, `"rrank"`:

  - `"rank"` replaces abundance values by their increasing ranks,
    leaving zeros unchanged.

  - `"rrank"` is similar but uses relative ranks with a maximum of 1
    (default `margin = 1`).

- `"standardize"`: Scales `x` to zero mean and unit variance (default
  `margin = 2`).

- `"pa"`: Converts `x` to presence/absence scale (0/1).

- `"chi.square"`: Divides by row sums and the square root of column
  sums, then adjusts for the square root of the matrix total (Legendre &
  Gallagher 2001). When used with Euclidean distance, the distances
  should be similar to Chi-square distances in correspondence analysis
  (default `margin = 1`).

- `"hellinger"`: Computes the square root of `method = "total"`
  (Legendre & Gallagher 2001).

- `"log"`: Logarithmic transformation suggested by Anderson et al.
  (2006): \$\$\log_b (x) + 1\$\$ for \\x \> 0\\, where \\b\\ is the base
  of the logarithm. Zeros remain unchanged. Higher bases give less
  weight to quantities and more to presences.

- `"alr"`: Additive log ratio (ALR) transformation (Aitchison 1986).
  Reduces skewness and compositional bias. Requires positive values;
  pseudocounts can be added. The transformation is defined as: \$\$alr =
  \[\log(x_1 / x_D), ..., \log(x\_{D-1} / x_D)\]\$\$ where the
  denominator sample \\x_D\\ can be chosen arbitrarily.

- `"clr"`: Centered log ratio (CLR) transformation (Aitchison 1986).
  Common in microbial ecology (Gloor et al. 2017). Only supports
  positive data; pseudocounts can be used to handle zeros. The
  transformation is defined as: \$\$clr = \log(x / g(x)) = \log x - \log
  g(x)\$\$ where \\x\\ is a single value, and \\g(x)\\ is the geometric
  mean of \\x\\.

- `"rclr"`: Robust CLR transformation. Unlike CLR, this method allows
  zeros without requiring pseudocounts. It divides values by the
  geometric mean of observed (non-zero) features, preserving zeros
  (Martino et al. 2019). The transformation is defined as: \$\$rclr =
  \log(x / g(x \> 0))\$\$ where \\x\\ is a single value, and \\g(x \>
  0)\\ is the geometric mean of sample-wide values \\x\\ that are
  positive (\\x \> 0\\).

Standardization, as contrasted to transformation, means that the entries
are transformed relative to other entries.

All methods have a default margin. `margin=1` means rows (sites in a
normal data set) and `margin=2` means columns (species in a normal data
set).

Command `wisconsin` is a shortcut to common Wisconsin double
standardization where species (`margin=2`) are first standardized by
maxima (`max`) and then sites (`margin=1`) by site totals (`tot`).

Most standardization methods will give nonsense results with negative
data entries that normally should not occur in the community data. If
there are empty sites or species (or constant with `method = "range"`),
many standardization will change these into `NaN`.

Function `decobackstand` can be used to transform standardized data back
to original. This is not possible for all standardization and may not be
implemented to all cases where it would be possible. There are round-off
errors and back-transformation is not exact, and it is wise not to
overwrite the original data. With `zap=TRUE` original zeros should be
exact.

## Note

This function is adapted from the `decostand` function in the `vegan` R
package, with modifications to improved handling.

## References

Aitchison, J. The Statistical Analysis of Compositional Data (1986).
London, UK: Chapman & Hall.

Anderson, M.J., Ellingsen, K.E. & McArdle, B.H. (2006) Multivariate
dispersion as a measure of beta diversity. *Ecology Letters* **9**,
683–693.

Egozcue, J.J., Pawlowsky-Glahn, V., Mateu-Figueras, G., Barcel'o-Vidal,
C. (2003) Isometric logratio transformations for compositional data
analysis. *Mathematical Geology* **35**, 279–300.

Gloor, G.B., Macklaim, J.M., Pawlowsky-Glahn, V. & Egozcue, J.J. (2017)
Microbiome Datasets Are Compositional: And This Is Not Optional.
*Frontiers in Microbiology* **8**, 2224.

Legendre, P. & Gallagher, E.D. (2001) Ecologically meaningful
transformations for ordination of species data. *Oecologia* **129**,
271–280.

Martino, C., Morton, J.T., Marotz, C.A., Thompson, L.R., Tripathi, A.,
Knight, R. & Zengler, K. (2019) A novel sparse compositional technique
reveals microbial perturbations. *mSystems* **4**, 1.

Oksanen, J. (1983) Ordination of boreal heath-like vegetation with
principal component analysis, correspondence analysis and
multidimensional scaling. *Vegetatio* **52**, 181–189.

## Examples

``` r
# Example usage with sample data
cam_data <- read.csv(system.file('penessoulou_season1.csv', package = 'ct'))
cam_data <- cam_data %>%
  ct_to_community(site_column = camera, species_column = species,
                  size_column = number, values_fill = 0)

standardized_data <- ct_standardize(data = cam_data[, 2:11], method = "total")
standardized_data
#> # A tibble: 13 × 10
#>    `Syncerus caffer` `Lepus crawshayi` `Erythrocebus patas`
#>                <dbl>             <dbl>                <dbl>
#>  1            0.981              0                   0.0169
#>  2            0                  0.375               0.5   
#>  3            0.430              0                   0.522 
#>  4            0.941              0                   0     
#>  5            0                  0                   0.0714
#>  6            0.480              0                   0.341 
#>  7            0                  0                   1     
#>  8            0.247              0                   0.306 
#>  9            0                  0                   0     
#> 10            0                  0                   0     
#> 11            0                  0                   0     
#> 12            0                  0                   0     
#> 13            0.0240             0                   0.974 
#> # ℹ 7 more variables: `Tragelaphus scriptus` <dbl>,
#> #   `Chlorocebus aethiops` <dbl>, `Canis adustus` <dbl>,
#> #   `Mellivora capensis` <dbl>, `Sylvicapra grimmia` <dbl>,
#> #   `Thryonomys swinderianus` <dbl>, `Genetta genetta` <dbl>

```
