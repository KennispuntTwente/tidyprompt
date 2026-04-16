# `answer_as_dataframe()` accepts multiple schema shapes.
# Prefer an ellmer row schema when possible, because it is concise and maps
# cleanly to native ellmer structured output.
# These ellmer schema definitions also work with non-ellmer LLM providers,
# because tidyprompt converts between ellmer schemas and JSON schemas for you.

if (requireNamespace("ellmer", quietly = TRUE)) {
  person_row_schema_ellmer <- ellmer::type_object(
    name = ellmer::type_string(),
    age = ellmer::type_integer(),
    city = ellmer::type_string()
  )

  # Also accepted: an array of row objects.
  person_array_schema_ellmer <- ellmer::type_array(person_row_schema_ellmer)
}

# Also accepted: a JSON schema describing one row.
person_row_schema_json <- list(
  type = "object",
  properties = list(
    name = list(type = "string"),
    age = list(type = "integer"),
    city = list(type = "string")
  ),
  required = c("name", "age", "city"),
  additionalProperties = FALSE
)

# Also accepted: a wrapper object with a `rows` array.
person_wrapper_schema_json <- list(
  type = "object",
  properties = list(
    rows = list(
      type = "array",
      items = person_row_schema_json
    )
  ),
  required = "rows",
  additionalProperties = FALSE
)

\dontrun{
  prompt <- paste(
    "Extract the people in the following notes as a table:",
    "Alice (32, Berlin), Bob (28, Utrecht)."
  )

  # Preferred: ellmer row schema.
  # This works both with ellmer-backed providers and with regular tidyprompt
  # providers, because tidyprompt converts the schema when needed.
  if (requireNamespace("ellmer", quietly = TRUE)) {
    prompt |>
      answer_as_dataframe(person_row_schema_ellmer) |>
      send_prompt()
    #    name age    city
    # 1 Alice  32  Berlin
    # 2   Bob  28 Utrecht

    # Also works: ellmer array-of-rows schema.
    prompt |>
      answer_as_dataframe(person_array_schema_ellmer) |>
      send_prompt()
  }

  # Also works: JSON schema for one row.
  prompt |>
    answer_as_dataframe(person_row_schema_json, type = "text-based") |>
    send_prompt()

  # Also works: JSON wrapper schema with a `rows` array.
  prompt |>
    answer_as_dataframe(person_wrapper_schema_json, type = "text-based") |>
    send_prompt()
}