# tests/testthat/test-openai-real.R

# Here we test some functions from R/internal_request_llm_provider.R,
#   to verify that the OpenAI API can be used correctly with both
#   the responses and the chat completions endpoints

testthat::skip_if_not_installed("httr2")

suppressWarnings(library(testthat))
suppressWarnings(library(httr2))

# ---- Config ------------------------------------------------------------------
openai_key <- Sys.getenv("OPENAI_API_KEY", unset = "")
skip_if(openai_key == "", "OPENAI_API_KEY not set; skipping OpenAI tests")

model_chat <- Sys.getenv("TIDYPROMPT_OPENAI_CHAT_MODEL", unset = "gpt-4o-mini")
model_resp <- Sys.getenv(
  "TIDYPROMPT_OPENAI_RESPONSES_MODEL",
  unset = "gpt-4o-mini"
)

dummy_history <- function() {
  data.frame(role = "user", content = "ping", stringsAsFactors = FALSE)
}

openai_headers <- function(req) {
  req |>
    req_headers(
      Authorization = paste("Bearer", openai_key),
      `Content-Type` = "application/json"
    )
}

# ---- Chat Completions (non-stream) -------------------------------------------
test_that("OpenAI Chat Completions (non-stream) returns content", {
  req <- request("https://api.openai.com/v1/chat/completions") |>
    openai_headers() |>
    req_body_json(
      list(
        model = model_chat,
        temperature = 0,
        max_tokens = 10,
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

  out <- request_llm_provider(
    chat_history = dummy_history(),
    request = req,
    stream = FALSE,
    api_type = "openai"
  )

  expect_s3_class(out$completed, "data.frame")
  assistant <- tail(out$completed$content, 1)
  expect_true(is.character(assistant) && nchar(assistant) > 0)
  expect_true(grepl("pong", assistant, ignore.case = TRUE))
})

# ---- Responses API (non-stream) ----------------------------------------------
test_that("OpenAI Responses API (non-stream) returns content", {
  req <- request("https://api.openai.com/v1/responses") |>
    openai_headers() |>
    req_body_json(
      list(
        model = model_resp,
        temperature = 0,
        max_output_tokens = 32,
        input = "Reply with exactly the single word: pong"
      ),
      auto_unbox = TRUE
    )

  out <- request_llm_provider(
    chat_history = dummy_history(),
    request = req,
    stream = FALSE,
    api_type = "openai"
  )

  assistant <- tail(out$completed$content, 1)
  expect_true(is.character(assistant) && nchar(assistant) > 0)
  expect_true(grepl("pong", assistant, ignore.case = TRUE))
})

# ---- Chat Completions (stream) -----------------------------------------------
test_that("OpenAI Chat Completions (stream) accumulates deltas", {
  req <- request("https://api.openai.com/v1/chat/completions") |>
    openai_headers() |>
    req_body_json(
      list(
        model = model_chat,
        temperature = 0,
        max_tokens = 32,
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

  out <- request_llm_provider(
    chat_history = dummy_history(),
    request = req,
    stream = TRUE, # ensure SSE path
    verbose = FALSE, # silence token-by-token printing in tests
    api_type = "openai"
  )

  assistant <- tail(out$completed$content, 1)
  reply <- tolower(trimws(assistant))

  expect_true(nchar(reply) > 0)
  expect_true(grepl("\\bpong\\b", reply, ignore.case = FALSE))

  # If you want to be strict:
  # expect_equal(reply, "pong")
})

# ---- Responses API (stream) ---------------------------------------------------
test_that("OpenAI Responses API (stream) accumulates output_text deltas", {
  req <- request("https://api.openai.com/v1/responses") |>
    openai_headers() |>
    req_body_json(
      list(
        model = model_resp,
        temperature = 0,
        max_output_tokens = 32,
        stream = TRUE,
        input = "Reply with exactly the single word: pong"
      ),
      auto_unbox = TRUE
    )

  out <- request_llm_provider(
    chat_history = dummy_history(),
    request = req,
    stream = TRUE, # ensure we take the SSE path
    verbose = FALSE, # the new impl can print token deltas; silence in tests
    api_type = "openai"
  )

  # Grab the assistant's final message from the completed history
  assistant <- tail(out$completed$content, 1)
  reply <- tolower(trimws(assistant))

  # Basic sanity checks
  expect_true(nchar(reply) > 0)
  expect_true(grepl("\\bpong\\b", reply, ignore.case = FALSE))

  # (Optional) If you want to be stricter, uncomment:
  # expect_equal(reply, "pong")
})
