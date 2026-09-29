#' Limit model requests during a prompt evaluation
#'
#' Count model requests across initial responses, tool follow-ups and feedback
#' rounds, for regular tidyprompt providers and 'ellmer'. The counter resets for
#' each [send_prompt()] evaluation. Streaming chunks and transport-level retries
#' within a model request do not count as additional model requests.
#' Nested [llm_verify()] evaluations, including rejection summaries, share the
#' outer evaluation's counter.
#'
#' @details
#' Alternatively, supply `max_requests` directly to [send_prompt()]. Both use
#' the same request counter mechanism. If both limits are supplied, the smaller
#' limit applies. `send_prompt(max_interactions = ...)` separately limits the
#' outer extraction, validation and feedback loop, which does not count requests
#' within provider tool loops.
#'
#' 'ellmer' providers require 'ellmer' 0.5.0 request hooks to count requests in
#' native tool loops. Blocking structured extraction is counted explicitly
#' because that path does not run the hooks in 'ellmer' 0.5.0.
#'
#' A custom provider's completion function counts as one request. Additional
#' calls through tidyprompt's internal `request_llm_provider()` helper are counted
#' when the working provider is passed as its `llm_provider` argument. Requests
#' made directly by custom code outside these boundaries cannot be counted.
#'
#' The limit stops the next model request. It does not prevent execution of tools
#' requested by a response already received, or guarantee a monetary budget.
#'
#' @param prompt A string or a [tidyprompt()] object.
#' @param max_requests A positive whole number of allowed model requests.
#' @return A [tidyprompt()] with a request limit. Exceeding the limit raises a
#'   `tidyprompt_request_limit` error containing `requests`, `max_requests` and
#'   the working `llm_provider`; 'ellmer' providers also include `ellmer_chat`.
#' @export
#' @seealso [send_prompt()], [llm_provider_ellmer()]
limit_requests <- function(prompt, max_requests) {
  if (
    !is.numeric(max_requests) ||
      length(max_requests) != 1L ||
      !is.finite(max_requests) ||
      max_requests < 1 ||
      max_requests != floor(max_requests)
  ) {
    stop("`max_requests` must be a positive whole number.")
  }
  force(max_requests)
  prompt_wrap(
    prompt,
    parameter_fn = function(llm_provider) {
      working <- NULL
      if (identical(llm_provider$api_type, "ellmer")) {
        working <- llm_provider$get_chat()
        if (!is.function(working$on_request_start)) {
          stop(
            "`limit_requests()` requires 'ellmer' 0.5.0 request hooks for 'ellmer' providers."
          )
        }
      }
      requests <- 0L
      guard <- function(turns = NULL) {
        if (requests >= max_requests) {
          rlang::abort(
            "Model request limit reached.",
            class = "tidyprompt_request_limit",
            llm_provider = llm_provider,
            ellmer_chat = working,
            max_requests = max_requests,
            requests = requests
          )
        }
        requests <<- requests + 1L
        invisible(NULL)
      }
      remove_hook <- if (!is.null(working)) {
        working$on_request_start(guard)
      } else {
        NULL
      }
      previous <- llm_provider$parameters$.request_guard
      previous_cleanup <- llm_provider$parameters$.request_limit_cleanup
      list(
        .request_guard = function() {
          if (is.function(previous)) {
            previous()
          }
          guard()
        },
        .request_limit_cleanup = function() {
          if (is.function(remove_hook)) {
            remove_hook()
          }
          if (is.function(previous_cleanup)) previous_cleanup()
        }
      )
    },
    name = "limit_requests"
  )
}

# Count custom completion functions even if they do not use our HTTP helper.
# The first transport call is already covered; subsequent calls count normally.
# Scope the exemption to the completion function so tool handlers cannot reuse it.
complete_chat_with_request_limit <- function(llm_provider, complete, history) {
  guard <- llm_provider$parameters$.request_guard
  if (!is.function(guard) || identical(llm_provider$api_type, "ellmer")) {
    return(complete(history))
  }
  guard()
  first_request <- TRUE
  llm_provider$parameters$.request_guard <- function() {
    if (first_request) {
      first_request <<- FALSE
      return(invisible(NULL))
    }
    guard()
  }
  on.exit(
    {
      llm_provider$parameters$.request_guard <- guard
    },
    add = TRUE
  )
  complete(history)
}
