test_that("ct_to_occupancy returns presence-absence detection windows", {
  data <- data.frame(
    date = c("01-01-2023", "03-01-2023", "10-01-2023", "15-01-2023"),
    site = c("A", "A", "B", "B"),
    species = c("Tiger", "Tiger", "Deer", "Deer"),
    count = c(1, 2, 3, 1)
  )

  occ <- ct_to_occupancy(
    data,
    date_column = date,
    format = "%d-%m-%Y",
    site_column = site,
    species_column = species,
    size_column = count,
    by_day = 7,
    presence_absence = TRUE
  )

  expect_s3_class(occ, "data.frame")
  num_vals <- unlist(occ[vapply(occ, is.numeric, logical(1))])
  expect_true(all(num_vals %in% c(0, 1) | is.na(num_vals)))
})

test_that("ct_to_occupancy keeps counts when presence_absence = FALSE", {
  data <- data.frame(
    date = c("01-01-2023", "03-01-2023", "10-01-2023", "15-01-2023"),
    site = c("A", "A", "B", "B"),
    species = c("Tiger", "Tiger", "Deer", "Deer"),
    count = c(1, 2, 3, 1)
  )
  # The two A/Tiger records fall in the same 7-day window, so its aggregated
  # count is 3 (> 1), confirming counts are retained rather than 0/1.
  occ <- ct_to_occupancy(data, date_column = date, format = "%d-%m-%Y",
                         site_column = site, species_column = species,
                         size_column = count, by_day = 7, presence_absence = FALSE)
  num_vals <- unlist(occ[vapply(occ, is.numeric, logical(1))])
  expect_true(any(num_vals > 1, na.rm = TRUE))
})
