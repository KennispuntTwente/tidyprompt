#' Create a new Ollama LLM provider
#'
#' This function creates a new [llm_provider-class] object that interacts with the Ollama API.
#'
#' @param parameters A named list of parameters. Currently the following parameters are required:
#'    - model: The name of the model to use
#'    - stream: A logical indicating whether the API should stream responses
#'
#'  Additional parameters may be passed by adding them to the parameters list;
#'  these parameters will be passed to the Ollama API via the body of the POST request.
#'
#'  Note that various Ollama options need to be set in a list named 'options' within
#'  the parameters list (e.g., context window size is represented in $parameters$options$num_ctx).
#'  For ease of configuration, the 'set_option' and 'set_options' functions are available
#'  (e.g., `$set_option("num_ctx", 1024)` or `$set_options(list(num_ctx = 1024, temperature = 1))`).
#   See available settings at https://github.com/ollama/ollama/blob/main/docs/api.md
#' @param verbose A logical indicating whether the interaction with the LLM provider
#' should be printed to the console
#' @param url The URL to the Ollama API endpoint for chat completion
#' (typically: "http://localhost:11434/api/chat")
#' @param num_ctx The context window size to use.
#' When NULL, the default context window size will be used. This is a function
#' argument for convenience, and will be passed to '$parameters$options$num_ctx'
#'
#' @return A new [llm_provider-class] object for use of the Ollama API
#'
#' @export
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_ollama <- function(
  parameters = list(
    model = "llama3.1:8b",
    stream = getOption("tidyprompt.stream", TRUE)
  ),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "http://localhost:11434/api/chat",
  num_ctx = NULL
) {
  complete_chat <- function(chat_history) {
    # Build messages, with optional image support for the last user message
    msgs <- lapply(seq_len(nrow(chat_history)), function(i) {
      list(role = chat_history$role[i], content = chat_history$content[i])
    })

    # If images are attached, convert them to Ollama's `images` array (base64)
    add_parts <- self$parameters$.add_image_parts %||% NULL
    if (!is.null(add_parts) && length(add_parts) > 0) {
      last_i <- nrow(chat_history)
      if (last_i > 0 && identical(chat_history$role[last_i], "user")) {
        b64s <- list()
        for (p in add_parts) {
          src <- p$source %||% NULL
          if (identical(src, "b64") && !is.null(p$data)) {
            b64s[[length(b64s) + 1]] <- as.character(p$data)
          } else if (identical(src, "url") && !is.null(p$data)) {
            # Download and base64-encode
            res <- tryCatch(
              {
                rq <- httr2::request(as.character(p$data))
                rp <- httr2::req_perform(rq)
                raw <- httr2::resp_body_raw(rp)
                jsonlite::base64_enc(raw)
              },
              error = function(e) NULL
            )
            if (!is.null(res)) b64s[[length(b64s) + 1]] <- as.character(res)
          }
        }
        if (length(b64s) > 0) {
          msgs[[last_i]]$images <- unname(b64s)
        }
      }
    }

    body <- list(
      model = self$parameters$model,
      messages = msgs
    )

    # Append user-facing parameters only; skip internal helpers (prefixed with '.')
    for (name in names(self$parameters)) {
      if (!startsWith(name, ".")) body[[name]] <- self$parameters[[name]]
    }

    request <- httr2::request(self$url) |>
      httr2::req_body_json(body)

    stream_cb <- self$stream_callback %||%
      getOption("tidyprompt.stream_callback", NULL)

    request_llm_provider(
      chat_history,
      request,
      stream = self$parameters$stream,
      verbose = self$verbose,
      api_type = self$api_type,
      stream_callback = stream_cb,
      llm_provider = self
    )
  }

  if (is.null(parameters$stream)) {
    parameters$stream <- FALSE
  }
  if (!is.null(num_ctx)) {
    parameters$options$num_ctx <- num_ctx
  }

  # Extend llm_provider-class with 'set_option' functions
  class <- R6::R6Class(
    "llm_provider_ollama-class",
    inherit = `llm_provider-class`,
    public = list(
      set_option = function(name, value) {
        stopifnot(
          is.character(name),
          is.character(value) || is.logical(value) || is.numeric(value)
        )

        self$parameters$options[[name]] <- value
        return(self)
      },
      set_options = function(options) {
        stopifnot(
          is.list(options),
          !is.null(names(options))
        )

        for (name in names(options)) {
          value <- options[[name]]
          stopifnot(
            is.character(value) || is.logical(value) || is.numeric(value)
          )

          self$parameters$options[[name]] <- value
        }
        return(self)
      }
    )
  )

  ollama <- class$new(
    complete_chat_function = complete_chat,
    parameters = parameters,
    verbose = verbose,
    url = url,
    api_type = "ollama"
  )

  return(ollama)
}

#' Create a new OpenAI LLM provider
#'
#' This function creates a new [llm_provider-class] object that interacts with the Open AI API.
#' Supports both the Chat Completions API (/v1/chat/completions) and the Responses API (/v1/responses).
#'
#' @param parameters A named list of parameters. Currently the following parameters are required:
#'    - model: The name of the model to use
#'    - api_key: The API key to use for authentication with the OpenAI API. This
#'    should be a project API key (not a user API key)
#'    - url: The URL to the OpenAI API (may also be an alternative endpoint
#'    that provides a similar API.)
#'    - stream: A logical indicating whether the API should stream responses
#'
#'  Additional parameters are appended to the request body; see the OpenAI API
#'  documentation for more information: https://platform.openai.com/docs/api-reference/chat
#' @param verbose A logical indicating whether the interaction with the LLM provider
#' should be printed to the console. Default is TRUE.
#' @param url The URL to the OpenAI API endpoint for chat completion
#' (typically: "https://api.openai.com/v1/chat/completions"
#' or "https://api.openai.com/v1/responses"; both the Chat Completions API and
#' the Responses API are supported; the Responses API is more modern)
#' @param api_key The API key to use for authentication with the OpenAI API
#'
#' @return A new [llm_provider-class] object for use of the OpenAI API
#'
#' @export
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_openai <- function(
  parameters = list(
    model = "gpt-4o-mini",
    stream = getOption("tidyprompt.stream", TRUE)
  ),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://api.openai.com/v1/responses",
  api_key = Sys.getenv("OPENAI_API_KEY")
) {
  complete_chat <- function(chat_history) {
    headers <- c(
      "Content-Type" = "application/json",
      "Authorization" = paste("Bearer", self$api_key)
    )

    # Build messages; support multimodal content for last user message
    add_parts <- self$parameters$.add_image_parts %||% NULL
    n <- nrow(chat_history)
    messages <- lapply(seq_len(n), function(i) {
      role <- chat_history$role[i]
      text <- chat_history$content[i]
      # For the last user message, if images are attached, convert to content parts
      if (!is.null(add_parts) && i == n && identical(role, "user")) {
        parts <- list()
        if (!is.null(text) && nzchar(text)) {
          parts[[length(parts) + 1]] <- list(type = "text", text = text)
        }
        for (p in add_parts) {
          src <- p$source %||% NULL
          if (identical(src, "url") && !is.null(p$data)) {
            parts[[length(parts) + 1]] <- list(
              type = "image_url",
              image_url = compact_list(list(
                url = as.character(p$data),
                detail = p$detail %||% NULL
              ))
            )
          } else if (identical(src, "b64") && !is.null(p$data)) {
            mime <- p$mime %||% "image/png"
            data_url <- paste0("data:", mime, ";base64,", as.character(p$data))
            parts[[length(parts) + 1]] <- list(
              type = "image_url",
              image_url = compact_list(list(
                url = data_url,
                detail = p$detail %||% NULL
              ))
            )
          }
        }
        return(list(role = role, content = parts))
      }
      list(role = role, content = text)
    })

    # Decide between Chat Completions style (messages) and Responses API (input)
    # Support both legacy Chat Completions (messages) and modern Responses API (input)
    use_responses_api <- grepl("/responses$", self$url)
    if (use_responses_api) {
      # Transform messages -> input with part types changed to input_*/output_* variants.
      # For image parts, OpenAI Responses API expects a scalar URL string in `image_url`
      # and (optionally) a separate `detail` field, not an object. The previous implementation
      # forwarded the object `{ url = ..., detail = ... }` which triggers a 400 error:
      # "Invalid type for 'input[0].content[1].image_url': expected an image URL, but got an object instead.".
      input <- lapply(messages, function(msg) {
        role <- msg$role
        content <- msg$content
        parts <- list()
        text_type <- if (identical(role, "assistant")) {
          "output_text"
        } else {
          "input_text"
        }
        image_type <- if (identical(role, "assistant")) {
          "output_image"
        } else {
          "input_image"
        }
        if (is.character(content)) {
          if (nzchar(content)) {
            parts[[length(parts) + 1]] <- list(type = text_type, text = content)
          }
        } else if (is.list(content)) {
          for (part in content) {
            if (identical(part$type, "text")) {
              if (!is.null(part$text) && nzchar(part$text)) {
                parts[[length(parts) + 1]] <- list(
                  type = text_type,
                  text = part$text
                )
              }
            } else if (identical(part$type, "image_url")) {
              img <- part$image_url
              if (is.list(img)) {
                url_val <- img$url %||% NULL
                detail_val <- img$detail %||% NULL
                if (!is.null(url_val)) {
                  parts[[length(parts) + 1]] <- compact_list(list(
                    type = image_type,
                    image_url = as.character(url_val),
                    detail = detail_val
                  ))
                }
              } else if (is.character(img) && length(img) == 1) {
                parts[[length(parts) + 1]] <- list(
                  type = image_type,
                  image_url = img
                )
              }
            } else {
              # Fallback: keep as input_text if unknown
              if (!is.null(part$text)) {
                parts[[length(parts) + 1]] <- list(
                  type = text_type,
                  text = part$text
                )
              }
            }
          }
        }
        list(role = role, content = parts)
      })
      body <- list(input = input)
    } else {
      body <- list(messages = messages)
    }

    # Append user-facing parameters only; skip internal helpers (prefixed with '.')
    # This prevents sending fields like '.add_image_parts' which cause 400 errors
    # from OpenAI ("Unknown parameter"). Internal parameters are consumed above.
    for (name in names(self$parameters)) {
      if (!startsWith(name, ".")) {
        body[[name]] <- self$parameters[[name]]
      }
    }

    request <- httr2::request(self$url) |>
      httr2::req_body_json(body) |>
      httr2::req_headers(!!!headers)

    stream_cb <- self$stream_callback %||%
      getOption("tidyprompt.stream_callback", NULL)

    request_llm_provider(
      chat_history,
      request,
      stream = self$parameters$stream,
      verbose = self$verbose,
      api_type = self$api_type,
      stream_callback = stream_cb,
      llm_provider = self
    )
  }

  return(
    `llm_provider-class`$new(
      complete_chat_function = complete_chat,
      parameters = parameters,
      verbose = verbose,
      url = url,
      api_key = api_key,
      api_type = "openai"
    )
  )
}

#' Create a new OpenRouter LLM provider
#'
#' This function creates a new [llm_provider-class] object that interacts with the OpenRouter API.
#'
#' @param parameters A named list of parameters. Currently the following parameters are required:
#'    - model: The name of the model to use
#'    - stream: A logical indicating whether the API should stream responses
#'
#'  Additional parameters are appended to the request body; see the OpenRouter API
#'  documentation for more information: https://openrouter.ai/docs/parameters
#' @param verbose A logical indicating whether the interaction with the LLM provider
#' should be printed to the console.
#' @param url The URL to the OpenRouter API endpoint for chat completion
#' @param api_key The API key to use for authentication with the OpenRouter API
#'
#' @return A new [llm_provider-class] object for use of the OpenRouter API
#'
#' @export
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_openrouter <- function(
  parameters = list(
    model = "qwen/qwen-2.5-7b-instruct",
    stream = getOption("tidyprompt.stream", TRUE)
  ),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://openrouter.ai/api/v1/chat/completions",
  api_key = Sys.getenv("OPENROUTER_API_KEY")
) {
  llm_provider_openai(parameters, verbose, url, api_key)
}

#' Create a new Mistral LLM provider
#'
#' This function creates a new [llm_provider-class] object that interacts with the Mistral API.
#'
#' @param parameters A named list of parameters. Currently the following parameters are required:
#'    - model: The name of the model to use
#'    - stream: A logical indicating whether the API should stream responses
#'
#'  Additional parameters are appended to the request body; see the Mistral API
#'  documentation for more information: https://docs.mistral.ai/api/#tag/chat
#' @param verbose A logical indicating whether the interaction with the LLM provider
#' should be printed to the consol
#' @param url The URL to the Mistral API endpoint for chat completion
#' @param api_key The API key to use for authentication with the Mistral API
#'
#' @return A new [llm_provider-class] object for use of the Mistral API
#'
#' @export
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_mistral <- function(
  parameters = list(
    model = "ministral-3b-latest",
    stream = getOption("tidyprompt.stream", TRUE)
  ),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://api.mistral.ai/v1/chat/completions",
  api_key = Sys.getenv("MISTRAL_API_KEY")
) {
  llm_provider_openai(parameters, verbose, url, api_key)
}

#' Create a new Groq LLM provider
#'
#' This function creates a new [llm_provider-class] object that interacts with the Groq API.
#'
#' @param parameters A named list of parameters. Currently the following parameters are required:
#'   - model: The name of the model to use
#'   - stream: A logical indicating whether the API should stream responses
#'
#'  Additional parameters are appended to the request body; see the Groq API
#'  documentation for more information: https://console.groq.com/docs/api-reference#chat-create
#' @param verbose A logical indicating whether the interaction with the LLM provider
#' should be printed to the console
#' @param api_key The API key to use for authentication with the Groq API
#' @param url The URL to the Groq API endpoint for chat completion
#'
#' @return A new [llm_provider-class] object for use of the Groq API
#'
#' @export
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_groq <- function(
  parameters = list(
    model = "llama-3.1-8b-instant",
    stream = TRUE
  ),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://api.groq.com/openai/v1/chat/completions",
  api_key = Sys.getenv("GROQ_API_KEY")
) {
  llm_provider_openai(parameters, verbose, url, api_key)
}

#' Create a new XAI (Grok) LLM provider
#'
#' This function creates a new [llm_provider-class] object that interacts with the XAI API.
#'
#' @param parameters A named list of parameters. Currently the following parameters are required:
#'   - model: The name of the model to use
#'   - stream: A logical indicating whether the API should stream responses
#'
#'  Additional parameters are appended to the request body; see the XAI API
#'  documentation for more information: https://docs.x.ai/api/endpoints#chat-completions
#' @param verbose A logical indicating whether the interaction with the LLM provider
#' should be printed to the console. Default is TRUE.
#' @param url The URL to the XAI API endpoint for chat completion
#' @param api_key The API key to use for authentication with the XAI API
#'
#' @return A new [llm_provider-class] object for use of the XAI API
#'
#' @export
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_xai <- function(
  parameters = list(
    model = "grok-beta",
    stream = getOption("tidyprompt.stream", TRUE)
  ),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://api.x.ai/v1/chat/completions",
  api_key = Sys.getenv("XAI_API_KEY")
) {
  llm_provider_openai(parameters, verbose, url, api_key)
}

#' Create a new Google Gemini LLM provider
#'
#' @description
#' `r lifecycle::badge("superseded")`
#' This function creates a new [llm_provider-class] object that interacts with the Google Gemini API.
#'
#' @details
#' Streaming is not yet supported in this implementation. Native functions
#' like structured output and tool calling are also not supported in this implemetation.
#' This may however be achieved through creating a [llm_provider_ellmer()] object
#' with as input a `ellmer::chat_google_gemini()` object. Therefore, this function
#' is now superseded by `llm_provider_ellmer(ellmer::chat_google_gemini())`.
#'
#' @param parameters A named list of parameters. Currently the following parameters are required:
#'    - model: The name of the model to use (see: https://ai.google.dev/gemini-api/docs/models/gemini)
#'
#'  Additional parameters are appended to the request body; see the Google AI Studio API
#'  documentation for more information: https://ai.google.dev/gemini-api/docs/text-generation
#'  and https://github.com/google/generative-ai-docs/blob/main/site/en/gemini-api/docs/get-started/rest.ipynb
#' @param verbose A logical indicating whether the interaction with the LLM provider
#' should be printed to the console
#' @param url The URL to the Google Gemini API endpoint for chat completion
#' @param api_key The API key to use for authentication with the Google Gemini API
#' (see: https://aistudio.google.com/app/apikey)
#'
#' @return A new [llm_provider-class] object for use of the Google Gemini API
#'
#' @export
#'
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_google_gemini <- function(
  parameters = list(
    model = "gemini-1.5-flash"
  ),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://generativelanguage.googleapis.com/v1beta/models/",
  api_key = Sys.getenv("GOOGLE_AI_STUDIO_API_KEY")
) {
  complete_chat <- function(chat_history) {
    # Construct URL for the API request
    endpoint <- paste0(
      self$url,
      self$parameters$model,
      ":generateContent"
    )

    # Format chat_history for API compatibility with the 'contents' format
    formatted_contents <- lapply(seq_len(nrow(chat_history)), function(i) {
      list(
        role = ifelse(
          chat_history$role[i] == "assistant",
          "model",
          chat_history$role[i]
        ),
        parts = list(list(text = chat_history$content[i]))
      )
    })

    # Build the request body with 'contents' field
    body <- list(
      contents = formatted_contents
    )

    # Append all other parameters to the body
    for (name in names(self$parameters)) {
      body[[name]] <- self$parameters[[name]]
    }

    # Send the POST request with httr2
    request <- httr2::request(endpoint) |>
      httr2::req_headers(
        `Content-Type` = "application/json"
      ) |>
      httr2::req_body_json(body) |>
      httr2::req_url_query(key = self$api_key)
    response <- request |> httr2::req_perform()

    # Check if the request was successful
    if (httr2::resp_status(response) == 200) {
      content <- httr2::resp_body_json(response)

      completed <- chat_history |>
        dplyr::bind_rows(
          data.frame(
            role = "assistant",
            content = content$candidates[[1]]$content$parts[[1]]$text
          )
        )

      return(
        list(
          completed = completed,
          http = list(
            request = request,
            response = response
          )
        )
      )
    } else {
      stop(
        "Error: ",
        httr2::resp_status(response),
        " - ",
        httr2::resp_body_string(response)
      )
    }
  }

  `llm_provider-class`$new(
    complete_chat_function = complete_chat,
    parameters = parameters,
    verbose = verbose,
    url = url,
    api_key = api_key,
    api_type = "gemini"
  )
}

#' Create a fake [llm_provider-class] (for development and testing purposes)
#'
#' This function creates a fake [llm_provider-class] that can be used for development
#' and testing purposes. It is hardcoded to send back specific responses to
#' specific prompts that are used in vignettes, tests, and examples.
#' This is useful for running tests and builds in environments in which an
#' actual [llm_provider-class] is not available.
#'
#' @param verbose A logical indicating whether the interaction with the [llm_provider-class]
#' should be printed to the console. Default is TRUE.
#'
#' @return A new [llm_provider-class] object for use of the fake LLM provider
#'
#' @noRd
#' @keywords internal
llm_provider_fake <- function(verbose = getOption("tidyprompt.verbose", TRUE)) {
  complete_chat <- function(chat_history) {
    last_msg <- utils::tail(chat_history$content, 1)

    answer_as_integer_input <-
      "You must answer with only an integer (use no other characters)."

    chain_of_thought_input <-
      "To answer the user's prompt, you need to think step by step to arrive at a final answer."

    if (last_msg == "Hi there!") {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = paste0(
                  "It's nice to meet you.",
                  " Is there something I can help you with or would you like to chat?"
                )
              )
            )
        )
      )
    }

    if (
      grepl(
        "What is a large language model? Explain in 10 words.",
        last_msg,
        fixed = TRUE
      )
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = "Complex computer program trained on vast texts to generate human-like responses."
              )
            )
        )
      )
    }

    if (
      grepl("What is 2 + 2?", last_msg, fixed = TRUE) &
        grepl(answer_as_integer_input, last_msg, fixed = TRUE) &
        !grepl(chain_of_thought_input, last_msg, fixed = TRUE)
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = "4"
              )
            )
        )
      )
    }

    if (
      grepl("What is 2 + 2?", last_msg, fixed = TRUE) &
        !grepl(answer_as_integer_input, last_msg, fixed = TRUE)
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = glue::glue(
                  ">> step 1: Identify the mathematical operation in the prompt,
          which is a simple addition problem.

          >> step 2: Recall the basic arithmetic fact that 2 + 2 equals a specific
          numerical value.

          >> step 3: Apply this knowledge to determine the result of the addition problem,
          using the known facts about numbers and their operations.

          >> step 4: Conclude that based on this mathematical understanding, the
          solution to the prompt \"What is 2 + 2?\" is a fixed numerical quantity."
                )
              )
            )
        )
      )
    }

    if (
      any(
        grepl(
          "What is 2 + 2?",
          chat_history$content[chat_history$role == "user"],
          fixed = TRUE
        )
      ) &
        grepl(answer_as_integer_input, last_msg, fixed = TRUE) &
        !grepl(chain_of_thought_input, last_msg, fixed = TRUE)
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = "22"
              )
            )
        )
      )
    }

    if (
      grepl("What is 2 + 2?", last_msg, fixed = TRUE) &
        grepl(chain_of_thought_input, last_msg, fixed = TRUE) &
        grepl(answer_as_integer_input, last_msg, fixed = TRUE)
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = glue::glue(
                  ">> step 1: Identify the mathematical operation in the prompt,
          which is a simple addition problem.

          >> step 2: Recall the basic arithmetic fact that 2 + 2 equals a specific
          numerical value.

          >> step 3: Apply this knowledge to determine the result of the addition problem,
          using the known facts about numbers and their operations.

          >> step 4: Conclude that based on this mathematical understanding, the
          solution to the prompt \"What is 2 + 2?\" is a fixed numerical quantity.

          FINISH[4]"
                )
              )
            )
        )
      )
    }

    if (
      grepl(
        'example usage: FUNCTION[temperature_in_location]("Amsterdam", "Fahrenheit")',
        last_msg,
        fixed = TRUE
      )
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = glue::glue(
                  "I'll use the provided function to get the current temperature in Enschede.

          FUNCTION[temperature_in_location](\"Enschede\", \"Celcius\")"
                )
              )
            )
        )
      )
    }

    if (
      grepl(
        "function called: temperature_in_location",
        last_msg,
        fixed = TRUE
      ) &
        grepl("arguments used: location = Enschede", last_msg, fixed = TRUE)
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = "22.7"
              )
            )
        )
      )
    }

    if (
      any(
        grepl(
          "So the current temperature in Enschede is 22.7 degrees Celsius.",
          chat_history$content[chat_history$role == "assistant"],
          fixed = TRUE
        )
      ) &
        grepl(last_msg, answer_as_integer_input, fixed = TRUE)
    ) {
      return(
        list(
          completed = chat_history |>
            dplyr::bind_rows(
              data.frame(
                role = "assistant",
                content = "22.7"
              )
            )
        )
      )
    }

    return(
      list(
        completed = chat_history |>
          dplyr::bind_rows(
            data.frame(
              role = "assistant",
              content = "I'm a fake LLM! This is my default response."
            )
          )
      )
    )
  }

  `llm_provider-class`$new(
    complete_chat_function = complete_chat,
    verbose = verbose,
    parameters = list(
      model = 'llama3.1:8b'
    ),
    api_type = "fake"
  )
}

#' Create a new LLM provider from an `ellmer::chat()` object
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function creates a [llm_provider-class] from an `ellmer::chat()` object.
#' This allows the user to use the various LLM providers which are supported
#' by the 'ellmer' R package, including respective configuration and features.
#'
#' Please note that this function is experimental. This provider type may show different behavior than
#' other LLM providers, and may not function optimally.
#'
#' @details
#' Unlike other LLM provider classes,
#' most LLM provider settings need to be managed in the `ellmer::chat()` object
#' (and not in the `$parameters` list). `$get_chat()` and `$set_chat()` may be used
#' to manipulate the chat object. There are however some parameters that can be set
#' in the `$parameters` list; these are documented below.
#'
#' 1) Streaming can be controlled through via the `$parameters$stream` parameter.
#' If set to TRUE (default), streaming will be used if supported by the underlying
#' `ellmer::chat()` object. If the underlying `ellmer::chat()` object does not support streaming,
#' you may need to set this parameter to FALSE to avoid errors.
#'
#' 2) A special parameter `$.ellmer_structured_type` may also be set in the `$parameters` list;
#' this parameter is used to specify a structured output format. This should be a 'ellmer'
#' structured type (e.g., `ellmer::type_object`; see https://ellmer.tidyverse.org/articles/structured-data.html).
#' `answer_as_json()` sets this parameter to obtain structured output
#' (it is not recommended to set this parameter manually, but it is possible).
#'
#' @param chat An `ellmer::chat()` object (e.g., `ellmer::chat_openai()`)
#' @param parameters A named list of parameters. See 'details' for supported parameters
#' @param verbose A logical indicating whether the interaction with the [llm_provider-class]
#' should be printed to the console. Default is TRUE
#'
#' @return An [llm_provider-class] with api_type = "ellmer"
#'
#' @export
#'
#' @example inst/examples/llm_providers.R
#'
#' @family llm_provider
llm_provider_ellmer <- function(
  chat,
  parameters = list(
    stream = getOption("tidyprompt.stream", TRUE)
  ),
  verbose = getOption("tidyprompt.verbose", TRUE)
) {
  if (missing(chat) || is.null(chat)) {
    stop("`chat` must be an ellmer chat object (e.g., ellmer::chat_openai()).")
  }
  if (!is.environment(chat) || !is.function(chat$chat)) {
    stop(
      "`chat` doesn't look like an ellmer chat object (no `$chat()` method)."
    )
  }

  if (isTRUE(parameters$stream) && !requireNamespace("coro", quietly = TRUE)) {
    stop(paste0(
      "The 'coro' package is required for streaming with `llm_provider_ellmer()`.\n",
      "Please install it first (e.g., `install.packages('coro')`), ",
      "or set `parameters$stream = FALSE` to disable streaming"
    ))
  }

  complete_chat <- function(chat_history) {
    private$sync_model()
    ch <- self$ellmer_chat
    params <- self$parameters

    if (!all(c("role", "content") %in% names(chat_history))) {
      stop("`chat_history` must have columns `role` and `content`.")
    }

    # Seed prior turns
    hist <- if (nrow(chat_history) > 1) {
      chat_history[seq_len(nrow(chat_history) - 1), , drop = FALSE]
    } else {
      chat_history[0, , drop = FALSE]
    }

    ellmer_available <- requireNamespace("ellmer", quietly = TRUE)
    ellmer_ns <- if (ellmer_available) asNamespace("ellmer") else NULL

    as_content_text <- function(text) {
      if (is.null(text) || !nzchar(text)) {
        return(NULL)
      }
      if (
        !is.null(ellmer_ns) &&
          exists("ContentText", envir = ellmer_ns, inherits = FALSE)
      ) {
        return(ellmer::ContentText(text))
      }
      list(type = "text", text = text)
    }

    as_turn <- function(role, contents) {
      if (
        !is.null(ellmer_ns) &&
          exists("Turn", envir = ellmer_ns, inherits = FALSE)
      ) {
        return(ellmer::Turn(role = role, contents = contents))
      }
      list(role = role, contents = contents)
    }

    build_image_content <- function(p) {
      # URL-based image
      if (
        identical(p$source, "url") &&
          !is.null(p$data) &&
          !is.null(ellmer_ns) &&
          isTRUE(exists("content_image_url", ellmer_ns, inherits = FALSE))
      ) {
        return(ellmer::content_image_url(
          url = as.character(p$data),
          detail = p$detail %||% "auto"
        ))
      }

      # Base64-encoded image -> temp file + content_image_file, when available
      if (
        identical(p$source, "b64") &&
          !is.null(p$data) &&
          !is.null(ellmer_ns) &&
          isTRUE(exists("content_image_file", ellmer_ns, inherits = FALSE))
      ) {
        raw_bytes <- tryCatch(
          jsonlite::base64_dec(as.character(p$data)),
          error = function(e) raw()
        )
        if (length(raw_bytes)) {
          ext <- ".png"
          if (!is.null(p$mime) && grepl("jpeg", p$mime)) {
            ext <- ".jpg"
          }
          if (!is.null(p$mime) && grepl("gif", p$mime)) {
            ext <- ".gif"
          }
          if (!is.null(p$mime) && grepl("webp", p$mime)) {
            ext <- ".webp"
          }
          tf <- tempfile(fileext = ext)
          writeBin(raw_bytes, tf)
          return(ellmer::content_image_file(
            path = tf,
            content_type = p$mime %||% "auto"
          ))
        }
      }

      # Already-constructed ellmer content (e.g., content_image_url/file/plot)
      if (identical(p$source, "ellmer") && !is.null(p$obj)) {
        return(p$obj)
      }

      # Fallback stub when ellmer helpers are unavailable (primarily for tests)
      if (!is.null(p$source) && !is.null(p$data)) {
        return(list(
          source = p$source,
          data = p$data,
          mime = p$mime %||% NA_character_
        ))
      }

      NULL
    }

    # Prepare historical turns (excluding the latest message)
    prior_turns <- if (nrow(hist)) {
      lapply(seq_len(nrow(hist)), function(i) {
        as_turn(
          role = hist$role[i],
          contents = {
            ct <- as_content_text(hist$content[i])
            if (is.null(ct)) list() else list(ct)
          }
        )
      })
    } else {
      list()
    }

    # Prompt = last message (may be converted to multimodal contents below)
    prompt <- chat_history$content[nrow(chat_history)] %||% ""
    prompt <- if (!is.na(prompt)) as.character(prompt) else ""
    current_role <- chat_history$role[nrow(chat_history)] %||% "user"

    # Register tools
    if (!is.null(params$.ellmer_tools)) {
      for (td in params$.ellmer_tools) {
        ch$register_tool(td)
      }
    }

    # Check if we are doing structured output
    structured_type <- params$.ellmer_structured_type %||% NULL
    use_structured <- !is.null(structured_type) &&
      is.function(ch$chat_structured)

    # Central streaming hook: if provided, we will stream tokens/chunks
    # through this function instead of letting ellmer print to console.
    stream_cb <- self$stream_callback %||%
      getOption("tidyprompt.stream_callback", NULL)

    # Try to detect attached images and use ellmer multimodal helpers if available.
    # `add_image()` normalizes all inputs into `.add_image_parts`; here we
    # translate those parts into ellmer content objects.
    add_parts <- self$parameters$.add_image_parts %||% NULL

    multimodal_contents <- list()
    use_multimodal <- length(add_parts) > 0

    if (use_multimodal) {
      text_content <- as_content_text(prompt)
      if (!is.null(text_content)) {
        multimodal_contents[[length(multimodal_contents) + 1]] <- text_content
      }

      for (p in add_parts) {
        ic <- build_image_content(p)
        if (!is.null(ic)) {
          multimodal_contents[[length(multimodal_contents) + 1]] <- ic
        }
      }

      if (length(multimodal_contents) == 0L) {
        use_multimodal <- FALSE
      }
    }

    turns_to_send <- prior_turns
    prompt_for_model <- prompt

    if (use_multimodal) {
      turns_to_send <- c(
        turns_to_send,
        list(as_turn(role = current_role, contents = multimodal_contents))
      )
      prompt_for_model <- ""
    }

    ch <- ch$set_turns(turns_to_send)

    if (use_structured) {
      reply_struct <- ch$chat_structured(
        prompt_for_model,
        type = structured_type
      )
      # Store a JSON string in the transcript (so downstream plain JSON extractors still work)
      assistant_text <- jsonlite::toJSON(reply_struct, auto_unbox = TRUE) |>
        as.character()
    } else if (isTRUE(params$stream) && is.function(ch$stream)) {
      # --- Streaming path (ellmer-style sync streaming) ----------------------
      stream_error <- NULL
      assistant_text <- NULL

      stream <- tryCatch(
        ch$stream(prompt_for_model),
        error = function(e) {
          stream_error <<- e
          NULL
        }
      )

      if (is.null(stream) && !is.null(stream_error)) {
        if (use_multimodal) {
          reply_any <- ch$chat(prompt_for_model)
          assistant_text <- as.character(reply_any)
        } else {
          stop(stream_error)
        }
      } else {
        # Create environment to hold partial response
        partial_response_env <- new.env()
        assign("partial_response", "", envir = partial_response_env)

        coro::loop(
          for (chunk in stream) {
            if (length(chunk) == 0L || all(is.na(chunk))) {
              next
            }

            chunk_str <- paste0(as.character(chunk), collapse = "")
            if (!nzchar(chunk_str)) {
              next
            }

            current_response <- get(
              "partial_response",
              envir = partial_response_env
            )
            updated_response <- paste0(current_response, chunk_str)
            assign(
              "partial_response",
              updated_response,
              envir = partial_response_env
            )

            # If a callback is provided, use it; otherwise, mirror HTTP providers
            # by cat()ing chunks when verbose = TRUE.
            if (is.function(stream_cb)) {
              latest_message <- chat_history[nrow(chat_history), , drop = FALSE]

              meta <- list(
                llm_provider = self,
                chat_history = chat_history,
                latest_message = latest_message,
                partial_response = updated_response,
                chunk = chunk_str,
                api_type = "ellmer",
                endpoint = "chat",
                verbose = self$verbose
              )

              stream_cb(chunk_str, meta)
            } else if (isTRUE(self$verbose)) {
              cat(chunk_str)
            }
          }
        )

        # After streaming, use accumulated partial_response as assistant text
        assistant_text <- get("partial_response", envir = partial_response_env)
        # If it leads with '\n', strip that
        assistant_text <- sub("^\n", "", assistant_text)
        # If it ends with '\n', strip that
        assistant_text <- sub("\n$", "", assistant_text)
      }
    } else {
      # Regular, non-streaming chat
      reply_any <- ch$chat(prompt_for_model)
      assistant_text <- as.character(reply_any)
    }

    completed <- dplyr::bind_rows(
      chat_history,
      data.frame(
        role = "assistant",
        content = assistant_text,
        stringsAsFactors = FALSE
      )
    )

    list(
      completed = completed,
      http = list(request = NULL, response = NULL),
      ellmer_chat = ch
    )
  }

  klass <- R6::R6Class(
    "llm_provider_ellmer-class",
    inherit = `llm_provider-class`,
    public = list(
      ellmer_chat = NULL,

      get_chat = function() self$ellmer_chat,

      # Replace the underlying ellmer chat object and re-sync `parameters$model`
      set_chat = function(new_chat) {
        stopifnot(is.environment(new_chat), is.function(new_chat$chat))
        self$ellmer_chat <- new_chat
        private$sync_model()
        invisible(self)
      }
    ),
    private = list(
      complete_chat_function = NULL,

      # Keep self$parameters$model in sync with ellmer_chat$get_model()
      sync_model = function() {
        m <- tryCatch(
          {
            gm <- self$ellmer_chat$get_model
            if (is.function(gm)) self$ellmer_chat$get_model() else NULL
          },
          error = function(e) NULL
        )
        if (!is.null(m)) {
          self$parameters$model <- as.character(m)
        }
        invisible(NULL)
      }
    )
  )

  provider <- klass$new(
    complete_chat_function = complete_chat,
    parameters = list(),
    verbose = verbose,
    api_type = "ellmer"
  )

  if (length(parameters)) {
    provider$set_parameters(parameters)
  }

  provider$ellmer_chat <- chat
  # Initial sync so $parameters$model reflects the chat's current model
  provider$.__enclos_env__$private$sync_model()

  provider
}
