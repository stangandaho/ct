library(testthat)
library(shiny)

# Test suite for ct_app function
test_that("ct_app function exists and is exported", {
  expect_true(exists("ct_app"))
  expect_true(is.function(ct_app))
})

test_that("ct_app has correct function signature", {
  # Check that function takes no required parameters
  args <- formals(ct_app)
  expect_equal(length(args), 0)
})

test_that("system.file returns valid app directory path", {
  app_dir <- system.file("app", package = "ct")

  # Skip test if package is not installed or app directory doesn't exist
  skip_if(app_dir == "", "ct package app directory not found")

  expect_true(nzchar(app_dir))
  expect_true(dir.exists(app_dir))
})

test_that("required app files exist in app directory", {
  app_dir <- system.file("app", package = "ct")
  skip_if(app_dir == "", "ct package app directory not found")

  # Check for typical Shiny app files (at least one should exist)
  ui_file <- file.path(app_dir, "ui.R")
  server_file <- file.path(app_dir, "server.R")
  app_file <- file.path(app_dir, "app.R")

  # At least one of these should exist for a valid Shiny app
  has_shiny_files <- file.exists(ui_file) || file.exists(server_file) || file.exists(app_file)
  expect_true(has_shiny_files,
              info = "At least one of ui.R, server.R, or app.R should exist")
})
