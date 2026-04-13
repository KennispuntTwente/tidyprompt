testthat::test_that("send_prompt deep-clones the ellmer chat object", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  # Remember the original chat identity

  original_chat <- provider$ellmer_chat

  result <- "Hello" |>
    send_prompt(provider, return_mode = "full", verbose = FALSE)

  # The provider's chat should still be the original (untouched)
  testthat::expect_identical(provider$ellmer_chat, original_chat)

  # The returned ellmer_chat should be a different object
  testthat::expect_false(identical(result$ellmer_chat, original_chat))
})
