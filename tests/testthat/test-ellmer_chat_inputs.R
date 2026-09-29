test_that("raw Chats select the same prompt rendering as wrapped providers", {
  skip_if_not_installed("ellmer")
  withr::local_options(list(tidyprompt.warn.auto.json = FALSE, tidyprompt.warn.auto.tools = FALSE))
  chat <- fake_ellmer_chat(turns = list("existing"))
  provider <- llm_provider_ellmer(chat, verbose = FALSE)
  prompt <- answer_as_json("Question", schema = ellmer::type_object(x = ellmer::type_number()))
  expect_identical(construct_prompt_text(prompt, chat), construct_prompt_text(prompt, provider))
  expect_identical(prompt$construct_prompt_text(chat), "Question")
  expect_identical(prompt$get_chat_history(chat), prompt$get_chat_history(provider))
  tool <- ellmer::tool(function() "ok", "A tool", name = "lookup")
  prompt <- answer_using_tools("Question", tool)
  expect_identical(construct_prompt_text(prompt, chat), construct_prompt_text(prompt, provider))
  expect_identical(chat$turns, list("existing"))
  expect_length(chat$get_tools(), 0L)
})

test_that("raw verifier Chats preserve configuration and isolate native state", {
  local_ellmer_response("FINISH[TRUE]", citations = FALSE)
  withr::local_options(list(tidyprompt.stream = FALSE, tidyprompt.verbose = FALSE))
  chat <- ellmer::chat_openai(
    model = "gpt-4.1-mini", system_prompt = "Judge carefully",
    credentials = function() "test-only", echo = "none"
  )
  chat$set_turns(list(ellmer::UserTurn("Old question"), ellmer::AssistantTurn("Old answer")))
  original <- chat$get_turns()
  seen <- list()
  chat$on_request_start(function(turns) seen[[length(seen) + 1L]] <<- turns)
  for (judge in list(chat, llm_provider_ellmer(chat, verbose = FALSE))) {
    result <- send_prompt(
      llm_verify("hi", llm_provider = judge), llm_provider_fake(),
      verbose = FALSE, max_requests = 2
    )
    expect_type(result, "character")
  }
  expect_length(seen, 2L)
  for (turns in seen) {
    text <- vapply(turns, function(turn) turn@text, character(1))
    expect_true(any(grepl("Judge carefully", text, fixed = TRUE)))
    expect_false(any(grepl("Old question", text, fixed = TRUE)))
  }
  expect_identical(chat$get_turns(), original)
})

test_that("persistent chats accept raw Chats and resume supplied history in isolation", {
  local_ellmer_response("answer", citations = FALSE)
  withr::local_options(list(tidyprompt.stream = FALSE))
  chat <- ellmer::chat_openai(
    model = "gpt-4.1-mini", system_prompt = "Be helpful",
    credentials = function() "test-only", echo = "none"
  )
  chat$set_turns(list(ellmer::UserTurn("Old question"), ellmer::AssistantTurn("Old answer")))
  original <- chat$get_turns()
  chat$register_tool(ellmer::tool(function() "ok", "A tool", name = "lookup"))
  pc <- `persistent_chat-class`$new(chat)
  expect_length(pc$llm_provider$get_chat()$get_turns(), 0L)
  expect_equal(pc$llm_provider$get_chat()$get_system_prompt(), "Be helpful")
  expect_named(pc$llm_provider$get_chat()$get_tools(), "lookup")
  pc$chat("First", verbose = FALSE)
  result <- pc$chat("Second", verbose = FALSE)
  expect_equal(vapply(result$ellmer_chat$get_turns(), function(turn) turn@text, character(1)),
    c("First", "answer", "Second", "answer"))
  resumed <- `persistent_chat-class`$new(chat, chat_history = pc$chat_history)
  result <- resumed$chat("Third", verbose = FALSE)
  expect_length(result$ellmer_chat$get_turns(), 6L)
  expect_identical(chat$get_turns(), original)
})
