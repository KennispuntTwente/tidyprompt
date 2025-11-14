# Create a new LLM provider from an `ellmer::chat()` object

**\[experimental\]**

This function creates a
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
from an
[`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
object. This allows the user to use the various LLM providers which are
supported by the 'ellmer' R package, including respective configuration
and features.

Please note that this function is experimental. This provider type may
show different behavior than other LLM providers, and may not function
optimally.

## Usage

``` r
llm_provider_ellmer(
  chat,
  parameters = list(stream = getOption("tidyprompt.stream", TRUE)),
  verbose = getOption("tidyprompt.verbose", TRUE)
)
```

## Arguments

- chat:

  An
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
  object (e.g.,
  [`ellmer::chat_openai()`](https://ellmer.tidyverse.org/reference/chat_openai.html))

- parameters:

  A named list of parameters. See 'details' for supported parameters

- verbose:

  A logical indicating whether the interaction with the
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  should be printed to the console. Default is TRUE

## Value

An
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
with api_type = "ellmer"

## Details

Unlike other LLM provider classes, most LLM provider settings need to be
managed in the
[`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
object (and not in the `$parameters` list). `$get_chat()` and
`$set_chat()` may be used to manipulate the chat object. There are
however some parameters that can be set in the `$parameters` list; these
are documented below.

1.  Streaming can be controlled through via the `$parameters$stream`
    parameter. If set to TRUE (default), streaming will be used if
    supported by the underlying
    [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
    object. If the underlying
    [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
    object does not support streaming, you may need to set this
    parameter to FALSE to avoid errors.

2.  A special parameter `$.ellmer_structured_type` may also be set in
    the `$parameters` list; this parameter is used to specify a
    structured output format. This should be a 'ellmer' structured type
    (e.g.,
    [`ellmer::type_object`](https://ellmer.tidyverse.org/reference/type_boolean.html);
    see https://ellmer.tidyverse.org/articles/structured-data.html).
    [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
    sets this parameter to obtain structured output (it is not
    recommended to set this parameter manually, but it is possible).

## See also

Other llm_provider:
[`llm_provider-class`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md),
[`llm_provider_google_gemini()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_google_gemini.md),
[`llm_provider_groq()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_groq.md),
[`llm_provider_mistral()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_mistral.md),
[`llm_provider_ollama()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ollama.md),
[`llm_provider_openai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openai.md),
[`llm_provider_openrouter()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openrouter.md),
[`llm_provider_xai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_xai.md)

## Examples

``` r
# Various providers:
ollama <- llm_provider_ollama()
openai <- llm_provider_openai()
openrouter <- llm_provider_openrouter()
mistral <- llm_provider_mistral()
groq <- llm_provider_groq()
xai <- llm_provider_xai()
gemini <- llm_provider_google_gemini()

# From an `ellmer::chat()` (e.g., `ellmer::chat_openai()`, ...):
if (FALSE) { # \dontrun{
ellmer <- llm_provider_ellmer(ellmer::chat_openai())
} # }

# Initialize with settings:
ollama <- llm_provider_ollama(
  parameters = list(
    model = "llama3.2:3b",
    stream = TRUE
  ),
  verbose = TRUE,
  url = "http://localhost:11434/api/chat"
)

# Change settings:
ollama$verbose <- FALSE
ollama$parameters$stream <- FALSE
ollama$parameters$model <- "llama3.1:8b"

if (FALSE) { # \dontrun{
# Try a simple chat message with '$complete_chat()':
response <- ollama$complete_chat("Hi!")
response
# $role
# [1] "assistant"
#
# $content
# [1] "How's it going? Is there something I can help you with or would you like
# to chat?"
#
# $http
# Response [http://localhost:11434/api/chat]
# Date: 2024-11-18 14:21
# Status: 200
# Content-Type: application/json; charset=utf-8
# Size: 375 B

# Use with send_prompt():
"Hi" |>
  send_prompt(ollama)
# [1] "How's your day going so far? Is there something I can help you with or
# would you like to chat?"
} # }
```
