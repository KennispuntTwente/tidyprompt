# Tests for tool scope isolation across successive ellmer-backed calls

test_that("prompt-level tools do not leak across successive send_prompt calls", {
  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  tool_a <- list(name = "tool_a")
  tool_b <- list(name = "tool_b")

  # First call: send_prompt with tool_a via .ellmer_tools parameter
  prompt_with_tool_a <- "Use tool A" |>
    prompt_wrap(parameter_fn = function(llm_provider) {
      list(.ellmer_tools = list(tool_a))
    })

  res1 <- send_prompt(
    prompt_with_tool_a,
    provider,
    verbose = FALSE,
    return_mode = "full"
  )

  # The returned ellmer_chat should only have tool_a registered
  expect_length(res1$ellmer_chat$get_tools(), 1)

  expect_identical(res1$ellmer_chat$get_tools()[[1]]$name, "tool_a")

  # Second call: plain prompt with no tools
  res2 <- "No tools" |>
    send_prompt(provider, verbose = FALSE, return_mode = "full")

  # The returned ellmer_chat should have NO tools registered
  expect_length(res2$ellmer_chat$get_tools(), 0)

  # Third call: prompt with only tool_b
  prompt_with_tool_b <- "Use tool B" |>
    prompt_wrap(parameter_fn = function(llm_provider) {
      list(.ellmer_tools = list(tool_b))
    })

  res3 <- send_prompt(
    prompt_with_tool_b,
    provider,
    verbose = FALSE,
    return_mode = "full"
  )

  # Should have ONLY tool_b, not tool_a + tool_b
  expect_length(res3$ellmer_chat$get_tools(), 1)
  expect_identical(res3$ellmer_chat$get_tools()[[1]]$name, "tool_b")
})

test_that("user-pre-registered tools are preserved across calls", {
  fake_chat <- fake_ellmer_chat()
  # User pre-registers a tool on the chat before creating the provider
  fake_chat$set_tools(list(list(name = "user_tool")))

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  # Plain call with no prompt tools -- base tool stays
  res1 <- "Hello" |>
    send_prompt(provider, verbose = FALSE, return_mode = "full")

  expect_length(res1$ellmer_chat$get_tools(), 1)
  expect_identical(res1$ellmer_chat$get_tools()[[1]]$name, "user_tool")

  # Call with a prompt tool -- base tool + prompt tool
  prompt_with_tool_a <- "Use tool A" |>
    prompt_wrap(parameter_fn = function(llm_provider) {
      list(.ellmer_tools = list(list(name = "tool_a")))
    })

  res2 <- send_prompt(
    prompt_with_tool_a,
    provider,
    verbose = FALSE,
    return_mode = "full"
  )

  expect_length(res2$ellmer_chat$get_tools(), 2)
  tool_names <- vapply(
    res2$ellmer_chat$get_tools(),
    `[[`,
    character(1),
    "name"
  )
  expect_true("user_tool" %in% tool_names)
  expect_true("tool_a" %in% tool_names)

  # Follow-up plain call -- back to just the base tool
  res3 <- "Again" |>
    send_prompt(provider, verbose = FALSE, return_mode = "full")

  expect_length(res3$ellmer_chat$get_tools(), 1)
  expect_identical(res3$ellmer_chat$get_tools()[[1]]$name, "user_tool")
})

test_that("prompt-level tools do not leak through persistent_chat", {
  fake_chat <- fake_ellmer_chat()
  # User pre-registers a base tool
  fake_chat$set_tools(list(list(name = "base_tool")))

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  # First call with prompt tool_a
  prompt_with_tool_a <- "Use tool A" |>
    prompt_wrap(parameter_fn = function(llm_provider) {
      list(.ellmer_tools = list(list(name = "tool_a")))
    })

  res1 <- send_prompt(
    prompt_with_tool_a,
    provider,
    verbose = FALSE,
    return_mode = "full"
  )

  # Should have base_tool + tool_a
  expect_length(res1$ellmer_chat$get_tools(), 2)

  # Second call with no prompt tools -- only base_tool should remain
  res2 <- "No tools" |>
    send_prompt(provider, verbose = FALSE, return_mode = "full")

  expect_length(res2$ellmer_chat$get_tools(), 1)
  expect_identical(res2$ellmer_chat$get_tools()[[1]]$name, "base_tool")
})
