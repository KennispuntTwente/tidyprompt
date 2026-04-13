testthat::test_that("tidyprompt_docs_to_ellmer_tool respects optional args", {
  testthat::skip_if_not_installed("ellmer")

  my_tool <- function(x, y = 10) x + y
  my_tool <- tools_add_docs(
    my_tool,
    list(
      name = "add",
      description = "Add two numbers",
      arguments = list(
        x = list(type = "numeric", description = "First number"),
        y = list(type = "numeric", description = "Second number (optional)")
      )
    )
  )

  docs <- tools_get_docs(my_tool)
  td <- tidyprompt_docs_to_ellmer_tool(my_tool, docs)

  testthat::expect_true(is_ellmer_tool(td))

  # x should be required, y should be optional
  props <- .ellmer_tool_properties(td)
  x_required <- attr(props[["x"]], "required", exact = TRUE)
  y_required <- attr(props[["y"]], "required", exact = TRUE)

  testthat::expect_true(isTRUE(x_required) || is.null(x_required))
  testthat::expect_false(isTRUE(y_required))
})

testthat::test_that("tidyprompt_docs_to_ellmer_tool fills missing formals", {
  testthat::skip_if_not_installed("ellmer")

  # A function with a formal not documented
  my_tool <- function(x, extra = "default") x
  my_tool <- tools_add_docs(
    my_tool,
    list(
      name = "identity",
      description = "Return x",
      arguments = list(
        x = list(type = "string", description = "input")
      )
    )
  )

  docs <- tools_get_docs(my_tool)
  td <- tidyprompt_docs_to_ellmer_tool(my_tool, docs)

  testthat::expect_true(is_ellmer_tool(td))

  # 'extra' should be present (filled) and not required
  props <- .ellmer_tool_properties(td)
  testthat::expect_true("extra" %in% names(props))
  extra_required <- attr(props[["extra"]], "required", exact = TRUE)
  testthat::expect_false(isTRUE(extra_required))
})
