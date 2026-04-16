# Make LLM answer as a data frame via structured output

This function builds on
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
to extract a data frame from an LLM response using structured output.
The supplied `schema` should describe a single row of the desired data
frame, or an array of such rows. Internally, `answer_as_dataframe()`
standardizes the schema to a JSON object with a `rows` field containing
an array of row objects. This shape works well with both text-based JSON
extraction and native structured-output backends, including 'ellmer',
where arrays of objects are converted to data frames.

## Usage

``` r
answer_as_dataframe(
  prompt,
  schema,
  min_rows = NULL,
  max_rows = NULL,
  schema_strict = FALSE,
  schema_in_prompt_as = c("example", "schema"),
  type = c("auto", "text-based", "openai", "ollama", "openai_oo", "ollama_oo", "ellmer")
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- schema:

  A JSON schema list or an 'ellmer' type definition describing a single
  row, an array of rows, or a wrapper object containing a `rows` array.

- min_rows:

  (optional) Minimum number of rows required in the returned data frame

- max_rows:

  (optional) Maximum number of rows allowed in the returned data frame

- schema_strict:

  If TRUE, the wrapped schema will be strictly enforced. Passed through
  to
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)

- schema_in_prompt_as:

  Passed through to
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  when using a text-based JSON path

- type:

  Passed through to
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  to control the structured output backend

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the LLM response is returned as a data frame.

## Details

Prefer supplying an 'ellmer' row schema created with
`ellmer::type_object(...)` when possible. This is usually the clearest
way to describe the columns you want, and it maps cleanly to native
'ellmer' structured output. These 'ellmer' schema definitions can also
be used with non-'ellmer' LLM providers, because 'tidyprompt' converts
between 'ellmer' schema definitions and JSON-schema representations as
needed.

`answer_as_dataframe()` accepts the following schema shapes:

- A single row schema, such as `ellmer::type_object(...)` or a JSON
  schema object whose properties describe the columns of one row.

- An array-of-rows schema, such as `ellmer::type_array(row_schema)` or a
  JSON schema with `type = "array"` and row objects under `items`.

- A wrapper object with a `rows` field containing an array of row
  objects.

Regardless of which of these forms you supply, `answer_as_dataframe()`
normalizes it to a row-oriented structured-output schema before
delegating to
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md).

## See also

Other pre_built_prompt_wraps:
[`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md),
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
[`answer_as_numeric()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_numeric.md),
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md),
[`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md),
[`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md),
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_sql()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_sql.md),
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other answer_as_prompt_wraps:
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
[`answer_as_numeric()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_numeric.md),
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md)

## Examples

``` r
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

if (FALSE) { # \dontrun{
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
} # }
```
