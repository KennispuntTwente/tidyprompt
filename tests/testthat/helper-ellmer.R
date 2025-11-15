fake_ellmer_chat <- function() {
  env <- new.env(parent = emptyenv())
  env$turns <- list()
  env$last_method <- NULL

  env$set_turns <- function(value) {
    env$turns <- value
    env
  }
  env$get_turns <- function() env$turns
  env$get_model <- function() "fake-model"
  env$register_tool <- function(tool) invisible(NULL)

  env$chat <- function(prompt, ...) {
    env$last_method <- list(
      method = "chat",
      prompt = prompt,
      turns = env$turns
    )
    paste0("chat-response:", prompt)
  }

  env$chat_structured <- function(prompt, type, ...) {
    env$last_method <- list(
      method = "chat_structured",
      prompt = prompt,
      type = type,
      turns = env$turns
    )
    list(result = "ok", prompt = prompt, type = type)
  }

  if (requireNamespace("coro", quietly = TRUE)) {
    env$stream <- function(prompt, ...) {
      env$last_method <- list(
        method = "stream",
        prompt = prompt,
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
