# tests/testthat/test-ellmer_json_compatability.R

# This tests the helper functions in R/helper_ellmer_json_compatibility.R
#   and ensures that the conversion between JSON schema and ellmer types works correctly

# library(testthat)
# devtools::load_all()

# ---- Helpers ---------------------------------------------------------------

# Recursively remove NULLs
strip_nulls <- function(x) {
  if (is.list(x)) {
    x <- lapply(x, strip_nulls)
    x <- x[!vapply(x, is.null, logical(1))]
  }
  x
}

# Canonicalize schema for stable comparisons:
# - sort `properties` by name at every depth
# - sort `required` character vectors
canonicalize_schema <- function(x) {
  if (!is.list(x)) {
    return(x)
  }

  x <- strip_nulls(x)

  # sort nested object properties
  if (!is.null(x$properties) && is.list(x$properties)) {
    nms <- names(x$properties)
    if (!is.null(nms)) {
      ord <- order(nms)
      x$properties <- x$properties[ord]
      x$properties <- lapply(x$properties, canonicalize_schema)
    }
  }

  # arrays: canonicalize the `items` schema
  if (!is.null(x$items)) {
    x$items <- canonicalize_schema(x$items)
  }

  # sort required names
  if (!is.null(x$required) && is.atomic(x$required)) {
    x$required <- sort(unique(x$required))
  }

  # Recurse over any other nested lists
  for (nm in names(x)) {
    if (nm %in% c("properties", "items")) {
      next
    }
    if (is.list(x[[nm]])) x[[nm]] <- canonicalize_schema(x[[nm]])
  }
  x
}

expect_schema_equal <- function(a, b) {
  testthat::expect_equal(canonicalize_schema(a), canonicalize_schema(b))
}

# ---- Basic detectors -------------------------------------------------------

testthat::test_that("is_json_schema_list detects typical shapes", {
  plain <- list(type = "string")
  wrapped <- list(
    name = "Thing",
    strict = TRUE,
    schema = list(type = "object", properties = list(x = list(type = "number")))
  )
  not_schema <- list(a = 1, b = 2)

  testthat::expect_true(is_json_schema_list(plain))
  testthat::expect_true(is_json_schema_list(wrapped))
  testthat::expect_false(is_json_schema_list(not_schema))
})

test_that("object respects additionalProperties flag", {
  testthat::skip_if_not_installed("ellmer")

  s <- list(
    type = "object",
    properties = list(x = list(type = "string")),
    required = "x"
  )
  ty_strict <- json_schema_to_ellmer_type(s, strict = TRUE)
  ty_loose <- json_schema_to_ellmer_type(s, strict = FALSE)

  back_strict <- ellmer_type_to_json_schema(ty_strict, strict = TRUE)
  back_loose <- ellmer_type_to_json_schema(ty_loose, strict = TRUE)

  expect_false(isTRUE(back_strict$additionalProperties))
  expect_true(isTRUE(back_loose$additionalProperties))
})

testthat::test_that("nested object without description converts cleanly", {
  testthat::skip_if_not_installed("ellmer")

  schema <- list(
    type = "object",
    properties = list(
      outer = list(
        type = "object",
        properties = list(
          inner = list(type = "boolean")
        ),
        required = "inner"
        # no description here on purpose
      )
    ),
    required = "outer"
  )

  ty <- json_schema_to_ellmer_type(schema, strict = TRUE)
  testthat::expect_true(is_ellmer_type(ty))

  back <- ellmer_type_to_json_schema(ty, strict = TRUE)

  # With strict=TRUE, both levels should have additionalProperties = FALSE
  testthat::expect_false(isTRUE(back$additionalProperties))
  testthat::expect_false(isTRUE(back$properties$outer$additionalProperties))
  testthat::expect_equal(back$properties$outer$required, "inner")
})


# ---- Round-trip: JSON -> ellmer -> JSON -----------------------------------

testthat::test_that("round-trip preserves structure incl. required and strict", {
  testthat::skip_if_not_installed("ellmer")

  schema <- list(
    type = "object",
    description = "root",
    properties = list(
      name = list(type = "string", description = "Name"),
      age = list(type = "integer"), # optional
      tags = list(type = "array", items = list(type = "string")),
      role = list(enum = c("admin", "user")),
      prefs = list(
        type = "object",
        properties = list(
          notify = list(type = "boolean")
        ),
        required = c("notify")
      )
    ),
    required = c("name")
    # additionalProperties omitted on purpose
  )

  # strict=TRUE should force additionalProperties=FALSE on the object(s)
  ty <- json_schema_to_ellmer_type(schema, strict = TRUE)
  testthat::expect_true(is_ellmer_type(ty))

  back <- ellmer_type_to_json_schema(ty, strict = TRUE)

  expected <- schema
  expected$additionalProperties <- FALSE
  # nested object prefs should also have explicit additionalProperties per our conversion
  expected$properties$prefs$additionalProperties <- FALSE

  expect_schema_equal(back, expected)
})

testthat::test_that("array with missing items defaults to string items", {
  testthat::skip_if_not_installed("ellmer")

  schema <- list(
    type = "object",
    properties = list(
      things = list(type = "array") # no `items` provided
    )
  )

  ty <- json_schema_to_ellmer_type(schema, strict = FALSE)
  back <- ellmer_type_to_json_schema(ty, strict = FALSE)

  # Expect items defaulted to string
  testthat::expect_equal(back$properties$things$type, "array")
  testthat::expect_equal(back$properties$things$items$type, "string")
  # With strict=FALSE, additionalProperties should default TRUE
  testthat::expect_true(isTRUE(back$additionalProperties))
})

testthat::test_that("enum values survive a JSON->ellmer->JSON roundtrip", {
  testthat::skip_if_not_installed("ellmer")

  schema <- list(
    type = "object",
    properties = list(
      color = list(enum = c("red", "green", "blue"))
    ),
    required = c("color")
  )

  ty <- json_schema_to_ellmer_type(schema, strict = TRUE)
  back <- ellmer_type_to_json_schema(ty, strict = TRUE)

  testthat::expect_equal(back$properties$color$enum, c("red", "green", "blue"))
  testthat::expect_equal(sort(back$required), "color")
  testthat::expect_false(isTRUE(back$additionalProperties))
})

# ---- Wrapper unwrapping ----------------------------------------------------

testthat::test_that("json_schema_to_ellmer_type unwraps {name, schema, strict}", {
  testthat::skip_if_not_installed("ellmer")

  inner <- list(
    type = "object",
    properties = list(x = list(type = "string")),
    required = "x"
  )
  wrapper <- list(name = "X", strict = TRUE, schema = inner)

  ty <- json_schema_to_ellmer_type(wrapper, strict = TRUE)
  testthat::expect_true(is_ellmer_type(ty))

  back <- ellmer_type_to_json_schema(ty, strict = TRUE)

  expected <- inner
  expected$additionalProperties <- FALSE
  expect_schema_equal(back, expected)
})

# ---- normalize_schema_dual -------------------------------------------------

testthat::test_that("normalize_schema_dual returns both sides from JSON input", {
  testthat::skip_if_not_installed("ellmer")

  schema <- list(type = "string", description = "a string")
  out <- normalize_schema_dual(schema, strict = FALSE)

  testthat::expect_type(out, "list")
  testthat::expect_true(is.list(out$json_schema))
  testthat::expect_true(is_ellmer_type(out$ellmer_type))
})

testthat::test_that("normalize_schema_dual returns both sides from ellmer input", {
  testthat::skip_if_not_installed("ellmer")

  ty <- ellmer::type_object(
    id = ellmer::type_integer(required = TRUE),
    note = ellmer::type_string(required = FALSE)
  )
  out <- normalize_schema_dual(ty, strict = TRUE)

  testthat::expect_true(is.list(out$json_schema))
  testthat::expect_true(is_ellmer_type(out$ellmer_type))

  # Required should include only id; strict=TRUE -> no additional properties
  testthat::expect_equal(out$json_schema$required, "id")
  testthat::expect_false(isTRUE(out$json_schema$additionalProperties))
})

# ---- Ellmer attributes: required flags ------------------------------------

testthat::test_that("optional vs required fields preserved across roundtrip", {
  testthat::skip_if_not_installed("ellmer")

  schema <- list(
    type = "object",
    properties = list(
      a = list(type = "string"), # optional
      b = list(type = "number") # optional
    ),
    required = "b"
  )

  ty <- json_schema_to_ellmer_type(schema, strict = FALSE)

  # Inspect required attributes on child ellmer nodes
  atts <- attributes(ty)
  atts_a <- atts$properties$a |> attributes()
  a_req <- atts_a$required
  atts_b <- atts$properties$b |> attributes()
  b_req <- atts_b$required

  testthat::expect_identical(a_req, FALSE)
  testthat::expect_true(isTRUE(b_req))

  # Back to JSON: only "b" should be required
  back <- ellmer_type_to_json_schema(ty, strict = FALSE)
  testthat::expect_equal(sort(back$required), "b")
  testthat::expect_true(isTRUE(back$additionalProperties))
})
