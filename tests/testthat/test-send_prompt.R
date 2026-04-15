test_that("extraction and validation works", {
  fake_llm <- llm_provider_fake()

  response <- "What is 2 + 2?" |>
    answer_by_chain_of_thought() |>
    answer_as_integer() |>
    send_prompt(fake_llm, verbose = TRUE)

  is_whole_number <- function(x) {
    is.numeric(x) && x == floor(x)
  }

  expect_true(is_whole_number(response))
  expect_equal(response, 4)
})

test_that("full return mode works", {
  fake_llm <- llm_provider_fake()

  response <- "hi" |>
    send_prompt(
      fake_llm,
      return_mode = "full",
      clean_chat_history = TRUE
    )

  expect_type(response$response, "character")
  expect_type(response$interactions, "double")

  expect_true(length(response$response) == 1)
  expect_true(is.data.frame(response$chat_history))
  expect_true(is.data.frame(response$chat_history_clean))
  expect_true(
    is.numeric(response$interactions) &
      response$interactions > 0 &
      response$interactions == floor(response$interactions)
  )
  expect_true(is.double(response$duration_seconds))
})

test_that("send_prompt accepts raw ellmer chats directly", {
  withr::local_options(list(tidyprompt.stream = FALSE))

  raw_chat <- fake_ellmer_chat(turns = list("old-turn"))

  result <- "Hello" |>
    send_prompt(raw_chat, return_mode = "full", verbose = FALSE)

  expect_equal(result$response, "chat-response:Hello")
  expect_identical(raw_chat$turns, list("old-turn"))
  expect_false(identical(result$ellmer_chat, raw_chat))
  expect_length(result$ellmer_chat$last_method$turns, 0)
})

test_that("send_prompt keeps llm_provider_ellmer stream defaults for raw chats", {
  skip_if_not_installed("coro")
  withr::local_options(list(tidyprompt.stream = TRUE))

  raw_chat <- fake_ellmer_chat()

  result <- "Hello" |>
    send_prompt(raw_chat, return_mode = "full", verbose = FALSE)

  expect_identical(result$ellmer_chat$last_method$method, "stream")
})
