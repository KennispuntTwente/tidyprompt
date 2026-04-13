testthat::test_that("llm_provider_ellmer supports multimodal structured output", {
  testthat::skip_if_not_installed("ellmer")

  provider <- llm_provider_ellmer(fake_ellmer_chat(), verbose = FALSE)
  provider$parameters$.ellmer_structured_type <- list(schema = "stub")
  provider$parameters$.add_image_parts <- list(
    list(
      source = "url",
      data = "https://example.com/image.png",
      detail = "low"
    )
  )

  chat_history <- data.frame(
    role = "user",
    content = "Hello world",
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  fake_chat <- provider$ellmer_chat

  testthat::expect_equal(fake_chat$last_method$method, "chat_structured")
  # Content objects passed directly (not pre-seeded as turns + empty prompt)
  testthat::expect_true(length(fake_chat$last_method$args) >= 2)
  # No prior turns should be pre-seeded (single-message history)
  testthat::expect_length(fake_chat$last_method$turns, 0)
  testthat::expect_match(
    tail(result$completed$content, 1),
    '"result":"ok"'
  )
})


testthat::test_that("llm_provider_ellmer streams multimodal prompts when supported", {
  testthat::skip_if_not_installed("coro")
  testthat::skip_if_not_installed("ellmer")

  provider <- llm_provider_ellmer(
    fake_ellmer_chat(),
    parameters = list(stream = TRUE),
    verbose = FALSE
  )
  provider$parameters$.add_image_parts <- list(
    list(
      source = "url",
      data = "https://example.com/image.png",
      detail = "low"
    )
  )

  chunks <- character()
  provider$stream_callback <- function(chunk, meta) {
    chunks <<- c(chunks, chunk)
  }

  chat_history <- data.frame(
    role = "user",
    content = "Ping",
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  fake_chat <- provider$ellmer_chat

  testthat::expect_equal(fake_chat$last_method$method, "stream")
  # Content objects passed directly (not pre-seeded + empty prompt)
  testthat::expect_true(length(fake_chat$last_method$args) >= 2)
  testthat::expect_equal(
    result$completed$content[nrow(result$completed)],
    "chunk-end"
  )
  testthat::expect_true(length(chunks) >= 2)
})
