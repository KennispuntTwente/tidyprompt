test_that("request limits span feedback rounds and reset between evaluations", {
  local_ellmer_response('{"x":1}', citations = FALSE)
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none")
  for (stream in c(FALSE, TRUE)) {
    for (structured in c(FALSE, TRUE)) {
      prompt <- "Question"
      if (structured) prompt <- answer_as_json(prompt, type = "ellmer",
        schema = ellmer::type_object(x = ellmer::type_number()))
      prompt <- prompt_wrap(prompt, validation_fn = function(...) llm_feedback("Again"))
      prompt <- limit_requests(prompt, 1)
      for (i in 1:2) {
        err <- tryCatch(send_prompt(prompt, ch, stream = stream, verbose = FALSE), tidyprompt_request_limit = identity)
        expect_s3_class(err, "tidyprompt_request_limit")
        expect_equal(err$requests, 1L)
        expect_length(err$ellmer_chat$get_turns(), 2L)
      }
    }
  }
  expect_length(ch$get_turns(), 0L)
  expect_error(limit_requests("x", 0), "positive whole")
})

test_that("request limits stop ellmer's internal tool loop", {
  skip_if_not_installed("ellmer", "0.5.0")
  requests <- 0L
  local_mocked_bindings(chat_perform = function(...) {
    requests <<- requests + 1L
    result <- list(id = "resp_tool", model = "gpt-4.1-mini", status = "completed",
      output = list(list(type = "function_call", id = "fc_1", call_id = "call_1", name = "lookup", arguments = "{}")),
      usage = list(input_tokens = 10, output_tokens = 5))
    httr2::response(status_code = 200L, headers = list("content-type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(result, auto_unbox = TRUE)))
  }, .package = "ellmer")
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none")
  ch$register_tool(ellmer::tool(function() "Data", name = "lookup", description = "Lookup"))
  err <- tryCatch(send_prompt(limit_requests("Question", 1), ch,
    stream = FALSE, verbose = FALSE), tidyprompt_request_limit = identity)
  expect_s3_class(err, "tidyprompt_request_limit")
  expect_equal(requests, 1L)
})

test_that("returned native chats do not retain an exhausted evaluation limit", {
  local_ellmer_response(citations = FALSE)
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none")
  callbacks <- 0L
  ch$on_request_start(function(turns) callbacks <<- callbacks + 1L)
  first <- send_prompt(limit_requests("Question", 1), ch,
    stream = FALSE, verbose = FALSE, return_mode = "full")
  expect_equal(callbacks, 1L)
  second <- send_prompt(limit_requests("Another question", 1), first$ellmer_chat,
    stream = FALSE, verbose = FALSE, return_mode = "full")
  expect_equal(callbacks, 2L)
  expect_equal(second$response, "The answer is 42.")
  prompt <- limit_requests(prompt_wrap("Question",
    validation_fn = function(...) llm_feedback("Again")), 1)
  err <- tryCatch(send_prompt(prompt, second$ellmer_chat,
    stream = FALSE, verbose = FALSE), tidyprompt_request_limit = identity)
  expect_s3_class(err, "tidyprompt_request_limit")
  expect_equal(send_prompt("Recovered", err$ellmer_chat, stream = FALSE, verbose = FALSE),
    "The answer is 42.")
})
