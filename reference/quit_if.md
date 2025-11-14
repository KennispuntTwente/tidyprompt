# Make evaluation of a prompt stop if LLM gives a specific response

This function is used to wrap a
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
object and ensure that the evaluation will stop if the LLM says it
cannot answer the prompt. This is useful in scenarios where it is
determined the LLM is unable to provide a response to a prompt.

## Usage

``` r
quit_if(
  prompt,
  quit_detect_regex = "NO ANSWER",
  instruction =
    paste0("If you think that you cannot provide a valid answer, you must type:\n",
    "'NO ANSWER' (use no other characters)"),
  success = TRUE,
  response_result = c("null", "llm_response", "regex_match")
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- quit_detect_regex:

  A regular expression to detect in the LLM's response which will cause
  the evaluation to stop. The default will detect the string "NO ANSWER"
  in the response

- instruction:

  A string to be added to the prompt to instruct the LLM how to respond
  if it cannot answer the prompt. The default is "If you think that you
  cannot provide a valid answer, you must type: 'NO ANSWER' (use no
  other characters)". This parameter can be set to `NULL` if no
  instruction is needed in the prompt

- success:

  A logical indicating whether the
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  loop break should nonetheless be considered as a successful completion
  of the extraction and validation process. If `FALSE`, the
  `object_to_return` must will always be set to NULL and thus parameter
  'response_result' must also be set to 'null'; if `FALSE`,
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  will also print a warning about the unsuccessful evaluation. If
  `TRUE`, the `object_to_return` will be returned as the response result
  of
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  (and
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  will print no warning about unsuccessful evaluation); parameter
  'response_result' will then determine what is returned as the response
  result of
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).

- response_result:

  A character string indicating what should be returned when the
  quit_detect_regex is detected in the LLM's response. The default is
  'null', which will return NULL as the response result o f
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).
  Under 'llm_response', the full LLM response will be returned as the
  response result of
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).
  Under 'regex_match', the part of the LLM response that matches the
  quit_detect_regex will be returned as the response result of
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the evaluation will stop upon detection of the
quit_detect_regex in the LLM's response

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
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other miscellaneous_prompt_wraps:
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  "What the favourite food of my cat on Thursday mornings?" |>
    quit_if() |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   What the favourite food of my cat on Thursday mornings?
  #
  #   If you think that you cannot provide a valid answer, you must type:
  #   'NO ANSWER' (use no other characters)
  # --- Receiving response from LLM provider: ---
  #   NO ANSWER
  # NULL
} # }
```
