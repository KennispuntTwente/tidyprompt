composition_provider <- function(replies) {
  state <- new.env(parent = emptyenv())
  state$requests <- list()
  state$replies <- replies
  provider <- `llm_provider-class`$new(
    function(history) {
      state <- self$parameters$.state
      i <- length(state$requests) + 1L
      state$requests[[i]] <- list(
        history = history,
        parameters = self$parameters
      )
      if (i > length(state$replies)) {
        stop("Unexpected model request")
      }
      list(
        completed = add_msg_to_chat_history(
          history,
          state$replies[[i]],
          "assistant"
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.state = state),
    verbose = FALSE
  )
  list(provider = provider, state = state)
}

test_that("verification receives all rows and nested fields independent of print options", {
  response <- dplyr::tibble(
    id = seq_len(100L),
    nested = lapply(seq_len(100L), function(i) list(value = paste0("row-", i)))
  )
  response$nested[[100]] <- list(value = "problem-in-last-row")
  expected <- llm_verify_serialize(response)
  withr::local_options(list(max.print = 5L, tibble.print_max = 2L, pillar.width = 10L))
  fixture <- composition_provider(c("answer", "FINISH[TRUE]"))
  prompt <- prompt_wrap("Question", extraction_fn = function(x) response) |>
    llm_verify()
  expect_identical(send_prompt(prompt, fixture$provider), response)
  judge_prompt <- tail(fixture$state$requests[[2]]$history$content, 1L)
  expect_match(judge_prompt, "problem-in-last-row", fixed = TRUE)
  expect_match(judge_prompt, expected, fixed = TRUE)
  expect_identical(eval(parse(text = expected)), response)
})

test_that("verification serialization preserves complete structured R values", {
  values <- list(
    list(empty = list(), missing = NULL, nested = list(c("a", "b"))),
    matrix(seq_len(200L), nrow = 100L),
    list(number = pi, special = c(NA_real_, NaN, Inf)),
    data.frame(day = as.Date("2026-09-29"), group = factor("a")),
    c("first", "last"), NULL
  )
  for (value in values) {
    expect_identical(eval(parse(text = llm_verify_serialize(value))), value)
  }
  expect_identical(llm_verify_serialize("full\ntext"), "full\ntext")
})

test_that("the first and last permitted answers are evaluated", {
  for (replies in list("42", c("invalid", "42"))) {
    fixture <- composition_provider(replies)
    result <- send_prompt(
      answer_as_integer("Question"),
      fixture$provider,
      max_interactions = length(replies),
      return_mode = "full"
    )
    expect_equal(result$response, 42)
    expect_equal(result$interactions, length(replies))
    expect_length(fixture$state$requests, length(replies))
  }
  fixture <- composition_provider("invalid")
  expect_warning(
    result <- send_prompt(
      answer_as_integer("Question"),
      fixture$provider,
      max_interactions = 1,
      return_mode = "full"
    ),
    "Failed to reach"
  )
  expect_null(result$response)
  expect_length(fixture$state$requests, 1L)
})

test_that("verification rejection provides feedback and shares the request budget", {
  replies <- c(
    "bad answer",
    "Wrong. FINISH[FALSE]",
    "Check the source.",
    "fixed answer",
    "FINISH[TRUE]"
  )
  fixture <- composition_provider(replies)
  result <- send_prompt(
    llm_verify("Question"),
    fixture$provider,
    max_requests = 5,
    return_mode = "full"
  )
  expect_equal(result$response, "fixed answer")
  expect_equal(result$interactions, 2)
  expect_length(fixture$state$requests, 5L)
  expect_match(
    fixture$state$requests[[3]]$history$content,
    "Wrong",
    fixed = TRUE
  )
  expect_match(
    tail(fixture$state$requests[[4]]$history$content, 1),
    "Check the source"
  )

  fixture <- composition_provider(replies)
  expect_error(
    send_prompt(llm_verify("Question"), fixture$provider, max_requests = 2),
    class = "tidyprompt_request_limit"
  )
  expect_length(fixture$state$requests, 2L)
})

test_that("verifiers inherit base configuration without answer-specific settings or handlers", {
  fixture <- composition_provider(c("answer", "FINISH[TRUE]"))
  fixture$provider$parameters$model <- "configured-model"
  handler_calls <- 0L
  prompt <- prompt_wrap(
    "Question",
    modify_fn = function(text, llm_provider) {
      paste(text, llm_provider$parameters$response_format$type)
    },
    parameter_fn = function(llm_provider) {
      list(response_format = list(type = "json_object"))
    },
    handler_fn = function(response, llm_provider) {
      handler_calls <<- handler_calls + 1L
      response
    }
  ) |>
    llm_verify()
  expect_equal(send_prompt(prompt, fixture$provider), "answer")
  expect_equal(handler_calls, 1L)
  expect_equal(fixture$state$requests[[2]]$parameters$model, "configured-model")
  expect_null(fixture$state$requests[[2]]$parameters$response_format)
  expect_match(fixture$state$requests[[2]]$history$content, "json_object")
})

test_that("an explicitly selected verifier still consumes the outer request budget", {
  answer <- composition_provider("answer")
  judge <- composition_provider("FINISH[TRUE]")
  prompt <- llm_verify("Question", llm_provider = judge$provider)
  expect_error(
    send_prompt(prompt, answer$provider, max_requests = 1),
    class = "tidyprompt_request_limit"
  )
  expect_length(answer$state$requests, 1L)
  expect_length(judge$state$requests, 0L)
})

test_that("soft breaks validate the current value without another request", {
  fixture <- composition_provider("42")
  prompt <- prompt_wrap("Question", extraction_fn = function(x) {
    llm_break_soft(x)
  }) |>
    answer_as_integer()
  expect_equal(send_prompt(prompt, fixture$provider), 42)
  fixture <- composition_provider("invalid")
  expect_warning(send_prompt(prompt, fixture$provider), "Failed to reach")
  expect_length(fixture$state$requests, 1L)
})

test_that("checks can reject a hard break and evaluate the next response", {
  for (stage in c("extraction_fn", "validation_fn")) {
    fixture <- composition_provider(c("1", "2"))
    wrap_args <- list(prompt = "Question")
    wrap_args[[stage]] <- function(x) llm_break(as.integer(x), success = TRUE)
    checked <- list()
    prompt <- do.call(prompt_wrap, wrap_args) |>
      prompt_wrap(type = "check", validation_fn = function(x) {
        checked[[length(checked) + 1L]] <<- x
        if (x == 1L) llm_feedback("Try again") else TRUE
      })
    result <- send_prompt(
      prompt,
      fixture$provider,
      max_interactions = 2,
      return_mode = "full"
    )
    expect_identical(result$response, 2L)
    expect_equal(result$interactions, 2)
    expect_identical(checked, list(1L, 2L))
    expect_length(fixture$state$requests, 2L)
  }
})

test_that("provider-wide verification wraps do not recurse into the verifier", {
  fixture <- composition_provider(c("answer", "FINISH[TRUE]"))
  fixture$provider$add_prompt_wrap(
    get_prompt_wraps(llm_verify("Question"))[[1]],
    position = "post"
  )
  expect_equal(send_prompt("Question", fixture$provider), "answer")
  expect_length(fixture$state$requests, 2L)
})
