# Create a new Google Gemini LLM provider

**\[superseded\]** This function creates a new
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
object that interacts with the Google Gemini API.

## Usage

``` r
llm_provider_google_gemini(
  parameters = list(model = "gemini-1.5-flash"),
  verbose = getOption("tidyprompt.verbose", TRUE),
  url = "https://generativelanguage.googleapis.com/v1beta/models/",
  api_key = Sys.getenv("GOOGLE_AI_STUDIO_API_KEY")
)
```

## Arguments

- parameters:

  A named list of parameters. Currently the following parameters are
  required:

  - model: The name of the model to use (see:
    https://ai.google.dev/gemini-api/docs/models/gemini)

  Additional parameters are appended to the request body; see the Google
  AI Studio API documentation for more information:
  https://ai.google.dev/gemini-api/docs/text-generation and
  https://github.com/google/generative-ai-docs/blob/main/site/en/gemini-api/docs/get-started/rest.ipynb

- verbose:

  A logical indicating whether the interaction with the LLM provider
  should be printed to the console

- url:

  The URL to the Google Gemini API endpoint for chat completion

- api_key:

  The API key to use for authentication with the Google Gemini API (see:
  https://aistudio.google.com/app/apikey)

## Value

A new
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
object for use of the Google Gemini API

## Details

Streaming is not yet supported in this implementation. Native functions
like structured output and tool calling are also not supported in this
implemetation. This may however be achieved through creating a
[`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
object with as input a
[`ellmer::chat_google_gemini()`](https://ellmer.tidyverse.org/reference/chat_google_gemini.html)
object. Therefore, this function is now superseded by
`llm_provider_ellmer(ellmer::chat_google_gemini())`.

## See also

Other llm_provider:
[`llm_provider-class`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md),
[`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md),
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
