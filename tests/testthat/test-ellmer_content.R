test_that("content attachments are passed by identity to each request mode", {
  skip_if_not_installed("ellmer")
  content <- ellmer::ContentText(text = "Attachment")
  for (stream in c(FALSE, TRUE)) {
    for (structured in c(FALSE, TRUE)) {
      prompt <- add_content("Question", list(file = content))
      if (structured) {
        prompt <- answer_as_json(
          prompt,
          type = "ellmer",
          schema = ellmer::type_object(result = ellmer::type_string())
        )
      }
      result <- send_prompt(
        prompt,
        fake_ellmer_chat(),
        stream = stream,
        verbose = FALSE,
        return_mode = "full"
      )
      expect_identical(result$ellmer_chat$last_method$args[[2]], content)
    }
  }
  expect_error(add_content("Question", "filename.pdf"), "Content object")
  expect_error(add_content("Question", list()), "nonempty")
  wrap <- add_content("Question", content)$get_prompt_wraps()[[1]]
  expect_error(wrap$parameter_fn(list(api_type = "openai")), "ellmer-backed")
})

test_that("native attachments are retained but not duplicated on feedback", {
  local_ellmer_response(citations = FALSE)
  ch <- ellmer::chat_openai(
    model = "gpt-4.1-mini",
    credentials = function() "test-only",
    echo = "none"
  )
  seen <- 0L
  attachment <- ellmer::ContentText(text = "Attachment")
  prompt <- prompt_wrap(
    add_content("Question", attachment),
    validation_fn = function(llm_response) {
      seen <<- seen + 1L
      if (seen == 1L) llm_feedback("Try again") else TRUE
    }
  )
  result <- send_prompt(
    prompt,
    ch,
    stream = FALSE,
    verbose = FALSE,
    return_mode = "full"
  )
  turns <- result$ellmer_chat$get_turns()
  expect_length(turns, 4L)
  expect_identical(turns[[1]]@contents[[2]], attachment)
  expect_length(turns[[3]]@contents, 1L)
})
