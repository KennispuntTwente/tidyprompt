testthat::test_that("send_prompt deep-clones the ellmer chat object", {
  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  # Remember the original chat identity

  original_chat <- provider$ellmer_chat

  result <- "Hello" |>
    send_prompt(provider, return_mode = "full", verbose = FALSE)

  # The provider's chat should still be the original (untouched)
  testthat::expect_identical(provider$ellmer_chat, original_chat)

  # The returned ellmer_chat should be a different object
  testthat::expect_false(identical(result$ellmer_chat, original_chat))
})

testthat::test_that("direct raw ellmer chats are reset before parameter_fn runs", {
  withr::local_options(list(tidyprompt.stream = FALSE))

  raw_env <- new.env(parent = emptyenv())
  provider_env <- new.env(parent = emptyenv())

  capture_turns <- function(prompt, store_env) {
    prompt |>
      prompt_wrap(parameter_fn = function(llm_provider) {
        store_env$turns <- llm_provider$ellmer_chat$get_turns()
        list()
      })
  }

  raw_chat <- fake_ellmer_chat(turns = list("existing-turn"))
  "Hello" |>
    capture_turns(raw_env) |>
    send_prompt(raw_chat, verbose = FALSE)

  explicit_provider <- llm_provider_ellmer(
    fake_ellmer_chat(turns = list("existing-turn")),
    parameters = list(stream = FALSE),
    verbose = FALSE
  )
  "Hello" |>
    capture_turns(provider_env) |>
    send_prompt(explicit_provider, verbose = FALSE)

  testthat::expect_length(raw_env$turns, 0)
  testthat::expect_length(provider_env$turns, 1)
})
