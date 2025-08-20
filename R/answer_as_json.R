#' @title Make LLM answer as JSON (with optional schema)
#'
#' @description This functions wraps a prompt with settings that ensure the LLM response
#' is a valid JSON object, optionally matching a given JSON schema. Users
#' may provide either an 'ellmer' type (e.g. `ellmer:type_object()`;
#' see https://ellmer.tidyverse.org/articles/structured-data.html) or
#' a JSON Schema (as R list object) to define the expected structure of the response.
#'
#' The function can work with all models and providers through text-based
#' handling, but also supports native settings for the OpenAI, Ollama,
#' and various 'ellmer' types. (See argument 'type'.) This means that it is possible to easily
#' switch between providers with different levels of JSON support,
#' while ensuring the results will be in the correct format.
#'
#' @param prompt A single string or a [tidyprompt()] object
#'
#' @param schema A list which represents
#' a JSON schema that the response should match.See example and your API's
#' documentation for more information on defining JSON schemas. Note that the schema should be a
#' list (R object) representing a JSON schema, not a JSON string
#' (use [jsonlite::fromJSON()] and [jsonlite::toJSON()] to convert between the two)
#'
#' @param schema_strict If TRUE, the provided schema will be strictly enforced.
#' This option is passed as part of the schema when using type  type
#' "openai" or "ollama", and when using the other types it is passed to
#' [jsonvalidate::json_validate()]
#'
#' @param schema_in_prompt_as If providing a schema and
#' when using type "text-based", "openai_oo", or "ollama_oo", this argument specifies
#' how the schema should be included in the prompt:
#' \itemize{
#' \item "example" (default): The schema will be included as an example JSON object
#' (tends to work best). [r_json_schema_to_example()] is used to generate the example object
#' from the schema
#' \item "schema": The schema will be included as a JSON schema
#' }
#' @param type The way that JSON response should be enforced:
#' \itemize{
#' #' \item "auto": Automatically determine the type based on 'llm_provider$api_type'
#' or 'llm_provider$json_type' (if set; 'json_type' overrides 'api_type' determination).
#' This may not always consider model compatibility and could lead to errors;
#' set 'type' manually if errors occur; use 'text-based' if unsure
#' \item "text-based": Instruction will be added to the prompt
#' asking for JSON; when a schema is provided, this will also be included
#' in the prompt (see argument 'schema_in_prompt_as'). JSON will be parsed
#' from the LLM response and, when a schema is provided, it will be validated
#' against the schema with [jsonvalidate::json_validate()]. Feedback is sent to the
#' LLM when the response is not valid. This option always works, but may in some
#' cases may be less powerful than the other native JSON options
#' \item "openai" and "ollama": The response format will be set via the relevant API parameters,
#' making the API enforce a valid JSON response. If a schema is provided,
#' it will also be included in the API parameters and also be enforced by the API.
#' When no schema is provided, a request for JSON is added to the prompt (as required
#' by the APIs). Note that these JSON options may not be available for all models
#' of your provider; consult their documentation for more information.
#' If you are unsure or encounter errors, use "text-based"
#' \item "openai_oo" and "ollama_oo": Similar to "openai" and "ollama", but if a
#' schema is provided it is not included in the API parameters. Schema validation
#' will be done in R with [jsonvalidate::json_validate()]. This can be useful if
#' you want to use the API's JSON support, but their schema support is limited
#' \item "ellmer": A parameter will be added to the LLM provider, indicating
#' that the response should be structured according to the provided schema.
#' This is only useful when using an `llm_provider_ellmer()` object,
#' and will lead to errors for other LLM provider types. Typically,
#' when type is set to 'auto' and the `llm_provider` is an 'ellmer' LLM provider,
#' this will be automatically selected (so it should not be necessary to set
#' this option manually)
#' }
#' Note that the "openai" and "ollama" types may also work for other APIs with a similar structure.
#' Note furthermore that the "ellmer" type is still experimental and conversion
#' between 'ellmer' schemas and R list schemas may contain bugs.
#'
#' @return A [tidyprompt()] with an added [prompt_wrap()] which will ensure
#' that the LLM response is a valid JSON object
#'
#' @export
#'
#' @example inst/examples/answer_as_json.R
#'
#' @family pre_built_prompt_wraps
#' @family answer_as_prompt_wraps
#' @family json
#' @title Make LLM answer as JSON (with optional schema)
#'
#' @description Wrap a prompt so the LLM returns a valid JSON object,
#' optionally constrained by a schema. The `schema` can be either
#' a JSON Schema (R list) or an `ellmer::type_*` object.
#'
#' @param schema Either a JSON Schema (R list) or an `ellmer::type_*` object.
#'   When an ellmer type is provided and the selected `type` supports JSON
#'   schemas (e.g. "openai", "ollama", "text-based"), it will be converted
#'   to JSON Schema via `ellmer_type_to_json_schema()`. When `type = "ellmer"`,
#'   the ellmer type is used directly for structured calls.
answer_as_json <- function(
  prompt,
  schema = NULL,
  schema_strict = FALSE,
  schema_in_prompt_as = c("example", "schema"),
  type = c(
    "auto",
    "text-based",
    "openai",
    "ollama",
    "openai_oo",
    "ollama_oo",
    "ellmer"
  )
) {
  prompt <- tidyprompt(prompt)
  schema_in_prompt_as <- match.arg(schema_in_prompt_as)
  type <- match.arg(type)

  # Accept either JSON Schema list or ellmer::type_* object
  if (!is.null(schema) && !(is.list(schema) || is_ellmer_type(schema))) {
    stop("The 'schema' must be a JSON Schema list or an ellmer::type_* object.")
  }
  if (is.list(schema) && length(schema) == 0) {
    stop("The 'schema' list must be non-empty.")
  }

  if (type == "auto" && getOption("tidyprompt.warn.auto.json", TRUE)) {
    cli::cli_alert_warning(
      paste0(
        "{.strong `answer_as_json()`}:\n",
        "* Automatically determining type based on 'llm_provider$api_type' ",
        "(or 'llm_provider$json_type' if set); this may not consider model compatibility\n",
        "* Manually set 'type' or 'llm_provider$json_type' if errors occur ",
        "(\"text-based\" always works)\n",
        "* Use `options(tidyprompt.warn.auto.json = FALSE)` to suppress this warning"
      )
    )
  }

  determine_type <- function(llm_provider = NULL) {
    if (type != "auto") return(type)
    valid_types <- c(
      "text-based",
      "openai",
      "ollama",
      "openai_oo",
      "ollama_oo",
      "ellmer"
    )
    provider_json_type <- llm_provider[["json_type"]]
    if (
      !is.null(provider_json_type) &&
        !identical(provider_json_type, "auto") &&
        provider_json_type %in% valid_types
    ) {
      return(provider_json_type)
    }
    provider_api_type <- llm_provider[["api_type"]]
    if (isTRUE(provider_api_type == "openai")) return("openai")
    if (isTRUE(provider_api_type == "ollama")) return("ollama")
    if (isTRUE(provider_api_type == "ellmer")) return("ellmer")
    "text-based"
  }

  # Normalize once so we can use either representation everywhere
  sch <- tryCatch(
    normalize_schema_dual(schema, strict = schema_strict),
    error = function(e) list(json_schema = NULL, ellmer_type = NULL)
  )

  # Will be filled by modify_fn if we inject schema details into the prompt
  schema_instruction <- NULL

  parameter_fn <- function(llm_provider) {
    t <- determine_type(llm_provider)

    if (t == "ellmer") {
      if (!is.null(sch$ellmer_type)) {
        return(list(.ellmer_structured_type = sch$ellmer_type))
      } else {
        cli::cli_alert_warning(
          "{.strong `answer_as_json()`}: ellmer type not available; falling back."
        )
        return(NULL)
      }
    }

    if (t == "ollama") {
      # Native JSON mode; include JSON Schema if we have it
      if (is.null(schema)) return(list(format = "json"))
      if (!is.null(sch$json_schema)) {
        js <- sch$json_schema
        js$strict <- schema_strict
        return(list(format = js))
      }
      return(list(format = "json"))
    }

    if (t == "openai") {
      # Native JSON mode; include JSON Schema if we have it
      if (is.null(schema))
        return(list(response_format = list(type = "json_object")))
      if (!is.null(sch$json_schema)) {
        json_schema <- list(
          name = "schema",
          schema = sch$json_schema,
          strict = schema_strict
        )
        return(list(
          response_format = list(
            type = "json_schema",
            json_schema = json_schema
          )
        ))
      }
      return(list(response_format = list(type = "json_object")))
    }

    if (t == "ollama_oo") return(list(format = "json"))
    if (t == "openai_oo")
      return(list(response_format = list(type = "json_object")))

    NULL
  }

  modify_fn <- function(prompt_text, llm_provider) {
    t <- determine_type(llm_provider)

    # If native schema support is in use AND we actually have the right form,
    # don't inject schema into the prompt.
    if (!is.null(schema)) {
      if (t == "ellmer" && !is.null(sch$ellmer_type)) return(prompt_text)
      if (t == "openai" && !is.null(sch$json_schema)) return(prompt_text)
      if (t == "ollama" && !is.null(sch$json_schema)) return(prompt_text)
    }

    # Otherwise, enforce JSON via instructions (text-based style),
    # optionally embedding a JSON example or schema (requires JSON Schema form).
    prompt_text <- glue::glue(
      "{prompt_text}\n\nYour must format your response as a JSON object."
    )

    if (!is.null(schema) && !is.null(sch$json_schema)) {
      jsonvalidate_installed() # warn if missing when we later validate

      if (schema_in_prompt_as == "example") {
        schema_instruction <<- paste0(
          "Your JSON object should match this example JSON object:\n",
          jsonlite::toJSON(
            r_json_schema_to_example(sch$json_schema),
            auto_unbox = TRUE,
            pretty = TRUE
          )
        )
      } else {
        # "schema"
        schema_instruction <<- paste0(
          "Your JSON object should match this JSON schema:\n",
          jsonlite::toJSON(sch$json_schema, auto_unbox = TRUE, pretty = TRUE)
        )
      }
      prompt_text <- paste0(prompt_text, "\n\n", schema_instruction)
    }

    prompt_text
  }

  extraction_fn <- function(llm_response, llm_provider) {
    t <- determine_type(llm_provider)

    # In ellmer structured mode, we already get an R object matching the type.
    if (isTRUE(t == "ellmer") && !is.null(schema)) {
      return(llm_response)
    }

    jsons <- extraction_fn_json(llm_response)
    if (length(jsons) == 0) {
      return(llm_feedback("You must respond as a valid JSON object."))
    }
    if (length(jsons) == 1) jsons <- jsons[[1]]

    # If we're not using provider-side schema enforcement, and we have a JSON Schema,
    # validate locally.
    if (
      !is.null(schema) &&
        !isTRUE(t %in% c("openai", "ollama")) &&
        !is.null(sch$json_schema) &&
        jsonvalidate_installed()
    ) {
      answer_json <- jsonlite::toJSON(jsons, auto_unbox = TRUE, pretty = TRUE)
      schema_json <- jsonlite::toJSON(
        sch$json_schema,
        auto_unbox = TRUE,
        pretty = TRUE
      )

      validation_result <- jsonvalidate::json_validate(
        answer_json,
        schema_json,
        strict = schema_strict,
        verbose = TRUE
      )

      if (!validation_result) {
        error_details <- attr(validation_result, "errors")
        return(
          llm_feedback(
            paste0(
              "Your response did not match the expected JSON schema.\n\n",
              df_to_string(error_details),
              if (!is.null(schema_instruction))
                paste0("\n\n", schema_instruction) else ""
            )
          )
        )
      }
    }

    jsons
  }

  prompt_wrap(
    prompt,
    modify_fn,
    extraction_fn,
    NULL,
    NULL,
    parameter_fn,
    name = "answer_as_json"
  )
}

jsonvalidate_installed <- function() {
  if (!requireNamespace("jsonvalidate", quietly = TRUE)) {
    cli::cli_alert_warning(
      paste0(
        "{.strong `answer_as_json()`}:\n",
        "* When using type \"text-based\" and providing a schema,\n",
        " the 'jsonvalidate' package must be installed to validate the response\n",
        " against the schema\n",
        "* The 'jsonvalidate' package is not installed;\n",
        " the LLM response will not be validated against the schema"
      )
    )

    return(invisible(FALSE))
  }
  return(invisible(TRUE))
}
