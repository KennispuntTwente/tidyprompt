test_that("rich schemas preserve constraints in both directions", {
  skip_if_not_installed("ellmer")
  schemas <- list(
    list(type = "integer", minimum = 0, maximum = 100),
    list(type = "string", pattern = "^[A-Z]+$", minLength = 2),
    list(type = "integer", enum = c(1L, 2L)),
    list(anyOf = list(list(type = "string"), list(type = "null"))),
    list(type = "object", additionalProperties = list(type = "integer"))
  )
  for (schema in schemas) {
    dual <- normalize_schema_dual(schema)
    expect_identical(dual$json_schema, schema)
    expect_identical(ellmer_type_to_json_schema(dual$ellmer_type), schema)
  }
  expect_error(answer_as_json("x", schema = list(nonsense = TRUE)), "JSON Schema")
})

test_that("native results enforce bounds while retaining native R shapes", {
  skip_if_not_installed("ellmer")
  skip_if_not_installed("jsonvalidate")
  schema <- list(type = "object", properties = list(x = list(type = "integer", minimum = 0)),
    required = "x", additionalProperties = FALSE)
  prompt <- answer_as_json("x", schema = schema, schema_strict = TRUE, type = "ellmer")
  extract <- prompt$get_prompt_wraps()[[1]]$extraction_fn
  provider <- new.env()
  provider$api_type <- "ellmer"
  provider$parameters <- list(.native_structured_result = list(x = -10))
  expect_s3_class(extract('{"x":-10}', provider), "llm_feedback")
  provider$parameters <- list(.native_structured_result = list(x = 1L))
  expect_identical(extract('{"x":1}', provider), list(x = 1L))
  rows <- data.frame(x = 1L)
  array_schema <- list(type = "array", items = schema)
  expect_true(validate_native_schema(rows, array_schema))
  expect_s3_class(validate_native_schema(data.frame(x = -1L), array_schema), "llm_feedback")
})
