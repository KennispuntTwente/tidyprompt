# Tidyprompt R6 Class

A tidyprompt object contains a base prompt and a list of
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
objects. It provides structured methods to modify the prompt while
simultaneously adding logic to extract from and validate the LLM
response. Besides a base prompt, a tidyprompt object may contain a
system prompt and a chat history which precede the base prompt.

## See also

Other tidyprompt:
[`construct_prompt_text()`](https://kennispunttwente.github.io/tidyprompt/reference/construct_prompt_text.md),
[`get_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/get_chat_history.md),
[`get_prompt_wraps()`](https://kennispunttwente.github.io/tidyprompt/reference/get_prompt_wraps.md),
[`is_tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/is_tidyprompt.md),
[`set_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/set_chat_history.md),
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)

## Public fields

- `base_prompt`:

  The base prompt string. The base prompt be modified by prompt wraps
  during
  [`construct_prompt_text()`](https://kennispunttwente.github.io/tidyprompt/reference/construct_prompt_text.md);
  the modified prompt text will be used as the final message of role
  'user' during
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

- `system_prompt`:

  A system prompt string. This will be added at the start of the chat
  history as role 'system' during
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

## Methods

### Public methods

- [`tidyprompt-class$new()`](#method-Tidyprompt-new)

- [`tidyprompt-class$is_valid()`](#method-Tidyprompt-is_valid)

- [`tidyprompt-class$add_prompt_wrap()`](#method-Tidyprompt-add_prompt_wrap)

- [`tidyprompt-class$get_prompt_wraps()`](#method-Tidyprompt-get_prompt_wraps)

- [`tidyprompt-class$construct_prompt_text()`](#method-Tidyprompt-construct_prompt_text)

- [`tidyprompt-class$set_chat_history()`](#method-Tidyprompt-set_chat_history)

- [`tidyprompt-class$get_chat_history()`](#method-Tidyprompt-get_chat_history)

- [`tidyprompt-class$clone()`](#method-Tidyprompt-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize a tidyprompt object

#### Usage

    tidyprompt-class$new(input)

#### Arguments

- `input`:

  A string, a chat history, a list containing a chat history under key
  '\$chat_history', or a tidyprompt object

#### Details

Different types of input are accepted for initialization of a tidyprompt
object:

- A single character string. This will be used as the base prompt

- A dataframe which is a valid chat history (see
  [`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md))

- A list containing a valid chat history under '\$chat_history' (e.g., a
  result from
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  when using 'return_mode' = "full")

- A tidyprompt object. This will be checked for validity and, if valid,
  the fields are copied to the object which is returned from this method

When passing a dataframe or list with a chat history, the last row of
the chat history must have role 'user'; this row will be used as the
base prompt. If the first row of the chat history has role 'system', it
will be used as the system prompt.

#### Returns

A tidyprompt object

------------------------------------------------------------------------

### Method `is_valid()`

Check if the tidyprompt object is valid.

#### Usage

    tidyprompt-class$is_valid()

#### Returns

`TRUE` if valid, otherwise `FALSE`

------------------------------------------------------------------------

### Method `add_prompt_wrap()`

Add a
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
to the tidyprompt object.

#### Usage

    tidyprompt-class$add_prompt_wrap(prompt_wrap)

#### Arguments

- `prompt_wrap`:

  A
  [`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
  object

#### Returns

The updated tidyprompt object

------------------------------------------------------------------------

### Method [`get_prompt_wraps()`](https://kennispunttwente.github.io/tidyprompt/reference/get_prompt_wraps.md)

Get list of
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
objects from the tidyprompt object.

#### Usage

    tidyprompt-class$get_prompt_wraps(
      order = c("default", "modification", "evaluation")
    )

#### Arguments

- `order`:

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

#### Returns

A list of
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
objects.

------------------------------------------------------------------------

### Method [`construct_prompt_text()`](https://kennispunttwente.github.io/tidyprompt/reference/construct_prompt_text.md)

Construct the complete prompt text.

#### Usage

    tidyprompt-class$construct_prompt_text(
      llm_provider = NULL,
      apply_provider_prompt_wraps = FALSE
    )

#### Arguments

- `llm_provider`:

  Optional
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object. This may sometimes affect the prompt text construction

- `apply_provider_prompt_wraps`:

  Logical. Whether to apply provider-specific pre/post prompt wraps when
  constructing the prompt text

#### Returns

A string representing the constructed prompt text

------------------------------------------------------------------------

### Method [`set_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/set_chat_history.md)

This function sets the chat history for the tidyprompt object. The chat
history will also set the base prompt and system prompt (the last
message of the chat history should be of role 'user' and will be used as
the base prompt; the first message of the chat history may be of the
role 'system' and will then be used as the system prompt). This may be
useful when one wants to change the base prompt, system prompt, and chat
history of a tidyprompt object while retaining other fields like the
prompt wraps.

#### Usage

    tidyprompt-class$set_chat_history(chat_history)

#### Arguments

- `chat_history`:

  A valid chat history (see
  [`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md))

#### Returns

The updated tidyprompt object

------------------------------------------------------------------------

### Method [`get_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/get_chat_history.md)

This function gets the chat history of the tidyprompt object. The chat
history is constructed from the base prompt, system prompt, and chat
history field. The returned object will be the chat history with the
system prompt as the first message with role 'system' and the the base
prompt as the last message with role 'user'.

#### Usage

    tidyprompt-class$get_chat_history(llm_provider = NULL)

#### Arguments

- `llm_provider`:

  An optional
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object. This may sometimes affect the prompt text construction

#### Returns

A dataframe containing the chat history

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    tidyprompt-class$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

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
