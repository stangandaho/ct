test_that("ct_solartime adds a solar-time column", {
  skip_if_not_installed("sf")

  f <- system.file("penessoulou_season1.csv", package = "ct")
  skip_if(f == "", "bundled CSV not found")

  st <- read.csv(f) %>%
    dplyr::filter(species == "Erythrocebus patas") %>%
    ct_independence(species_column = species, datetime = datetimes,
                    threshold = 300, format = "%Y-%m-%d %H:%M:%S") %>%
    ct_solartime(date = datetime, longitude = longitude, latitude = latitude,
                 crs = "EPSG:32631", time_zone = 1)

  expect_s3_class(st, "data.frame")
  expect_true("solar" %in% names(st))
  expect_true(all(st$solar >= 0 & st$solar <= 2 * pi, na.rm = TRUE))
})
