# Tests for tool scope isolation across successive ellmer-backed calls

test_that("tools do not leak across successive send_prompt calls", {
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

test_that("persistent_chat does not leak tools across turns", {
  fake_chat <- fake_ellmer_chat()
  # Pre-register a tool to simulate leftover state
  fake_chat$set_tools(list(list(name = "leftover_tool")))

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  pc <- `persistent_chat-class`$new(
    llm_provider = provider,
    chat_history = NULL
  )

  # First turn with tool_a
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

  # Should only have tool_a, not leftover_tool + tool_a
  expect_length(res1$ellmer_chat$get_tools(), 1)
  expect_identical(res1$ellmer_chat$get_tools()[[1]]$name, "tool_a")
})

test_that("tools are cleared when set_tools is available on chat", {
  fake_chat <- fake_ellmer_chat()
  # Pre-load tools to simulate previous call's leftovers
  fake_chat$set_tools(list(
    list(name = "stale_tool_1"),
    list(name = "stale_tool_2")
  ))
  expect_length(fake_chat$get_tools(), 2)

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  # Call with no tools -- stale tools should be cleared
  res <- "Hello" |>
    send_prompt(provider, verbose = FALSE, return_mode = "full")

  expect_length(res$ellmer_chat$get_tools(), 0)
})
