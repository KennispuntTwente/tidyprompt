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
