testthat::test_that("llm_provider_ellmer supports multimodal structured output", {
  testthat::skip_if_not_installed("ellmer")

  provider <- llm_provider_ellmer(fake_ellmer_chat(), verbose = FALSE)
  provider$parameters$.ellmer_structured_type <- list(schema = "stub")
  provider$parameters$.add_image_parts <- list(
    list(
      source = "url",
      data = "https://example.com/image.png",
      detail = "low"
    )
  )

  chat_history <- data.frame(
    role = "user",
    content = "Hello world",
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  fake_chat <- provider$ellmer_chat

  testthat::expect_equal(fake_chat$last_method$method, "chat_structured")
  # Content objects passed directly (not pre-seeded as turns + empty prompt)
  testthat::expect_true(length(fake_chat$last_method$args) >= 2)
  # No prior turns should be pre-seeded (single-message history)
  testthat::expect_length(fake_chat$last_method$turns, 0)
  testthat::expect_match(
    tail(result$completed$content, 1),
    '"result":"ok"'
  )
})


testthat::test_that("llm_provider_ellmer streams multimodal prompts when supported", {
  testthat::skip_if_not_installed("coro")
  testthat::skip_if_not_installed("ellmer")

  provider <- llm_provider_ellmer(
    fake_ellmer_chat(),
    parameters = list(stream = TRUE),
    verbose = FALSE
  )
  provider$parameters$.add_image_parts <- list(
    list(
      source = "url",
      data = "https://example.com/image.png",
      detail = "low"
    )
  )

  chunks <- character()
  provider$stream_callback <- function(chunk, meta) {
    chunks <<- c(chunks, chunk)
  }

  chat_history <- data.frame(
    role = "user",
    content = "Ping",
    stringsAsFactors = FALSE
  )

  result <- provider$complete_chat(chat_history)
  fake_chat <- provider$ellmer_chat

  testthat::expect_equal(fake_chat$last_method$method, "stream")
  # Content objects passed directly (not pre-seeded + empty prompt)
  testthat::expect_true(length(fake_chat$last_method$args) >= 2)
  testthat::expect_equal(
    result$completed$content[nrow(result$completed)],
    "chunk-end"
  )
  testthat::expect_true(length(chunks) >= 2)
})

testthat::test_that("ellmer follow-up calls replay multimodal turns with native content", {
  skip_if_no_ellmer_turn_classes()

  make_multimodal_fake_chat <- function(turns = list()) {
    chat_env <- fake_ellmer_chat(turns = turns)

    chat_env$chat <- function(...) {
      args <- list(...)
      chat_env$last_method <- list(
        method = "chat",
        args = args,
        turns = chat_env$turns
      )

      user_contents <- lapply(args, function(x) {
        if (is.character(x)) {
          return(ellmer::ContentText(x))
        }
        x
      })

      chat_env$turns <- c(
        chat_env$turns,
        list(
          ellmer::UserTurn(user_contents),
          ellmer::AssistantTurn(list(
            ellmer::ContentThinking("internal reasoning"),
            ellmer::content_image_url("https://example.com/cat.png"),
            ellmer::ContentText("A cat")
          ))
        )
      )

      "A cat"
    }

    chat_env$clone <- function() {
      copy <- make_multimodal_fake_chat(turns = chat_env$turns)
      copy$last_method <- chat_env$last_method
      copy$set_turns_calls <- chat_env$set_turns_calls
      copy
    }

    chat_env
  }

  fake_chat <- make_multimodal_fake_chat()

  provider <- llm_provider_ellmer(
    fake_chat,
    parameters = list(stream = FALSE),
    verbose = FALSE
  )

  first <- tidyprompt("Describe the image") |>
    add_image("https://example.com/cat.png") |>
    send_prompt(provider, return_mode = "full", verbose = FALSE)

  provider$ellmer_chat <- first$ellmer_chat

  follow_up <- first$chat_history |>
    add_msg_to_chat_history("What image was that?") |>
    send_prompt(provider, return_mode = "full", verbose = FALSE)

  prior_turns <- follow_up$ellmer_chat$last_method$turns

  testthat::expect_length(prior_turns, 2)
  testthat::expect_equal(prior_turns[[1]]@role, "user")
  testthat::expect_length(prior_turns[[1]]@contents, 2)
  testthat::expect_true(any(grepl(
    "ContentText",
    class(prior_turns[[1]]@contents[[1]])
  )))
  testthat::expect_true(any(grepl(
    "ContentImageRemote",
    class(prior_turns[[1]]@contents[[2]])
  )))

  testthat::expect_equal(prior_turns[[2]]@role, "assistant")
  testthat::expect_length(prior_turns[[2]]@contents, 2)
  testthat::expect_false(any(vapply(
    prior_turns[[2]]@contents,
    function(x) any(grepl("ContentThinking", class(x))),
    logical(1)
  )))
  testthat::expect_true(any(grepl(
    "ContentImageRemote",
    class(prior_turns[[2]]@contents[[1]])
  )))
  testthat::expect_equal(prior_turns[[2]]@contents[[2]]@text, "A cat")
})
