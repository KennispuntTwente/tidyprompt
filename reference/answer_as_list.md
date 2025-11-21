# Make LLM answer as a list of items

Make LLM answer as a list of items

## Usage

``` r
answer_as_list(
  prompt,
  item_name = "item",
  item_explanation = NULL,
  n_unique_items = NULL,
  list_mode = c("bullet", "comma")
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- item_name:

  (optional) Name of the items in the list

- item_explanation:

  (optional) Additional explanation of what an item should be. Item
  explanation should be a single string. It will be appended after the
  list instruction

- n_unique_items:

  (optional) Number of unique items required in the list

- list_mode:

  (optional) Mode of the list. Either "bullet" or "comma". "bullet mode
  expects items to be listed with "–" before each item, with a new line
  for each item (e.g., "– item1\n– item2\n– item3"). "comma" mode
  expects items to be listed with a number and a period before (e.g.,
  "1. item1, 2. item2, 3. item3"). "comma" mode may be easier for
  smaller LLMs to use

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the LLM response is a list of items

## See also

[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md)

Other pre_built_prompt_wraps:
[`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md),
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
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
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  "What are some delicious fruits?" |>
    answer_as_list(item_name = "fruit", n_unique_items = 5) |>
    send_prompt()
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # What are some delicious fruits?
  #
  # Respond with a list, like so:
  #   -- <<fruit 1>>
  #   -- <<fruit 2>>
  #   etc.
  # The list should contain 5 unique items.
  # --- Receiving response from LLM provider: ---
  # Here's the list of delicious fruits:
  #   -- Strawberries
  #   -- Pineapples
  #   -- Mangoes
  #   -- Blueberries
  #   -- Pomegranates
  # [[1]]
  # [1] "Strawberries"
  #
  # [[2]]
  # [1] "Pineapples"
  #
  # [[3]]
  # [1] "Mangoes"
  #
  # [[4]]
  # [1] "Blueberries"
  #
  # [[5]]
  # [1] "Pomegranates"
} # }
```
