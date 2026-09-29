fake_ellmer_chat <- function(turns = list()) {
  env <- new.env(parent = emptyenv())
  env$turns <- turns
  env$last_method <- NULL
  env$set_turns_calls <- list()

  env$set_turns <- function(value) {
    env$set_turns_calls[[length(env$set_turns_calls) + 1]] <- value
    env$turns <- value
    env
  }
  env$get_turns <- function() env$turns
  env$get_model <- function() "fake-model"
  env$._tools <- list()
  env$register_tool <- function(tool) {
    env$._tools[[length(env$._tools) + 1L]] <- tool
    invisible(NULL)
  }
  env$set_tools <- function(tools) {
    env$._tools <- tools
    invisible(NULL)
  }
  env$get_tools <- function() env$._tools

  env$clone <- function() {
    copy <- fake_ellmer_chat(turns = env$turns)
    copy$turns <- env$turns
    copy$last_method <- env$last_method
    copy$set_turns_calls <- env$set_turns_calls
    copy$._tools <- env$._tools
    copy
  }

  env$chat <- function(...) {
    args <- list(...)
    env$last_method <- list(
      method = "chat",
      args = args,
      turns = env$turns
    )
    paste0(
      "chat-response:",
      paste(
        vapply(
          args,
          function(a) {
            tryCatch(
              paste(as.character(a), collapse = ","),
              error = function(e) class(a)[1]
            )
          },
          character(1)
        ),
        collapse = ""
      )
    )
  }

  env$chat_structured <- function(..., type) {
    args <- list(...)
    env$last_method <- list(
      method = "chat_structured",
      args = args,
      type = type,
      turns = env$turns
    )
    list(result = "ok")
  }

  if (requireNamespace("coro", quietly = TRUE)) {
    env$stream <- function(...) {
      args <- list(...)
      env$last_method <- list(
        method = "stream",
        args = args,
        turns = env$turns
      )
      coro::generator(function() {
        coro::yield("chunk")
        coro::yield("-end")
      })()
    }
  } else {
    env$stream <- NULL
  }

  env
}

# Helper: skip tests requiring ellmer >= 0.4.0 S7 turn constructors
skip_if_no_ellmer_turn_classes <- function() {
  testthat::skip_if_not_installed("ellmer")
  ns <- asNamespace("ellmer")
  if (!exists("UserTurn", envir = ns, inherits = FALSE)) {
    testthat::skip("ellmer >= 0.4.0 required (UserTurn not available)")
  }
}

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
    controller <- list(...)$controller
    if (mode == "stream") {
      coro::generator(function() {
        for (x in text) {
          if (!is.null(controller) && controller$cancelled) return(invisible(NULL))
          coro::yield(list(type = "response.output_text.delta", delta = x))
        }
        if (!is.null(controller) && controller$cancelled) return(invisible(NULL))
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
