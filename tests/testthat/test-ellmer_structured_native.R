test_that("structured extraction diagnoses the full native tool registry", {
  local_ellmer_response('{"value":42}', citations = FALSE)
  reply <- getFromNamespace("chat_perform", "ellmer")
  requests <- list()
  local_mocked_bindings(
    chat_perform = function(tools, ...) {
      requests[length(requests) + 1L] <<- list(tools)
      reply(tools = tools, ...)
    },
    .package = "ellmer"
  )
  tool <- ellmer::tool(function() "ok", "A tool", name = "lookup")
  for (stream in c(FALSE, TRUE)) {
    for (location in c("base", "prompt", "both", "none")) {
      chat <- ellmer::chat_openai(
        model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none"
      )
      if (location %in% c("base", "both")) chat$register_tool(tool)
      prompt <- answer_as_json(
        "Question", schema = ellmer::type_object(value = ellmer::type_integer()),
        type = "ellmer"
      )
      if (location %in% c("prompt", "both")) {
        prompt <- answer_using_tools(prompt, list(other = tool), type = "ellmer")
      }
      evaluate <- function() send_prompt(
        prompt, chat, stream = stream, verbose = FALSE, max_interactions = 1,
        return_mode = "full"
      )
      if (location == "none") {
        expect_message(result <- evaluate(), NA)
      } else {
        expect_message(result <- evaluate(), "suppresses tool use")
      }
      expect_equal(result$response$value, 42L)
      expect_length(tail(requests, 1L)[[1]], 0L)
      expect_length(chat$get_tools(), as.integer(location %in% c("base", "both")))
      expect_length(result$ellmer_chat$get_tools(), switch(location, base = 1, prompt = 1, both = 2, none = 0))
    }
  }
})

testthat::test_that("ellmer structured output uses native result without round-trip", {
  testthat::skip_if_not_installed("ellmer")

  # The fake chat returns list(result = "ok", type = ...) from chat_structured.
  # After the fix, answer_as_json extraction should receive this directly
  # rather than a JSON round-tripped version.

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  schema <- ellmer::type_from_schema(
    '{"type":"object","properties":{"result":{"type":"string"}},"required":["result"],"additionalProperties":true}'
  )

  result <- "Return a result" |>
    answer_as_json(schema = schema, type = "ellmer") |>
    send_prompt(provider)

  # The result should be the native R list from chat_structured, not reparsed
  testthat::expect_true(is.list(result))
  testthat::expect_equal(result$result, "ok")
})

testthat::test_that("native_structured_result is cleared after use", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  schema <- ellmer::type_from_schema(
    '{"type":"object","properties":{"result":{"type":"string"}},"required":["result"],"additionalProperties":true}'
  )

  # send_prompt clones the provider, so the original should be unaffected
  result <- "Test" |>
    answer_as_json(schema = schema, type = "ellmer") |>
    send_prompt(provider, return_mode = "full")

  # The original provider should not have the native result stashed
  testthat::expect_null(provider$parameters$.native_structured_result)
})

testthat::test_that("ellmer warns when structured output and tools are both requested", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  schema <- ellmer::type_from_schema(
    '{"type":"object","properties":{"result":{"type":"string"}},"required":["result"],"additionalProperties":true}'
  )
  dummy_tool <- ellmer::tool(
    function() "ok",
    "A dummy tool"
  )

  # Combining answer_as_json (ellmer native) + answer_using_tools (ellmer)
  # should emit a warning about chat_structured suppressing tool use
  tp <- "Do something" |>
    answer_as_json(schema = schema, type = "ellmer") |>
    answer_using_tools(tools = list(dummy = dummy_tool), type = "ellmer")

  testthat::expect_message(
    send_prompt(tp, provider, verbose = FALSE),
    "suppresses tool use"
  )
})
