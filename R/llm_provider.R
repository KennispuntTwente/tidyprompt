#' @title LlmProvider R6 Class
#' @name llm_provider-class
#'
#' @description This class provides a structure for creating [llm_provider-class]
#'  objects with different implementations of `$complete_chat()`.
#' Using this class, you can create an [llm_provider-class] object that interacts
#'  with different LLM providers, such Ollama, OpenAI, or other custom providers.
#'
#' @example inst/examples/llm_provider.R
#'
#' @family llm_provider
NULL

#' @rdname llm_provider-class
#' @export
`llm_provider-class` <- R6::R6Class(
  "LlmProvider",
  public = list(
    #' @field parameters
    #' A named list of parameters to configure the [llm_provider-class].
    #' Parameters may be appended to the request body when interacting with the
    #'  LLM provider API
    parameters = list(),

    #' @field verbose
    #' A logical indicating whether interaction with the LLM provider should be
    #'  printed to the console
    verbose = getOption("tidyprompt.verbose", TRUE),

    #' @field url
    #' The URL to the LLM provider API endpoint for chat completion
    url = NULL,

    #' @field api_key
    #' The API key to use for authentication with the LLM provider API
    api_key = NULL,

    #' @field api_type
    #' The type of API to use (e.g., "openai", "ollama", "ellmer").
    #'  This is used to determine certain specific behaviors for different APIs,
    #'  for instance, as is done in the [answer_as_json()] function
    api_type = "unspecified",

    #' @field json_type
    #' The type of JSON mode to use (e.g., 'auto', 'openai', 'ollama', or 'text-based').
    #'  Using 'auto' or having this field not set, the api_type field will be used to
    #'  determine the JSON mode during the [answer_as_json()] function. If this field
    #'  is set, this will override the api_type field for JSON mode determination.
    #'  (Note: this determination only happens when the 'type' argument in
    #'  [answer_as_json()] is also set to 'auto'.)
    json_type = "auto",

    #' @field handler_fns
    #' A list of functions that will be called after the completion of a chat.
    #'  See `$add_handler_fn()`
    handler_fns = list(),

    #' @field pre_prompt_wraps
    #' A list of prompt wraps that will be applied to any prompt evaluated
    #' by this [llm_provider-class] object, before any prompt-specific
    #' prompt wraps are applied. See `$add_prompt_wrap()`.
    #' This can be used to set default behavior for all prompts
    #' evaluated by this [llm_provider-class] object.
    pre_prompt_wraps = list(),

    #' @field post_prompt_wraps
    #' A list of prompt wraps that will be applied to any prompt evaluated
    #' by this [llm_provider-class] object, after any prompt-specific
    #' prompt wraps are applied. See `$add_prompt_wrap()`.
    #' This can be used to set default behavior for all prompts
    #' evaluated by this [llm_provider-class] object.
    post_prompt_wraps = list(),

    #' @description
    #' Create a new [llm_provider-class] object
    #'
    #' @param complete_chat_function
    #' Function that will be called by the [llm_provider-class] to complete a chat.
    #' This function should take a list containing at least '$chat_history'
    #'  (a data frame with 'role' and 'content' columns) and return a response
    #'  object, which contains:
    #'  \itemize{
    #'  \item 'completed': A dataframe with 'role' and 'content' columns,
    #'  containing the completed chat history
    #'
    #'  \item 'http': A list containing a list 'requests' and a list 'responses',
    #'  containing the HTTP requests and responses made during the chat completion
    #'  }
    #'
    #' @param parameters
    #' A named list of parameters to configure the [llm_provider-class].
    #'  These parameters may be appended to the request body when interacting with
    #'  the LLM provider.
    #' For example, the `model` parameter may often be required.
    #'  The 'stream' parameter may be used to indicate that the API should stream.
    #' Parameters should not include the chat_history, or 'api_key' or 'url', which
    #'  are handled separately by the [llm_provider-class] and '$complete_chat()'.
    #' Parameters should also not be set when they are handled by prompt wraps
    #'
    #' @param verbose
    #' A logical indicating whether interaction with the LLM
    #'  provider should be printed to the console
    #'
    #' @param url
    #' The URL to the LLM provider API endpoint for chat completion
    #'  (typically required, but may be left NULL in some cases, for instance
    #'  when creating a fake LLM provider)
    #'
    #' @param api_key
    #' The API key to use for authentication with the LLM
    #'  provider API (optional, not required for, for instance, Ollama)
    #'
    #' @param api_type
    #' The type of API to use (e.g., "openai", "ollama").
    #'  This is used to determine certain specific behaviors for different APIs
    #'  (see for example the [answer_as_json()] function)
    #'
    #' @return
    #' A new [llm_provider-class] R6 object
    initialize = function(
      complete_chat_function,
      parameters = list(),
      verbose = TRUE,
      url = NULL,
      api_key = NULL,
      api_type = "unspecified"
    ) {
      if (length(parameters) > 0 && is.null(names(parameters)))
        stop("parameters must be a named list")

      private$complete_chat_function <- complete_chat_function
      self$parameters <- parameters
      self$verbose <- verbose
      self$url <- url
      self$api_key <- api_key
      self$api_type <- api_type
    },

    #' @description
    #' Helper function to set the parameters of the [llm_provider-class]
    #'  object.
    #' This function appends new parameters to the existing parameters
    #'  list.
    #'
    #' @param new_parameters
    #' A named list of new parameters to append to the
    #'  existing parameters list
    #'
    #' @return The modified [llm_provider-class] object
    set_parameters = function(new_parameters) {
      if (length(new_parameters) == 0) return(self)

      stopifnot(
        is.list(new_parameters),
        length(new_parameters) > 0,
        !is.null(names(new_parameters))
      )
      self$parameters <- utils::modifyList(self$parameters, new_parameters)
      return(self)
    },

    #' @description Sends a chat history (see [chat_history()]
    #'  for details) to the LLM provider using the configured `$complete_chat()`.
    #' This function is typically called by [send_prompt()] to interact with the LLM
    #'  provider, but it can also be called directly.
    #'
    #' @param input A string, a data frame which is a valid chat history
    #'  (see [chat_history()]), or a list containing a valid chat history under key
    #'  '$chat_history'
    #'
    #' @return The response from the LLM provider
    complete_chat = function(input) {
      if (length(input) == 1 & is.character(input)) {
        chat_history <- chat_history(input)
        input <- list(chat_history = chat_history)
      } else if (is.data.frame(input)) {
        chat_history <- chat_history(input)
        input <- list(chat_history = chat_history)
      }

      stopifnot(
        is.list(input),
        "chat_history" %in% names(input)
      )

      chat_history <- chat_history(input$chat_history)
      if (self$verbose) {
        message(
          crayon::bold(
            glue::glue(
              "--- Sending request to LLM provider",
              " ({
              if (!is.null(self$parameters$model)) {
                self$parameters$model
              } else {
                'no model specified'
              }
          }):",
              " ---"
            )
          )
        )

        message(chat_history$content[nrow(chat_history)])
      }

      if (self$verbose)
        message(
          crayon::bold(
            glue::glue(
              "--- Receiving response from LLM provider: ---"
            )
          )
        )

      environment(private$complete_chat_function) <- environment()
      response <- private$complete_chat_function(chat_history)

      # Filter content with empty string ("") (Ollama tool call)
      response$completed <- response$completed[
        response$completed$content != "",
      ]

      http <- list()
      http$requests[[1]] <- response$http$request
      http$responses[[1]] <- response$http$response

      while (TRUE) {
        for (handler_fn in self$handler_fns) {
          response <- handler_fn(response, self)
          http$requests[[length(http$requests) + 1]] <- response$http$request
          http$responses[[length(http$responses) + 1]] <- response$http$response

          stopifnot(
            is.list(response),
            "completed" %in% names(response),
            is.data.frame(response$completed),
            all(c("role", "content") %in% names(response$completed))
          )

          if (isTRUE(response$`break`)) break
        }

        if (!isFALSE(response$done) | isTRUE(response$`break`)) {
          break
        }
      }

      # Update http list
      response$http <- http

      # Print difference between chat_history and completed
      if (
        self$verbose &&
          (is.null(self$parameters$stream) || !self$parameters$stream)
      ) {
        chat_history_new <- response$completed[
          (nrow(chat_history) + 1):nrow(response$completed),
        ]

        # Filter out rows with 'tool_result' == TRUE
        # That's already being printed in the handler function of
        #   `answer_using_tools()`
        if (
          "tool_result" %in%
            names(chat_history_new) &
            "tool_call" %in% names(chat_history_new)
        ) {
          chat_history_new_print <- chat_history_new |>
            dplyr::filter(
              (is.na(tool_result) | tool_result == FALSE),
              (is.na(tool_call) | tool_call == FALSE)
            )
        } else {
          chat_history_new_print <- chat_history_new
        }

        for (i in seq_len(nrow(chat_history_new_print))) {
          message(chat_history_new_print$content[i])
        }
      }

      if (isTRUE(response$`break`))
        warning(
          paste0(
            "Chat completion was interrupted by a handler break"
          )
        )

      if (self$verbose) return(invisible(response))

      return(response)
    },

    #' @description
    #' Helper function to add a handler function to the
    #'  [llm_provider-class] object.
    #' Handler functions are called after the completion of a chat and can be
    #'  used to modify the response before it is returned by the [llm_provider-class].
    #' Each handler function should take the response object
    #'  as input (first argument) as well as 'self' (the [llm_provider-class]
    #'  object) and return a modified response object.
    #' The functions will be called in the order they are added to the list.
    #'
    #' @details
    #' If a handler function returns a list with a 'break' field set to `TRUE`,
    #'  the chat completion will be interrupted and the response will be returned
    #'  at that point.
    #' If a handler function returns a list with a 'done' field set to `FALSE`,
    #'  the handler functions will continue to be called in a loop until the 'done'
    #'  field is not set to `FALSE`.
    #'
    #' @param handler_fn A function that takes the response object plus
    #'  'self' (the [llm_provider-class] object) as input and
    #'  returns a modified response object
    add_handler_fn = function(handler_fn) {
      stopifnot(is.function(handler_fn))
      self$handler_fns <- c(self$handler_fns, list(handler_fn))
      return(self)
    },

    #' @description
    #' Helper function to set the handler functions of the
    #'  [llm_provider-class] object.
    #' This function replaces the existing
    #'  handler functions list with a new list of handler functions.
    #' See `$add_handler_fn()` for more information
    #'
    #' @param handler_fns A list of handler functions to set
    set_handler_fns = function(handler_fns) {
      stopifnot(is.list(handler_fns))
      self$handler_fns <- handler_fns
      return(self)
    },

    #' `r lifecycle::badge("experimental")`
    #' @description
    #' Add a provider-level prompt wrap template to be applied to all prompts.
    #' @param prompt_wrap A list created by [provider_prompt_wrap()]
    #' @param position One of "pre" or "post" (applied before/after prompt-specific wraps)
    add_prompt_wrap = function(prompt_wrap, position = c("pre", "post")) {
      position <- match.arg(position)
      stopifnot(is.list(prompt_wrap))

      # Normalize fields so downstream code can rely on them
      needed <- c(
        "type",
        "modify_fn",
        "extraction_fn",
        "validation_fn",
        "handler_fn",
        "parameter_fn",
        "name"
      )
      missing <- setdiff(needed, names(prompt_wrap))
      for (nm in missing) prompt_wrap[[nm]] <- NULL

      class(prompt_wrap) <- unique(c(
        "provider_prompt_wrap",
        class(prompt_wrap)
      ))

      if (identical(position, "pre")) {
        self$pre_prompt_wraps <- c(self$pre_prompt_wraps, list(prompt_wrap))
      } else {
        self$post_prompt_wraps <- c(self$post_prompt_wraps, list(prompt_wrap))
      }
      invisible(self)
    },

    #' `r lifecycle::badge("experimental")`
    #' @description
    #' Apply all provider-level wraps to a prompt (character or tidyprompt)
    #' and return a tidyprompt with wraps attached.
    #' This is typically called inside `send_prompt()` before evaluation of
    #' the prompt.
    #' @param prompt A string, a chat history, a list containing
    #' a chat history under key '$chat_history', or a [tidyprompt-class] object
    apply_prompt_wraps = function(prompt) {
      if (!inherits(prompt, "Tidyprompt")) {
        prompt <- tidyprompt(prompt)
      }

      # Fresh Tidyprompt with same base/system/chat_history but no wraps yet
      new_prompt <- `tidyprompt-class`$new(prompt$base_prompt)
      new_prompt$system_prompt <- prompt$system_prompt
      # Preserve chat history without constructing prompt text
      new_prompt$.__enclos_env__$private$chat_history <-
        prompt$.__enclos_env__$private$chat_history

      # 1) Provider pre wraps
      if (length(self$pre_prompt_wraps)) {
        for (pw in self$pre_prompt_wraps) {
          new_prompt <- prompt_wrap_internal(
            new_prompt,
            modify_fn = pw$modify_fn,
            extraction_fn = pw$extraction_fn,
            validation_fn = pw$validation_fn,
            handler_fn = pw$handler_fn,
            parameter_fn = pw$parameter_fn,
            type = pw$type,
            name = pw$name
          )
        }
      }

      # 2) Existing prompt wraps in their original order
      if (length(prompt$get_prompt_wraps(order = "default"))) {
        for (pw in prompt$get_prompt_wraps(order = "default")) {
          new_prompt <- prompt_wrap_internal(
            new_prompt,
            modify_fn = pw$modify_fn,
            extraction_fn = pw$extraction_fn,
            validation_fn = pw$validation_fn,
            handler_fn = pw$handler_fn,
            parameter_fn = pw$parameter_fn,
            type = pw$type,
            name = pw$name
          )
        }
      }

      # 3) Provider post wraps
      if (length(self$post_prompt_wraps)) {
        for (pw in self$post_prompt_wraps) {
          new_prompt <- prompt_wrap_internal(
            new_prompt,
            modify_fn = pw$modify_fn,
            extraction_fn = pw$extraction_fn,
            validation_fn = pw$validation_fn,
            handler_fn = pw$handler_fn,
            parameter_fn = pw$parameter_fn,
            type = pw$type,
            name = pw$name
          )
        }
      }

      new_prompt
    }
  ),
  private = list(
    complete_chat_function = NULL
  )
)
