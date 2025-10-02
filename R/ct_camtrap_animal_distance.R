#' Estimate distance from camera trap to animal
#'
#' @description
#' Calculates the radial distance between a camera trap and an animal detected
#' in an image using geometric principles and reference markers.
#'
#'
#' @param fov Numeric. The camera's horizontal field of view in degrees.
#'   Common values range from 30° to 60° depending on camera model.
#' @param forward_distance Numeric. The forward distance (in meters) from the camera to the
#'   animal along the central axis, estimated using reference markers visible
#'   in the image.
#' @param ref_halfwidth Numeric. The measured half-width of the camera's field of view
#'   in the image at distance `forward_distance`, in any unit (e.g., cm, pixels). This is
#'   typically measured with a ruler on the photo or using image analysis software.
#' @param animal_offset Numeric. The measured horizontal offset of the animal from the
#'   central vertical line in the image, in the same units as `ref_halfwidth`.
#'
#' @return Numeric. The estimated radial distance (in meters) from the camera
#'   to the animal.
#'
#' @examples
#' distance <- ct_camtrap_animal_distance(
#'   fov = 35,
#'   forward_distance = 7.5,
#'   ref_halfwidth = 12,
#'   animal_offset = 3
#' )
#'
#' @export
ct_camtrap_animal_distance <- function(fov,
                                       forward_distance,
                                       ref_halfwidth,
                                       animal_offset) {
  # Convert field of view to radians
  fov_rad <- fov * pi / 180

  # Compute maximum horizontal extent at distance y
  Xmax <- forward_distance * tan(fov_rad / 2)

  # Scale animal offset using rule of three
  x <- (animal_offset / ref_halfwidth) * Xmax

  # Apply Pythagoras
  r <- sqrt(x^2 + forward_distance^2)

  return(r)
}
