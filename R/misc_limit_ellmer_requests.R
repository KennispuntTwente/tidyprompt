#' Limit model requests during an ellmer evaluation
#'
#' Count individual model requests, including ellmer's internal tool loop and
#' tidyprompt feedback requests. Requires ellmer 0.5.0 request hooks. The counter
#' resets for each send_prompt() evaluation. The blocking structured-output
#' path is counted explicitly because ellmer 0.5.0 does not run its hooks there.
#'
#' @param prompt A string or a [tidyprompt()] object.
#' @param max_requests A positive whole number of allowed model requests.
#' @return A [tidyprompt()] with a request limit. Exceeding the limit raises a
#'   `tidyprompt_request_limit` error containing the working `ellmer_chat`.
#' @export
#' @seealso [send_prompt()], [llm_provider_ellmer()]
limit_ellmer_requests <- function(prompt, max_requests) {
  if (!is.numeric(max_requests) || length(max_requests) != 1L ||
      !is.finite(max_requests) || max_requests < 1 || max_requests != floor(max_requests)) {
    stop("`max_requests` must be a positive whole number.")
  }
  force(max_requests)
  prompt_wrap(prompt, parameter_fn = function(llm_provider) {
    if (!identical(llm_provider$api_type, "ellmer")) {
      stop("`limit_ellmer_requests()` requires an ellmer-backed provider.")
    }
    working <- llm_provider$get_chat()
    if (!is.function(working$on_request_start)) {
      stop("`limit_ellmer_requests()` requires ellmer 0.5.0 request hooks.")
    }
    requests <- 0L
    guard <- function(turns = NULL) {
      if (requests >= max_requests) {
        rlang::abort("Ellmer model request limit reached.", class = "tidyprompt_request_limit",
          ellmer_chat = working, max_requests = max_requests, requests = requests)
      }
      requests <<- requests + 1L
      invisible(NULL)
    }
    working$on_request_start(guard)
    previous <- llm_provider$parameters$.ellmer_request_guard
    list(.ellmer_request_guard = function() {
      if (is.function(previous)) previous()
      guard()
    })
  }, name = "limit_ellmer_requests")
}
