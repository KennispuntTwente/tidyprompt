# Make LLM answer match a specific regex

Make LLM answer match a specific regex

## Usage

``` r
answer_as_regex_match(prompt, regex, mode = c("full_match", "extract_matches"))
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- regex:

  A character string specifying the regular expression the response must
  match

- mode:

  A character string specifying the mode of the regex match. Options are
  "exact_match" (default) and "extract_all_matches". Under "full_match",
  the full LLM response must match the regex. If it does not, the LLM
  will be sent feedback to retry. The full LLM response will be returned
  if the regex is matched. Under "extract_matches", all matches of the
  regex in the LLM response will be returned (if present). If the regex
  is not matched at all, the LLM will be sent feedback to retry. If
  there is at least one match, the matches will be returned as a
  character vector

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the LLM response matches the specified regex

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
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  "What would be a suitable e-mail address for cupcake company?" |>
    answer_as_regex_match("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$") |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   What would be a suitable e-mail address for cupcake company?
  #
  #   You must answer with a response that matches this regex format:
  #     ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$
  #     (use no other characters)
  # --- Receiving response from LLM provider: ---
  #   sweet.treats.cupcakes@gmail.com
  # [1] "sweet.treats.cupcakes@gmail.com"

  "What would be a suitable e-mail address for cupcake company?" |>
    add_text("Give three ideas.") |>
    answer_as_regex_match(
      "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}",
      mode = "extract_matches"
    ) |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   What would be a suitable e-mail address for cupcake company?
  #
  #   Give three ideas.
  #
  #   You must answer with a response that matches this regex format:
  #     [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}
  # --- Receiving response from LLM provider: ---
  #   Here are three potential email addresses for a cupcake company:
  #
  #   1. sweettreats.cupcakes@yummail.com
  #   2. cupcakes.and.love@flourpower.net
  #   3. thecupcakery@gmail.com
  # [1] "sweettreats.cupcakes@yummail.com" "cupcakes.and.love@flourpower.net"
  # "thecupcakery@gmail.com"
} # }
```
