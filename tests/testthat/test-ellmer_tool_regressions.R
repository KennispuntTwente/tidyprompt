test_that("renaming preserves ignored formals and does not mutate the original", {
  skip_if_not_installed("ellmer", "0.4.0")
  tool <- ellmer::tool(function(x, hidden = 2) x + hidden, name = "original",
    description = "Add", arguments = list(x = ellmer::type_number(), hidden = ellmer::type_ignore()),
    convert = FALSE, annotations = list(readOnlyHint = TRUE))
  renamed <- rename_ellmer_tool(tool, "alias")
  expect_equal(renamed(3), 5)
  expect_equal(renamed@name, "alias")
  expect_equal(tool@name, "original")
  expect_identical(renamed@arguments, tool@arguments)
  expect_identical(renamed@annotations, tool@annotations)
  expect_false(renamed@convert)
  prompt <- answer_using_tools("x", tools = list(alias = tool), type = "ellmer")
  params <- prompt$get_prompt_wraps()[[1]]$parameter_fn(list(api_type = "ellmer"))
  expect_equal(params$.ellmer_tools[[1]]@name, "alias")
})

test_that("zero-argument functions register and failed conversions are explicit", {
  skip_if_not_installed("ellmer")
  fn <- tools_add_docs(function() "yes", list(name = "noargs", description = "No args",
    arguments = list()))
  prompt <- answer_using_tools("x", tools = fn, type = "ellmer")
  params <- prompt$get_prompt_wraps()[[1]]$parameter_fn(list(api_type = "ellmer"))
  expect_length(params$.ellmer_tools, 1L)
  expect_equal(params$.ellmer_tools[[1]](), "yes")

  local_mocked_bindings(tidyprompt_tool_to_ellmer = function(...) stop("Invalid argument schema"))
  prompt <- answer_using_tools("x", tools = list(broken = fn), type = "ellmer")
  expect_error(prompt$get_prompt_wraps()[[1]]$parameter_fn(list(api_type = "ellmer")),
    "Could not convert tool 'broken'.*|Invalid argument schema")
})
