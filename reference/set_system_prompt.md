# Set system prompt of a [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md) object

Set the system prompt for a prompt. The system prompt will be added as a
message with role 'system' at the start of the chat history when this
prompt is evaluated by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).

## Usage

``` r
set_system_prompt(prompt, system_prompt)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- system_prompt:

  A single character string representing the system prompt

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with the system prompt set

## Details

The system prompt will be stored in the
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
object as '\$system_prompt'.

## See also

Other pre_built_prompt_wraps:
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
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
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md)

Other miscellaneous_prompt_wraps:
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md)

## Examples

``` r
prompt <- "Hi there!" |>
  set_system_prompt("You are an assistant who always answers in very short poems.")
prompt$system_prompt
#> [1] "You are an assistant who always answers in very short poems."

if (FALSE) { # \dontrun{
  prompt |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   Hi there!
  # --- Receiving response from LLM provider: ---
  #   Hello to you, I say,
  #   Welcome here, come what may!
  #   How can I assist today?
  # [1] "Hello to you, I say,\nWelcome here, come what may!\nHow can I assist today?"
} # }
```
