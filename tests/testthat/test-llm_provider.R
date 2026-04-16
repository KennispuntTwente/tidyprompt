# Test: Initialization of llm_provider with basic parameters
test_that("llm_provider initializes with parameters", {
  parameters <- list(model = "my-llm-model", api_key = "my-api-key")
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      list(role = "assistant", content = "Hello")
    },
    parameters = parameters
  )

  expect_s3_class(provider, "LlmProvider")
  expect_equal(provider$parameters, parameters)
})

# Test: Setting and updating parameters
test_that("llm_provider updates parameters correctly", {
  parameters <- list(model = "my-llm-model", api_key = "my-api-key")
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      list(role = "assistant", content = "Hello")
    },
    parameters = parameters
  )

  # Update parameters
  new_parameters <- list(api_key = "new-api-key", timeout = 10)
  provider$set_parameters(new_parameters)

  updated_params <- provider$parameters
  expect_equal(updated_params$model, "my-llm-model")
  expect_equal(updated_params$api_key, "new-api-key")
  expect_equal(updated_params$timeout, 10)
})

# Test: complete_chat function with verbose on
test_that("llm_provider complete_chat prints message when verbose is TRUE", {
  test_chat_function <- function(chat_history) {
    return(
      list(
        completed = data.frame(
          role = "assistant",
          content = "Hello!"
        )
      )
    )
  }

  provider <- `llm_provider-class`$new(
    complete_chat_function = test_chat_function,
    verbose = TRUE
  )

  # Test interaction with chat history
  chat_history <- data.frame(role = "user", content = "Hello")
  expect_message(
    provider$complete_chat(list(chat_history = chat_history)),
    "--- Receiving response from LLM provider: ---"
  )
})

# Test: Fake LLM provider responses
test_that("llm_provider_fake returns expected response for known prompt", {
  provider_fake <- llm_provider_fake(verbose = FALSE)

  chat_history <- data.frame(role = "user", content = "Hi there!")
  result <- provider_fake$complete_chat(list(chat_history = chat_history))
  response <- result$completed |> utils::tail(1)

  expect_equal(response$role, "assistant")
  expect_match(response$content, "nice to meet you")
})

test_that("llm_provider normalizes sparse tool metadata in completed history", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      list(
        completed = dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "Hello!",
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    verbose = FALSE
  )

  result <- provider$complete_chat(list(
    chat_history = data.frame(
      role = "user",
      content = "Hello",
      tool_call = FALSE,
      tool_call_id = NA_character_,
      tool_result = FALSE,
      stringsAsFactors = FALSE
    )
  ))

  expect_equal(result$completed$tool_call, c(FALSE, FALSE))
  expect_true(all(is.na(result$completed$tool_call_id)))
  expect_equal(result$completed$tool_result, c(FALSE, FALSE))
})

test_that("llm_provider excludes hidden rows from outgoing requests", {
  state <- new.env(parent = emptyenv())
  state$seen_chat_history <- NULL

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      self$parameters$.test_state$seen_chat_history <- chat_history

      list(
        completed = dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "Fixed answer",
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.test_state = state),
    verbose = FALSE
  )

  input <- data.frame(
    role = c("user", "assistant", "assistant", "user"),
    content = c("Question", "Reasoning step", "Answer", "Follow-up"),
    hidden_from_llm = c(FALSE, TRUE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(list(chat_history = input))

  expect_equal(
    state$seen_chat_history$content,
    c("Question", "Answer", "Follow-up")
  )
  expect_false(any(state$seen_chat_history$hidden_from_llm))
  expect_equal(
    result$completed$content,
    c("Question", "Reasoning step", "Answer", "Follow-up", "Fixed answer")
  )
  expect_equal(
    result$completed$hidden_from_llm,
    c(FALSE, TRUE, FALSE, FALSE, FALSE)
  )
})

test_that("llm_provider excludes tool call rows from outgoing requests", {
  state <- new.env(parent = emptyenv())
  state$seen_chat_history <- NULL

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      self$parameters$.test_state$seen_chat_history <- chat_history

      list(
        completed = dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "Fixed answer",
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.test_state = state),
    verbose = FALSE
  )

  input <- data.frame(
    role = c("user", "assistant", "tool", "assistant", "user"),
    content = c(
      "Question",
      "~>> Calling function 'tool' with arguments:\n{}",
      "~>> Result:\n42",
      "Answer",
      "Follow-up"
    ),
    tool_call = c(FALSE, TRUE, FALSE, FALSE, FALSE),
    tool_call_id = c(
      NA_character_,
      "call-1",
      "call-1",
      NA_character_,
      NA_character_
    ),
    tool_result = c(FALSE, FALSE, TRUE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(list(chat_history = input))

  expect_equal(
    state$seen_chat_history$content,
    c("Question", "~>> Result:\n42", "Answer", "Follow-up")
  )
  expect_false(any(state$seen_chat_history$tool_call))
  expect_equal(
    result$completed$hidden_from_llm,
    c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE)
  )
})

# Test: Invalid parameters handling
test_that("llm_provider errors on invalid parameters", {
  expect_error(
    `llm_provider-class`$new(
      complete_chat_function = function(chat_history) {
        list(role = "assistant", content = "Hello")
      },
      parameters = list("unnamed")
    ),
    "parameters must be a named list"
  )
})
