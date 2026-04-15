# Tests for persistent_chat ellmer state sync

test_that("persistent_chat syncs ellmer_chat after each turn", {
  skip_if_not_installed("ellmer")

  call_count <- 0L

  fake_chat <- new.env(parent = emptyenv())
  fake_chat$chat <- function(...) {
    call_count <<- call_count + 1L
    paste0("reply-", call_count)
  }
  fake_chat$clone <- function() {
    copy <- new.env(parent = emptyenv())
    copy$chat <- fake_chat$chat
    copy$clone <- fake_chat$clone
    copy$set_turns <- fake_chat$set_turns
    copy$get_turns <- fake_chat$get_turns
    copy$stream <- NULL
    copy$.synced_marker <- call_count
    copy
  }
  fake_chat$set_turns <- function(turns) {
    fake_chat
  }
  fake_chat$get_turns <- function() list()
  fake_chat$stream <- NULL
  fake_chat$.synced_marker <- 0L

  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)
  provider$parameters$stream <- FALSE

  pc <- `persistent_chat-class`$new(
    llm_provider = provider,
    chat_history = NULL
  )

  # First turn
  res1 <- pc$chat("hello", verbose = FALSE)
  # The ellmer_chat from the response should now be stored on the provider.
  expect_false(is.null(res1$ellmer_chat))
  # The provider's ellmer_chat should have been updated to the returned one.
  expect_identical(pc$llm_provider$ellmer_chat, res1$ellmer_chat)

  # Second turn
  res2 <- pc$chat("world", verbose = FALSE)
  expect_identical(pc$llm_provider$ellmer_chat, res2$ellmer_chat)
  # Chat history should span both turns (system included or not, at least
  # user + assistant for each).
  expect_true(nrow(pc$chat_history) >= 4L)
})
