local_request_limit_transport <- function(tool_rounds = 0L, .local_envir = parent.frame()) {
  state <- new.env(parent = emptyenv())
  state$requests <- 0L
  state$bodies <- list()
  respond <- function(req, api_type, ...) {
    state$requests <- state$requests + 1L
    state$bodies[[state$requests]] <- req$body$data
    message <- list(role = "assistant", content = "ok")
    if (state$requests <= tool_rounds) {
      message$content <- ""
      message$tool_calls <- list(list(id = paste0("call_", state$requests),
        type = "function", `function` = list(name = "lookup",
          arguments = if (api_type == "openai") "{}" else list())))
    }
    payload <- if (api_type == "openai") list(choices = list(list(message = message))) else list(message = message)
    list(new = data.frame(role = "assistant", content = message$content),
      httr2_response = httr2::response(status_code = 200L,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(payload, auto_unbox = TRUE))))
  }
  local_mocked_bindings(req_llm_non_stream = respond, req_llm_stream = respond,
    .package = "tidyprompt", .env = .local_envir)
  state
}

request_limit_provider <- function(api_type, stream) {
  if (api_type == "openai") {
    llm_provider_openai(parameters = list(model = "test-model", stream = stream),
      api_key = "test-only", url = "https://example.invalid/v1/chat/completions", verbose = FALSE)
  } else {
    llm_provider_ollama(parameters = list(model = "test-model", stream = stream),
      url = "https://example.invalid/api/chat", verbose = FALSE)
  }
}

test_that("regular providers count feedback requests once and reset between evaluations", {
  state <- local_request_limit_transport()
  # Ordinary providers do not need ellmer installed to enforce a limit.
  local_mocked_bindings(ellmer_available = function() FALSE)
  for (api_type in c("openai", "ollama")) {
    for (stream in c(FALSE, TRUE)) {
      provider <- request_limit_provider(api_type, stream)
      before <- state$requests
      expect_equal(send_prompt(limit_requests("Question", 1), provider, verbose = FALSE), "ok")
      expect_equal(state$requests - before, 1L)
      prompt <- limit_requests(prompt_wrap("Question",
        validation_fn = function(...) llm_feedback("Again")), 2)
      for (i in 1:2) {
        before <- state$requests
        err <- tryCatch(send_prompt(prompt, provider, verbose = FALSE), tidyprompt_request_limit = identity)
        expect_s3_class(err, "tidyprompt_request_limit")
        expect_equal(err$requests, 2L)
        expect_equal(err$max_requests, 2)
        expect_equal(state$requests - before, 2L)
        expect_s3_class(err$llm_provider, "LlmProvider")
        expect_null(err$ellmer_chat)
        expect_null(provider$parameters$.request_guard)
        # No unused first-request exemption survives an error.
        expect_error(err$llm_provider$complete_chat("Continue"), class = "tidyprompt_request_limit")
        expect_equal(state$requests - before, 2L)
      }
    }
  }
  expect_true(all(vapply(state$bodies, function(x) !".request_guard" %in% names(x), logical(1))))
})

test_that("regular native tool loops count follow-up model requests", {
  for (api_type in c("openai", "ollama")) {
    for (stream in c(FALSE, TRUE)) {
      state <- local_request_limit_transport(tool_rounds = 2L)
      tool <- tools_add_docs(function() "Data", list(name = "lookup",
        description = "Lookup", arguments = list()))
      prompt <- answer_using_tools("Question", tools = list(lookup = tool), type = api_type)
      provider <- request_limit_provider(api_type, stream)
      err <- tryCatch(send_prompt(limit_requests(prompt, 2), provider, verbose = FALSE),
        tidyprompt_request_limit = identity)
      expect_s3_class(err, "tidyprompt_request_limit")
      expect_equal(state$requests, 2L)
      expect_equal(err$requests, 2L)
      state$requests <- 0L
      expect_equal(send_prompt(limit_requests(prompt, 3), provider, verbose = FALSE), "ok")
      expect_equal(state$requests, 3L)
    }
  }
})

test_that("custom completions are limited even without the shared transport", {
  state <- new.env(parent = emptyenv())
  state$requests <- 0L
  provider <- `llm_provider-class`$new(function(history) {
    state <- self$parameters$.state
    state$requests <- state$requests + 1L
    list(completed = dplyr::bind_rows(history, data.frame(role = "assistant", content = "ok")),
      http = list(request = NULL, response = NULL))
  }, parameters = list(.state = state), verbose = FALSE)
  prompt <- prompt_wrap("Question", validation_fn = function(...) llm_feedback("Again"))
  for (limits in list(c(1, 3), c(3, 1))) {
    before <- state$requests
    bounded <- limit_requests(limit_requests(prompt, limits[1]), limits[2])
    expect_error(send_prompt(bounded, provider, verbose = FALSE), class = "tidyprompt_request_limit")
    expect_equal(state$requests - before, 1L)
  }
})

test_that("custom completions using multiple shared requests cannot bypass the limit", {
  state <- local_request_limit_transport()
  provider <- `llm_provider-class`$new(function(history) {
    for (i in 1:3) {
      result <- request_llm_provider(history,
        httr2::request("https://example.invalid/v1/chat/completions"),
        stream = FALSE, verbose = FALSE, api_type = "openai", llm_provider = self)
    }
    result
  }, verbose = FALSE)
  expect_error(send_prompt(limit_requests("Question", 2), provider, verbose = FALSE),
    class = "tidyprompt_request_limit")
  expect_equal(state$requests, 2L)
  state$requests <- 0L
  expect_equal(send_prompt(limit_requests("Question", 3), provider, verbose = FALSE), "ok")
  expect_equal(state$requests, 3L)
})

test_that("the Gemini provider keeps request guards out of its API payload", {
  requests <- 0L
  local_mocked_bindings(req_perform = function(req, ...) {
    requests <<- requests + 1L
    expect_false(".request_guard" %in% names(req$body$data))
    httr2::response(status_code = 200L, headers = list("content-type" = "application/json"),
      body = charToRaw('{"candidates":[{"content":{"parts":[{"text":"ok"}]}}]}'))
  }, .package = "httr2")
  provider <- llm_provider_google_gemini(api_key = "test-only", verbose = FALSE,
    url = "https://example.invalid/")
  prompt <- limit_requests(prompt_wrap("Question",
    validation_fn = function(...) llm_feedback("Again")), 2)
  expect_error(send_prompt(prompt, provider, verbose = FALSE), class = "tidyprompt_request_limit")
  expect_equal(requests, 2L)
})

test_that("request limits validate their input and native hook support", {
  for (value in list(0, -1, 1.5, NA_real_, Inf, numeric(), c(1, 2), "1")) {
    expect_error(limit_requests("Question", value), "positive whole number")
  }
  provider <- llm_provider_ellmer(fake_ellmer_chat(), parameters = list(stream = FALSE), verbose = FALSE)
  expect_error(send_prompt(limit_requests("Question", 1), provider), "0.5.0 request hooks")
})
