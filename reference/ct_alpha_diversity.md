# Alpha diversity index

Calculate index diversity within a particular area or ecosystem; usually
expressed by the number of species (i.e., species richness) in that
ecosystem.

## Usage

``` r
ct_alpha_diversity(
  data,
  to_community = TRUE,
  index = "shannon",
  site_column,
  species_column,
  size_column = NULL,
  margin = 1
)
```

## Arguments

- data:

  A data frame containing species observation data.

- to_community:

  Logical; if `TRUE`, the function first transforms `data` into a
  community matrix format where sites are rows and species are columns
  before computing indices. Default is `TRUE`.

- index:

  A character vector specifying the diversity index to calculate.
  Accepted values are `"shannon"`, `"simpson"`, `"invsimpson"`,
  `"evenness"`, and `"pielou"`. Multiple indices can be computed
  simultaneously by providing a vector.

- site_column:

  The column name in `data` that represents the site or location where
  species were recorded.

- species_column:

  The column(s) in `data` representing species or taxa. This can be a
  single column name, a range of column indices (e.g., `2:5`), or a
  selection helper (e.g., `dplyr::starts_with("sp_")`).

- size_column:

  (Optional) The column in `data` containing the count or abundance of
  individuals per species. If `NULL`, the function assumes each row
  represents one individual.

- margin:

  An integer specifying whether diversity calculations should be
  performed by row (`margin = 1`) or by column (`margin = 2`). Default
  is `1` (row-wise).

## Value

A tibble with diversity index values for each site. The first column
corresponds to `site_column`, followed by one or more columns containing
the computed diversity indices, depending on the values specified in the
`index` argument.

## Details

**Simpson diversity index**

Simpson (1949) introduced a diversity index that quantifies the
likelihood of two randomly chosen individuals belonging to the same
species. This probability increases as diversity decreases; in a
scenario with no diversity (only one species), the probability
reaches 1. Simpson's Index is computed using the following formula:

\$\$D = \sum\_{i=1}^{S} \left( \frac{n\_{i}}{N} \right)^2\$\$

where \\n\_{i}\\ is the number of individuals in species *i*, N = total
number of individuals of all species, and \\\frac{n\_{i}}{N} = pi\\
(proportion of individuals of species *i*), and S = species richness.
The value of Simpson’s *D* ranges from 0 to 1, with 0 representing
infinite diversity and 1 representing no diversity, so the larger the
value of D, the lower the diversity. For this reason, Simpson’s index is
often as its complement (*1-D*). Simpson's Dominance Index is the
inverse of the Simpson's Index (\\1/D\\).

**Shannon-Weiner Diversity Index**

Shannon-Weiner Diversity Index is a measure of diversity that takes into
account both species richness and evenness, introduced by Claude Shannon
in 1948. Commonly referred to as Shannon's Diversity Index, it is based
on the concept of uncertainty. For instance, in a community with very
low diversity, there is a high level of certainty (or low uncertainty)
about the identity of a randomly selected organism. Conversely, in a
highly diverse community, the uncertainty increases, making it harder to
predict which species a randomly chosen organism will belong to (low
certainty or high uncertainty).

\$\$H = -\sum\_{i=1}^{S} p\_{i} \* \ln p\_{i}\$\$

where \\p\_{i}\\ = proportion of individuals of species *i*, and *ln* is
the natural logarithm, and S = species richness. The value of H ranges
from 0 to Hmax. Hmax is different for each community and depends on
species richness. (Note: Shannon-Weiner is often denoted H' ).

**Pielou or Evenness diversity index**

Species evenness refers to the relative abundance of each species within
an environment. For example, if there are 40 foxes and 1000 dogs, the
community is uneven because one species dominates. However, if there are
40 foxes and 42 dogs, the community is much more even, as the species
are more balanced in number. The degree of evenness in a community can
be quantified using Pielou's evenness index (Pielou, 1966):

\$\$J=\frac{H}{H\_{\max }}\$\$

The value of J ranges from 0 to 1. Higher values indicate higher levels
of evenness. At maximum evenness, J = 1. J and D can be used as measures
of species dominance (the opposite of diversity) in a community. Low J
indicates that 1 or few species dominate the community.

## References

Pielou, E.C. (1966). The measurement of diversity in different types of
biological collections. Journal of Theoretical Biology, 13, pp. 131–144.
[doi:10.1016/0022-5193(66)90013-0](https://doi.org/10.1016/0022-5193%2866%2990013-0)
.

Simpson, E.H. (1949). Measurement of diversity. Nature, 163, pp. 688.
[doi:10.1038/163688a0](https://doi.org/10.1038/163688a0)

Shannon, C.E. (1948). A mathematical theory of communication. The Bell
System Technical Journal, 27, pp.
379-423.[doi:10.1002/j.1538-7305.1948.tb01338.x](https://doi.org/10.1002/j.1538-7305.1948.tb01338.x)

## Examples

``` r
cam_data <- read.csv(system.file('penessoulou_season1.csv', package = 'ct'))

# Transform data to community format and compute diversity indices
alpha1 <- cam_data %>%
  ct_alpha_diversity(
    to_community = TRUE,
    size_column = number,
    site_column = camera,
    species_column = species,
    index = c("shannon", "evenness", "invsimpson")
  )

# Alternative method using a manually transformed community matrix
alpha2 <- cam_data %>%
  ct_to_community(site_column = camera, species_column = species,
                  size_column = number, values_fill = 0) %>%
  ct_alpha_diversity(
    to_community = FALSE,
    site_column = camera,
    species_column = 2:11,
    index = c("shannon", "evenness", "invsimpson")
  )
alpha2
#> # A tibble: 13 × 4
#>    camera          shannon evenness invsimpson
#>    <chr>             <dbl>    <dbl>      <dbl>
#>  1 CAMERA 10         0.103    0.045       1.04
#>  2 CAMERA 3          0.974    0.423       2.46
#>  3 CAMERA 5          0.893    0.388       2.18
#>  4 CAMERA 8          0.224    0.097       1.12
#>  5 CAMERA 2          0.509    0.221       1.34
#>  6 CAMERA 1          1.14     0.497       2.73
#>  7 CAMERA 12         0        0           1   
#>  8 CAMERA 4          1.31     0.57        3.55
#>  9 CAMERA 11         0        0           1   
#> 10 CAMERA 3 - Bait   0.562    0.244       1.6 
#> 11 CAMERA 1 - Bait   0        0           1   
#> 12 CAMERA 19         0.637    0.276       1.80
#> 13 FCPEN             0.131    0.057       1.06
# Compare results
all(alpha1 == alpha2) # TRUE
#> [1] TRUE
```
