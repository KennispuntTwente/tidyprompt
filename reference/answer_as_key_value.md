# Make LLM answer as a list of key-value pairs

This function is similar to
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md)
but instead of returning a list of items, it instructs the LLM to return
a list of key-value pairs.

## Usage

``` r
answer_as_key_value(
  prompt,
  key_name = "key",
  value_name = "value",
  pair_explanation = NULL,
  n_unique_items = NULL,
  list_mode = c("bullet", "comma")
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- key_name:

  (optional) A name or placeholder describing the "key" part of each
  pair

- value_name:

  (optional) A name or placeholder describing the "value" part of each
  pair

- pair_explanation:

  (optional) Additional explanation of what a pair should be. It should
  be a single string. It will be appended after the list instruction.

- n_unique_items:

  (optional) Number of unique key-value pairs required in the list

- list_mode:

  (optional) Mode of the list: "bullet" or "comma".

  - "bullet" mode expects pairs like:

        -- key1: value1
        -- key2: value2

  - "comma" mode expects pairs like:

        1. key: value, 2. key: value, etc.

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the LLM response is a list of key-value pairs.

## Examples

``` r
if (FALSE) { # \dontrun{
  "What are a few capital cities around the world?" |>
    answer_as_key_value(
      key_name = "country",
      value_name = "capital"
    ) |>
    send_prompt()
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # What are a few capital cities around the world?
  #
  # Respond with a list of key-value pairs, like so:
  #   -- <<country 1>>: <<capital 1>>
  #   -- <<country 2>>: <<capital 2>>
  #   etc.
  # --- Receiving response from LLM provider: ---
  # Here are a few:
  #   -- Australia: Canberra
  #   -- France: Paris
  #   -- United States: Washington D.C.
  #   -- Japan: Tokyo
  #   -- China: Beijing
  # $Australia
  # [1] "Canberra"
  #
  # $France
  # [1] "Paris"
  #
  # $`United States`
  # [1] "Washington D.C."
  #
  # $Japan
  # [1] "Tokyo"
  #
  # $China
  # [1] "Beijing"
} # }
```
