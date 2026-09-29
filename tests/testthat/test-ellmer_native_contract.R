test_that("native citations do not replace answers in either request mode", {
  local_ellmer_response(c("The answer is 42.\n", "Second paragraph."))
  for (stream in c(FALSE, TRUE)) {
    ch <- ellmer::chat_openai(model = "gpt-4.1-mini",
      credentials = function() "test-only", echo = "none")
    result <- send_prompt("Question", ch, stream = stream, verbose = FALSE,
      return_mode = "full")
    expect_identical(result$response, "The answer is 42.\nSecond paragraph.")
    expect_true(length(result$citations) > 0L)
    expect_equal(result$citations[[1]]@source@url, "https://example.com/source")
    expect_true(any(grepl("ContentCitation", result$chat_history$content)))
  }
})

test_that("system turns do not offset native user metadata", {
  local_ellmer_response(citations = FALSE)
  for (system_in_history in c(TRUE, FALSE)) {
    ch <- ellmer::chat_openai(model = "gpt-4.1-mini",
      system_prompt = if (!system_in_history) "Be helpful" else NULL,
      credentials = function() "test-only", echo = "none")
    provider <- llm_provider_ellmer(ch, parameters = list(stream = FALSE), verbose = FALSE)
    history <- data.frame(role = "user", content = "Question")
    if (system_in_history) history <- rbind(
      data.frame(role = "system", content = "Be helpful"), history)
    first <- provider$complete_chat(history)
    user <- which(first$completed$role == "user")
    expect_equal(first$completed$native_turn_role[user], "user")
    expect_equal(first$completed$native_contents[[user]][[1]]@text, "Question")
    second <- provider$complete_chat(add_msg_to_chat_history(first$completed, "Follow-up"))
    turns <- second$ellmer_chat$get_turns()
    expect_equal(turns[[1]]@role, "user")
    expect_equal(turns[[1]]@text, "Question")
    expect_equal(second$ellmer_chat$get_system_prompt(), "Be helpful")
  }
})

test_that("replay retains native assistant metadata and reasoning signatures", {
  local_ellmer_response(citations = FALSE)
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini",
    credentials = function() "test-only", echo = "none")
  provider <- llm_provider_ellmer(ch, parameters = list(stream = FALSE), verbose = FALSE)
  first <- provider$complete_chat("Question")
  answer <- which(first$completed$role == "assistant")
  original <- first$completed$native_turn[[answer]]
  expect_equal(unname(original@tokens), c(10, 5, 0))
  second <- provider$complete_chat(add_msg_to_chat_history(first$completed, "Follow-up"))
  expect_identical(second$ellmer_chat$get_turns()[[2]], original)

  request <- ellmer::ContentToolRequest(id = "call-1", name = "tool", arguments = list())
  thought <- ellmer::ContentThinking("", extra = list(signature = "opaque-signature"))
  fake <- fake_ellmer_chat()
  fake$chat <- function(...) {
    fake$turns <- c(fake$turns, list(
      ellmer::UserTurn("Question"),
      ellmer::AssistantTurn(list(thought, request), tokens = c(10, 5, 0), cost = 0.5),
      ellmer::UserTurn(list(ellmer::ContentToolResult(value = "42", request = request))),
      ellmer::AssistantTurn("42")))
    "42"
  }
  p <- llm_provider_ellmer(fake, parameters = list(stream = FALSE), verbose = FALSE)
  first <- p$complete_chat("Question")
  cleaned <- clean_chat_history(first$completed, preserve_native = TRUE)
  expect_equal(nrow(cleaned), nrow(first$completed))
  p$complete_chat(add_msg_to_chat_history(cleaned, "Follow-up"))
  replay <- fake$set_turns_calls[[2]]
  expect_identical(replay[[2]]@contents, list(thought, request))
  expect_equal(replay[[2]]@cost, 0.5)
  expect_equal(replay[[3]]@contents[[1]]@request@id, request@id)
})

test_that("request-hook compaction becomes authoritative for subsequent requests", {
  local_ellmer_response(citations = FALSE)
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini",
    credentials = function() "test-only", echo = "none")
  provider <- llm_provider_ellmer(ch, parameters = list(stream = FALSE), verbose = FALSE)
  history <- data.frame(role = c("user", "assistant", "user"),
    content = c("Old question", "Old answer", "New question"))
  remove <- ch$on_request_start(function(turns) ch$set_turns(list()))
  first <- provider$complete_chat(history)
  expect_true(first$history_replaced)
  expect_equal(first$completed$content, c("New question", "The answer is 42."))
  remove()
  second <- provider$complete_chat(add_msg_to_chat_history(first$completed, "Follow-up"))
  expect_false(any(grepl("Old", second$completed$content)))
  expect_equal(second$ellmer_chat$get_turns()[[1]]@text, "New question")

  prompt <- prompt_wrap(history, parameter_fn = function(llm_provider) {
    working <- llm_provider$get_chat()
    working$on_request_start(function(turns) working$set_turns(list()))
    list()
  })
  result <- send_prompt(prompt, provider, verbose = FALSE, return_mode = "full")
  expect_equal(result$chat_history$content, c("New question", "The answer is 42."))
})

test_that("send_prompt isolates callback registries and configures the working clone", {
  local_ellmer_response(citations = FALSE)
  ch <- ellmer::chat_openai(model = "gpt-4.1-mini",
    credentials = function() "test-only", echo = "none")
  seen <- 0L
  prompt <- prompt_wrap("Question", parameter_fn = function(llm_provider) {
    working <- llm_provider$get_chat()
    working$on_request_start(function(turns) {
      seen <<- seen + 1L
      working$set_turns(list())
    })
    list()
  })
  for (i in 1:2) send_prompt(prompt, ch, stream = FALSE, verbose = FALSE)
  expect_equal(seen, 2L)
  expect_length(ch$get_turns(), 0L)
  ch$chat("Direct request")
  expect_equal(seen, 2L)
  expect_length(ch$get_turns(), 2L)
})
