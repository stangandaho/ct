# Rarefaction / extrapolation via iNEXT (optional dependency).

test_that("ct_inext returns an iNEXT object and ct_plot_inext a ggplot", {
  skip_if_not_installed("iNEXT")

  f <- system.file("penessoulou_season1.csv", package = "ct")
  skip_if(f == "", "bundled CSV not found")

  camdata <- read.csv(f) %>%
    dplyr::mutate(site = "pene") %>%
    ct_independence(species_column = species, site_column = camera,
                    datetime = datetimes, threshold = 60,
                    format = "%Y-%m-%d %H:%M:%S")

  camday <- ct_camera_day(data = camdata, deployment_column = camera,
                          datetime_column = datetime, species_column = species,
                          size_column = number)

  ie <- ct_inext(data = camday, diversity_order = c(0, 1, 2),
                 species_column = species, site_column = camera,
                 size_column = number)
  expect_s3_class(ie, "iNEXT")

  p <- suppressWarnings(ct_plot_inext(ie))
  expect_s3_class(p, "ggplot")
})
