test_that("structured streaming emits JSON chunks and retains native R coercion", {
  local_ellmer_response('{"wrapper":[{"value":1},{"value":2}]}', citations = FALSE)
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini",
    credentials = function() "test-only", echo = "none")
  p <- llm_provider_ellmer(ch, verbose = FALSE)
  chunks <- character()
  p$stream_callback <- function(chunk, meta) chunks <<- c(chunks, chunk)
  prompt <- answer_as_json("Rows", type = "ellmer",
    schema = ellmer::type_array(ellmer::type_object(value = ellmer::type_number())))
  result <- send_prompt(prompt, p, stream = TRUE, verbose = FALSE, return_mode = "full")
  expect_s3_class(result$response, "data.frame")
  expect_equal(result$response$value, c(1, 2))
  expect_equal(paste(chunks, collapse = ""), '{"wrapper":[{"value":1},{"value":2}]}')
  expect_length(result$ellmer_chat$get_turns(), 2L)
})

test_that("providers using tool-based structured output are detected before sending", {
  skip_if_not_installed("ellmer", "0.5.0")
  ch <- ellmer::chat_anthropic(model = "claude-3-haiku-20240307",
    credentials = function() "test-only", echo = "none")
  expect_null(ellmer_structured_stream(ch, ellmer::type_string()))
  expect_length(ch$get_turns(), 0L)
  # Older versions and custom adapters keep the synchronous extraction path.
  expect_null(ellmer_structured_stream(fake_ellmer_chat(), ellmer::type_string()))
})
