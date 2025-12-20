# Estimate distance from camera trap to animal

Calculates the radial distance between a camera trap and an animal
detected in an image using geometric principles and reference markers.

## Usage

``` r
ct_camtrap_animal_distance(fov, forward_distance, ref_halfwidth, animal_offset)
```

## Arguments

- fov:

  Numeric. The camera's horizontal field of view in degrees. Common
  values range from 30° to 60° depending on camera model.

- forward_distance:

  Numeric. The forward distance (in meters) from the camera to the
  animal along the central axis, estimated using reference markers
  visible in the image.

- ref_halfwidth:

  Numeric. The measured half-width of the camera's field of view in the
  image at distance `forward_distance`, in any unit (e.g., cm, pixels).
  This is typically measured with a ruler on the photo or using image
  analysis software.

- animal_offset:

  Numeric. The measured horizontal offset of the animal from the central
  vertical line in the image, in the same units as `ref_halfwidth`.

## Value

Numeric. The estimated radial distance (in meters) from the camera to
the animal.

## Examples

``` r
distance <- ct_camtrap_animal_distance(
  fov = 35,
  forward_distance = 7.5,
  ref_halfwidth = 12,
  animal_offset = 3
)
```
