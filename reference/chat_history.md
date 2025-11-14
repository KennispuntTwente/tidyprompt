# Create or validate `chat_history` object

This function creates and validates a `chat_history` object, ensuring
that it matches the expected format with 'role' and 'content' columns.
It has separate methods for `data.frame` and `character` inputs and
includes a helper function to add a system prompt to the chat history.

## Usage

``` r
chat_history(chat_history)
```

## Arguments

- chat_history:

  A single string, a `data.frame` with 'role' and 'content' columns, or
  NULL. If a `data.frame` is provided, it should contain 'role' and
  'content' columns, where 'role' is either 'user', 'assistant', or
  'system', and 'content' is a character string representing a chat
  message

## Value

A valid chat history `data.frame` (of class `chat_history`)

## Examples

``` r
chat <- "Hi there!" |>
  chat_history()
chat
#>   role   content tool_result
#> 1 user Hi there!       FALSE

chat_from_df <- data.frame(
  role = c("user", "assistant"),
  content = c("Hi there!", "Hello! How can I help you today?")
) |>
  chat_history()
chat_from_df
#>        role                          content tool_result
#> 1      user                        Hi there!       FALSE
#> 2 assistant Hello! How can I help you today?       FALSE

# `add_msg_to_chat_history()` may be used to add messages to a chat history
chat_from_df <- chat_from_df |>
  add_msg_to_chat_history("Calculate 2+2 for me, please!")
chat_from_df
#>        role                          content tool_result
#> 1      user                        Hi there!       FALSE
#> 2 assistant Hello! How can I help you today?       FALSE
#> 3      user    Calculate 2+2 for me, please!       FALSE

# You can also continue conversations which originate from `send_prompt()`:
if (FALSE) { # \dontrun{
  result <- "Hi there!" |>
    send_prompt(return_mode = "full")
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # Hi there!
  # --- Receiving response from LLM provider: ---
  # It's nice to meet you. Is there something I can help you with, or would you
  # like to chat?

  # Access the chat history from the result:
  chat_from_send_prompt <- result$chat_history

  # Add a message to the chat history:
  chat_history_with_new_message <- chat_from_send_prompt |>
    add_msg_to_chat_history("Let's chat!")

  # The new chat history can be input for a new tidyprompt:
  prompt <- tidyprompt(chat_history_with_new_message)

  # You can also take an existing tidyprompt and add the new chat history to it;
  #   this way, you can continue a conversation using the same prompt wraps
  prompt$set_chat_history(chat_history_with_new_message)

  # send_prompt() also accepts a chat history as input:
  new_result <- chat_history_with_new_message |>
    send_prompt(return_mode = "full")

  # You can also create a persistent chat history object from
  #   a chat history data frame; see ?`persistent_chat-class`
  chat <- `persistent_chat-class`$new(llm_provider_ollama(), chat_from_send_prompt)
  chat$chat("Let's chat!")
} # }
```
