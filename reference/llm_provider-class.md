# LlmProvider R6 Class

This class provides a structure for creating llm_provider objects with
different implementations of `$complete_chat()`. Using this class, you
can create an llm_provider object that interacts with different LLM
providers, such Ollama, OpenAI, or other custom providers.

## See also

Other llm_provider:
[`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md),
[`llm_provider_google_gemini()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_google_gemini.md),
[`llm_provider_groq()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_groq.md),
[`llm_provider_mistral()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_mistral.md),
[`llm_provider_ollama()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ollama.md),
[`llm_provider_openai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openai.md),
[`llm_provider_openrouter()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openrouter.md),
[`llm_provider_xai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_xai.md)

## Public fields

- `parameters`:

  A named list of parameters to configure the llm_provider. Parameters
  may be appended to the request body when interacting with the LLM
  provider API

- `verbose`:

  A logical indicating whether interaction with the LLM provider should
  be printed to the console

- `url`:

  The URL to the LLM provider API endpoint for chat completion

- `api_key`:

  The API key to use for authentication with the LLM provider API

- `api_type`:

  The type of API to use (e.g., "openai", "ollama", "ellmer"). This is
  used to determine certain specific behaviors for different APIs, for
  instance, as is done in the
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  function

- `json_type`:

  The type of JSON mode to use (e.g., 'auto', 'openai', 'ollama',
  'ellmer', or 'text-based'). Using 'auto' or having this field not set,
  the api_type field will be used to determine the JSON mode during the
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  function. If this field is set, this will override the api_type field
  for JSON mode determination. (Note: this determination only happens
  when the 'type' argument in
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  is also set to 'auto'.)

- `tool_type`:

  The type of tool use mode to use (e.g., 'auto', 'openai', 'ollama',
  'ellmer', or 'text-based'). Using 'auto' or having this field not set,
  the api_type field will be used to determine the tool use mode during
  the
  [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
  function. If this field is set, this will override the api_type field
  for tool use mode determination (Note: this determination only happens
  when the 'type' argument in
  [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
  is also set to 'auto'.)

- `handler_fns`:

  A list of functions that will be called after the completion of a
  chat. See `$add_handler_fn()`

- `stream_callback`:

  Optional callback function for streaming tokens/chunks. If set, this
  function will be called with arguments `(chunk, meta)` where `chunk`
  is the latest streamed text chunk and `meta` is a list with fields
  including `llm_provider`, `chat_history`, and `partial_response` to
  provide more context about the current prompt that is being replied
  to. You may use this to implement custom streaming behaviour; see
  `vignette(`"streaming_shiny_ipc", "tidyprompt")\` for an example of
  how this function is used to stream a non-blocking async LLM response
  to a Shiny app using the 'ipc' package.

- `pre_prompt_wraps`:

  A list of prompt wraps that will be applied to any prompt evaluated by
  this llm_provider object, before any prompt-specific prompt wraps are
  applied. See `$add_prompt_wrap()`. This can be used to set default
  behavior for all prompts evaluated by this llm_provider object.

- `post_prompt_wraps`:

  A list of prompt wraps that will be applied to any prompt evaluated by
  this llm_provider object, after any prompt-specific prompt wraps are
  applied. See `$add_prompt_wrap()`. This can be used to set default
  behavior for all prompts evaluated by this llm_provider object.

## Methods

### Public methods

- [`llm_provider-class$new()`](#method-LlmProvider-new)

- [`llm_provider-class$set_parameters()`](#method-LlmProvider-set_parameters)

- [`llm_provider-class$complete_chat()`](#method-LlmProvider-complete_chat)

- [`llm_provider-class$add_handler_fn()`](#method-LlmProvider-add_handler_fn)

- [`llm_provider-class$set_handler_fns()`](#method-LlmProvider-set_handler_fns)

- [`llm_provider-class$add_prompt_wrap()`](#method-LlmProvider-add_prompt_wrap)

- [`llm_provider-class$apply_prompt_wraps()`](#method-LlmProvider-apply_prompt_wraps)

- [`llm_provider-class$clone()`](#method-LlmProvider-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new llm_provider object

#### Usage

    llm_provider-class$new(
      complete_chat_function,
      parameters = list(),
      verbose = TRUE,
      url = NULL,
      api_key = NULL,
      api_type = "unspecified"
    )

#### Arguments

- `complete_chat_function`:

  Function that will be called by the llm_provider to complete a chat.
  This function should take a list containing at least '\$chat_history'
  (a data frame with 'role' and 'content' columns) and return a response
  object, which contains:

  - 'completed': A dataframe with 'role' and 'content' columns,
    containing the completed chat history

  - 'http': A list containing a list 'requests' and a list 'responses',
    containing the HTTP requests and responses made during the chat
    completion

- `parameters`:

  A named list of parameters to configure the llm_provider. These
  parameters may be appended to the request body when interacting with
  the LLM provider. For example, the `model` parameter may often be
  required. The 'stream' parameter may be used to indicate that the API
  should stream. Parameters should not include the chat_history, or
  'api_key' or 'url', which are handled separately by the llm_provider
  and '\$complete_chat()'. Parameters should also not be set when they
  are handled by prompt wraps

- `verbose`:

  A logical indicating whether interaction with the LLM provider should
  be printed to the console

- `url`:

  The URL to the LLM provider API endpoint for chat completion
  (typically required, but may be left NULL in some cases, for instance
  when creating a fake LLM provider)

- `api_key`:

  The API key to use for authentication with the LLM provider API
  (optional, not required for, for instance, Ollama)

- `api_type`:

  The type of API to use (e.g., "openai", "ollama"). This is used to
  determine certain specific behaviors for different APIs (see for
  example the
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  function)

#### Returns

A new llm_provider R6 object

------------------------------------------------------------------------

### Method `set_parameters()`

Helper function to set the parameters of the llm_provider object. This
function appends new parameters to the existing parameters list.

#### Usage

    llm_provider-class$set_parameters(new_parameters)

#### Arguments

- `new_parameters`:

  A named list of new parameters to append to the existing parameters
  list

#### Returns

The modified llm_provider object

------------------------------------------------------------------------

### Method `complete_chat()`

Sends a chat history (see
[`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md)
for details) to the LLM provider using the configured
`$complete_chat()`. This function is typically called by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
to interact with the LLM provider, but it can also be called directly.

#### Usage

    llm_provider-class$complete_chat(input)

#### Arguments

- `input`:

  A string, a data frame which is a valid chat history (see
  [`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md)),
  or a list containing a valid chat history under key '\$chat_history'

#### Returns

The response from the LLM provider

------------------------------------------------------------------------

### Method `add_handler_fn()`

Helper function to add a handler function to the llm_provider object.
Handler functions are called after the completion of a chat and can be
used to modify the response before it is returned by the llm_provider.
Each handler function should take the response object as input (first
argument) as well as 'self' (the llm_provider object) and return a
modified response object. The functions will be called in the order they
are added to the list.

#### Usage

    llm_provider-class$add_handler_fn(handler_fn)

#### Arguments

- `handler_fn`:

  A function that takes the response object plus 'self' (the
  llm_provider object) as input and returns a modified response object

#### Details

If a handler function returns a list with a 'break' field set to `TRUE`,
the chat completion will be interrupted and the response will be
returned at that point. If a handler function returns a list with a
'done' field set to `FALSE`, the handler functions will continue to be
called in a loop until the 'done' field is not set to `FALSE`.

------------------------------------------------------------------------

### Method `set_handler_fns()`

Helper function to set the handler functions of the llm_provider object.
This function replaces the existing handler functions list with a new
list of handler functions. See `$add_handler_fn()` for more information

#### Usage

    llm_provider-class$set_handler_fns(handler_fns)

#### Arguments

- `handler_fns`:

  A list of handler functions to set

------------------------------------------------------------------------

### Method `add_prompt_wrap()`

Add a provider-level prompt wrap template to be applied to all prompts.

#### Usage

    llm_provider-class$add_prompt_wrap(prompt_wrap, position = c("pre", "post"))

#### Arguments

- `prompt_wrap`:

  A list created by
  [`provider_prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/provider_prompt_wrap.md)

- `position`:

  One of "pre" or "post" (applied before/after prompt-specific wraps)

------------------------------------------------------------------------

### Method `apply_prompt_wraps()`

Apply all provider-level wraps to a prompt (character or tidyprompt) and
return a tidyprompt with wraps attached. This is typically called inside
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
before evaluation of the prompt.

#### Usage

    llm_provider-class$apply_prompt_wraps(prompt)

#### Arguments

- `prompt`:

  A string, a chat history, a list containing a chat history under key
  '\$chat_history', or a
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    llm_provider-class$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Example creation of a llm_provider-class object:
llm_provider_openai <- function(
    parameters = list(
      model = "gpt-4o-mini",
      stream = getOption("tidyprompt.stream", TRUE)
    ),
    verbose = getOption("tidyprompt.verbose", TRUE),
    url = "https://api.openai.com/v1/chat/completions",
    api_key = Sys.getenv("OPENAI_API_KEY")
) {
  complete_chat <- function(chat_history) {
    headers <- c(
      "Content-Type" = "application/json",
      "Authorization" = paste("Bearer", self$api_key)
    )

    body <- list(
      messages = lapply(seq_len(nrow(chat_history)), function(i) {
        list(role = chat_history$role[i], content = chat_history$content[i])
      })
    )

    for (name in names(self$parameters))
      body[[name]] <- self$parameters[[name]]

    request <- httr2::request(self$url) |>
      httr2::req_body_json(body) |>
      httr2::req_headers(!!!headers)

    request_llm_provider(
      chat_history,
      request,
      stream = self$parameters$stream,
      verbose = self$verbose,
      api_type = self$api_type
    )
  }

  return(`llm_provider-class`$new(
    complete_chat_function = complete_chat,
    parameters = parameters,
    verbose = verbose,
    url = url,
    api_key = api_key,
    api_type = "openai"
  ))
}

llm_provider <- llm_provider_openai()

if (FALSE) { # \dontrun{
  llm_provider$complete_chat("Hi!")
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # Hi!
  # --- Receiving response from LLM provider: ---
  # Hello! How can I assist you today?
} # }
```
