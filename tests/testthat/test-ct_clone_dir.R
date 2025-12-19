test_that("ct_clone_dir clones directory structure correctly", {
  src <- tempfile("source_dir")
  dir.create(src)
  dir.create(file.path(src, "A"))
  dir.create(file.path(src, "A", "B"))
  dir.create(file.path(src, "C"))

  # Add a dummy file (should not be copied)
  file.create(file.path(src, "A", "file.txt"))

  dst <- tempfile("destination_dir")
  dir.create(dst)

  # Clone
  ct_clone_dir(from = src, to = dst)

  # List directories in destination
  dst_dirs <- list.dirs(dst, full.names = FALSE, recursive = TRUE)
  src_dirs <- list.dirs(src, full.names = FALSE, recursive = TRUE)

  # Expect the same directory structure (excluding files)
  expect_setequal(dst_dirs, src_dirs)

  # Ensure no files copied
  expect_length(list.files(dst, recursive = TRUE, pattern = "\\.txt$"), 0)

  # Clean up
  unlink(c(src, dst), recursive = TRUE)
})

test_that("ct_clone_dir handles non-existent source gracefully", {
  src <- tempfile("no_such_dir")
  dst <- tempfile("destination_dir")
  dir.create(dst)

  expect_error(ct_clone_dir(from = src, to = dst))
  unlink(dst, recursive = TRUE)
})

test_that("ct_clone_dir errors if destination does not exist", {
  src <- tempfile("source_dir")
  dir.create(src)
  dst <- tempfile("no_such_dir")

  expect_error(ct_clone_dir(from = src, to = dst))
  unlink(src, recursive = TRUE)
})
