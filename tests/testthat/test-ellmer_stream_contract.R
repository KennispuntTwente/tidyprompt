test_that("ellmer supplies the private structured-stream contracts we depend on", {
  skip_if_not_installed("ellmer", "0.5.0")
  helpers <- ellmer_structured_stream_helpers()
  expect_named(helpers, c(
    "uses_tool_structured_output", "type_needs_wrapper",
    "wrap_type_if_needed", "extract_data"
  ))
  expect_true(all(vapply(helpers, is.function, logical(1))))
})

test_that("incomplete or changed private signatures disable structured streaming", {
  skip_if_not_installed("ellmer", "0.5.0")
  helpers <- ellmer_structured_stream_helpers()
  for (name in names(helpers)) {
    for (replacement in list(NULL, 1L, function(renamed) NULL)) {
      ns <- list2env(helpers, parent = emptyenv())
      ns[[name]] <- replacement
      expect_null(ellmer_structured_stream_helpers(ns))
    }
  }
  ns <- list2env(helpers, parent = emptyenv())
  ns$extract_data <- function(turn, type, convert, needs_wrapper, new_required) NULL
  expect_null(ellmer_structured_stream_helpers(ns))
  ns$extract_data <- function(turn, type, convert, needs_wrapper, optional = NULL) NULL
  expect_false(is.null(ellmer_structured_stream_helpers(ns)))
})

test_that("private API fallback happens before the single blocking request", {
  local_ellmer_response('{"value":42}', citations = FALSE)
  reply <- getFromNamespace("chat_perform", "ellmer")
  modes <- character()
  local_mocked_bindings(chat_perform = function(mode, ...) {
    modes <<- c(modes, mode)
    reply(mode = mode, ...)
  }, .package = "ellmer")
  original <- ellmer_structured_stream_helpers()
  for (helpers in list(NULL, within(original, {
    type_needs_wrapper <- function(type, provider) stop("Changed upstream API")
  }))) {
    local_mocked_bindings(ellmer_structured_stream_helpers = function() helpers)
    chat <- ellmer::chat_openai(
      model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none"
    )
    expect_null(ellmer_structured_stream(chat, ellmer::type_string()))
    expect_length(chat$get_turns(), 0L)
    result <- send_prompt(answer_as_json(
      "Question", type = "ellmer",
      schema = ellmer::type_object(value = ellmer::type_integer())
    ), chat, stream = TRUE, verbose = FALSE)
    expect_equal(result$value, 42L)
  }
  expect_equal(modes, c("value", "value"))
})

test_that("structured stream extraction matches blocking conversion across types", {
  skip_if_not_installed("ellmer", "0.5.0")
  cases <- list(
    list(type = ellmer::type_string(), json = '{"wrapper":"answer"}'),
    list(type = ellmer::type_array(ellmer::type_enum(c("a", "b"))), json = '{"wrapper":["a","b"]}'),
    list(type = ellmer::type_array(ellmer::type_integer()), json = '{"wrapper":[]}'),
    list(type = ellmer::type_object(rows = ellmer::type_array(ellmer::type_object(
      tags = ellmer::type_array(ellmer::type_string()),
      value = ellmer::type_integer(required = FALSE)
    ))), json = '{"rows":[{"tags":["a","b"],"value":1},{"tags":[],"value":null}]}'),
    list(type = ellmer::type_from_schema('{"type":"object","properties":{"value":{"type":"integer","minimum":1}}}'),
      json = '{"value":42}')
  )
  for (case in cases) {
    local_ellmer_response(case$json, citations = FALSE)
    chat <- ellmer::chat_openai(
      model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none"
    )
    expected <- chat$clone()$chat_structured("Question", type = case$type)
    contract <- ellmer_structured_stream(chat, case$type)
    expect_true(is.function(contract$extract))
    expect_length(chat$get_turns(), 0L)
    coro::collect(chat$stream("Question", type = case$type))
    expect_identical(contract$extract(), expected)
    expect_length(chat$get_turns(), 2L)
  }
})

test_that("extraction failures after structured streaming do not retry a request", {
  local_ellmer_response('{"value":42}', citations = FALSE)
  reply <- getFromNamespace("chat_perform", "ellmer")
  requests <- 0L
  local_mocked_bindings(chat_perform = function(...) {
    requests <<- requests + 1L
    reply(...)
  }, .package = "ellmer")
  helpers <- ellmer_structured_stream_helpers()
  helpers$extract_data <- function(...) stop("Extraction contract changed")
  local_mocked_bindings(ellmer_structured_stream_helpers = function() helpers)
  chat <- ellmer::chat_openai(
    model = "gpt-4.1-mini", credentials = function() "test-only", echo = "none"
  )
  expect_error(send_prompt(answer_as_json(
    "Question", type = "ellmer",
    schema = ellmer::type_object(value = ellmer::type_integer())
  ), chat, stream = TRUE, verbose = FALSE), "Extraction contract changed")
  expect_equal(requests, 1L)
})
