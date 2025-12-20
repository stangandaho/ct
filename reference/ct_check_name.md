# Check species name and retrieve Taxonomic Serial Number (TSN) from ITIS

This function queries the **Integrated Taxonomic Information System
(ITIS)** to find taxonomic details for a given species name. It can
search using either a **scientific name** or a **common name** and
return relevant taxonomic information, including the TSN.

## Usage

``` r
ct_check_name(
  species_name,
  search_type = c("common_name", "scientific_name"),
  ask = FALSE
)
```

## Arguments

- species_name:

  A character string specifying the species name to search for. Only a
  **single name** is allowed.

- search_type:

  A character string specifying the type of search. Options:

  - `"scientific_name"`: Search by scientific name.

  - `"common_name"`: Search by common name.

- ask:

  A logical value (`TRUE` or `FALSE`). If `TRUE`, allows interactive
  selection when multiple matches are found.

## Value

A tibble containing taxonomic details:

- `search`: The original species name queried.

- `tsn`: The **Taxonomic Serial Number** (TSN) from ITIS.

- `common_name`: The common name of the species (if available).

- `scientific_name`: The scientific name of the species.

- `author`: The author who classified the species.

- `itis_url`: A direct link to the species report on ITIS.

- `taxon_status`: The taxonomic status of the species.

## Details

- If the necessary packages (`httr2`, `xml2`) are not installed, the
  function prompts the user to install them.

- If multiple results are found and `ask = TRUE`, the user is prompted
  to select the correct match.

- If no exact match is found, all results are displayed for manual
  selection.

## See also

<https://www.itis.gov>

## Examples

``` r
# \donttest{
# Search for a species by scientific name
ct_check_name("Panthera leo", search_type = "scientific_name")
#> # A tibble: 13 × 7
#>    search       tsn    common_name  scientific_name author itis_url taxon_status
#>    <chr>        <chr>  <chr>        <chr>           <chr>  <chr>    <chr>       
#>  1 Panthera leo 183803 Lion         Panthera leo    Linna… https:/… valid       
#>  2 Panthera leo 622026 Asiatic lion Panthera leo p… Meyer… https:/… invalid     
#>  3 Panthera leo 622059 Barbary lion Panthera leo l… Linna… https:/… valid       
#>  4 Panthera leo 726446 NA           Panthera leo a… J. A.… https:/… invalid     
#>  5 Panthera leo 726447 NA           Panthera leo b… Lönnb… https:/… invalid     
#>  6 Panthera leo 726448 NA           Panthera leo h… J. A.… https:/… invalid     
#>  7 Panthera leo 726449 NA           Panthera leo k… Matsc… https:/… invalid     
#>  8 Panthera leo 726450 NA           Panthera leo k… Rober… https:/… invalid     
#>  9 Panthera leo 726451 NA           Panthera leo m… Neuma… https:/… invalid     
#> 10 Panthera leo 726452 South Afric… Panthera leo m… C. E.… https:/… valid       
#> 11 Panthera leo 726453 NA           Panthera leo n… Helle… https:/… invalid     
#> 12 Panthera leo 726454 NA           Panthera leo s… J. N.… https:/… invalid     
#> 13 Panthera leo 933424 NA           Panthera leo n… de Bl… https:/… invalid     

# Search by common name with interactive selection
ct_check_name("Lion", search_type = "common_name")
#> # A tibble: 1,114 × 7
#>    search tsn   common_name scientific_name         author itis_url taxon_status
#>    <chr>  <chr> <chr>       <chr>                   <chr>  <chr>    <chr>       
#>  1 Lion   5272  NA          Nitzschia tryblionella… Arn. … https:/… not accepted
#>  2 Lion   10885 NA          Chilionema              NA     https:/… accepted    
#>  3 Lion   10886 NA          Chilionema ocellatum    Kuetz… https:/… accepted    
#>  4 Lion   10887 NA          Chilionema reptans      NA     https:/… accepted    
#>  5 Lion   11682 NA          Nemalion                Duby   https:/… accepted    
#>  6 Lion   11683 NA          Nemalion multifidum     NA     https:/… accepted    
#>  7 Lion   11684 NA          Nemalion helminthoides  Velle… https:/… accepted    
#>  8 Lion   11685 NA          Nemalion pulvinatum     NA     https:/… accepted    
#>  9 Lion   11686 NA          Nemalion virens         NA     https:/… accepted    
#> 10 Lion   11687 NA          Nemalion lubricum       Duby,… https:/… accepted    
#> # ℹ 1,104 more rows
# }

```
