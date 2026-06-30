test_that("ct_solartime adds a solar-time column", {
  skip_if_not_installed("sf")

  data(penessoulou)

  st <- penessoulou %>%
    dplyr::filter(project == "Last", species == "Erythrocebus patas") %>%
    ct_independence(species_column = species, datetime = datetimes,
                    threshold = 300, format = "%Y-%m-%d %H:%M:%S") %>%
    ct_solartime(date = datetime, longitude = longitude, latitude = latitude,
                 crs = "EPSG:32631", time_zone = 1)

  expect_s3_class(st, "data.frame")
  expect_true("solar" %in% names(st))
  expect_true(all(st$solar >= 0 & st$solar <= 2 * pi, na.rm = TRUE))
})
