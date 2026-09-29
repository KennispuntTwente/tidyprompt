#' Attach native ellmer content to a prompt
#'
#' Attach documents, PDFs, uploaded-file references, or other native ellmer
#' Content objects. Requires an ellmer-backed provider. Ellmer handles upload
#' lifecycle and provider-specific content support. Content is attached to the
#' first request and retained in native history during feedback and retries.
#'
#' @param prompt A string or a [tidyprompt()] object.
#' @param content An ellmer Content object or a nonempty list of Content objects.
#' @return A [tidyprompt()] with an attachment [prompt_wrap()].
#' @export
#' @seealso [add_image()]
add_content <- function(prompt, content) {
  if (!ellmer_available()) stop("`add_content()` requires the ellmer package.")
  if (is_native_tool_content(content)) content <- list(content)
  if (!is.list(content) || !length(content) ||
      !all(vapply(content, is_native_tool_content, logical(1)))) {
    stop("`content` must be an ellmer Content object or a nonempty list of Content objects.")
  }
  # Remove names: these are positional input parts, not chat method arguments.
  content <- unname(content)
  prompt_wrap(prompt, parameter_fn = function(llm_provider) {
    if (!identical(llm_provider$api_type, "ellmer")) {
      stop("`add_content()` requires an ellmer-backed provider.")
    }
    parts <- c(llm_provider$parameters$.ellmer_content %||% list(), content)
    llm_provider$parameters$.ellmer_content <- parts
    list(.ellmer_content = parts)
  }, name = "add_content")
}
