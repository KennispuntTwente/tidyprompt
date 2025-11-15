test_that("add_image() accumulates image parts via parameter_fn", {
  tp <- tidyprompt("Describe the picture")
  tp <- add_image(tp, image = "data:image/png;base64,AAAA")
  tp <- add_image(tp, image = "https://example.com/cat.jpg")

  wraps <- get_prompt_wraps(tp, order = "default")
  expect_true(length(wraps) >= 1)

  prov <- llm_provider_fake()
  # Apply parameter_fns as send_prompt would
  for (pw in wraps) {
    if (!is.null(pw$parameter_fn)) {
      prov$set_parameters(pw$parameter_fn(prov))
    }
  }

  parts <- prov$parameters$.add_image_parts
  expect_true(is.list(parts))
  expect_equal(length(parts), 2)
  expect_setequal(unique(vapply(parts, function(p) p$source, character(1))), c("b64", "url"))
})
