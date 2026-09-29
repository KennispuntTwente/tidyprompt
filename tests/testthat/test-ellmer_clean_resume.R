test_that("returned cleaned history can resume a native tool conversation", {
  local_ellmer_response("42", citations = FALSE)
  reply <- getFromNamespace("chat_perform", "ellmer")
  requests <- list()
  local_mocked_bindings(
    chat_perform = function(turns, ...) {
      requests[[length(requests) + 1L]] <<- turns
      if (length(requests) != 1L) {
        return(reply(turns = turns, ...))
      }
      httr2::response(
        status_code = 200L,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(
          list(
            id = "resp_tool",
            model = "gpt-4.1-mini",
            status = "completed",
            output = list(list(
              type = "function_call",
              id = "fc_1",
              call_id = "call_1",
              name = "lookup",
              arguments = "{}",
              status = "completed"
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
  chat$register_tool(ellmer::tool(
    function() 42,
    "Look up the answer",
    name = "lookup"
  ))
  first <- send_prompt(
    "Look up the answer",
    chat,
    clean_chat_history = TRUE,
    stream = FALSE,
    verbose = FALSE,
    return_mode = "full"
  )
  expect_length(requests, 2L)
  expect_equal(first$response, "42")
  expect_identical(
    first$chat_history_clean,
    clean_chat_history(first$chat_history, preserve_native = TRUE)
  )
  resumed <- send_prompt(
    add_msg_to_chat_history(
      first$chat_history_clean,
      "Explain the answer",
      role = "user"
    ),
    chat,
    clean_chat_history = TRUE,
    stream = FALSE,
    verbose = FALSE,
    return_mode = "full"
  )
  expect_equal(resumed$response, "42")
  expect_length(requests, 3L)
  contents <- unlist(
    lapply(requests[[3]], function(turn) turn@contents),
    recursive = FALSE
  )
  calls <- Filter(
    function(x) inherits(x, "ellmer::ContentToolRequest"),
    contents
  )
  results <- Filter(
    function(x) inherits(x, "ellmer::ContentToolResult"),
    contents
  )
  expect_length(calls, 1L)
  expect_length(results, 1L)
  expect_identical(results[[1]]@request, calls[[1]])
  expect_identical(calls[[1]]@id, "fc_1")
  expect_length(chat$get_turns(), 0L)
})
