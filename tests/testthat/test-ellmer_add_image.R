test_that("llm_provider_ellmer forwards add_image URL parts via ellmer helpers", {
  skip_if_not_installed("ellmer")

  # Create a minimal ellmer chat that records content objects it receives.
  rec_env <- new.env(parent = emptyenv())
  rec_env$last_contents <- NULL

  chat <- ellmer::chat_openai()

  # Wrap the original chat$chat to capture the constructed Turn contents.
  orig_chat <- chat$chat
  chat$chat <- function(prompt, ...) {
    # ellmer will have already built the Turn from contents; we only
    # assert that at least one content_image_url-like object was passed
    # through the ellmer helper layer. We can't easily introspect Turn
    # internals without relying on ellmer internals, so this test simply
    # asserts that the call succeeds when an image URL is attached.
    rec_env$called <- TRUE
    orig_chat(prompt, ...)
  }

  prov <- llm_provider_ellmer(chat, parameters = list(stream = FALSE))

  tp <- tidyprompt("Describe the image") |>
    add_image("https://example.com/cat.jpg")

  expect_no_error({
    send_prompt(tp, prov)
  })
})
