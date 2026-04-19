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
