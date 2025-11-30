# Changelog

## tidyprompt 0.3.0

CRAN release: 2025-11-30

- `llm_provider-class`: can now take a `stream_callback` function, which
  can be used to intercept streamed tokens as they arrive from the LLM
  provider. This may be used to build custom streaming behavior, for
  instance to show a live response in a Shiny app (see new
  [`vignette("streaming_shiny_ipc")`](https://kennispunttwente.github.io/tidyprompt/articles/streaming_shiny_ipc.md)
  for an example)

- ’llm_provider_ellmer()\`: now supports streaming responses

- [`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md):
  new prompt wrap to add an image to a prompt, for use with multimodal
  LLMs

- [`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md):
  fixed error with unsafe conversion of resulting object to character

## tidyprompt 0.2.0

CRAN release: 2025-08-25

- Add provider-level prompt wraps
  ([`provider_prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/provider_prompt_wrap.md))
  these are prompt wraps which can be attached to a LLM provider object.
  They can be applied to any prompt which is sent through this LLM
  provider, either before or after prompt-specific prompt wraps. This is
  useful when you want to achieve certain behavior for various prompts,
  without having to re-apply the same prompt wrap to each prompt

- [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md):
  support ‘ellmer’ definitions of structured output (e.g.,
  [`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html)).
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  can convert between ellmer definitions and the previous R list objects
  which represent JSON schemas; thus, ‘ellmer’ and R list object
  definitions work with both regular and ‘ellmer’ LLM providers. When
  using an
  [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md),
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  will ensure the native ‘ellmer’ functions for obtaining structured
  output are used

- [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md):
  support ‘ellmer’ definitions of tools (from
  [`ellmer::tool()`](https://ellmer.tidyverse.org/reference/tool.html)).
  [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
  can convert between ‘ellmer’ tool definitions and the previous R
  function objects with documentation from
  [`tools_add_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_add_docs.md);
  thus, ‘ellmer’ and
  [`tools_add_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_add_docs.md)
  definitions work with both regular and ‘ellmer’ LLM providers. When
  using an
  [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md),
  [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
  will ensure the native ‘ellmer’ functions for registering tools are
  used.

- [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md):
  because of the above, and the fact that package ‘mcptools’ returns
  ‘ellmer’ tool definitions with
  [`mcptools::mcp_tools()`](https://posit-dev.github.io/mcptools/reference/client.html),
  [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
  can now also be used with tools from Model Context Protocol (MCP)
  servers

- [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  can now return an updated ‘ellmer’ chat object when using an
  [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
  (containing for instance the history of ‘ellmer’ turns and tool
  calls). Additionally fixed issues with how turn history is handled in
  ‘ellmer’ chat objects

- [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)’s
  `clean_chat_history` argument is now defaulted to `FALSE`, as it may
  be confusing for users to see cleaned chat histories without having
  actively requested this. If `return_mode = "full"`,
  `$clean_chat_history` is also no longer included when
  `clean_chat_history = FALSE`

- [`llm_provider_openai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openai.md)
  now supports (as default) the OpenAI responses API, which allows
  setting parameters like ‘reasoning_effort’ and ‘verbosity’ (relevant
  for gpt-5). The OpenAI chat completions API is also still supported

- [`llm_provider_google_gemini()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_google_gemini.md)
  has been superseded by
  `llm_provider_ellmer(ellmer::chat_google_gemini())`

- Add a `json_type` & `tool_type` field to LLM provider objects; when
  automatically determining the route towards structured output (in
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md))
  and tool use (in
  [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)),
  this can override the type decided by the `api_type` field (e.g., user
  can use this field to force the text-based type, for instance when
  using an OpenAI type LLM provider but with a model which does not
  support the typical OpenAI API parameters for structured output)

- Update how responses are streamed (with
  [`httr2::req_perform_connection()`](https://httr2.r-lib.org/reference/req_perform_connection.html),
  since
  [`httr2::req_perform_stream()`](https://httr2.r-lib.org/reference/req_perform_stream.html)
  is being deprecated)

- Fix bug where the LLM provider object was not properly passed on to
  `modify_fn` in
  [`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
  which could lead to errors when dynamically constructing prompt text
  based on the LLM provider type

## tidyprompt 0.1.0

CRAN release: 2025-08-18

- New prompt wraps
  [`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md)
  and
  [`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md)

- New
  [`llm_break_soft()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break_soft.md)
  interrupts prompt evaluation without error

- New experimental provider
  [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
  for `ellmer` chat objects

- Ollama provider gains `num_ctx` parameter to control context window
  size

- `set_option()` and `set_options()` are now available for the Ollama
  provider to configure options

- Error messages are more informative when an LLM provider cannot be
  reached

- Google Gemini provider now works without errors in affected cases

- Chat history handling is safer; rows with `NA` values no longer cause
  errors in specific cases

- Final-answer extraction in chain-of-thought prompts is more flexible

- Printed LLM responses now use
  [`message()`](https://rdrr.io/r/base/message.html) instead of
  [`cat()`](https://rdrr.io/r/base/cat.html)

- Moved repository to <https://github.com/KennispuntTwente/tidyprompt>

## tidyprompt 0.0.1

CRAN release: 2025-01-08

- Initial CRAN release

## tidyprompt 0.0.0.9000

- Initial development version available on GitHub
