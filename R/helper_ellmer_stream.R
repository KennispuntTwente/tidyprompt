# Ellmer has no exported capability/extraction helpers. Keep these optional
# dependencies at one boundary, and fall back before sending a request if the
# installed version cannot support the complete structured-stream contract.
# See .github/ellmer-api-follow-up.md for the public API replacement proposal.
ellmer_structured_stream_helpers <- function(ns = asNamespace("ellmer")) {
  arguments <- list(
    uses_tool_structured_output = c("provider", "model", "type"),
    type_needs_wrapper = c("type", "provider"),
    wrap_type_if_needed = c("type", "needs_wrapper"),
    extract_data = c("turn", "type", "convert", "needs_wrapper")
  )
  helpers <- lapply(names(arguments), get0, envir = ns, inherits = FALSE)
  names(helpers) <- names(arguments)
  compatible <- vapply(
    names(arguments),
    function(name) {
      fn <- helpers[[name]]
      if (!is.function(fn)) {
        return(FALSE)
      }
      signature <- formals(fn)
      required <- names(signature)[vapply(
        signature,
        identical,
        logical(1),
        quote(expr = )
      )]
      all(arguments[[name]] %in% names(signature)) &&
        length(setdiff(required, c(arguments[[name]], "..."))) == 0L
    },
    logical(1)
  )
  if (all(compatible)) helpers else NULL
}

ellmer_structured_stream <- function(chat, type) {
  if (
    !is.function(chat$stream) ||
      !"type" %in% names(formals(chat$stream)) ||
      !is.function(chat$get_provider) ||
      !is.function(chat$get_model_object) ||
      !is.function(chat$last_turn)
  ) {
    return(NULL)
  }
  helpers <- ellmer_structured_stream_helpers()
  if (is.null(helpers)) {
    return(NULL)
  }
  # Only capability preparation can fall back. Once a stream has started,
  # extraction failures must propagate without issuing another model request.
  tryCatch(
    {
      provider <- chat$get_provider()
      needs_wrapper <- helpers$type_needs_wrapper(
        type = type,
        provider = provider
      )
      if (
        !is.logical(needs_wrapper) ||
          length(needs_wrapper) != 1L ||
          is.na(needs_wrapper)
      ) {
        return(NULL)
      }
      wrapped <- helpers$wrap_type_if_needed(
        type = type,
        needs_wrapper = needs_wrapper
      )
      uses_tools <- helpers$uses_tool_structured_output(
        provider = provider,
        model = chat$get_model_object(),
        type = wrapped
      )
      if (!identical(uses_tools, FALSE)) {
        return(NULL)
      }
      list(extract = function() {
        helpers$extract_data(
          turn = chat$last_turn(),
          type = wrapped,
          convert = TRUE,
          needs_wrapper = needs_wrapper
        )
      })
    },
    error = function(e) NULL
  )
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
