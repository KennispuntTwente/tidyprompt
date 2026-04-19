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

test_that("send_prompt does not resend hidden history rows on retry", {
  feedback_sent <- FALSE
  state <- new.env(parent = emptyenv())
  state$provider_calls <- list()
  state$provider_call_n <- 0L

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      state <- self$parameters$.test_state
      state$provider_call_n <- state$provider_call_n + 1L
      state$provider_calls[[state$provider_call_n]] <- chat_history

      if (state$provider_call_n == 1L) {
        completed <- dplyr::bind_rows(
          chat_history,
          data.frame(
            role = c("assistant", "assistant"),
            content = c("Reasoning step", "Initial answer"),
            hidden_from_llm = c(TRUE, FALSE),
            stringsAsFactors = FALSE
          )
        )
      } else {
        completed <- dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "Fixed answer",
            stringsAsFactors = FALSE
          )
        )
      }

      list(
        completed = completed,
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.test_state = state),
    verbose = FALSE
  )

  prompt <- "Think through this" |>
    prompt_wrap(validation_fn = function(response) {
      if (!feedback_sent) {
        feedback_sent <<- TRUE
        return(llm_feedback("Please fix format"))
      }

      TRUE
    })

  result <- send_prompt(
    prompt,
    provider,
    return_mode = "full",
    verbose = FALSE
  )

  expect_equal(result$response, "Fixed answer")
  expect_equal(state$provider_calls[[1]]$content, "Think through this")
  expect_equal(
    state$provider_calls[[2]]$content,
    c("Think through this", "Initial answer", "Please fix format")
  )
  expect_false(any(state$provider_calls[[2]]$content == "Reasoning step"))
  expect_equal(
    result$chat_history$hidden_from_llm,
    c(FALSE, TRUE, FALSE, FALSE, FALSE)
  )
})

test_that("send_prompt preserves provider metadata updates on existing rows", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      updated_history <- chat_history
      updated_history$native_turn_id <- rep(
        NA_character_,
        nrow(updated_history)
      )
      updated_history$native_turn_id[nrow(updated_history)] <- "turn-1"
      updated_history$native_turn_role <- rep(
        NA_character_,
        nrow(updated_history)
      )
      updated_history$native_turn_role[nrow(updated_history)] <- "user"

      list(
        completed = dplyr::bind_rows(
          updated_history,
          data.frame(
            role = "assistant",
            content = "reply",
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    verbose = FALSE
  )

  result <- send_prompt(
    "Hello",
    provider,
    return_mode = "full",
    verbose = FALSE
  )

  expect_equal(result$response, "reply")
  expect_equal(result$chat_history$native_turn_id[1], "turn-1")
  expect_equal(result$chat_history$native_turn_role[1], "user")
})

test_that("send_prompt preserves metadata updates when hidden rows exist", {
  feedback_sent <- FALSE
  state <- new.env(parent = emptyenv())
  state$provider_calls <- list()
  state$provider_call_n <- 0L

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      state <- self$parameters$.test_state
      state$provider_call_n <- state$provider_call_n + 1L
      state$provider_calls[[state$provider_call_n]] <- chat_history

      if (state$provider_call_n == 1L) {
        # Provider adds metadata to the sent user row
        chat_history$native_turn_id <- rep(
          NA_character_,
          nrow(chat_history)
        )
        chat_history$native_turn_id[nrow(chat_history)] <- "turn-1"

        completed <- dplyr::bind_rows(
          chat_history,
          data.frame(
            role = c("assistant", "assistant"),
            content = c("Hidden reasoning", "First answer"),
            hidden_from_llm = c(TRUE, FALSE),
            stringsAsFactors = FALSE
          )
        )
      } else {
        # On retry, provider adds metadata to the (re-sent) user row
        chat_history$native_turn_id <- rep(
          NA_character_,
          nrow(chat_history)
        )
        chat_history$native_turn_id[nrow(chat_history)] <- "turn-retry"

        completed <- dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "Fixed answer",
            stringsAsFactors = FALSE
          )
        )
      }

      list(
        completed = completed,
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.test_state = state),
    verbose = FALSE
  )

  prompt <- "Hello" |>
    prompt_wrap(validation_fn = function(response) {
      if (!feedback_sent) {
        feedback_sent <<- TRUE
        return(llm_feedback("Please fix"))
      }
      TRUE
    })

  result <- send_prompt(
    prompt,
    provider,
    return_mode = "full",
    verbose = FALSE
  )

  expect_equal(result$response, "Fixed answer")

  # The feedback user row should carry the metadata from the retry call,
  # even though a hidden row existed earlier in the transcript.  Without
  # the merge fix the provider's metadata update on sent rows is discarded
  # because complete_chat reconstructs from the original (pre-send) history.
  user_rows <- which(result$chat_history$role == "user")
  expect_true(length(user_rows) >= 2)
  # Last user row is the feedback row — provider tagged it "turn-retry"
  expect_equal(
    result$chat_history$native_turn_id[user_rows[length(user_rows)]],
    "turn-retry"
  )
})

test_that("send_prompt does not resend tool call rows on retry", {
  feedback_sent <- FALSE
  state <- new.env(parent = emptyenv())
  state$provider_calls <- list()
  state$provider_call_n <- 0L

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      state <- self$parameters$.test_state
      state$provider_call_n <- state$provider_call_n + 1L
      state$provider_calls[[state$provider_call_n]] <- chat_history

      if (state$provider_call_n == 1L) {
        completed <- dplyr::bind_rows(
          chat_history,
          data.frame(
            role = c("assistant", "tool", "assistant"),
            content = c(
              "~>> Calling function 'tool' with arguments:\n{}",
              "~>> Result:\n42",
              "Initial answer"
            ),
            tool_call = c(TRUE, FALSE, FALSE),
            tool_call_id = c("call-1", "call-1", NA_character_),
            tool_result = c(FALSE, TRUE, FALSE),
            stringsAsFactors = FALSE
          )
        )
      } else {
        completed <- dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "Fixed answer",
            stringsAsFactors = FALSE
          )
        )
      }

      list(
        completed = completed,
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.test_state = state),
    verbose = FALSE
  )

  prompt <- "Think through this" |>
    prompt_wrap(validation_fn = function(response) {
      if (!feedback_sent) {
        feedback_sent <<- TRUE
        return(llm_feedback("Please fix format"))
      }

      TRUE
    })

  result <- send_prompt(
    prompt,
    provider,
    return_mode = "full",
    verbose = FALSE
  )

  expect_equal(result$response, "Fixed answer")
  expect_equal(state$provider_calls[[1]]$content, "Think through this")
  expect_equal(
    state$provider_calls[[2]]$content,
    c(
      "Think through this",
      "~>> Result:\n42",
      "Initial answer",
      "Please fix format"
    )
  )
  expect_false(any(grepl(
    "Calling function",
    state$provider_calls[[2]]$content
  )))
  expect_equal(
    result$chat_history$hidden_from_llm,
    c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE)
  )
})
