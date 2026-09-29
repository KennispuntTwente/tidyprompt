test_that("native tools accumulate across wraps and preserve the base registry", {
  local_ellmer_response("done", citations = FALSE)
  chat <- ellmer::chat_openai(
    model = "gpt-4.1-mini",
    credentials = function() "test-only",
    echo = "none"
  )
  a <- ellmer::tool(function() "A", "Return A", name = "a")
  b <- ellmer::tool(function() "B", "Return B", name = "b")
  base <- ellmer::tool(function() "Base", "Return base", name = "base")
  chat$register_tool(base)
  prompt <- answer_using_tools("Question", a, type = "ellmer") |>
    answer_using_tools(b, type = "ellmer")
  result <- send_prompt(
    prompt,
    chat,
    stream = FALSE,
    verbose = FALSE,
    return_mode = "full"
  )
  expect_setequal(names(result$ellmer_chat$get_tools()), c("base", "a", "b"))
  expect_equal(names(chat$get_tools()), "base")
  expect_error(
    send_prompt(
      answer_using_tools(prompt, list(a = b), type = "ellmer"),
      chat,
      stream = FALSE,
      verbose = FALSE
    ),
    "Tool name collision"
  )
})

test_that("valid nested native results retain their R classes through validation", {
  skip_if_not_installed("jsonvalidate")
  payload <- '{"rows":[{"tags":["a","b"],"person":{"name":"Alice"}},{"tags":null,"person":{"name":"Bob"}}]}'
  local_ellmer_response(payload, citations = FALSE)
  chat <- ellmer::chat_openai(
    model = "gpt-4.1-mini",
    credentials = function() "test-only",
    echo = "none"
  )
  type <- ellmer::type_object(
    rows = ellmer::type_array(ellmer::type_object(
      tags = ellmer::type_array(ellmer::type_string(), required = FALSE),
      person = ellmer::type_object(name = ellmer::type_string())
    ))
  )
  expected <- chat$chat_structured("Question", type = type)
  for (stream in c(FALSE, TRUE)) {
    result <- send_prompt(
      answer_as_json("Question", schema = type, type = "ellmer"),
      chat,
      stream = stream,
      verbose = FALSE,
      max_interactions = 1
    )
    expect_identical(result, expected)
  }
})

test_that("native nested verification preserves the outer limit and clears its schema", {
  skip_if_not_installed("ellmer", "0.5.0")
  requests <- list()
  local_mocked_bindings(
    chat_perform = function(type = NULL, turns, ...) {
      i <- length(requests) + 1L
      requests[[i]] <<- list(type = type, turns = turns)
      if (i > 2L) {
        stop("Unexpected third request")
      }
      text <- if (i == 1L) '{"x":1}' else "FINISH[TRUE]"
      httr2::response(
        status_code = 200L,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(
          list(
            id = "resp_test",
            model = "gpt-4.1-mini",
            status = "completed",
            output = list(list(
              type = "message",
              role = "assistant",
              content = list(list(
                type = "output_text",
                text = text,
                annotations = list()
              ))
            )),
            usage = list(input_tokens = 1, output_tokens = 1)
          ),
          auto_unbox = TRUE
        ))
      )
    },
    .package = "ellmer"
  )
  chat <- ellmer::chat_openai(
    model = "gpt-4.1-mini",
    credentials = function() "test-only",
    echo = "none"
  )
  prompt <- answer_as_json(
    "Question",
    schema = ellmer::type_object(x = ellmer::type_number()),
    type = "ellmer"
  ) |>
    llm_verify() |>
    prompt_wrap(
      validation_fn = function(...) llm_feedback("Again"),
      type = "check"
    )
  expect_error(
    send_prompt(
      prompt,
      chat,
      stream = FALSE,
      verbose = FALSE,
      max_requests = 2
    ),
    class = "tidyprompt_request_limit"
  )
  expect_length(requests, 2L)
  expect_false(is.null(requests[[1]]$type))
  expect_null(requests[[2]]$type)
  expect_length(chat$get_turns(), 0L)
})

test_that("conflicting native output wraps are rejected before requesting a response", {
  skip_if_not_installed("ellmer")
  chat <- fake_ellmer_chat()
  prompt <- answer_as_json(
    "Question",
    schema = ellmer::type_object(a = ellmer::type_string()),
    type = "ellmer"
  ) |>
    answer_as_json(
      schema = ellmer::type_object(b = ellmer::type_string()),
      type = "ellmer"
    )
  expect_error(
    send_prompt(prompt, chat, stream = FALSE, verbose = FALSE),
    "one native structured-output wrap"
  )
  expect_null(chat$last_method)
})

test_that("nested verification limits are cleaned up before reusing a native chat", {
  skip_if_not_installed("ellmer", "0.5.0")
  local_ellmer_response("FINISH[TRUE]", citations = FALSE)
  chat <- ellmer::chat_openai(
    model = "gpt-4.1-mini",
    credentials = function() "test-only",
    echo = "none"
  )
  for (i in 1:2) {
    result <- send_prompt(
      llm_verify("Question"),
      chat,
      stream = FALSE,
      verbose = FALSE,
      max_requests = 2,
      return_mode = "full"
    )
    expect_equal(result$response, "FINISH[TRUE]")
    chat <- result$ellmer_chat
  }
})
