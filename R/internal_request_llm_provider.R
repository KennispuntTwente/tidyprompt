#' @title Make a request to an LLM provider
#'
#' @description This is a helper function which facilitates making requests to LLM
#' providers which follow the structure of the OpenAI API or the Ollama
#' API. It handles both streaming and non-streaming requests.
#'
#' This function is part of the internal API and is not intended to be called directly by
#' users. It is used in some of the pre-built [llm_provider-class] objects
#' included in 'tidyprompt' (e.g., [llm_provider_openai()) and
#' [llm_provider_ollama()]).
#'
#' @param chat_history A data frame with 'role' and 'content' columns
#' (see [chat_history()])
#' @param request A 'httr2' request object with the URL, headers, and body
#' @param stream Logical indicating whether the API should stream responses
#' @param verbose Logical indicating whether interactions should be printed to the console
#' @param api_type API type, one of "openai" or "ollama"
#'
#' @return A list with the completed chat history and the HTTP request and response
#' objects
#'
#' @keywords internal
#' @noRd
request_llm_provider <- function(
  chat_history,
  request,
  stream = NULL,
  verbose = getOption("tidyprompt.verbose", TRUE),
  api_type = c("openai", "ollama")
) {
  api_type <- match.arg(api_type)
  request <- normalize_openai_request(request, api_type)

  if (!is.null(stream) && stream) {
    req_result <- req_llm_stream(request, api_type, verbose)
  } else {
    req_result <- req_llm_non_stream(request, api_type, verbose)
  }

  stopifnot(
    is.list(req_result),
    "new" %in% names(req_result),
    is.data.frame(req_result$new)
  )

  completed <- dplyr::bind_rows(chat_history, req_result$new)

  return(
    list(
      completed = completed,
      http = list(
        request = request,
        response = req_result$httr2_response
      )
    )
  )
}

req_llm_handle_error <- function(e) {
  msg <- paste0(e$message)

  # Try to parse and include JSON body if available
  body_msg <- tryCatch(
    {
      body <- e$resp |>
        httr2::resp_body_string() |>
        jsonlite::fromJSON()
      paste0(
        "\nResponse body: ",
        jsonlite::toJSON(body, pretty = TRUE, auto_unbox = TRUE)
      )
    },
    error = function(e) "\n(Could not parse JSON body from response)"
  )

  msg <- paste0(
    msg,
    body_msg,
    "\nUse 'httr2::last_response()' and 'httr2::last_request()' for more information"
  )

  stop(msg, call. = FALSE)
}

req_llm_stream <- function(req, api_type, verbose) {
  role <- NULL
  message_accumulator <- ""
  tool_calls <- list()

  using_responses <- (api_type == "openai") && is_openai_responses_endpoint(req)

  # No low-level HTTP verbosity; we'll print only tokens ourselves
  resp <- tryCatch(
    httr2::req_perform_connection(req, verbosity = 0),
    error = function(e) req_llm_handle_error(e)
  )

  if (api_type == "ollama") {
    while (!httr2::resp_stream_is_complete(resp)) {
      lines <- httr2::resp_stream_lines(resp, lines = 1, warn = FALSE)
      if (length(lines) == 0) next
      for (line in lines) {
        if (!nzchar(line)) next
        data <- tryCatch(jsonlite::fromJSON(line), error = function(e) NULL)
        if (is.null(data)) next

        if (is.null(role) && !is.null(data$message$role))
          role <- data$message$role
        if (!is.null(data$message$content)) {
          message_accumulator <- paste0(
            message_accumulator,
            data$message$content
          )
          if (isTRUE(verbose)) cat(data$message$content)
        }
      }
    }
  } else if (!using_responses) {
    # OpenAI Chat Completions (SSE) — use resp_stream_sse for robust parsing
    if (is.null(role)) role <- "assistant"

    repeat {
      ev <- httr2::resp_stream_sse(resp)
      if (!nzchar(ev$data)) next # keepalive / empty
      if (identical(ev$data, "[DONE]")) break # sentinel

      payload <- tryCatch(jsonlite::fromJSON(ev$data), error = function(e) NULL)
      if (is.null(payload)) next

      # tool calls (function calling) support
      tc <- payload$choices[1, ]$delta$tool_calls
      if (length(tc) > 0) {
        tool_calls <- append_or_update_tool_calls(
          tool_calls,
          tc,
          verbose
        )
        next
      }

      d <- tryCatch(
        payload$choices[1, ]$delta,
        error = function(e) NULL
      )
      if (is.null(d)) next

      if (!is.null(d$role) && is.null(role)) role <- d$role

      # text tokens
      if (!is.null(d$content)) {
        add <- d$content
        if (length(add) > 0 && !is.na(add)) {
          message_accumulator <- paste0(message_accumulator, add)
          if (isTRUE(verbose)) cat(add)
        }
      }
    }
  } else {
    # OpenAI Responses API (SSE)
    if (is.null(role)) role <- "assistant"
    repeat {
      ev <- httr2::resp_stream_sse(resp)
      if (is.null(ev)) break
      if (!nzchar(ev$data) || identical(ev$data, "[DONE]")) next

      payload <- tryCatch(jsonlite::fromJSON(ev$data), error = function(e) NULL)
      if (is.null(payload)) next

      # Only handle text deltas, ignore response.created/in_progress/etc.
      if (
        !is.null(payload$type) &&
          grepl("response\\.(output_)?text\\.delta$", payload$type) &&
          !is.null(payload$delta)
      ) {
        message_accumulator <- paste0(message_accumulator, payload$delta)
        if (isTRUE(verbose)) cat(payload$delta)
      }
    }
  }

  if (isTRUE(verbose)) cat("\n")

  if (!is.list(resp$body)) resp$body <- list()
  resp$body$tool_calls <- tool_calls

  list(
    new = data.frame(
      role = if (is.null(role)) "assistant" else role,
      content = message_accumulator,
      stringsAsFactors = FALSE
    ),
    httr2_response = resp
  )
}

req_llm_non_stream <- function(req, api_type, verbose) {
  response <- tryCatch(
    httr2::req_perform(req),
    error = function(e) req_llm_handle_error(e)
  )

  content <- httr2::resp_body_json(response)
  using_responses <- (api_type == "openai") && is_openai_responses_endpoint(req)

  if (api_type == "ollama") {
    new <- tryCatch(
      data.frame(
        role = content$message$role,
        content = content$message$content,
        stringsAsFactors = FALSE
      ),
      error = function(e) data.frame()
    )
  } else if (using_responses) {
    # Prefer convenience field if present
    txt <- NULL
    if (!is.null(content$output_text)) {
      txt <- content$output_text
    } else if (!is.null(content$output) && length(content$output) > 0) {
      # Fallback: stitch message items' text
      bits <- unlist(lapply(content$output, function(it) {
        if (!is.null(it$content)) {
          unlist(lapply(it$content, function(c) c$text %||% NULL))
        }
      }))
      txt <- paste(bits, collapse = "")
    }
    new <- data.frame(
      role = "assistant",
      content = txt %||% "",
      stringsAsFactors = FALSE
    )
  } else {
    # OpenAI Chat Completions
    new <- tryCatch(
      data.frame(
        role = content$choices[[1]]$message$role,
        content = content$choices[[1]]$message$content,
        stringsAsFactors = FALSE
      ),
      error = function(e) data.frame()
    )
  }

  list(new = new, httr2_response = response)
}

parse_ollama_stream_chunk <- function(chunk) {
  # Each chunk is separated by newline
  lines <- rawToChar(chunk) |> strsplit("\n") |> unlist()

  parsed <- lapply(lines, function(x) {
    content <- tryCatch(jsonlite::fromJSON(x), error = function(e) NULL)
    # if (!is.null(content$message$content)) {
    #   list(role = content$message$role, content = content$message$content)
    # } else {
    #   NULL
    # }
  })

  Filter(Negate(is.null), parsed)
}

parse_openai_stream_chunk <- function(chunk) {
  # Each chunk may contain multiple lines of streaming data
  char <- rawToChar(chunk) |> strsplit(split = "\ndata: ") |> unlist()

  parsed_data <- lapply(char, function(x) {
    json_text <- sub("^data:\\s*", "", x)
    tryCatch(jsonlite::fromJSON(json_text), error = function(e) NULL)
  })

  Filter(Negate(is.null), parsed_data)
}

parse_openai_responses_stream_chunk <- function(chunk) {
  # SSE frames typically arrive as lines prefixed with "data: ..."
  char <- rawToChar(chunk)
  parts <- strsplit(char, split = "\n")[[1]]
  # Keep only JSON-bearing "data:" lines
  json_lines <- gsub("^data:\\s*", "", parts[grepl("^data:", parts)])
  parsed <- lapply(json_lines, function(x) {
    # Some providers send sentinel like [DONE] — skip non-JSON
    if (identical(x, "[DONE]") || x == "") return(NULL)
    tryCatch(jsonlite::fromJSON(x), error = function(e) NULL)
  })
  Filter(Negate(is.null), parsed)
}

append_or_update_tool_calls <- function(tool_calls, new_tool_calls, verbose) {
  tool_call <- new_tool_calls[[1]]
  id <- tool_call$id

  last_id <- if (length(tool_calls) > 0)
    tool_calls[[length(tool_calls)]]$id else NULL

  if (!is.null(id) & (is.null(last_id) || (id != last_id))) {
    if (verbose & !is.null(last_id)) cat("\n\n")
    tool_calls <- append(
      tool_calls,
      list(
        list(
          id = tool_call$id,
          type = tool_call$type,
          `function` = list(
            name = tool_call$`function`$name,
            args = tool_call$`function`$arguments
          )
        )
      )
    )

    if (verbose) {
      cat(
        glue::glue(
          "Calling tool '{tool_call$`function`$name}', with arguments:"
        )
      )
      cat("\n")
      if (verbose & length(tool_call$`function`$arguments) > 0)
        cat(tool_call$`function`$arguments)
    }
  } else {
    # Update arguments of the last call
    arguments_current <- tool_calls[[length(tool_calls)]]$`function`$arguments
    arguments_new <- tool_call$`function`$arguments
    if (length(arguments_new) > 0) {
      tool_calls[[length(tool_calls)]]$`function`$arguments <- paste0(
        arguments_current,
        arguments_new
      )
      if (verbose) cat(arguments_new)
    }
  }

  tool_calls
}

is_openai_responses_endpoint <- function(req) {
  url_str <- tryCatch(
    httr2::url_build(req$url),
    error = function(e) as.character(req$url)
  )
  grepl("/responses(\\b|/|\\?)", url_str)
}

normalize_openai_request <- function(req, api_type) {
  if (api_type != "openai") return(req)
  if (!is_openai_responses_endpoint(req)) return(req)

  body_obj <- tryCatch(req$body$data, error = function(e) NULL)
  if (!is.list(body_obj)) return(req)

  # Chat Completions -> Responses rename
  if (!is.null(body_obj$messages) && is.null(body_obj$input)) {
    body_obj$input <- body_obj$messages
    body_obj$messages <- NULL
  }

  # response_format -> text.format  (Responses API)
  if (!is.null(body_obj$response_format) && is.null(body_obj$text$format)) {
    rf <- body_obj$response_format

    # allow legacy "json_object" string
    if (is.character(rf)) rf <- list(type = rf)

    fmt <- NULL

    if (identical(rf$type, "json_object")) {
      fmt <- list(type = "json_object")
    } else if (identical(rf$type, "json_schema")) {
      # accept either wrapped { json_schema = ... } or a raw schema
      js <- rf$json_schema %||% rf$schema %||% rf

      # pull name from common places (Draft-04 'title' is fine)
      name <- js$name %||% js$title %||% "Schema"
      schema <- js$schema %||% js
      strict <- isTRUE(rf$strict %||% js$strict)

      fmt <- list(
        type = "json_schema",
        name = as.character(name),
        schema = schema
      )
      if (strict) fmt$strict <- TRUE
    }

    if (!is.null(fmt)) {
      body_obj$text <- body_obj$text %||% list()
      body_obj$text$format <- fmt
      body_obj$response_format <- NULL
    }
  }

  # --- Tools normalization for Responses API -------------------------------
  # Some providers/endpoints require top-level `name` (and sometimes `parameters`)
  # instead of nesting under `function`. Keep the nested `function` too for
  # compatibility; we're just ensuring required fields exist at top-level.
  if (!is.null(body_obj$tools) && is.list(body_obj$tools)) {
    body_obj$tools <- lapply(body_obj$tools, function(t) {
      # Ensure type if omitted but a function spec exists
      if (is.null(t$type) && !is.null(t$`function`)) t$type <- "function"

      # Hoist nested fields to top-level when missing there
      if (is.null(t$name) && !is.null(t$`function`$name)) {
        t$name <- t$`function`$name
      }
      if (is.null(t$description) && !is.null(t$`function`$description)) {
        t$description <- t$`function`$description
      }
      # Some Responses implementations expect top-level `parameters`
      if (is.null(t$parameters) && !is.null(t$`function`$parameters)) {
        t$parameters <- t$`function`$parameters
      }
      t
    })
  }

  # Normalize tool_choice shape (if using CC-style {"type":"function","function":{"name":...}})
  if (!is.null(body_obj$tool_choice) && is.list(body_obj$tool_choice)) {
    if (
      !is.null(body_obj$tool_choice$`function`$name) &&
        is.null(body_obj$tool_choice$name)
    ) {
      body_obj$tool_choice$name <- body_obj$tool_choice$`function`$name
    }
  }

  httr2::req_body_json(req, body_obj, auto_unbox = TRUE)
}
