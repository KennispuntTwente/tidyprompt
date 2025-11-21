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

test_that("add_image() converts recordedplot objects to images", {
  skip_on_cran()
  skip_on_ci()

  tmp_img <- tempfile(fileext = ".png")
  on.exit(unlink(tmp_img), add = TRUE)

  grDevices::png(tmp_img)
  recorded <- tryCatch({
    plot(1:5, 1:5)
    grDevices::recordPlot()
  }, error = function(e) e)
  grDevices::dev.off()

  skip_if(inherits(recorded, "error"), "Current device cannot record plots")
  skip_if_not(inherits(recorded, "recordedplot"))
  # In headless CI environments, png() might produce empty files or fail to record properly
  if (file.exists(tmp_img) && file.size(tmp_img) == 0) {
    skip("png() device produced empty file; skipping plot test")
  }

  tp <- tidyprompt("Describe the chart")
  tp <- add_image(tp, image = recorded)

  wraps <- get_prompt_wraps(tp, order = "default")
  prov <- llm_provider_fake()
  for (pw in wraps) {
    if (!is.null(pw$parameter_fn)) {
      prov$set_parameters(pw$parameter_fn(prov))
    }
  }

  parts <- prov$parameters$.add_image_parts
  expect_true(length(parts) >= 1)
  last_part <- parts[[length(parts)]]
  expect_identical(last_part$mime, "image/png")
  expect_identical(last_part$source, "b64")
  expect_true(nchar(last_part$data) > 100)
})

test_that("add_image() accepts ggplot objects when available", {
  skip_if_not_installed("ggplot2")
  skip_on_ci()
  skip_on_cran()

  plt <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point()

  skip_if_not(inherits(plt, "ggplot"), "ggplot object creation failed to produce 'ggplot' class")

  # Check if png device is working (required for rasterizing ggplot)
  tmp_check <- tempfile()
  png_works <- tryCatch({
    grDevices::png(tmp_check)
    grDevices::dev.off()
    file.exists(tmp_check)
  }, error = function(e) FALSE)
  unlink(tmp_check)
  skip_if_not(png_works, "png() device is not available or working")

  tp <- tidyprompt("Describe the scatterplot")
  tp <- add_image(tp, image = plt)

  wraps <- get_prompt_wraps(tp, order = "default")
  prov <- llm_provider_fake()
  for (pw in wraps) {
    if (!is.null(pw$parameter_fn)) {
      prov$set_parameters(pw$parameter_fn(prov))
    }
  }

  parts <- prov$parameters$.add_image_parts
  expect_true(length(parts) >= 1)
  last_part <- parts[[length(parts)]]
  expect_identical(last_part$mime, "image/png")
  expect_identical(last_part$source, "b64")
  expect_true(nchar(last_part$data) > 100)
})
