# Tests for hardened streaming in llm_provider_ellmer:
# 1. stream_callback errors are caught (stream continues)
# 2. Streaming-init failures fall back to non-streaming chat

test_that("stream_callback errors are caught and warned, stream continues", {
  skip_if_not_installed("ellmer")
  skip_if_not_installed("coro")

  # Build a tiny fake ellmer-like chat that supports stream().
  # stream() returns a coro generator yielding two chunks.
  fake_chat <- new.env(parent = emptyenv())
  fake_chat$chat <- function(...) "ok"
  fake_chat$clone <- function() fake_chat
  fake_chat$set_turns <- function(turns) {
    fake_chat
  }
  fake_chat$get_turns <- function() list()
  fake_chat$stream <- function(...) {
    coro::gen({
      coro::yield("hello")
      coro::yield(" world")
    })()
  }

  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)
  provider$parameters$stream <- TRUE

  bomb_count <- 0L
  provider$stream_callback <- function(chunk, meta) {
    bomb_count <<- bomb_count + 1L
    stop("callback boom")
  }

  chat_hist <- data.frame(
    role = "user",
    content = "hi",
    stringsAsFactors = FALSE
  )

  # The callback explodes on every chunk; we should get warnings but NOT an error.
  warnings_seen <- character()
  result <- withCallingHandlers(
    provider$complete_chat(chat_hist),
    warning = function(w) {
      warnings_seen <<- c(warnings_seen, conditionMessage(w))
      tryInvokeRestart("muffleWarning")
    }
  )

  expect_true(bomb_count >= 1L)
  expect_true(any(grepl("stream_callback error", warnings_seen)))
  # The assistant text should still be accumulated despite callback errors.
  assistant <- utils::tail(result$completed$content, 1)
  expect_true(grepl("hello", assistant))
})

test_that("streaming-init failure falls back to non-streaming chat", {
  skip_if_not_installed("ellmer")

  fake_chat <- new.env(parent = emptyenv())
  fake_chat$chat <- function(...) "fallback reply"
  fake_chat$clone <- function() fake_chat
  fake_chat$set_turns <- function(turns) {
    fake_chat
  }
  fake_chat$get_turns <- function() list()
  fake_chat$stream <- function(...) stop("stream not supported")

  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)
  provider$parameters$stream <- TRUE

  chat_hist <- data.frame(
    role = "user",
    content = "hi",
    stringsAsFactors = FALSE
  )

  # Should fall back to ch$chat() instead of crashing.
  result <- provider$complete_chat(chat_hist)
  assistant <- utils::tail(result$completed$content, 1)
  expect_equal(assistant, "fallback reply")
})
