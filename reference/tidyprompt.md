# Create a [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md) object

This is a wrapper around the
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
constructor.

## Usage

``` r
tidyprompt(input)
```

## Arguments

- input:

  A string, a chat history, a list containing a chat history under key
  '\$chat_history', or a
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object

## Value

A
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
object

## Details

Different types of input are accepted for initialization of a
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
object:

- A single character string. This will be used as the base prompt

- A dataframe which is a valid chat history (see
  [`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md))

- A list containing a valid chat history under '\$chat_history' (e.g., a
  result from
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  when using 'return_mode' = "full")

- A
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object. This will be checked for validity and, if valid, the fields
  are copied to the object which is returned from this method

When passing a dataframe or list with a chat history, the last row of
the chat history must have role 'user'; this row will be used as the
base prompt. If the first row of the chat history has role 'system', it
will be used as the system prompt.

## See also

Other tidyprompt:
[`construct_prompt_text()`](https://kennispunttwente.github.io/tidyprompt/reference/construct_prompt_text.md),
[`get_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/get_chat_history.md),
[`get_prompt_wraps()`](https://kennispunttwente.github.io/tidyprompt/reference/get_prompt_wraps.md),
[`is_tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/is_tidyprompt.md),
[`set_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/set_chat_history.md),
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
