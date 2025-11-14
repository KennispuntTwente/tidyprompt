# Create a new XAI (Grok) LLM provider

This function creates a new
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
object that interacts with the XAI API.

## Usage

``` r
llm_provider_xai(
  parameters = list(model = "grok-beta", stream = getOption("tidyprompt.stream", TRUE)),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://api.x.ai/v1/chat/completions",
  api_key = Sys.getenv("XAI_API_KEY")
)
```

## Arguments

- parameters:

  A named list of parameters. Currently the following parameters are
  required:

  - model: The name of the model to use

  - stream: A logical indicating whether the API should stream responses

  Additional parameters are appended to the request body; see the XAI
  API documentation for more information:
  https://docs.x.ai/api/endpoints#chat-completions

- verbose:

  A logical indicating whether the interaction with the LLM provider
  should be printed to the console. Default is TRUE.

- url:

  The URL to the XAI API endpoint for chat completion

- api_key:

  The API key to use for authentication with the XAI API

## Value

A new
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
object for use of the XAI API

## See also

Other llm_provider:
[`llm_provider-class`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md),
[`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md),
[`llm_provider_google_gemini()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_google_gemini.md),
[`llm_provider_groq()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_groq.md),
[`llm_provider_mistral()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_mistral.md),
[`llm_provider_ollama()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ollama.md),
[`llm_provider_openai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openai.md),
[`llm_provider_openrouter()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openrouter.md)

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
