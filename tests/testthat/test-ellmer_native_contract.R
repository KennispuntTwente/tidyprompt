local_ellmer_response <- function(text = "The answer is 42.", citations = TRUE,
                                  .local_envir = parent.frame()) {
  skip_if_not_installed("ellmer", "0.5.0")
  annotation <- list(type = "url_citation", url = "https://example.com/source",
    title = "Source", start_index = 0, end_index = 16)
  result <- list(id = "resp_test", model = "gpt-4.1-mini", status = "completed",
    output = list(list(type = "message", role = "assistant", content = lapply(text,
      function(x) list(type = "output_text", text = x,
        annotations = if (citations) list(annotation) else list())))),
    usage = list(input_tokens = 10, output_tokens = 5))
  testthat::local_mocked_bindings(chat_perform = function(mode, ...) {
    if (mode == "stream") {
      coro::generator(function() {
        for (x in text) coro::yield(list(type = "response.output_text.delta", delta = x))
        if (citations) coro::yield(list(type = "response.output_text.annotation.added",
          annotation = annotation))
        coro::yield(list(type = "response.completed", response = result))
      })()
    } else {
      httr2::response(status_code = 200L,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(result, auto_unbox = TRUE)))
    }
  }, .package = "ellmer", .env = .local_envir)
}

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
