test_that("answer_as_numeric adds instruction", {
  prompt <- "What is 5 / 2?" |>
    answer_as_numeric(min = 0, max = 10) |>
    construct_prompt_text()

  expect_true(
    grepl(
      "You must answer with only a number (use no other characters).",
      prompt,
      fixed = TRUE
    )
  )
  expect_true(
    grepl(
      "Enter a number between 0 and 10.",
      prompt,
      fixed = TRUE
    )
  )
})

test_that("answer_as_numeric extracts numeric responses", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      list(
        completed = dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "2.5",
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    verbose = FALSE
  )

  result <- "What is 10 divided by 4?" |>
    answer_as_numeric() |>
    send_prompt(provider, verbose = FALSE)

  expect_true(is.numeric(result))
  expect_equal(result, 2.5)
})

test_that("answer_as_numeric retries when response is outside bounds", {
  state <- new.env(parent = emptyenv())
  state$call_n <- 0L

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      state <- self$parameters$.test_state
      state$call_n <- state$call_n + 1L
      reply <- c("11", "7.25")[[state$call_n]]

      list(
        completed = dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = reply,
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.test_state = state),
    verbose = FALSE
  )

  result <- "Give me a number between 5 and 10" |>
    answer_as_numeric(min = 5, max = 10) |>
    send_prompt(provider, return_mode = "full", verbose = FALSE)

  expect_equal(result$response, 7.25)
  expect_equal(state$call_n, 2L)
})
