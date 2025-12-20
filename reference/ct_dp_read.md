# Read camera trap data package

Reads [Camera Trap Data Package](https://camtrap-dp.tdwg.org) (Camtrap
DP) dataset into memory.

## Usage

``` r
ct_dp_read(file)
```

## Arguments

- file:

  Path or URL to a `datapackage.json` file.

## Value

Camera Trap Data Package object.

## Assign taxonomic information

Camtrap DP metadata has a `taxonomic` property that can contain extra
information for each `scientificName` found in observations. Such
information can include higher taxonomy (`family`, `order`, etc.) and
vernacular names in multiple languages.

This function **will automatically include this taxonomic information in
observations**, as extra columns starting with `taxon.`.

## Assign eventIDs

Observations can contain two classifications at two levels:

**Media-based** observations (`observationLevel = "media"`) are based on
a single media file and are directly linked to it via `mediaID`.

**Event-based** observations (`observationLevel = "event"`) are based on
an event, defined as a combination of `eventID`, `eventStart` and
`eventEnd`. This event can consist of one or more media files, but is
not directly linked to these.

This function **will automatically assign `eventID`s to media**, using
`media.deploymentID = event.deploymentID` and
`eventStart <= media.timestamp <= eventEnd`. Note that this can result
in media being linked to multiple events (and thus being duplicated),
for example when events and sub-events were defined.

## Examples

``` r
# \donttest{
file <- "https://raw.githubusercontent.com/tdwg/camtrap-dp/1.0/example/datapackage.json"
dp <- ct_dp_read(file)
# }
```
