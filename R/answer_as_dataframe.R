#' Make LLM answer as a data frame via structured output
#'
#' @description
#' This function builds on [answer_as_json()] to extract a data frame from an
#' LLM response using structured output. The supplied `schema` should describe a
#' single row of the desired data frame, or an array of such rows. Internally,
#' `answer_as_dataframe()` standardizes the schema to a JSON object with a
#' `rows` field containing an array of row objects. This shape works well with
#' both text-based JSON extraction and native structured-output backends,
#' including 'ellmer', where arrays of objects are converted to data frames.
#'
#' @details
#' Prefer supplying an 'ellmer' row schema created with
#' `ellmer::type_object(...)` when possible. This is usually the clearest way to
#' describe the columns you want, and it maps cleanly to native 'ellmer'
#' structured output. These 'ellmer' schema definitions can also be used with
#' non-'ellmer' LLM providers, because 'tidyprompt' converts between 'ellmer'
#' schema definitions and JSON-schema representations as needed.
#'
#' `answer_as_dataframe()` accepts the following schema shapes:
#' * A single row schema, such as `ellmer::type_object(...)` or a JSON schema
#'   object whose properties describe the columns of one row.
#' * An array-of-rows schema, such as `ellmer::type_array(row_schema)` or a JSON
#'   schema with `type = "array"` and row objects under `items`.
#' * A wrapper object with a `rows` field containing an array of row objects.
#'
#' Regardless of which of these forms you supply, `answer_as_dataframe()`
#' normalizes it to a row-oriented structured-output schema before delegating to
#' [answer_as_json()].
#'
#' @param prompt A single string or a [tidyprompt()] object
#' @param schema A JSON schema list or an 'ellmer' type definition describing a
#' single row, an array of rows, or a wrapper object containing a `rows` array.
#' @param min_rows (optional) Minimum number of rows required in the returned
#' data frame
#' @param max_rows (optional) Maximum number of rows allowed in the returned
#' data frame
#' @param schema_strict If TRUE, the wrapped schema will be strictly enforced.
#' Passed through to [answer_as_json()]
#' @param schema_in_prompt_as Passed through to [answer_as_json()] when using a
#' text-based JSON path
#' @param type Passed through to [answer_as_json()] to control the structured
#' output backend
#'
#' @return A [tidyprompt()] with an added [prompt_wrap()] which will ensure
#' that the LLM response is returned as a data frame.
#'
#' @export
#'
#' @example inst/examples/answer_as_dataframe.R
#'
#' @family pre_built_prompt_wraps
#' @family answer_as_prompt_wraps
answer_as_dataframe <- function(
  prompt,
  schema,
  min_rows = NULL,
  max_rows = NULL,
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
  schema_in_prompt_as <- match.arg(schema_in_prompt_as)
  type <- match.arg(type)

  row_schema <- answer_as_dataframe_row_schema(schema, strict = schema_strict)
  wrapped_schema <- answer_as_dataframe_wrapper_schema(row_schema)
  json_wrap <- answer_as_dataframe_json_wrap(
    wrapped_schema = wrapped_schema,
    schema_strict = schema_strict,
    schema_in_prompt_as = schema_in_prompt_as,
    type = type
  )

  prompt_wrap(
    prompt,
    modify_fn = json_wrap$modify_fn,
    extraction_fn = function(x, llm_provider, http_list) {
      structured <- json_wrap$extraction_fn(x, llm_provider, http_list)

      if (
        inherits(structured, "llm_feedback") ||
          inherits(structured, "llm_feedback_tool_result") ||
          inherits(structured, "llm_break") ||
          inherits(structured, "llm_break_soft")
      ) {
        return(structured)
      }

      answer_as_dataframe_extract(
        structured,
        row_schema = row_schema,
        min_rows = min_rows,
        max_rows = max_rows
      )
    },
    validation_fn = json_wrap$validation_fn,
    handler_fn = json_wrap$handler_fn,
    parameter_fn = json_wrap$parameter_fn,
    type = json_wrap$type,
    name = "answer_as_dataframe"
  )
}

answer_as_dataframe_json_wrap <- function(
  wrapped_schema,
  schema_strict,
  schema_in_prompt_as,
  type
) {
  json_prompt <- answer_as_json(
    tidyprompt("dataframe"),
    schema = wrapped_schema,
    schema_strict = schema_strict,
    schema_in_prompt_as = schema_in_prompt_as,
    type = type
  )

  wraps <- json_prompt$get_prompt_wraps(order = "default")
  wraps[[length(wraps)]]
}

answer_as_dataframe_row_schema <- function(schema, strict = FALSE) {
  normalized <- normalize_schema_dual(schema, strict = strict)
  json_schema <- normalized$json_schema

  if (is.null(json_schema)) {
    stop(
      "The 'schema' must be convertible to a JSON schema for ",
      "`answer_as_dataframe()`."
    )
  }

  json_schema <- unwrap_json_schema(json_schema)

  # Detect a wrapper object whose `rows` field is an array of row objects.

  # We require that rows.items looks like a row schema (has properties)
  # AND that `rows` is the ONLY property -- a genuine wrapper produced by

  # answer_as_dataframe_wrapper_schema() never has sibling columns.  When

  # a row schema itself has a column named "rows" (e.g. array<object>),
  # sibling columns will be present and we leave the schema alone.
  if (
    identical(json_schema$type %||% NULL, "object") &&
      is.list(json_schema$properties) &&
      length(json_schema$properties) == 1L &&
      "rows" %in% names(json_schema$properties) &&
      identical(json_schema$properties$rows$type %||% NULL, "array") &&
      is.list(json_schema$properties$rows$items) &&
      (identical(json_schema$properties$rows$items$type %||% NULL, "object") ||
        is.list(json_schema$properties$rows$items$properties))
  ) {
    json_schema <- json_schema$properties$rows$items
  }

  if (identical(json_schema$type %||% NULL, "array")) {
    json_schema <- json_schema$items
  }

  if (
    !identical(json_schema$type %||% NULL, "object") &&
      is.null(json_schema$properties)
  ) {
    stop(
      "The 'schema' for `answer_as_dataframe()` must describe row objects, ",
      "an array of row objects, or an object with a `rows` array."
    )
  }

  json_schema
}

answer_as_dataframe_wrapper_schema <- function(row_schema) {
  list(
    type = "object",
    properties = list(
      rows = list(
        type = "array",
        description = "Rows of the data frame.",
        items = row_schema
      )
    ),
    required = "rows",
    additionalProperties = FALSE
  )
}

answer_as_dataframe_extract <- function(
  x,
  row_schema,
  min_rows = NULL,
  max_rows = NULL
) {
  rows <- answer_as_dataframe_rows_from_response(x)

  if (is.null(rows)) {
    return(llm_feedback(
      "You must respond with a JSON object containing a `rows` array of objects."
    ))
  }

  df <- answer_as_dataframe_to_df(rows, row_schema = row_schema)

  if (is.null(df)) {
    return(llm_feedback(
      "The `rows` field must contain an array of objects that can be converted to a data frame."
    ))
  }

  observed_names <- names(df)
  required_cols <- row_schema$required %||% character()
  missing_required <- setdiff(required_cols, observed_names)
  if (length(missing_required) > 0) {
    return(llm_feedback(
      paste0(
        "The data frame is missing required columns: ",
        paste(missing_required, collapse = ", "),
        "."
      )
    ))
  }

  df <- answer_as_dataframe_complete_columns(df, row_schema)

  if (!is.null(min_rows) && nrow(df) < min_rows) {
    return(llm_feedback(
      glue::glue("The data frame should contain at least {min_rows} rows.")
    ))
  }
  if (!is.null(max_rows) && nrow(df) > max_rows) {
    return(llm_feedback(
      glue::glue("The data frame should contain at most {max_rows} rows.")
    ))
  }

  df
}

answer_as_dataframe_rows_from_response <- function(x) {
  if (is.data.frame(x)) {
    return(x)
  }

  if (is.list(x) && "rows" %in% names(x)) {
    return(x$rows)
  }

  if (is.list(x) && length(x) > 0 && all(vapply(x, is.list, logical(1)))) {
    return(x)
  }

  NULL
}

answer_as_dataframe_to_df <- function(rows, row_schema) {
  if (is.data.frame(rows)) {
    return(rows)
  }

  if (is.list(rows) && length(rows) == 0) {
    return(answer_as_dataframe_empty_df(row_schema))
  }

  if (!is.list(rows) || !all(vapply(rows, is.list, logical(1)))) {
    return(NULL)
  }

  tryCatch(
    dplyr::bind_rows(rows),
    error = function(e) NULL
  )
}

answer_as_dataframe_complete_columns <- function(df, row_schema) {
  expected_cols <- names(row_schema$properties %||% list())
  if (length(expected_cols) == 0) {
    return(df)
  }

  missing_cols <- setdiff(expected_cols, names(df))
  for (col in missing_cols) {
    df[[col]] <- answer_as_dataframe_missing_column(
      row_schema$properties[[col]],
      nrow(df)
    )
  }

  ordered <- c(expected_cols, setdiff(names(df), expected_cols))
  df[, ordered, drop = FALSE]
}

answer_as_dataframe_empty_df <- function(row_schema) {
  props <- row_schema$properties %||% list()
  out <- lapply(props, answer_as_dataframe_missing_column, n_rows = 0)

  if (length(out) == 0) {
    return(data.frame())
  }

  out <- out[names(props)]
  data.frame(out, check.names = FALSE)
}

answer_as_dataframe_missing_column <- function(column_schema, n_rows) {
  column_type <- column_schema$type %||% NULL
  if (!is.null(column_schema$enum)) {
    column_type <- "string"
  }

  if (identical(column_type, "string")) {
    return(rep(NA_character_, n_rows))
  }
  if (identical(column_type, "number")) {
    return(rep(NA_real_, n_rows))
  }
  if (identical(column_type, "integer")) {
    return(rep(NA_integer_, n_rows))
  }
  if (identical(column_type, "boolean")) {
    return(rep(NA, n_rows))
  }

  vector("list", n_rows)
}
