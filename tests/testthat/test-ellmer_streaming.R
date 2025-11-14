test_that("llm_provider_ellmer streaming uses stream_callback and accumulates text", {
  skip_if_not_installed("ellmer")

  # Build a minimal ellmer chat that supports streaming
  ch <- ellmer::chat_openai()

  # Prefer a very small model / cheap model if configured
  model <- Sys.getenv("TIDYPROMPT_OPENAI_CHAT_MODEL", unset = NA_character_)
  if (!is.na(model)) {
    ch <- ch$set_model(model)
  }

  # Force streaming on the underlying chat if such a knob exists; we rely on
  # ch$stream() being available for chat_openai() in recent ellmer versions.
  expect_true(is.function(ch$stream))

  provider <- llm_provider_ellmer(ch, verbose = FALSE)

  # Enable streaming via parameters list
  provider$parameters$stream <- TRUE

  # Tracking env for the callback
  seen <- new.env(parent = emptyenv())
  seen$n_calls <- 0L
  seen$partial_values <- character()

  provider$stream_callback <- function(chunk, meta) {
    seen$n_calls <- seen$n_calls + 1L
    seen$partial_values <- c(seen$partial_values, meta$partial_response)

    # Basic sanity on metadata
    expect_equal(meta$api_type, "ellmer")
    expect_equal(meta$endpoint, "chat")
    expect_true(is.list(meta$chat_history))
  }

  chat_history <- data.frame(
    role = "user",
    content = "Reply with exactly the single word: pong",
    stringsAsFactors = FALSE
  )

  out <- provider$complete_chat(list(chat_history = chat_history))
  expect_true(nrow(out$completed) == 2L)
  assistant <- utils::tail(out$completed$content, 1)
  reply <- tolower(trimws(assistant))

  expect_true(seen$n_calls > 0L)
  expect_true(nchar(reply) > 0)
})
