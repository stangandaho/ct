test_that("ct_camtrap_animal_distance returns a positive numeric distance", {
  d <- ct_camtrap_animal_distance(
    fov = 35,
    forward_distance = 7.5,
    ref_halfwidth = 12,
    animal_offset = 3
  )
  expect_type(d, "double")
  expect_length(d, 1)
  expect_gt(d, 0)
})

test_that("ct_camtrap_animal_distance grows with the forward distance", {
  near <- ct_camtrap_animal_distance(fov = 35, forward_distance = 5,
                                     ref_halfwidth = 12, animal_offset = 3)
  far <- ct_camtrap_animal_distance(fov = 35, forward_distance = 10,
                                    ref_halfwidth = 12, animal_offset = 3)
  expect_gt(far, near)
})
