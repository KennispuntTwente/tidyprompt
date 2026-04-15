testthat::test_that("is_ellmer_builtin_tool detects ToolBuiltIn objects", {
  testthat::skip_if_not_installed("ellmer")
  ellmer_ns <- asNamespace("ellmer")
  testthat::skip_if_not(
    exists("ToolBuiltIn", envir = ellmer_ns),
    "ToolBuiltIn not available in this ellmer version"
  )

  tbi <- ellmer_ns$ToolBuiltIn(
    name = "web_search"
  )
  testthat::expect_true(is_ellmer_builtin_tool(tbi))
  testthat::expect_true(is_ellmer_any_tool(tbi))
  testthat::expect_false(is_ellmer_tool(tbi))
})

testthat::test_that("normalize_tool_dual handles ToolBuiltIn", {
  testthat::skip_if_not_installed("ellmer")
  ellmer_ns <- asNamespace("ellmer")
  testthat::skip_if_not(
    exists("ToolBuiltIn", envir = ellmer_ns),
    "ToolBuiltIn not available in this ellmer version"
  )

  tbi <- ellmer_ns$ToolBuiltIn(
    name = "web_search"
  )
  dual <- normalize_tool_dual(tbi)

  # ToolBuiltIn has no tidyprompt equivalent
  testthat::expect_null(dual$tidyprompt_tool)
  # But should be passed through as the ellmer tool
  testthat::expect_identical(dual$ellmer_tool, tbi)
})

testthat::test_that("answer_using_tools accepts ToolBuiltIn in tool list", {
  testthat::skip_if_not_installed("ellmer")
  ellmer_ns <- asNamespace("ellmer")
  testthat::skip_if_not(
    exists("ToolBuiltIn", envir = ellmer_ns),
    "ToolBuiltIn not available in this ellmer version"
  )

  my_fun <- function(x) x
  my_fun <- tools_add_docs(
    my_fun,
    list(
      name = "echo",
      description = "Echo input",
      arguments = list(x = list(type = "string"))
    )
  )

  tbi <- ellmer_ns$ToolBuiltIn(
    name = "web_search"
  )

  # Should not error when mixed ToolDef/ToolBuiltIn/function tools are passed
  result <- testthat::expect_no_error(
    "test" |>
      answer_using_tools(tools = list(echo = my_fun, search = tbi))
  )
})

testthat::test_that("answer_using_tools errors for ToolBuiltIn on non-ellmer providers", {
  testthat::skip_if_not_installed("ellmer")
  ellmer_ns <- asNamespace("ellmer")
  testthat::skip_if_not(
    exists("ToolBuiltIn", envir = ellmer_ns),
    "ToolBuiltIn not available in this ellmer version"
  )

  tbi <- ellmer_ns$ToolBuiltIn(
    name = "web_search"
  )

  testthat::expect_error(
    "test" |>
      answer_using_tools(tools = list(search = tbi), type = "text-based"),
    "built-in tools can only be used with an ellmer-backed provider"
  )

  prompt <- "test" |>
    answer_using_tools(tools = list(search = tbi))

  testthat::expect_error(
    send_prompt(prompt, llm_provider_fake(verbose = FALSE), verbose = FALSE),
    "built-in tools can only be used with an ellmer-backed provider"
  )
})
