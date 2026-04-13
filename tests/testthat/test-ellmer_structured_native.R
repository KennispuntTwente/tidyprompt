testthat::test_that("ellmer structured output uses native result without round-trip", {
  testthat::skip_if_not_installed("ellmer")

  # The fake chat returns list(result = "ok", type = ...) from chat_structured.
  # After the fix, answer_as_json extraction should receive this directly
  # rather than a JSON round-tripped version.

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  schema <- ellmer::type_object(
    result = ellmer::type_string(),
    .additional_properties = TRUE
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

  schema <- ellmer::type_object(
    value = ellmer::type_string(),
    .additional_properties = TRUE
  )

  # send_prompt clones the provider, so the original should be unaffected
  result <- "Test" |>
    answer_as_json(schema = schema, type = "ellmer") |>
    send_prompt(provider, return_mode = "full")

  # The original provider should not have the native result stashed
  testthat::expect_null(provider$parameters$.native_structured_result)
})
