# tests/testthat/test-ellmer_tool_compatability.R
#
# This tests the helper functions in R/helper_ellmer_json_compatability.R
#   for converting between ellmer ToolDef <-> tidyprompt tools (functions+docs)

# library(testthat)
# devtools::load_all()

# ---- Local helpers (mirrors your schema helpers style) ---------------------

# Recursively remove NULLs
strip_nulls <- function(x) {
  if (is.list(x)) {
    x <- lapply(x, strip_nulls)
    x <- x[!vapply(x, is.null, logical(1))]
  }
  x
}

# Extract a minimal, stable “types-only” view from tidyprompt docs$arguments
docs_types_only <- function(docs) {
  stopifnot(is.list(docs), is.list(docs$arguments))
  arg_names <- sort(names(docs$arguments))
  out <- list()
  for (nm in arg_names) {
    a <- docs$arguments[[nm]]
    # If nested named-list: recurse on names
    if (is.list(a$type)) {
      sub <- a$type
      # ensure simple types-only without descriptions
      for (sn in names(sub)) {
        s <- sub[[sn]]
        if (is.list(s)) {
          # support deeper nesting if present
          out[[nm]][[sn]] <- if (is.list(s$type)) s$type else (s$type %||% "unknown")
        } else {
          out[[nm]][[sn]] <- s %||% "unknown"
        }
      }
    } else if (!is.null(a$enum) || identical(a$type, "match.arg")) {
      out[[nm]] <- list(type = "match.arg", values = sort(as.character(a$default_value %||% character())))
    } else {
      out[[nm]] <- a$type %||% "unknown"
    }
  }
  strip_nulls(out)
}

expect_docs_types_equal <- function(a, b) {
  testthat::expect_equal(docs_types_only(a), docs_types_only(b))
}

# Extract per-argument JSON Schemas from an ellmer ToolDef
ellmer_tool_prop_schemas <- function(tooldef, strict = TRUE) {
  props <- tryCatch(tooldef@arguments@properties, error = function(e) NULL)
  if (is.null(props)) {
    # attribute fallback
    at <- attributes(tooldef@arguments) %||% list()
    reserved <- c(
      ".additional_properties", "additional_properties", "class",
      "description", "required", "properties"
    )
    prop_names <- setdiff(names(at), reserved)
    props <- lapply(prop_names, function(nm) at[[nm]])
    names(props) <- prop_names
  }
  lapply(props, function(p) ellmer_type_to_json_schema(p, strict = strict))
}

# ---- Detection -------------------------------------------------------------

testthat::test_that("is_ellmer_tool detects ToolDef and not plain functions", {
  testthat::skip_if_not_installed("ellmer")

  add <- function(x, y) x + y
  td <- ellmer::tool(
    add,
    description = "Add two numbers",
    arguments = list(
      x = ellmer::type_number(),
      y = ellmer::type_number()
    )
  )

  testthat::expect_true(is_ellmer_tool(td))
  testthat::expect_false(is_ellmer_tool(add))
})

# ---- ellmer -> tidyprompt: docs -------------------------------------------

testthat::test_that("ellmer_tool_to_tidyprompt_docs maps common types correctly", {
  testthat::skip_if_not_installed("ellmer")

  f <- function(s, n, i, b, c, vs, obj) {
    paste(s, n, i, b, c[1], paste(vs, collapse = ","), obj$x)
  }

  td <- ellmer::tool(
    f,
    description = "Mixed args",
    arguments = list(
      s  = ellmer::type_string("S"),
      n  = ellmer::type_number(),
      i  = ellmer::type_integer(),
      b  = ellmer::type_boolean(),
      c  = ellmer::type_enum(c("a","b")),
      vs = ellmer::type_array(ellmer::type_string()),
      obj = ellmer::type_object(
        x = ellmer::type_string(),
        y = ellmer::type_integer(required = FALSE)
      )
    )
  )

  docs <- ellmer_tool_to_tidyprompt_docs(td)
  # Types-only assertions
  types <- docs_types_only(docs)
  testthat::expect_equal(types$s,  "string")
  testthat::expect_equal(types$n,  "numeric")
  testthat::expect_equal(types$i,  "integer")
  testthat::expect_equal(types$b,  "logical")
  testthat::expect_equal(types$vs, "vector string")
  testthat::expect_true(is.list(types$c))
  testthat::expect_equal(unname(types$c$type), "match.arg")
  testthat::expect_equal(unname(types$c$values), c("a","b"))
  testthat::expect_true(is.list(types$obj))
  testthat::expect_equal(types$obj$x, "string")
  testthat::expect_equal(types$obj$y, "integer")
})

# ---- ellmer -> tidyprompt: function wrapper --------------------------------

testthat::test_that("ellmer_tool_to_tidyprompt creates a working wrapper with docs", {
  testthat::skip_if_not_installed("ellmer")

  add <- function(x, y) x + y
  td <- ellmer::tool(
    add,
    description = "Add two numbers",
    arguments = list(
      x = ellmer::type_number(),
      y = ellmer::type_number()
    )
  )

  tp_fun <- ellmer_tool_to_tidyprompt(td)

  # Same behavior
  testthat::expect_identical(tp_fun(2, 3), add(2, 3))

  # Docs attached & name preserved
  tp_docs <- tools_get_docs(tp_fun)
  testthat::expect_true(is.list(tp_docs))
  testthat::expect_identical(tp_docs$name, td@name)
})

# ---- tidyprompt -> ellmer: from docs + function ----------------------------

testthat::test_that("tidyprompt_docs_to_ellmer_tool builds a ToolDef that matches formals and types", {
  testthat::skip_if_not_installed("ellmer")

  get_weather_like <- function(city, units = c("metric","imperial"), opts = list(detail = TRUE)) {
    paste(city, units[1], if (isTRUE(opts$detail)) "(detail)" else "")
  }

  docs <- list(
    name = "get_weather_like",
    description = "Demo weather-like tool",
    arguments = list(
      city  = list(type = "string",  description = "City name"),
      units = list(type = "match.arg", default_value = c("metric","imperial")),
      opts  = list(type = list(detail = "logical"))
    ),
    return = list(description = "A short string")
  )

  td <- tidyprompt_docs_to_ellmer_tool(get_weather_like, docs, strict = TRUE)
  testthat::expect_true(is_ellmer_tool(td))

  # Names must match function formals
  testthat::expect_identical(names(formals(get_weather_like)),
                             names(td@arguments@properties))

  # Per-argument schema checks
  ps <- ellmer_tool_prop_schemas(td, strict = TRUE)
  testthat::expect_equal(ps$city$type, "string")
  testthat::expect_equal(sort(ps$units$enum), c("imperial","metric"))

  # opts should be an object with a boolean subproperty "detail"
  testthat::expect_equal(ps$opts$type, "object")
  testthat::expect_equal(ps$opts$properties$detail$type, "boolean")

  # Callable and returns expected string
  res <- td(city = "London", units = "metric", opts = list(detail = TRUE))
  testthat::expect_match(res, "London metric")
})

# ---- tidyprompt -> ellmer: fills missing type defs to satisfy formals ------

testthat::test_that("tidyprompt_docs_to_ellmer_tool fills missing argument types", {
  testthat::skip_if_not_installed("ellmer")

  f <- function(a, b) a
  docs <- list(
    name = "f",
    description = "Returns a, ignores b",
    arguments = list(
      a = list(type = "string")
      # b intentionally missing
    )
  )

  td <- tidyprompt_docs_to_ellmer_tool(f, docs, strict = TRUE)
  testthat::expect_true(is_ellmer_tool(td))
  # Both names present and ordered as formals
  testthat::expect_identical(names(td@arguments@properties), c("a", "b"))

  # b gets a permissive string type
  ps <- ellmer_tool_prop_schemas(td, strict = TRUE)
  testthat::expect_equal(ps$b$type, "string")
})

# ---- Round-trip behavior ---------------------------------------------------

testthat::test_that("ellmer ToolDef -> tidyprompt fn -> ellmer ToolDef keeps behavior", {
  testthat::skip_if_not_installed("ellmer")

  greet <- function(name, excited = FALSE) {
    paste0("Hello, ", name, if (isTRUE(excited)) "!")
  }

  td <- ellmer::tool(
    greet,
    description = "Greet a person",
    arguments = list(
      name = ellmer::type_string(),
      excited = ellmer::type_boolean()
    )
  )

  # Convert to tidyprompt wrapper
  tp_fun <- ellmer_tool_to_tidyprompt(td)

  # Back to ellmer ToolDef from the tidyprompt function
  td2 <- tidyprompt_tool_to_ellmer(tp_fun, strict = TRUE)

  # Same call results on both tooldefs
  r1 <- td(name = "Ada", excited = TRUE)
  r2 <- td2(name = "Ada", excited = TRUE)
  testthat::expect_identical(r1, r2)
})

# ---- normalize_tool_dual ---------------------------------------------------

testthat::test_that("normalize_tool_dual returns both sides from ellmer input", {
  testthat::skip_if_not_installed("ellmer")

  adder <- function(x, y) x + y
  td <- ellmer::tool(
    adder,
    description = "Add",
    arguments = list(x = ellmer::type_number(), y = ellmer::type_number())
  )

  out <- normalize_tool_dual(td)
  testthat::expect_true(is.function(out$tidyprompt_tool))
  testthat::expect_true(is_ellmer_tool(out$ellmer_tool))

  # Both callable
  testthat::expect_equal(out$tidyprompt_tool(10, 5), 15)
  testthat::expect_equal(out$ellmer_tool(x = 10, y = 5), 15)
})

testthat::test_that("normalize_tool_dual returns both sides from tidyprompt function input", {
  testthat::skip_if_not_installed("ellmer")

  # a small documented function
  say <- function(text, shout = FALSE) {
    if (isTRUE(shout)) toupper(text) else text
  }
  say <- tools_add_docs(say, list(
    name = "say",
    description = "Echo text",
    arguments = list(
      text = list(type = "string"),
      shout = list(type = "logical")
    )
  ))

  out <- normalize_tool_dual(say)
  testthat::expect_true(is.function(out$tidyprompt_tool))
  testthat::expect_true(is_ellmer_tool(out$ellmer_tool))

  testthat::expect_identical(out$tidyprompt_tool("ok", FALSE), "ok")
  testthat::expect_identical(out$ellmer_tool(text = "ok", shout = FALSE), "ok")
})
