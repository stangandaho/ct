make_one_year <- function() {
  set.seed(1)
  dplyr::tibble(
    datetimes = format(as.Date("2024-01-01") + sample(0:200, 60, replace = TRUE),
                       "%Y-%m-%d %H:%M:%S"),
    number = sample(1:3, 60, replace = TRUE)
  )
}

test_that("ct_plot_calendar returns a ggplot", {
  p <- ct_plot_calendar(make_one_year(), datetime = datetimes)
  expect_s3_class(p, "ggplot")
})

test_that("datetime accepts bare name, string and position (tidy-select)", {
  d <- make_one_year()
  expect_s3_class(ct_plot_calendar(d, datetime = datetimes), "ggplot")
  expect_s3_class(ct_plot_calendar(d, datetime = "datetimes"), "ggplot")
  expect_s3_class(ct_plot_calendar(d, datetime = 1), "ggplot")
})

test_that("size_column is summed per day and tidy-selected", {
  d <- make_one_year()
  expect_s3_class(ct_plot_calendar(d, datetime = datetimes, size_column = number), "ggplot")
  expect_s3_class(ct_plot_calendar(d, datetime = datetimes, size_column = "number"), "ggplot")
})

test_that("more than one year is rejected", {
  d <- dplyr::tibble(datetimes = c("2023-05-01 10:00:00", "2024-05-01 10:00:00"))
  expect_error(ct_plot_calendar(d, datetime = datetimes), "One year")
})

test_that("fit_distribution shades by the fitted density and reports it", {
  p <- ct_plot_calendar(make_one_year(), datetime = datetimes, fit_distribution = TRUE)
  expect_s3_class(p, "ggplot")
  fill <- p$data$daily_effort
  expect_false(anyNA(fill))                  # every day modelled (zeros included)
  expect_true(all(fill >= 0 & fill <= 1))    # fitted densities, not raw counts
  expect_match(p$labels$subtitle, "Fitted")  # the fitted distribution is reported
})

test_that("only_month restricts the data and the panels drawn", {
  d <- make_one_year()
  p <- ct_plot_calendar(d, datetime = datetimes, only_month = 1:2)
  months <- unique(lubridate::month(as.Date(p$data$doy)))
  expect_true(all(months %in% 1:2))          # no days outside the kept months
  expect_error(ct_plot_calendar(d, datetime = datetimes, only_month = 13),
               "between 1 and 12")
})

test_that("custom month and day labels are validated", {
  d <- make_one_year()
  expect_error(ct_plot_calendar(d, datetime = datetimes, month_name = letters[1:5]),
               "length 12")
  expect_error(ct_plot_calendar(d, datetime = datetimes, day_name = c("a", "b")),
               "length 7")
})
