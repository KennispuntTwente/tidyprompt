testthat::test_that("is_ellmer_type detects type_from_schema objects", {
  testthat::skip_if_not_installed("ellmer")
  ellmer_ns <- asNamespace("ellmer")
  testthat::skip_if_not(
    exists("type_from_schema", envir = ellmer_ns),
    "type_from_schema not available in this ellmer version"
  )

  schema <- list(type = "object", properties = list(x = list(type = "string")))
  tfs <- ellmer::type_from_schema(schema)
  testthat::expect_true(is_ellmer_type(tfs))
})

testthat::test_that("ellmer_type_to_json_schema handles type_from_schema", {
  testthat::skip_if_not_installed("ellmer")
  ellmer_ns <- asNamespace("ellmer")
  testthat::skip_if_not(
    exists("type_from_schema", envir = ellmer_ns),
    "type_from_schema not available in this ellmer version"
  )

  schema <- list(
    type = "object",
    properties = list(
      name = list(type = "string"),
      age = list(type = "integer")
    ),
    required = c("name")
  )
  tfs <- ellmer::type_from_schema(schema)
  result <- ellmer_type_to_json_schema(tfs)

  testthat::expect_equal(result$type, "object")
  testthat::expect_true("name" %in% names(result$properties))
})

testthat::test_that("normalize_schema_dual works with type_from_schema", {
  testthat::skip_if_not_installed("ellmer")
  ellmer_ns <- asNamespace("ellmer")
  testthat::skip_if_not(
    exists("type_from_schema", envir = ellmer_ns),
    "type_from_schema not available in this ellmer version"
  )

  schema <- list(type = "string")
  tfs <- ellmer::type_from_schema(schema)
  dual <- normalize_schema_dual(tfs)

  testthat::expect_true(!is.null(dual$json_schema))
  testthat::expect_true(!is.null(dual$ellmer_type))
})
