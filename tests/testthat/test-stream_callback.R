test_that("request_llm_provider stream_callback is invoked with metadata", {
  skip_if_not_installed("httr2")

  library(httr2)

  dummy_history <- data.frame(
    role = "user",
    content = "ping",
    stringsAsFactors = FALSE
  )

  # We'll hit a cheap, fast OpenAI endpoint if configured; otherwise skip.
  openai_key <- Sys.getenv("OPENAI_API_KEY", unset = "")
  skip_if(openai_key == "", "OPENAI_API_KEY not set; skipping stream_callback test")

  model_chat <- Sys.getenv(
    "TIDYPROMPT_OPENAI_CHAT_MODEL",
    unset = "gpt-4o-mini"
  )

  req <- request("https://api.openai.com/v1/chat/completions") |>
    req_headers(
      Authorization = paste("Bearer", openai_key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(
      list(
        model = model_chat,
        temperature = 0,
        max_tokens = 8,
        stream = TRUE,
        messages = list(
          list(
            role = "system",
            content = "Reply with exactly the single word: pong"
          ),
          list(role = "user", content = "Say it.")
        )
      ),
      auto_unbox = TRUE
    )

  seen <- new.env(parent = emptyenv())
  seen$n_calls <- 0L
  seen$last_chunk <- NULL
  seen$meta_samples <- list()

  cb <- function(chunk, meta) {
    seen$n_calls <- seen$n_calls + 1L
    seen$last_chunk <- chunk
    # Store a tiny sample of metadata for later checks
    seen$meta_samples[[length(seen$meta_samples) + 1L]] <- list(
      api_type = meta$api_type,
      endpoint = meta$endpoint,
      verbose = meta$verbose,
      has_partial = !is.null(meta$partial_response),
      has_latest = !is.null(meta$latest_message)
    )
  }

  out <- request_llm_provider(
    chat_history = dummy_history,
    request = req,
    stream = TRUE,
    verbose = FALSE,
    api_type = "openai",
    stream_callback = cb
  )

  expect_true(nrow(out$completed) == 2L)
  assistant <- tail(out$completed$content, 1)

  expect_true(seen$n_calls > 0L)
  expect_true(is.character(seen$last_chunk))
  expect_true(nchar(seen$last_chunk) > 0)

  # At least one metadata sample has the expected shape
  expect_true(length(seen$meta_samples) > 0L)
  m <- seen$meta_samples[[1L]]
  expect_equal(m$api_type, "openai")
  expect_true(m$has_partial)
  expect_true(m$has_latest)
  expect_true(is.character(assistant))
  expect_true(nchar(assistant) > 0)
})
