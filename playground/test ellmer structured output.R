library(ellmer)
devtools::load_all()

x <- tidyprompt::llm_provider_ellmer(ellmer::chat_openai())

ellmer_schema <- type_object(
  name = type_string(),
  age = type_integer(),
  hobbiesss_for_Fun = type_array(type_string())
)

schemas <- normalize_schema_dual(ellmer_schema)

"Make up a persona" |>
  answer_as_json(
    schema = ellmer_schema
  ) |>
  send_prompt(x)
