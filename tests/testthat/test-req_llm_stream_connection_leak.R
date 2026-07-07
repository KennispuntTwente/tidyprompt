test_that("req_llm_stream()/request_llm_provider() close the streaming connection", {
  # Regression test for a connection leak: httr2::req_perform_connection()
  # opens a connection which, per httr2's docs, must be closed manually with
  # close(resp) once done reading, or it leaks a slot in R's hard-coded
  # 128-connection table. Previously, tidyprompt's streaming code never
  # closed the connection (it also overwrote resp$body with a plain list
  # before closing, which silently made close() a no-op even when added
  # naively). This test calls the streaming path repeatedly and asserts
  # that no connections are left open afterwards.
  skip_if_not_installed("httr2")
  skip_if_not_installed("webfakes")

  library(httr2)

  count_open_connections <- function() nrow(showConnections(all = TRUE))

  baseline <- count_open_connections()

  url <- httr2::example_url()
  dummy_history <- data.frame(
    role = "user",
    content = "hi",
    stringsAsFactors = FALSE
  )

  for (i in 1:5) {
    req <- httr2::request(url) |> httr2::req_url_path("/stream/2")

    out <- request_llm_provider(
      chat_history = dummy_history,
      request = req,
      stream = TRUE,
      verbose = FALSE,
      api_type = "ollama"
    )

    expect_true(is.data.frame(out$completed))
  }

  # No net increase in open connections: every streaming connection opened
  # above must have been closed again.
  expect_equal(count_open_connections(), baseline)
})

test_that("req_llm_stream() closes the connection even when a tool_calls/response_id is attached", {
  # More targeted check: the returned httr2_response's body should no
  # longer be the streaming connection once req_llm_stream() has returned,
  # confirming close() ran while the StreamingBody was still reachable.
  skip_if_not_installed("httr2")
  skip_if_not_installed("webfakes")

  library(httr2)

  url <- httr2::example_url()
  req <- httr2::request(url) |> httr2::req_url_path("/stream/2")

  before <- nrow(showConnections(all = TRUE))

  out <- req_llm_stream(
    req = req,
    api_type = "ollama",
    verbose = FALSE
  )

  expect_false(inherits(out$httr2_response$body, "StreamingBody"))
  expect_equal(nrow(showConnections(all = TRUE)), before)
})
