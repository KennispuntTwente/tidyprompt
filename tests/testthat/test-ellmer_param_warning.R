# Tests for unforwardable parameter warnings on ellmer providers

test_that("ellmer provider warns about unforwardable parameters", {
  skip_if_not_installed("ellmer")

  fake_chat <- new.env(parent = emptyenv())
  fake_chat$chat <- function(...) "ok"
  fake_chat$clone <- function() fake_chat
  fake_chat$set_turns <- function(turns) {
    fake_chat
  }
  fake_chat$get_turns <- function() list()
  fake_chat$stream <- NULL

  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)
  provider$parameters$stream <- FALSE
  provider$parameters$temperature <- 0.7
  provider$parameters$max_tokens <- 100L

  chat_hist <- data.frame(
    role = "user",
    content = "hi",
    stringsAsFactors = FALSE
  )

  # Reset the rlang once-per-session guard so the warning fires in tests.
  rlang::reset_warning_verbosity("tidyprompt_ellmer_extra_params")

  expect_warning(
    provider$complete_chat(chat_hist),
    "not forwarded"
  )
})

test_that("ellmer provider does not warn with only known parameters", {
  skip_if_not_installed("ellmer")

  fake_chat <- new.env(parent = emptyenv())
  fake_chat$chat <- function(...) "ok"
  fake_chat$clone <- function() fake_chat
  fake_chat$set_turns <- function(turns) {
    fake_chat
  }
  fake_chat$get_turns <- function() list()
  fake_chat$stream <- NULL

  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)
  provider$parameters$stream <- FALSE

  chat_hist <- data.frame(
    role = "user",
    content = "hi",
    stringsAsFactors = FALSE
  )

  expect_no_warning(provider$complete_chat(chat_hist))
})
