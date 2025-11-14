# PersistentChat R6 class

A class for managing a persistent chat with a large language model
(LLM).

While 'tidyprompt' is primariy focused on automatic interactions with
LLMs through
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
using a
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
object with
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
this class may be useful for having a manual conversation with an LLM.
(It may specifically be used to continue a chat history which was
returned by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
with `return_mode = "full"`.)

## See also

[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
[`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md)

## Public fields

- `chat_history`:

  A
  [`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md)
  object

- `llm_provider`:

  A
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object

## Methods

### Public methods

- [`persistent_chat-class$new()`](#method-PersistentChat-new)

- [`persistent_chat-class$chat()`](#method-PersistentChat-chat)

- [`persistent_chat-class$reset_chat_history()`](#method-PersistentChat-reset_chat_history)

- [`persistent_chat-class$clone()`](#method-PersistentChat-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize the PersistentChat object

#### Usage

    persistent_chat-class$new(llm_provider, chat_history = NULL)

#### Arguments

- `llm_provider`:

  A
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object

- `chat_history`:

  (optional) A
  [`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md)
  object

#### Returns

The initialized PersistentChat object

------------------------------------------------------------------------

### Method `chat()`

Add a message to the chat history and get a response from the LLM

#### Usage

    persistent_chat-class$chat(msg, role = "user", verbose = TRUE)

#### Arguments

- `msg`:

  Message to add to the chat history

- `role`:

  Role of the message

- `verbose`:

  Whether to print the interaction to the console

#### Returns

The response from the LLM

------------------------------------------------------------------------

### Method `reset_chat_history()`

Reset the chat history

#### Usage

    persistent_chat-class$reset_chat_history()

#### Returns

NULL

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    persistent_chat-class$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Create a persistent chat with any LLM provider
chat <- `persistent_chat-class`$new(llm_provider_ollama())

if (FALSE) { # \dontrun{
  chat$chat("Hi! Tell me about Twente, in a short sentence?")
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # Hi! Tell me about Twente, in a short sentence?
  # --- Receiving response from LLM provider: ---
  # Twente is a charming region in the Netherlands known for its picturesque
  # countryside and vibrant culture!

  chat$chat("How many people live there?")
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # How many people live there?
  # --- Receiving response from LLM provider: ---
  # The population of Twente is approximately 650,000 inhabitants, making it one of
  # the largest regions in the Netherlands.

  # Access the chat history:
  chat$chat_history

  # Reset the chat history:
  chat$reset_chat_history()

  # Continue a chat from the result of `send_prompt()`:
  result <- "Hi there!" |>
    answer_as_integer() |>
    send_prompt(return_mode = "full")
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # Hi there!
  #
  # You must answer with only an integer (use no other characters).
  # --- Receiving response from LLM provider: ---
  # 42
  chat <- `persistent_chat-class`$new(llm_provider_ollama(), result$chat_history)
  chat$chat("Why did you choose that number?")
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # Why did you choose that number?
  # --- Receiving response from LLM provider: ---
  # I chose the number 42 because it's a reference to Douglas Adams' science fiction
  # series "The Hitchhiker's Guide to the Galaxy," in which a supercomputer named
  # Deep Thought is said to have calculated the "Answer to the Ultimate Question of
  # Life, the Universe, and Everything" as 42.
} # }
```
