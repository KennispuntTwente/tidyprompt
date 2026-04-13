testthat::test_that("ellmer provider prefers role-specific Turn constructors", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  chat_history <- data.frame(
    role = c("system", "user"),
    content = c("Be helpful.", "Hello"),
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  turns <- result$ellmer_chat$turns

  # The prior turn (system) should be a Turn object with contents
  testthat::expect_true(length(turns) >= 1)
  testthat::expect_true(length(turns[[1]]@contents) >= 1)
  testthat::expect_equal(turns[[1]]@role, "system")
})

testthat::test_that("ellmer provider builds Turn objects with correct contents", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  chat_history <- data.frame(
    role = c("user", "assistant", "user"),
    content = c("First", "Reply", "Second"),
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  turns <- result$ellmer_chat$turns

  # Two prior turns should have been built (the third is the current prompt)
  testthat::expect_length(turns, 2)

  # Check contents are accessible via S7 slot
  for (turn in turns) {
    testthat::expect_true(length(turn@contents) >= 1)
  }
})
