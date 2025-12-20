# Manage Media Metadata

![Wildlife at Faro National Park,
Cameroon](https://zenodo.org/records/17978848/files/11030555.JPG)

Camera traps generate vast amounts of data, primarily in the form of
images or videos. While the visual content is the primary focus for
identifying species and behaviors, the files themselves contain a hidden
layer of crucial information: metadata. This embedded data serves as the
backbone for transforming raw media into a structured dataset, providing
the “when”, “where”, and “how” of each record.

## Media to Dataset

The first step in any camera-trap analysis pipeline is converting a
collection of image or video files into a structured dataset. This
process relies on metadata embedded within the media files. A single
image can contain **hundreds of metadata tags** (i.e. fields), but only
a subset is typically relevant for camera-trap studies.

For camera-trap data analysis, the most important tags fall into a few
core categories: **time**, **location**, **camera identity and
settings**, and **image identity**. Commonly used fields include:

- **DateTimeOriginal**: The exact date and time the image was captured;
  essential for analysing activity patterns and detection histories.
- **TimeZoneOffset / OffsetTimeOriginal**: Critical for avoiding
  time-shift errors when combining data from multiple cameras or
  regions.
- **GPSLatitude**, **GPSLongitude**
- **GPSAltitude** (optional)

Most analyses rely heavily on DateTimeOriginal, and incorrect camera
clocks are one of the most common sources of error in camera-trap
datasets. In addition, **many camera traps do not record GPS
information**; in such cases, camera locations are usually provided
separately (e.g. in deployment tables or filenames).

Because metadata are often incomplete or inconsistent, this step
typically involves **quality control and enrichment** rather than simple
extraction. This may include correcting timestamps (see
[`ct_correct_datetime()`](https://stangandaho.github.io/ct/reference/ct_correct_datetime.md)),
assigning missing coordinates, and linking images to external deployment
information. The outcome is a clean, consistent, and analysis-ready
dataset.

## Managing Metadata with `ct`

The `ct` package provides a suite of functions to not only read metadata
but also to actively manage and enrich it using **Hierarchical Subjects
(HS)**.

### Reading Metadata

The
[`ct_read_metadata()`](https://stangandaho.github.io/ct/reference/ct_read_metadata.md)
function is the primary tool for extracting information. It leverages
the [ExifTool](https://exiftool.org/) to parse standard tags and can
also structure hierarchical tags into a usable format. For demonstration
purposes, we use the image shown below, which can be downloaded
[here](https://zenodo.org/records/17978848/files/10200034.JPG?download=1).

![Kobus kob at Faro National Park,
Cameroon](https://zenodo.org/records/17978848/files/10200034.JPG)

As is typical for camera-trap images, basic information is overlaid
directly on the image, including the camera ID, ambient temperature (in
both Fahrenheit and Celsius), and the date and time of capture.

Using a single image, it would be possible to manually construct a
dataset by recording attributes such as the species present,
temperature, date, time, and location. However, doing this manually for
hundreds or thousands of images quickly becomes time-consuming and
error-prone. This is where metadata extraction becomes essential.

In the following sections, we demonstrate how the `ct` package can be
used to perform this extraction and convert raw camera-trap media into a
structured, analysis-ready dataset.

``` r
# Install the development version of the package
pak::pkg_install("stangandaho/ct")
# Load the package
library(ct)

# Read the metadata
ct_read_metadata(path = "10200034.JPG", tags = "all")
```

| SourceFile                                    | ExifToolVersion | FileName     | Directory                        | FileSize | ZoneIdentifier | FileModifyDate            | FileAccessDate            | FileCreateDate            | FilePermissions | FileType | FileTypeExtension | MIMEType   | ExifByteOrder | ImageDescription       | Make     | Model   | Orientation | XResolution | YResolution | ResolutionUnit | Software         | ModifyDate          | YCbCrPositioning | Copyright | ExposureTime | FNumber | ExposureProgram | ISO | ExifVersion | DateTimeOriginal    | CreateDate          | ComponentsConfiguration | CompressedBitsPerPixel | ShutterSpeedValue | ApertureValue | ExposureCompensation | MaxApertureValue | MeteringMode | LightSource | Flash | FocalLength | Warning                           | UserComment                                                | FlashpixVersion | ColorSpace | ExifImageWidth | ExifImageHeight | InteropIndex | InteropVersion | FileSource | SceneType | ExposureMode | WhiteBalance | DigitalZoomRatio | FocalLengthIn35mmFormat | SceneCaptureType | Sharpness | GPSVersionID | GPSLatitudeRef | GPSLongitudeRef | Compression | ThumbnailOffset | ThumbnailLength | MPFVersion | NumberOfImages | MPImageFlags | MPImageFormat | MPImageType | MPImageLength | MPImageStart | DependentImage1EntryNumber | DependentImage2EntryNumber | ImageWidth | ImageHeight | EncodingProcess | BitsPerSample | ColorComponents | YCbCrSubSampling | Aperture | ImageSize | Megapixels | ShutterSpeed | ThumbnailImage                                     | GPSLatitude | GPSLongitude | PreviewImage                                        | FocalLength35efl | GPSPosition               | LightValue |
|:----------------------------------------------|----------------:|:-------------|:---------------------------------|---------:|:---------------|:--------------------------|:--------------------------|:--------------------------|----------------:|:---------|:------------------|:-----------|:--------------|:-----------------------|:---------|:--------|------------:|------------:|------------:|---------------:|:-----------------|:--------------------|-----------------:|----------:|-------------:|--------:|----------------:|----:|------------:|:--------------------|:--------------------|:------------------------|:-----------------------|------------------:|--------------:|---------------------:|-----------------:|-------------:|------------:|------:|------------:|:----------------------------------|:-----------------------------------------------------------|----------------:|-----------:|---------------:|----------------:|:-------------|---------------:|-----------:|----------:|-------------:|-------------:|-----------------:|------------------------:|-----------------:|----------:|:-------------|:---------------|:----------------|------------:|----------------:|----------------:|-----------:|---------------:|-------------:|--------------:|------------:|--------------:|-------------:|---------------------------:|---------------------------:|-----------:|------------:|----------------:|--------------:|----------------:|:-----------------|---------:|:----------|-----------:|-------------:|:---------------------------------------------------|------------:|-------------:|:----------------------------------------------------|-----------------:|:--------------------------|-----------:|
| C:/Users/ganda/Downloads/camtest/10200034.JPG |           13.42 | 10200034.JPG | C:/Users/ganda/Downloads/camtest |  8558864 | Exists         | 2025:12:18 16:50:35+01:00 | 2025:12:18 16:50:35+01:00 | 2025:12:18 16:50:14+01:00 |          100666 | JPEG     | JPG               | image/jpeg | II            | P,L:F,40,24H,2 cmN,wbA | BUSHNELL | 119977C |           1 |          72 |          72 |              2 | BS977\_ 2003130B | 2020:10:20 13:16:09 |                2 |      2020 |        0.002 |     2.4 |               2 | 100 |         220 | 2020:10:20 13:16:09 | 2020:10:20 13:16:09 | 1 2 3 0                 | undef                  |         0.0020013 |      2.397812 |                    0 |         2.828427 |            2 |           0 |    16 |        7.45 | \[minor\] Unrecognized MakerNotes | 00,cds843:841,t126,p136:0183,c000:0000,ae103:0,10224:10000 |             100 |          1 |           7296 |            4104 | R98          |            100 |          3 |         1 |            0 |          288 |             1000 |                       0 |                0 |         0 | 2 0 0 0      | N              | E               |           6 |           34756 |            4124 |        100 |              2 |            8 |             0 |       65537 |         58493 |      8500371 |                          0 |                          0 |       7296 |        4104 |               0 |             8 |               3 | 2 1              |      2.4 | 7296 4104 |   29.94278 |        0.002 | (Binary data 4124 bytes, use -b option to extract) |    8.166705 |      12.9667 | (Binary data 58493 bytes, use -b option to extract) |             7.45 | 8.166705 12.9666966666667 |   11.49185 |

This single file contains 90 columns. However, not all of these fields
(i.e. columns) are relevant for every analysis. During metadata
extraction, you can filter the output to retain only the fields of
interest by using the `tags` argument.

A convenient first option is to use `tags = "standard"` (default), which
returns a predefined set of commonly used metadata fields.
Alternatively, you can explicitly specify the tags you want to extract.
For example, to extract only the date the image was captured and its
location information, you can do the following:

``` r
ct_read_metadata(
  path = "10200034.JPG",
  tags = c("DateTimeOriginal", "GPSLongitude", "GPSLatitude")
)
```

| SourceFile                                    | DateTimeOriginal    | GPSLongitude | GPSLatitude |
|:----------------------------------------------|:--------------------|-------------:|------------:|
| C:/Users/ganda/Downloads/camtest/10200034.JPG | 2020:10:20 13:16:09 |      12.9667 |    8.166705 |

The `path` argument can point to a single image file or to a directory
containing multiple images. If all images are located directly at the
root of the directory, metadata are extracted automatically. If the
images are stored within one or more subdirectories, you must set
`recursive = TRUE`. Otherwise, no files will be detected and an empty
tibble will be returned.

For advanced users requiring specific ExifTool features not covered by
the wrapper,
[`ct_exiftool_call()`](https://stangandaho.github.io/ct/reference/ct_exiftool_call.md)
allows direct access to the ExifTool command line interface from within
R.

### Hierarchical Subjects (HS)

As shown above, we can extract information stored in the metadata
written by the camera hardware. However, some key attributes are often
missing. For example, the species captured, as well as its age, sex, or
behaviour, are not recorded because the camera has no ability to
identify these characteristics. We may also be interested in additional
information such as habitat type or ambient temperature measured
independently.

If these attributes are required for a study, they must be added
manually for all captured images, which can be a time-consuming task.

A key feature of the `ct` package is its support for **hierarchical
subjects**. These are structured tags stored directly in the image
metadata using a `Parent|Child` format (e.g. `Species|Fox`,
`Sex|Female`). This approach allows users to store and manage customized
metadata consistently across large image collections.

**Why use Hierarchical Subjects?**  
- **Portability**: The data travels with the image. If you move the
file, you don’t lose the classification.  
- **Standardization**: The `Parent|Child` structure enforces a
consistent schema (e.g., always specifying “Species” vs. just “Fox”).  
- **Multi-dimensionality**: You can assign multiple attributes to a
single image (e.g., Species, Sex, Behavior) without complex external
lookup tables.  
The package offers three key functions to manage these tags:

1.  **[`ct_create_hs()`](https://stangandaho.github.io/ct/reference/ct_create_hs.md)**:
    Adds new hierarchical tags to an image.

``` r
# Add a species tag
ct_create_hs(path = "10200034.JPG", value = c("Species" = "Kobus_kob"))

# Add multiple tags at once
ct_create_hs(path = "10200034.JPG", 
             value = c("Species" = "Kobus_kob", 
                       "Count" = 1, 
                       "Habitat" = "Shrub_savanah"))
```

When an image contains multiple species, their names and corresponding
counts can be provided directly. For example:
`c("Species" = "Kobus_kob, Bubalus_bubalis", "Count" = "1, 2")`. This
indicates that the image contains **1 *Kobus kob*** and **2 *Bubalus
bubalis***.

``` r
ct_create_hs(path = "10200034.JPG", 
             value = c("Species" = "Kobus_kob, Bubalus_bubalis", 
                       "Count" = "1, 2", 
                       "Sex" = "Male, Unknown",
                       "Habitat" = "Shrub_savanah, Shrub_savanah"))
```

2.  **[`ct_get_hs()`](https://stangandaho.github.io/ct/reference/ct_get_hs.md)**:
    Reads the existing hierarchical tags.

``` r
ct_get_hs(path = "10200034.JPG")
#> [1] "Species|Kobus_kob"       "Count|1"                 "Sex|Male"               
#> [4] "Habitat|Shrub_savanah"   "Species|Bubalus_bubalis" "Count|2"                
#> [7] "Sex|Unknown" 
```

3.  **[`ct_remove_hs()`](https://stangandaho.github.io/ct/reference/ct_remove_hs.md)**:
    Removes specific tags or clears them all.

``` r
# Remove just the Count tag
ct_remove_hs(path = "10200034.JPG", hierarchy = c("Count" = "1"))
```

Now that you understand how hierarchical subjects are managed, you can
include them directly in the extracted metadata by setting
`parse_hs = TRUE` in the
[`ct_read_metadata()`](https://stangandaho.github.io/ct/reference/ct_read_metadata.md)
function. This option parses the `HierarchicalSubject` field into
separate columns, where each parent category becomes its own column in
the resulting tibble.

``` r
ct_read_metadata(
  path = "10200034.JPG",
  parse_hs = TRUE
)
```

| SourceFile                                    | FileName     | Make     | Model   | DateTimeOriginal    | FileModifyDate            | GPSLongitude | GPSLatitude | GPSLongitudeRef | GPSLatitudeRef | Orientation | HierarchicalSubject                                                                                               | Species         | Count | Sex     | Habitat       |
|:----------------------------------------------|:-------------|:---------|:--------|:--------------------|:--------------------------|-------------:|------------:|:----------------|:---------------|------------:|:------------------------------------------------------------------------------------------------------------------|:----------------|:------|:--------|:--------------|
| C:/Users/ganda/Downloads/camtest/10200034.JPG | 10200034.JPG | BUSHNELL | 119977C | 2020:10:20 13:16:09 | 2020:10:20 13:16:09+01:00 |      12.9667 |    8.166705 | E               | N              |           1 | Species\|Kobus_kob, Count\|1, Sex\|Male, Habitat\|Shrub_savanah, Species\|Bubalus_bubalis, Count\|2, Sex\|Unknown | Kobus_kob       | 1     | Male    | Shrub_savanah |
| C:/Users/ganda/Downloads/camtest/10200034.JPG | 10200034.JPG | BUSHNELL | 119977C | 2020:10:20 13:16:09 | 2020:10:20 13:16:09+01:00 |      12.9667 |    8.166705 | E               | N              |           1 | Species\|Kobus_kob, Count\|1, Sex\|Male, Habitat\|Shrub_savanah, Species\|Bubalus_bubalis, Count\|2, Sex\|Unknown | Bubalus_bubalis | 2     | Unknown | NA            |

Adding or removing hierarchical subjects programmatically can be
difficult to manage, especially when working with hundreds or thousands
of images. Manually locating an image, providing its path to
[`ct_create_hs()`](https://stangandaho.github.io/ct/reference/ct_create_hs.md),
and specifying attributes for each file quickly becomes impractical.

The purpose of these functions is to provide a wrapper with a graphical
user interface (GUI) that simplifies this process and makes managing
hierarchical subjects more efficient and user-friendly.
