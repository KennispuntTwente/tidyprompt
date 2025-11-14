# Get prompt wraps from a [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md) object

Get prompt wraps from a
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
object

## Usage

``` r
get_prompt_wraps(x, order = c("default", "modification", "evaluation"))
```

## Arguments

- x:

  A
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object

- order:

  The order to return the wraps. Options are:

  - "default": as originally added to the object

  - "modification": as ordered for modification of the base prompt;
    ordered by type: check, unspecified, mode, tool, break. This is the
    order in which prompt wraps are applied during
    [`construct_prompt_text()`](https://kennispunttwente.github.io/tidyprompt/reference/construct_prompt_text.md)

  - "evaluation": ordered for evaluation of the LLM response; ordered by
    type: tool, mode, break, unspecified, check. This is the order in
    which wraps are applied to the LLM output during
    [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

## Value

A list of prompt wrap objects (see
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md))

## See also

Other tidyprompt:
[`construct_prompt_text()`](https://kennispunttwente.github.io/tidyprompt/reference/construct_prompt_text.md),
[`get_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/get_chat_history.md),
[`is_tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/is_tidyprompt.md),
[`set_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/set_chat_history.md),
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md),
[`tidyprompt-class`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)

## Examples

``` r
prompt <- tidyprompt("Hi!")
print(prompt)
#> <tidyprompt>
#> The base prompt is not modified by prompt wraps:
#> > Hi! 
#> Use 'x$base_prompt' to show the base prompt text.
#> Use 'x$construct_prompt_text()' to get the full prompt text.
#> 

# Add to a tidyprompt using a prompt wrap:
prompt <- tidyprompt("Hi!") |>
  add_text("How are you?")
print(prompt)
#> <tidyprompt>
#> The base prompt is modified by a prompt wrap, resulting in:
#> > Hi!
#> > 
#> > How are you? 
#> Use 'x$base_prompt' to show the base prompt text.
#> Use 'x$construct_prompt_text()' to get the full prompt text.
#> Use 'get_prompt_wraps(x)' to show the prompt wraps.
#> 

# Strings can be input for prompt wraps; therefore,
#   a call to tidyprompt() is not necessary:
prompt <- "Hi" |>
  add_text("How are you?")

# Example of adding extraction & validation with a prompt_wrap():
prompt <- "Hi" |>
  add_text("What is 5 + 5?") |>
  answer_as_integer()

if (FALSE) { # \dontrun{
  # tidyprompt objects are evaluated by send_prompt(), which will
  #   handle construct the prompt text, send it to the LLM provider,
  #   and apply the extraction and validation functions from the tidyprompt object
  prompt |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   Hi
  #
  #   What is 5 + 5?
  #
  #   You must answer with only an integer (use no other characters).
  # --- Receiving response from LLM provider: ---
  #   10
  # [1] 10

  # See prompt_wrap() and send_prompt() for more details
} # }

# `tidyprompt` objects may be validated with these helpers:
is_tidyprompt(prompt) # Returns TRUE if input is a valid tidyprompt object
#> [1] TRUE

# Get base prompt text
base_prompt <- prompt$base_prompt

# Get all prompt wraps
prompt_wraps <- prompt$get_prompt_wraps()
# Alternative:
prompt_wraps <- get_prompt_wraps(prompt)

# Construct prompt text
prompt_text <- prompt$construct_prompt_text()
# Alternative:
prompt_text <- construct_prompt_text(prompt)

# Set chat history (affecting also the base prompt)
chat_history <- data.frame(
  role = c("user", "assistant", "user"),
  content = c("What is 5 + 5?", "10", "And what is 5 + 6?")
)
prompt$set_chat_history(chat_history)

# Get chat history
chat_history <- prompt$get_chat_history()
```
