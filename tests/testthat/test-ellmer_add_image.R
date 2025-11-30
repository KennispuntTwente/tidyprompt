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

  expect_no_error(send_prompt(tp, prov))
  expect_true("https://example.com/cat.jpg" %in% rec_env$urls)

  turn <- chat$last_method$turns[[length(chat$last_method$turns)]]
  turn_contents <- tryCatch(
    {
      if (base::isS4(turn) && "contents" %in% methods::slotNames(turn)) {
        methods::slot(turn, "contents")
      } else if (
        inherits(turn, "S7_object") && requireNamespace("S7", quietly = TRUE)
      ) {
        props <- S7::props(turn)
        props[["contents"]] %||% list()
      } else if (
        !inherits(turn, "S7_object") &&
          !base::isS4(turn) &&
          !is.null(turn[["contents"]])
      ) {
        turn[["contents"]]
      } else {
        list()
      }
    },
    error = function(e) list()
  )
  expect_true(length(turn_contents) >= 2)
})
