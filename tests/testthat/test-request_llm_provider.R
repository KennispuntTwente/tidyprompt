testthat::test_that("request_llm_provider normalizes sparse tool metadata", {
  testthat::skip_if_not_installed("httr2")

  testthat::local_mocked_bindings(
    req_llm_non_stream = function(req, api_type, verbose) {
      list(
        new = data.frame(
          role = "assistant",
          content = "pong",
          stringsAsFactors = FALSE
        ),
        httr2_response = NULL
      )
    },
    .package = "tidyprompt"
  )

  history <- data.frame(
    role = "user",
    content = "ping",
    tool_call = FALSE,
    tool_call_id = NA_character_,
    tool_result = FALSE,
    stringsAsFactors = FALSE
  )

  result <- request_llm_provider(
    chat_history = history,
    request = httr2::request("https://example.com/v1/chat/completions"),
    stream = FALSE,
    verbose = FALSE,
    api_type = "openai"
  )

  testthat::expect_equal(result$completed$tool_call, c(FALSE, FALSE))
  testthat::expect_true(all(is.na(result$completed$tool_call_id)))
  testthat::expect_equal(result$completed$tool_result, c(FALSE, FALSE))
})
