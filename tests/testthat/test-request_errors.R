test_that("send_prompt preserves real HTTP errors for both request modes and providers", {
  skip_if_not_installed("webfakes")
  app <- webfakes::new_app()
  app$post("/error", function(req, res) {
    res$set_status(400L)$
      set_header("x-request-id", "request-integration-400")$
      set_header("Content-Type", "application/json")$
      send(paste0(
        '{"error":{"message":"Unsupported test parameter","code":"invalid_parameter"},',
        '"debug":"PRIVATE_RESPONSE_BODY_SENTINEL"}'
      ))
  })
  server <- webfakes::new_app_process(app)
  withr::defer(server$stop())

  for (stream in c(FALSE, TRUE)) {
    for (provider_name in c("openai", "ollama")) {
      parameters <- list(model = "test-model", stream = stream)
      provider <- if (provider_name == "openai") {
        llm_provider_openai(parameters = parameters, url = server$url("/error"),
          api_key = "test-only", verbose = FALSE)
      } else {
        llm_provider_ollama(parameters = parameters, url = server$url("/error"),
          verbose = FALSE)
      }
      error <- tryCatch(send_prompt("test prompt", provider, verbose = FALSE),
        error = identity)

      expect_s3_class(error, "tidyprompt_request_error")
      expect_equal(error$status_code, 400L)
      expect_identical(error$request_id, "request-integration-400")
      expect_s3_class(error$parent, "httr2_http_400")
      expect_equal(httr2::resp_status(error$parent$resp), 400L)
      expect_identical(httr2::resp_header(error$parent$resp, "x-request-id"),
        "request-integration-400")
      expect_match(conditionMessage(error), "Unsupported test parameter", fixed = TRUE)
      expect_match(conditionMessage(error), "HTTP 400", fixed = TRUE)
      expect_false(grepl("PRIVATE_RESPONSE_BODY_SENTINEL", conditionMessage(error), fixed = TRUE))
    }
  }
})

test_that("request diagnostics survive missing headers and non-JSON responses", {
  skip_if_not_installed("webfakes")
  app <- webfakes::new_app()
  app$post("/error", function(req, res) {
    res$set_status(400L)$set_header("Content-Type", "text/plain")$
      send("PRIVATE_NON_JSON_BODY")
  })
  server <- webfakes::new_app_process(app)
  withr::defer(server$stop())
  for (stream in c(FALSE, TRUE)) {
    provider <- llm_provider_openai(
      parameters = list(model = "test-model", stream = stream),
      api_key = "test-only", url = server$url("/error"), verbose = FALSE
    )
    error <- tryCatch(send_prompt("test prompt", provider, verbose = FALSE), error = identity)
    expect_s3_class(error, "tidyprompt_request_error")
    expect_equal(error$status_code, 400L)
    expect_null(error$request_id)
    expect_s3_class(error$parent, "httr2_http_400")
    expect_false(grepl("PRIVATE_NON_JSON_BODY", conditionMessage(error), fixed = TRUE))
  }
})

test_that("transport errors retain their original condition without invented HTTP metadata", {
  original <- structure(
    list(message = "Could not resolve host", call = quote(connect_to_provider())),
    class = c("httr2_failure", "error", "condition")
  )
  # A deterministic transport failure at the HTTP boundary; send_prompt and
  # tidyprompt's error handler remain real in both modes.
  local_mocked_bindings(
    req_perform = function(...) stop(original),
    req_perform_connection = function(...) stop(original),
    .package = "httr2"
  )
  for (stream in c(FALSE, TRUE)) {
    provider <- llm_provider_openai(
      parameters = list(model = "test-model", stream = stream),
      api_key = "test-only", url = "https://example.invalid", verbose = FALSE
    )
    error <- tryCatch(send_prompt("test prompt", provider, verbose = FALSE), error = identity)
    expect_s3_class(error, "tidyprompt_request_error")
    expect_identical(error$parent, original)
    expect_identical(conditionCall(error$parent), quote(connect_to_provider()))
    expect_null(error$status_code)
    expect_null(error$request_id)
    expect_match(conditionMessage(error), "Could not resolve host", fixed = TRUE)
  }
})

test_that("provider message extraction handles Ollama, malformed JSON and alternate request IDs", {
  cases <- list(
    list(body = '{"error":"model not found","debug":"PRIVATE_BODY"}',
         message = "model not found"),
    list(body = '{"message":"bad parameter","debug":"PRIVATE_BODY"}',
         message = "bad parameter"),
    list(body = '{broken json', message = NULL),
    list(body = '[1,2]', message = NULL),
    list(body = '{"error":{"message":["not","a","string"]}}', message = NULL)
  )
  for (case in cases) {
    response <- httr2::response(
      status_code = 400L,
      headers = list("content-type" = "application/json", "apim-request-id" = "azure-request"),
      body = charToRaw(case$body)
    )
    original <- structure(list(message = "HTTP 400", call = NULL, resp = response),
      class = c("httr2_http_400", "error", "condition"))
    error <- tryCatch(req_llm_handle_error(original), error = identity)
    expect_identical(error$parent, original)
    expect_identical(error$request_id, "azure-request")
    expect_equal(error$status_code, 400L)
    if (!is.null(case$message)) {
      expect_match(conditionMessage(error), case$message, fixed = TRUE)
    }
    expect_false(grepl("PRIVATE_BODY", conditionMessage(error), fixed = TRUE))
  }
})
