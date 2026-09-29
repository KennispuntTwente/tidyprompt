# Ellmer has no exported capability/extraction helpers. Keep these optional
# dependencies at one boundary, and fall back before sending a request if the
# installed version cannot support the complete structured-stream contract.
ellmer_structured_stream <- function(chat, type) {
  if (
    !is.function(chat$stream) ||
      !"type" %in% names(formals(chat$stream)) ||
      !is.function(chat$get_provider) ||
      !is.function(chat$get_model_object)
  ) {
    return(NULL)
  }
  ns <- asNamespace("ellmer")
  helpers <- lapply(
    c(
      "uses_tool_structured_output",
      "type_needs_wrapper",
      "wrap_type_if_needed",
      "extract_data"
    ),
    get0,
    envir = ns,
    inherits = FALSE
  )
  if (!all(vapply(helpers, is.function, logical(1)))) {
    return(NULL)
  }
  provider <- chat$get_provider()
  needs_wrapper <- helpers[[2]](type, provider)
  wrapped <- helpers[[3]](type, needs_wrapper)
  if (helpers[[1]](provider, chat$get_model_object(), wrapped)) {
    return(NULL)
  }
  list(extract = function() {
    helpers[[4]](
      chat$last_turn(),
      wrapped,
      convert = TRUE,
      needs_wrapper = needs_wrapper
    )
  })
}

ellmer_stream_abort <- function(
  chat,
  partial_response,
  parent = NULL,
  cancelled = FALSE
) {
  turns <- ellmer_chat_turns(chat)
  rlang::abort(
    if (cancelled) {
      "Ellmer stream cancelled."
    } else {
      "Ellmer stream failed; partial state is available on this condition."
    },
    class = if (cancelled) {
      c("tidyprompt_stream_cancelled", "tidyprompt_stream_error")
    } else {
      "tidyprompt_stream_error"
    },
    parent = parent,
    ellmer_chat = chat,
    partial_response = partial_response,
    partial_turn = if (length(turns)) utils::tail(turns, 1L)[[1L]] else NULL
  )
}
