test_that("llm_provider_ellmer forwards add_image URL parts via ellmer helpers", {
  skip_if_not_installed("ellmer")

  rec_env <- new.env(parent = emptyenv())
  rec_env$urls <- character()

  original_content_image_url <- ellmer::content_image_url

  testthat::local_mocked_bindings(
    content_image_url = function(url, detail = "auto", ...) {
      rec_env$urls <- c(rec_env$urls, url)
      original_content_image_url(url = url, detail = detail, ...)
    },
    .package = "ellmer"
  )

  chat <- fake_ellmer_chat()
  prov <- llm_provider_ellmer(
    chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  tp <- tidyprompt("Describe the image") |>
    add_image("https://example.com/cat.jpg")

  result <- send_prompt(tp, prov, return_mode = "full", verbose = FALSE)
  expect_true("https://example.com/cat.jpg" %in% rec_env$urls)

  # After multimodal fix, content objects are passed as args to chat(), not pre-seeded as turns.
  # Access the cloned chat's last_method via the returned ellmer_chat.
  used_chat <- result$ellmer_chat
  expect_true(length(used_chat$last_method$args) >= 2)
})

test_that("llm_provider_ellmer falls back to ellmer content when content_image_file fails", {
  skip_if_not_installed("ellmer")

  testthat::local_mocked_bindings(
    content_image_file = function(...) {
      stop("simulated content_image_file failure")
    },
    .package = "ellmer"
  )

  chat <- fake_ellmer_chat()
  prov <- llm_provider_ellmer(
    chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  img <- tempfile(fileext = ".png")
  grDevices::png(img)
  plot(1:2, 1:2)
  grDevices::dev.off()
  on.exit(unlink(img), add = TRUE)

  result <- tidyprompt("Describe the image") |>
    add_image(img) |>
    send_prompt(prov, return_mode = "full", verbose = FALSE)

  used_chat <- result$ellmer_chat
  image_arg <- used_chat$last_method$args[[2]]

  expect_true(.tp_is_ellmer_content(image_arg))
})

test_that("add_image preserves MIME type from ellmer ContentImageInline", {
  skip_if_not_installed("ellmer")
  skip_if_not_installed("S7")
  skip_if_not(
    exists(
      "ContentImageInline",
      envir = asNamespace("ellmer"),
      inherits = FALSE
    ),
    "ContentImageInline not available in this ellmer version"
  )

  # Create an inline JPEG content object via ellmer
  # ContentImageInline has props: type (MIME), data (base64)
  inline <- ellmer::ContentImageInline(
    type = "image/jpeg",
    data = paste0(rep("A", 200), collapse = "")
  )

  part <- .tp_normalize_image_input(inline)
  expect_equal(part$mime, "image/jpeg")
  expect_equal(part$source, "b64")
})

test_that("build_image_content cleans up temp files for base64 images", {
  skip_if_not_installed("ellmer")

  chat <- fake_ellmer_chat()
  prov <- llm_provider_ellmer(
    chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  # Create a real PNG image file to use as input
  img <- tempfile(fileext = ".png")
  grDevices::png(img)
  plot(1:2, 1:2)
  grDevices::dev.off()
  on.exit(unlink(img), add = TRUE)

  before <- list.files(tempdir(), full.names = TRUE)

  tp <- tidyprompt("Describe the image") |>
    add_image(img)

  send_prompt(tp, prov, verbose = FALSE)

  after <- list.files(tempdir(), full.names = TRUE)
  leaked <- setdiff(after, before)

  expect_length(leaked, 0L)
})
