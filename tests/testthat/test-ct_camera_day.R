test_that("ct_camera_day runs on observation and deployment data", {
  obs <- data.frame(
    species = c("Deer", "Deer", "Fox", "Deer"),
    count = c(2, 1, 1, 3),
    datetime = c("2023-06-01 08:12:00", "2023-06-01 15:30:00",
                 "2023-06-01 21:10:00", "2023-06-02 06:45:00"),
    location_id = c("Cam1", "Cam1", "Cam1", "Cam1"),
    stringsAsFactors = FALSE
  )
  dep <- data.frame(
    location_id = "Cam1",
    deploy_start = "2023-06-01 00:00:00",
    deploy_end = "2023-06-03 23:59:59",
    stringsAsFactors = FALSE
  )

  out <- ct_camera_day(
    data = obs,
    deployment_data = dep,
    datetime_column = "datetime",
    species_column = "species",
    size_column = "count",
    deployment_column = "location_id",
    format = "%Y-%m-%d %H:%M:%S",
    start_column = "deploy_start",
    end_column = "deploy_end"
  )

  expect_false(is.null(out))
  expect_s3_class(out, "data.frame")
})
