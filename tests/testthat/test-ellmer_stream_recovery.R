test_that("rich events retain a string callback contract and citation identity", {
  local_ellmer_response()
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none")
  p <- llm_provider_ellmer(ch, parameters = list(stream = TRUE, stream_content = TRUE), verbose = FALSE)
  events <- list()
  p$stream_callback <- function(chunk, meta) events[[length(events) + 1L]] <<- list(chunk = chunk, meta = meta)
  result <- send_prompt("Question", p, verbose = FALSE, return_mode = "full")
  citation <- Filter(function(x) S7::S7_inherits(x$meta$content, ellmer::ContentCitation), events)
  expect_length(citation, 1L)
  expect_identical(citation[[1]]$chunk, "")
  expect_identical(citation[[1]]$meta$partial_response, "The answer is 42.")
  expect_identical(citation[[1]]$meta$content, result$citations[[1]])
})

test_that("cancellation exposes the native partial turn without validation or retries", {
  local_ellmer_response(c("First", " second"), citations = FALSE)
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none")
  controller <- ellmer::stream_controller()
  p <- llm_provider_ellmer(ch, parameters = list(stream = TRUE, stream_controller = controller), verbose = FALSE)
  p$stream_callback <- function(chunk, meta) controller$cancel("user requested")
  prompt <- prompt_wrap("Question", validation_fn = function(...) stop("validation must not run"))
  err <- tryCatch(send_prompt(prompt, p, verbose = FALSE), tidyprompt_stream_cancelled = identity)
  expect_s3_class(err, "tidyprompt_stream_cancelled")
  expect_equal(err$partial_response, "First")
  expect_true(S7::S7_inherits(err$partial_turn, ellmer::AssistantPartialTurn))
  expect_equal(err$partial_turn@reason, "user requested")
  expect_length(err$ellmer_chat$get_turns(), 2L)
  expect_length(ch$get_turns(), 0L)
})

test_that("lazy iteration errors preserve partial history and never issue a fallback request", {
  skip_if_not_installed("ellmer", "0.5.0")
  requests <- 0L
  local_mocked_bindings(chat_perform = function(...) {
    requests <<- requests + 1L
    coro::generator(function() {
      coro::yield(list(type = "response.output_text.delta", delta = "Partial"))
      stop("transport broke")
    })()
  }, .package = "ellmer")
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none")
  err <- tryCatch(send_prompt("Question", ch, stream = TRUE, verbose = FALSE), tidyprompt_stream_error = identity)
  expect_s3_class(err, "tidyprompt_stream_error")
  expect_match(conditionMessage(err), "transport broke")
  expect_equal(err$partial_response, "Partial")
  expect_true(S7::S7_inherits(err$partial_turn, ellmer::AssistantPartialTurn))
  expect_equal(err$partial_turn@text, "Partial")
  expect_equal(requests, 1L)
})
