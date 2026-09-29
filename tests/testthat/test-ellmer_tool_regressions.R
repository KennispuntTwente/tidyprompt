test_that("renaming preserves ignored formals and does not mutate the original", {
  skip_if_not_installed("ellmer", "0.4.0")
  tool <- ellmer::tool(
    function(x, hidden = 2) x + hidden,
    name = "original",
    description = "Add",
    arguments = list(x = ellmer::type_number(), hidden = ellmer::type_ignore()),
    convert = FALSE,
    annotations = list(readOnlyHint = TRUE)
  )
  renamed <- rename_ellmer_tool(tool, "alias")
  expect_equal(renamed(3), 5)
  expect_equal(renamed@name, "alias")
  expect_equal(tool@name, "original")
  expect_identical(renamed@arguments, tool@arguments)
  expect_identical(renamed@annotations, tool@annotations)
  expect_false(renamed@convert)
  prompt <- answer_using_tools("x", tools = list(alias = tool), type = "ellmer")
  params <- prompt$get_prompt_wraps()[[1]]$parameter_fn(list(
    api_type = "ellmer"
  ))
  expect_equal(params$.ellmer_tools[[1]]@name, "alias")
})

test_that("nonnative tools preserve nested schemas and ellmer argument coercion", {
  skip_if_not_installed("ellmer")
  td <- ellmer::tool(
    function(rows) rows,
    name = "rows",
    description = "Rows",
    arguments = list(
      rows = ellmer::type_array(ellmer::type_object(x = ellmer::type_number()))
    )
  )
  prompt <- answer_using_tools("x", tools = td, type = "openai")
  params <- prompt$get_prompt_wraps()[[1]]$parameter_fn(list(
    api_type = "openai"
  ))
  expect_equal(
    params$tools[[
      1
    ]]$`function`$parameters$properties$rows$items$properties$x$type,
    "number"
  )
  expect_identical(tidyprompt_tool_to_ellmer(ellmer_tool_to_tidyprompt(td)), td)

  for (convert in c(TRUE, FALSE)) {
    td <- ellmer::tool(
      function(values) class(values),
      name = "classes",
      description = "Classes",
      arguments = list(
        values = ellmer::type_array(ellmer::type_enum(c("red", "blue")))
      ),
      convert = convert
    )
    prompt <- answer_using_tools("x", tools = td, type = "text-based")
    result <- prompt$get_prompt_wraps()[[1]]$extraction_fn(
      '{"function":"classes","arguments":{"values":["red","blue"]}}',
      list(api_type = "fake")
    )
    expect_match(
      result$text,
      if (convert) "result: factor" else "result: list",
      fixed = TRUE
    )
  }
  td <- ellmer::tool(
    function(x) x + 1,
    name = "add",
    description = "Add",
    arguments = list(x = ellmer::type_number())
  )
  fn <- ellmer_tool_to_tidyprompt(td)
  value <- 5
  expect_equal(fn(value), 6)
})

test_that("zero-argument functions register and failed conversions are explicit", {
  skip_if_not_installed("ellmer")
  fn <- tools_add_docs(
    function() "yes",
    list(name = "noargs", description = "No args", arguments = list())
  )
  prompt <- answer_using_tools("x", tools = fn, type = "ellmer")
  params <- prompt$get_prompt_wraps()[[1]]$parameter_fn(list(
    api_type = "ellmer"
  ))
  expect_length(params$.ellmer_tools, 1L)
  expect_equal(params$.ellmer_tools[[1]](), "yes")

  local_mocked_bindings(tidyprompt_tool_to_ellmer = function(...) {
    stop("Invalid argument schema")
  })
  prompt <- answer_using_tools("x", tools = list(broken = fn), type = "ellmer")
  expect_error(
    prompt$get_prompt_wraps()[[1]]$parameter_fn(list(api_type = "ellmer")),
    "Could not convert tool 'broken'.*|Invalid argument schema"
  )
})

test_that("context-aware tools explain their native-provider requirement", {
  skip_if_not_installed("ellmer", "0.5.0")
  td <- ellmer::tool(
    function() ellmer::tool_context()$request@id,
    name = "context",
    description = "Context"
  )
  expect_error(
    invoke_tidyprompt_tool(ellmer_tool_to_tidyprompt(td), list()),
    "require an ellmer-backed provider",
    fixed = TRUE
  )
})

test_that("generated native tools serialize collections without losing rich content", {
  skip_if_not_installed("ellmer")
  fn <- tools_add_docs(
    function(x = 2) list(nested = list(value = x)),
    list(
      name = "nested",
      description = "Nested result",
      arguments = list(
        x = list(type = "numeric", description = "A value", required = FALSE)
      )
    )
  )
  td <- tidyprompt_tool_to_ellmer(fn)
  expect_equal(jsonlite::fromJSON(td()), list(nested = list(value = 2)))
  value <- 3
  expect_equal(jsonlite::fromJSON(td(value)), list(nested = list(value = 3)))
  expect_equal(
    normalize_tidyprompt_tool_result(data.frame(x = c(1, 2))),
    jsonlite::toJSON(data.frame(x = c(1, 2)), auto_unbox = TRUE)
  )
  content <- ellmer::ContentText(text = "rich")
  expect_identical(normalize_tidyprompt_tool_result(content), content)
  expect_identical(
    normalize_tidyprompt_tool_result(list(content)),
    list(content)
  )
  expect_error(
    normalize_tidyprompt_tool_result(content, native = FALSE),
    "require native ellmer"
  )
  prompt <- answer_using_tools(
    "x",
    tools = list(nested = fn),
    type = "text-based"
  )
  result <- prompt$get_prompt_wraps()[[1]]$extraction_fn(
    '{"function":"nested","arguments":{"x":4}}',
    list(api_type = "fake")
  )
  expect_match(result$text, 'result: {"nested":{"value":4}}', fixed = TRUE)
  # Exercise ellmer's own result normalizer with lifecycle warnings as errors.
  withr::local_options(lifecycle_verbosity = "error")
  normalize <- get0(
    "normalize_tool_result",
    asNamespace("ellmer"),
    inherits = FALSE
  )
  if (is.function(normalize)) expect_identical(normalize(td()), td())
})
