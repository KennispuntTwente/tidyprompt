# Send a prompt to a LLM provider

This function is responsible for sending prompts to a LLM provider for
evaluation. The function will interact with the LLM provider until a
successful response is received or the maximum number of interactions is
reached. The function will apply extraction and validation functions to
the LLM response, as specified in the prompt wraps (see
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)).
If the maximum number of interactions

## Usage

``` r
send_prompt(
  prompt,
  llm_provider = llm_provider_ollama(),
  max_interactions = 10,
  clean_chat_history = FALSE,
  verbose = NULL,
  stream = NULL,
  return_mode = c("only_response", "full")
)
```

## Arguments

- prompt:

  A string or a
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object

- llm_provider:

  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object (default is
  [`llm_provider_ollama()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ollama.md)).
  This object and its settings will be used to evaluate the prompt. Note
  that the 'verbose' and 'stream' settings in the LLM provider will be
  overruled by the 'verbose' and 'stream' arguments in this function
  when those are not NULL. Furthermore, advanced
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  objects may carry '\$parameter_fn' functions which can set parameters
  in the llm_provider object (see
  [`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
  and
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  for more ).

- max_interactions:

  Maximum number of interactions allowed with the LLM provider. Default
  is 10. If the maximum number of interactions is reached without a
  successful response, 'NULL' is returned as the response (see return
  value). The first interaction is the initial chat completion

- clean_chat_history:

  If the chat history should be cleaned after each interaction. Cleaning
  the chat history means that only the first and last message from the
  user, the last message from the assistant, all messages from the
  system, and all tool results are kept in a 'clean' chat history. This
  clean chat history is used when requesting a new chat completion.
  (i.e., if a LLM repeatedly fails to provide a correct response, only
  its last failed response will included in the context window). This
  may increase the LLM performance on the next interaction

- verbose:

  If the interaction with the LLM provider should be printed to the
  console. This will overrule the 'verbose' setting in the LLM provider

- stream:

  If the interaction with the LLM provider should be streamed. This
  setting will only be used if the LLM provider already has a 'stream'
  parameter (which indicates there is support for streaming). Note that
  when 'verbose' is set to FALSE, the 'stream' setting will be ignored

- return_mode:

  One of 'full' or 'only_response'. See return value

## Value

- If return mode 'only_response', the function will return only the LLM
  response after extraction and validation functions have been applied
  (NULL is returned when unsuccessful after the maximum number of
  interactions).

- If return mode 'full', the function will return a list with the
  following elements:

  - 'response' (the LLM response after extraction and validation
    functions have been applied; NULL is returned when unsuccessful
    after the maximum number of interactions),

  - 'interactions' (the number of interactions with the LLM provider),

  - 'chat_history' (a dataframe with the full chat history which led to
    the final response),

  - 'chat_history_clean' (a dataframe with the cleaned chat history
    which led to the final response; here, only the first and last
    message from the user, the last message from the assistant, and all
    messages from the system are kept),

  - 'start_time' (the time when the function was called),

  - 'end_time' (the time when the function ended),

  - 'duration_seconds' (the duration of the function in seconds),

  - 'http_list' (a list with all HTTP responses made during the
    interactions; as returned by `llm_provider$complete_chat()`),

  - 'ellmer_chat' (if
    [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
    was used, this will be the updated 'ellmer' chat object, containing
    for instance the turns and possible tool calls. (As this function
    uses a clone of the provided LLM provider, the 'ellmer' chat object
    in the LLM provider will not be updated; via this way, you can then
    still get an updated 'ellmer' chat object. Note that turns in the
    'ellmer' chat object may not contain the full chat history when
    `clean_chat_history = TRUE` was used.)

## See also

[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md),
[`llm_provider_ollama()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ollama.md),
[`llm_provider_openai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openai.md)

Other prompt_evaluation:
[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md),
[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  "Hi!" |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   Hi!
  # --- Receiving response from LLM provider: ---
  #   It's nice to meet you. Is there something I can help you with, or would you like to chat?
  # [1] "It's nice to meet you. Is there something I can help you with, or would you like to chat?"

  "Hi!" |>
    send_prompt(llm_provider_ollama(), return_mode = "full")
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   Hi!
  # --- Receiving response from LLM provider: ---
  #   It's nice to meet you. Is there something I can help you with, or would you like to chat?
  # $response
  # [1] "It's nice to meet you. Is there something I can help you with, or would you like to chat?"
  #
  # $chat_history
  # ...
  #
  # $chat_history_clean
  # ...
  #
  # $start_time
  # [1] "2024-11-18 15:43:12 CET"
  #
  # $end_time
  # [1] "2024-11-18 15:43:13 CET"
  #
  # $duration_seconds
  # [1] 1.13276
  #
  # $http_list
  # $http_list[[1]]
  # Response [http://localhost:11434/api/chat]
  #   Date: 2024-11-18 14:43
  #   Status: 200
  #   Content-Type: application/x-ndjson
  # <EMPTY BODY>

  "Hi!" |>
    add_text("What is 5 + 5?") |>
    answer_as_integer() |>
    send_prompt(llm_provider_ollama(), verbose = FALSE)
  # [1] 10
} # }
```
