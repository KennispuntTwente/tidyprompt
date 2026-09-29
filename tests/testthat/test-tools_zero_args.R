test_that("zero-argument tools produce valid native schemas for regular providers", {
  tool <- tools_add_docs(
    function() "ok",
    list(name = "lookup", description = "Lookup", arguments = list())
  )
  for (provider in c("openai", "ollama")) {
    prompt <- answer_using_tools(
      "Question",
      tools = list(lookup = tool),
      type = provider
    )
    params <- prompt$get_prompt_wraps()[[1]]$parameter_fn(list(
      api_type = provider
    ))
    schema <- params$tools[[1]]$`function`$parameters
    wire <- as.character(jsonlite::toJSON(schema, auto_unbox = TRUE))
    expect_match(wire, '"properties":{}', fixed = TRUE)
    expect_match(wire, '"required":[]', fixed = TRUE)
  }
})
