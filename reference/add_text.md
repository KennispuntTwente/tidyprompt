# Add text to a tidyprompt

Add text to a prompt by adding a
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will append the text to the before or after the current prompt
text.

## Usage

``` r
add_text(prompt, text, position = c("after", "before"), sep = "\n\n")
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- text:

  Text to be added to the current prompt text

- position:

  Where to add the text; either "after" or "before".

- sep:

  Separator to be used between the current prompt text and the text to
  be added

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will append the text to the end of the current prompt text

## See also

Other pre_built_prompt_wraps:
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
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other miscellaneous_prompt_wraps:
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

## Examples

``` r
prompt <- "Hi there!" |>
  add_text("How is your day?")
prompt
#> <tidyprompt>
#> The base prompt is modified by a prompt wrap, resulting in:
#> > Hi there!
#> > 
#> > How is your day? 
#> Use 'x$base_prompt' to show the base prompt text.
#> Use 'x$construct_prompt_text()' to get the full prompt text.
#> Use 'get_prompt_wraps(x)' to show the prompt wraps.
#> 
prompt |>
  construct_prompt_text()
#> [1] "Hi there!\n\nHow is your day?"
```
