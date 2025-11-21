# Make LLM answer as a named list

Get a named list from LLM response with optional item instructions and
validations.

## Usage

``` r
answer_as_named_list(
  prompt,
  item_names,
  item_instructions = NULL,
  item_validations = NULL
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- item_names:

  A character vector specifying the expected item names

- item_instructions:

  An optional named list of additional instructions for each item

- item_validations:

  An optional named list of validation functions for each item. Like
  validation functions for a
  [`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
  these functions should return
  [`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)
  if the validation fails. If the validation is successful, the function
  should return TRUE

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
that ensures the LLM response is a named list with the specified item
names, optional instructions, and validations.

## See also

[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md)
[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)

Other pre_built_prompt_wraps:
[`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md),
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
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
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  persona <- "Create a persona for me, please." |>
    answer_as_named_list(
      item_names = c("name", "age", "occupation"),
      item_instructions = list(
        name = "The name of the persona",
        age = "The age of the persona",
        occupation = "The occupation of the persona"
      )
    ) |> send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   Create a persona for me, please.
  #
  #   Respond with a named list like so:
  #     -- name: <<value>> (The name of the persona)
  #     -- age: <<value>> (The age of the persona)
  #     -- occupation: <<value>> (The occupation of the persona)
  #   Each name must correspond to: name, age, occupation
  # --- Receiving response from LLM provider: ---
  #   Here is your persona:
  #
  #   -- name: Astrid Welles
  #   -- age: 32
  #   -- occupation: Museum Curator
  persona$name
  # [1] "Astrid Welles"
  persona$age
  # [1] "32"
  persona$occupation
  # [1] "Museum Curator"
} # }
```
