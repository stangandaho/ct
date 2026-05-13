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

A Camera Trap Data Package object.

## Taxonomic information

Camtrap DP metadata has a `taxonomic` property that can contain extra
information for each `scientificName` found in observations. Such
information can include higher taxonomy (`family`, `order`, etc.) and
vernacular names in multiple languages.

The `read_camtrapdp()` function **will automatically include this
taxonomic information in observations**, as extra columns starting with
`taxon.`. It will then update the `taxonomic` scope in the metadata to
the unique
[`taxa()`](https://inbo.github.io/camtrapdp/reference/taxa.html) found
in the data.

## Events

Observations can contain classifications at two levels:

- **Media-based** observations (`observationLevel = "media"`) are based
  on a single media file and are directly linked to it via `mediaID`.

- **Event-based** observations (`observationLevel = "event"`) are based
  on an event, defined as a combination of `eventID`, `eventStart` and
  `eventEnd`. This event can consist of one or more media files, but is
  not directly linked to these.

The `read_camtrapdp()` function **will automatically assign `eventID`s
to media**, using `media.deploymentID = observations.deploymentID` and
`observations.eventStart <= media.timestamp <= observations.eventEnd`.
Note that this can result in media being linked to multiple events (and
thus being duplicated), for example when events and sub-events were
defined.

## Examples

``` r
# \donttest{
file <- "https://raw.githubusercontent.com/tdwg/camtrap-dp/1.0/example/datapackage.json"
dp <- ct_dp_read(file)
# }
```
