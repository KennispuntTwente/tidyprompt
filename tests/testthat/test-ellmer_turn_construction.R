testthat::test_that("ellmer provider prefers role-specific Turn constructors", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  chat_history <- data.frame(
    role = c("system", "user"),
    content = c("Be helpful.", "Hello"),
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  turns <- result$ellmer_chat$turns

  # The prior turn (system) should be a Turn object with contents
  testthat::expect_true(length(turns) >= 1)
  testthat::expect_true(length(turns[[1]]@contents) >= 1)
  testthat::expect_equal(turns[[1]]@role, "system")
})

testthat::test_that("ellmer provider builds Turn objects with correct contents", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  chat_history <- data.frame(
    role = c("user", "assistant", "user"),
    content = c("First", "Reply", "Second"),
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  turns <- result$ellmer_chat$turns

  # Two prior turns should have been built (the third is the current prompt)
  testthat::expect_length(turns, 2)

  # Check contents are accessible via S7 slot
  for (turn in turns) {
    testthat::expect_true(length(turn@contents) >= 1)
  }
})

testthat::test_that("ellmer provider handles tool-role rows without crashing", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(fake_chat, verbose = FALSE)

  # Simulate a chat history containing tool-role rows (as produced by

  # the openai/ollama handler in answer_using_tools)
  chat_history <- data.frame(
    role = c("user", "assistant", "tool", "assistant", "user"),
    content = c(
      "Call my_func(1)",
      "Calling my_func...",
      "~>> Result:\n42",
      "The result is 42.",
      "Thanks"
    ),
    tool_result = c(FALSE, FALSE, TRUE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )

  # Should not error; tool rows are mapped to user turns
  result <- testthat::expect_no_error(
    provider$complete_chat(chat_history)
  )

  turns <- result$ellmer_chat$turns
  # 4 prior turns (all except last), tool row mapped to user
  testthat::expect_length(turns, 4)
  # The third turn (originally "tool") should now be a user turn
  testthat::expect_equal(turns[[3]]@role, "user")
})

testthat::test_that("ellmer provider normalizes tool metadata on plain replies", {
  testthat::skip_if_not_installed("ellmer")

  fake_chat <- fake_ellmer_chat()
  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  result <- provider$complete_chat(data.frame(
    role = "user",
    content = "what is 5+5",
    stringsAsFactors = FALSE
  ))

  testthat::expect_equal(result$completed$role, c("user", "assistant"))
  testthat::expect_equal(result$completed$tool_call, c(FALSE, FALSE))
  testthat::expect_true(all(is.na(result$completed$tool_call_id)))
  testthat::expect_equal(result$completed$tool_result, c(FALSE, FALSE))
})

testthat::test_that("ellmer provider preserves native tool history in completed rows", {
  skip_if_no_ellmer_turn_classes()

  fake_chat <- fake_ellmer_chat()
  fake_chat$chat <- function(...) {
    request <- ellmer::ContentToolRequest(
      id = "call-1",
      name = "get_secret_number",
      arguments = list(input = 123)
    )

    fake_chat$turns <- c(
      fake_chat$turns,
      list(
        ellmer::UserTurn(list(ellmer::ContentText("Call the function"))),
        ellmer::AssistantTurn(list(request)),
        ellmer::UserTurn(list(
          ellmer::ContentToolResult(value = "42", request = request)
        )),
        ellmer::AssistantTurn(list(ellmer::ContentText("The result is 42.")))
      )
    )

    "The result is 42."
  }

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  result <- provider$complete_chat(data.frame(
    role = "user",
    content = "Call the function",
    stringsAsFactors = FALSE
  ))

  testthat::expect_equal(
    result$completed$role,
    c("user", "assistant", "tool", "assistant")
  )
  testthat::expect_equal(
    result$completed$hidden_from_llm,
    c(FALSE, TRUE, FALSE, FALSE)
  )
  testthat::expect_true(isTRUE(result$completed$tool_call[2]))
  testthat::expect_equal(result$completed$tool_call_id[2], "call-1")
  testthat::expect_true(isTRUE(result$completed$tool_result[3]))
  testthat::expect_match(
    result$completed$content[2],
    "Calling function 'get_secret_number'"
  )
  testthat::expect_match(result$completed$content[3], "~>> Result")
  testthat::expect_equal(result$completed$content[4], "The result is 42.")
})

testthat::test_that("ellmer provider preserves native thinking content in completed rows", {
  skip_if_no_ellmer_turn_classes()

  fake_chat <- fake_ellmer_chat()
  fake_chat$chat <- function(...) {
    fake_chat$turns <- c(
      fake_chat$turns,
      list(
        ellmer::UserTurn(list(ellmer::ContentText("Think through this"))),
        ellmer::AssistantTurn(list(
          ellmer::ContentThinking("Reasoning step"),
          ellmer::ContentText("Final answer")
        ))
      )
    )

    "Final answer"
  }

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  result <- provider$complete_chat(data.frame(
    role = "user",
    content = "Think through this",
    stringsAsFactors = FALSE
  ))

  testthat::expect_equal(
    result$completed$role,
    c("user", "assistant", "assistant")
  )
  testthat::expect_equal(
    result$completed$hidden_from_llm,
    c(FALSE, TRUE, FALSE)
  )
  testthat::expect_match(result$completed$content[2], "Reasoning step")
  testthat::expect_equal(result$completed$content[3], "Final answer")
})

testthat::test_that("ellmer provider preserves native json content in completed rows", {
  skip_if_no_ellmer_turn_classes()

  ellmer_ns <- asNamespace("ellmer")
  fake_chat <- fake_ellmer_chat()
  fake_chat$chat <- function(...) {
    fake_chat$turns <- c(
      fake_chat$turns,
      list(
        ellmer::UserTurn(list(ellmer::ContentText("Return JSON"))),
        ellmer::AssistantTurn(list(
          ellmer_ns$ContentJson(data = list(answer = 42))
        ))
      )
    )

    "{\"answer\":42}"
  }

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  result <- provider$complete_chat(data.frame(
    role = "user",
    content = "Return JSON",
    stringsAsFactors = FALSE
  ))

  testthat::expect_equal(result$completed$role, c("user", "assistant"))
  testthat::expect_equal(result$completed$content[2], '{"answer":42}')
})

testthat::test_that("ellmer provider preserves native image tool results in completed rows", {
  skip_if_no_ellmer_turn_classes()

  ellmer_ns <- asNamespace("ellmer")
  fake_chat <- fake_ellmer_chat()
  fake_chat$chat <- function(...) {
    request <- ellmer::ContentToolRequest(
      id = "call-image-1",
      name = "make_plot",
      arguments = list()
    )

    fake_chat$turns <- c(
      fake_chat$turns,
      list(
        ellmer::UserTurn(list(ellmer::ContentText("Make me a plot"))),
        ellmer::AssistantTurn(list(request)),
        ellmer::UserTurn(list(
          ellmer::ContentToolResult(
            value = ellmer_ns$ContentImageRemote(
              url = "https://example.com/plot.png"
            ),
            request = request
          )
        )),
        ellmer::AssistantTurn(list(ellmer::ContentText("Done")))
      )
    )

    "Done"
  }

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  result <- provider$complete_chat(data.frame(
    role = "user",
    content = "Make me a plot",
    stringsAsFactors = FALSE
  ))

  testthat::expect_equal(
    result$completed$role,
    c("user", "assistant", "tool", "assistant")
  )
  testthat::expect_match(
    result$completed$content[3],
    "\\[image: https://example.com/plot.png\\]"
  )
  testthat::expect_equal(result$completed$content[4], "Done")
})
