# Hierarchical-subject metadata round trip. Runs on a TEMP COPY of the bundled
# image so the packaged file is never modified. Requires ExifTool.

has_exiftool <- function() {
  # find_exiftool() returns NULL (not an error) when ExifTool is absent, so a
  # try()-based check is not enough. Actually invoke ExifTool: this mirrors what
  # ct_exiftool_call() needs, so the skip is accurate on machines (e.g. CI)
  # where ExifTool is not installed.
  isTRUE(tryCatch({
    v <- ct_exiftool_call(args = "-ver", intern = TRUE)
    length(v) > 0 && nzchar(v[1])
  }, error = function(e) FALSE))
}

temp_image <- function() {
  img <- file.path(system.file("img", package = "ct"), "large.jpeg")
  skip_if(!file.exists(img), "bundled example image not found")
  tmp <- tempfile(fileext = ".jpeg")
  file.copy(img, tmp, overwrite = TRUE)
  tmp
}

test_that("ct_create_hs writes and ct_get_hs reads a hierarchical subject", {
  skip_if(!has_exiftool(), "ExifTool not available")
  tmp <- temp_image()
  on.exit(unlink(c(tmp, paste0(tmp, "_original"))), add = TRUE)

  ct_create_hs(path = tmp, value = c("Species" = "Vulture"))
  got <- as.character(ct_get_hs(path = tmp))
  expect_true(any(grepl("Species\\|Vulture", got)))
})

test_that("ct_get_hs can return a tibble", {
  skip_if(!has_exiftool(), "ExifTool not available")
  tmp <- temp_image()
  on.exit(unlink(c(tmp, paste0(tmp, "_original"))), add = TRUE)

  ct_create_hs(path = tmp, value = c("Species" = "Vulture", "Location" = "Africa"))
  tb <- ct_get_hs(path = tmp, into_tibble = TRUE)
  expect_s3_class(tb, "data.frame")
})

test_that("ct_remove_hs removes a specific hierarchy, then all", {
  skip_if(!has_exiftool(), "ExifTool not available")
  tmp <- temp_image()
  on.exit(unlink(c(tmp, paste0(tmp, "_original"))), add = TRUE)

  ct_create_hs(path = tmp, value = c("Species" = "Vulture", "Location" = "Africa"))

  # Remove just one hierarchy: the other must remain.
  ct_remove_hs(path = tmp, hierarchy = c("Species" = "Vulture"))
  got <- as.character(ct_get_hs(path = tmp))
  expect_false(any(grepl("Species\\|Vulture", got)))
  expect_true(any(grepl("Location\\|Africa", got)))

  # Remove everything that remains.
  expect_no_error(ct_remove_hs(path = tmp))
})

test_that("ct_create_hs validates the hierarchical-subject format", {
  skip_if(!has_exiftool(), "ExifTool not available")
  tmp <- temp_image()
  on.exit(unlink(c(tmp, paste0(tmp, "_original"))), add = TRUE)

  expect_error(ct_create_hs(path = tmp))                       # no value
  expect_error(ct_create_hs(path = tmp, value = c("Species"))) # unnamed
})
