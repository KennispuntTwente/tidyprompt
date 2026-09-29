# tidyprompt (development version)

* Cross-provider schemas preserve singleton `required` and `enum` arrays during
  HTTP serialization instead of unboxing them into invalid scalar keywords.

* Native schema validation preserves empty objects and ellmer's absent optional
  fields instead of incorrectly treating them as arrays or explicit nulls.

* The ellmer interoperability vignette now documents supported capabilities,
  a tools-then-extraction workflow, and async/batch boundaries.

* `limit_ellmer_requests()` bounds native model requests across internal tool
  loops, structured extraction and tidyprompt feedback rounds.

* Ellmer streams can expose rich content events and accept a stream controller.
  Cancellation and iteration errors retain recoverable partial chat state.

* Native structured output can now stream with ellmer 0.5.0, retaining native R
  coercion and falling back for providers that require tool-based extraction.

* `add_content()` attaches native ellmer content, including documents and file
  references, to prompts and preserves it across feedback turns.

* CI now pins ellmer 0.5.0 alongside the minimum version and checks ellmer
  regressions with lifecycle deprecations treated as errors.

* Schema conversion no longer calls ellmer's deprecated `.additional_properties`
  argument. Open-object schemas are preserved using `type_from_schema()`.

* Ellmer chats now deep-clone callback registries for each evaluation. The new
  interoperability vignette explains how to bind hooks to the working chat.

* Tool results now serialize lists and data frames as JSON, preserving nested
  data and satisfying ellmer's result contract. Native content results are retained.

* Ellmer tools retain nested argument schemas and input conversion semantics
when used with other providers. Context-aware tools explicitly require the
native ellmer path, and direct converted-tool calls evaluate R arguments normally.

* Zero-argument R tools register correctly with ellmer. Failed native tool
conversions now identify the tool and preserve the original error.

* Renaming ellmer tools preserves ignored arguments, conversion settings and
annotations without reconstructing their definitions.

* Rich JSON schemas retain their constraints through ellmer conversion.
Native structured results are validated without changing their R classes;
unsupported schemas no longer silently lose enforcement.

* History compacted by ellmer request callbacks is now reflected in returned
transcripts and subsequent requests instead of restoring removed messages.

* Ellmer follow-up requests preserve complete native turns, including tool
request/result pairs, reasoning blocks, usage metadata and partial-turn classes.
Native protocol content is retained when cleaning an ellmer conversation.

* Ellmer history indexing now handles both tidyprompt system rows and system
prompts configured on the native chat without assigning assistant content to
user messages.

* Ellmer replies now use the complete final assistant text rather than the
last transcript row. Citations no longer replace the answer and are available
in `$citations` when `return_mode = "full"`.

* Built-in OpenAI-compatible and Ollama request failures now signal
`tidyprompt_request_error` with the original condition in `parent`, plus
`status_code` and `request_id` fields when available. This preserves HTTP
diagnostics through `send_prompt()` for both streaming connection setup and
non-streaming requests. Error messages include a provider's explicit error
message instead of appending the entire JSON response body.

* Fixed a connection leak in streaming requests: `req_llm_stream()` (used
internally when `stream = TRUE`) now closes the underlying `httr2`
streaming connection once a response has been read. Previously, the
connection was never closed, so each streamed LLM call permanently used up
one of R's limited (128) connection slots; after enough streamed calls,
this would cause unrelated code (e.g. `textConnection()`/`capture.output()`)
to fail with "all connections are in use".

# tidyprompt 0.4.0

* New prompt wrap `answer_as_dataframe()` for extracting tabular results via
structured output, with support for row schemas, array-of-row schemas,
and optional row-count validation.

* New prompt wrap `answer_as_numeric()` for extracting numeric responses,
including optional minimum and maximum value validation.

* `send_prompt()` can now directly use an 'ellmer' chat object as
the `llm_provider` to evaluate the prompt with (will build 
an `llm_provider_ellmer()` under the hood)

* `llm_provider_ellmer()` was improved to better synchronize with 
the native 'ellmer' state, for instance for streaming, multimodal/image
content, and persistent chats, with clearer warnings when settings need to
be configured on the underlying `ellmer` chat object.

* `answer_as_json()` and `answer_using_tools()` have broader ellmer
compatibility, including `ellmer::type_from_schema()`, ellmer built-in tools,
and better handling of optional or ignored tool arguments.

* Chat history handling is more robust for tool and ellmer-native workflows:
`tool` rows are supported, non-replayable native rows (tool call and thinking rows)
are kept for inspection but not re-sent to the LLM provider, and related
metadata is normalized more reliably.

* Update e-mail address of maintainer in DESCRIPTION file 
(change to a personal e-mail address due to leaving the organization).

# tidyprompt 0.3.0

* `llm_provider-class`: can now take a `stream_callback` function, which
can be used to intercept streamed tokens as they arrive from the LLM provider.
This may be used to build custom streaming behavior, for instance to show a live
response in a Shiny app (see new `vignette("streaming_shiny_ipc")` for an example)

* 'llm_provider_ellmer()`: now supports streaming responses

* `add_image()`: new prompt wrap to add an image to a prompt, for use
with multimodal LLMs

* `answer_using_r()`: fixed error with unsafe conversion of resulting object
to character

# tidyprompt 0.2.0

* Add provider-level prompt wraps (`provider_prompt_wrap()`) these are prompt
wraps which can be attached to a LLM provider object. They can be applied to
any prompt which is sent through this LLM provider, either before or after
prompt-specific prompt wraps. This is useful when you want to achieve 
certain behavior for various prompts, without having to re-apply the same
prompt wrap to each prompt

* `answer_as_json()`: support 'ellmer' definitions of structured output
(e.g., `ellmer::type_object()`). `answer_as_json()` can convert between ellmer
definitions and the previous R list objects which represent JSON schemas; thus,
'ellmer' and R list object definitions work with both regular and 'ellmer'
LLM providers. When using an `llm_provider_ellmer()`, `answer_as_json()` will 
ensure the native 'ellmer' functions for obtaining structured output are used

* `answer_using_tools()`: support 'ellmer' definitions of tools (from 
`ellmer::tool()`). `answer_using_tools()` can convert between 'ellmer' tool
definitions and the previous R function objects with documentation from 
`tools_add_docs()`; thus, 'ellmer' and `tools_add_docs()` definitions work
with both regular and 'ellmer' LLM providers. When using an 
`llm_provider_ellmer()`, `answer_using_tools()` will ensure the native 'ellmer'
functions for registering tools are used. 

* `answer_using_tools()`: because of the above, and the fact that 
package 'mcptools' returns 'ellmer' tool definitions with 
`mcptools::mcp_tools()`, `answer_using_tools()`
can now also be used with tools from Model Context Protocol (MCP) servers

* `send_prompt()` can now return an updated 'ellmer' chat object when using an
`llm_provider_ellmer()` (containing for instance the history of 'ellmer' turns 
and tool calls). Additionally fixed issues with how turn history is handled
in 'ellmer' chat objects

* `send_prompt()`'s `clean_chat_history` argument is now defaulted to `FALSE`,
as it may be confusing for users to see cleaned chat histories without
having actively requested this. If `return_mode = "full"`, `$clean_chat_history`
is also no longer included when `clean_chat_history = FALSE`

* `llm_provider_openai()` now supports (as default) the OpenAI responses API,
which allows setting parameters like 'reasoning_effort' and 'verbosity' 
(relevant for gpt-5). The OpenAI chat completions API is also still supported

* `llm_provider_google_gemini()` has been superseded by
`llm_provider_ellmer(ellmer::chat_google_gemini())`

* Add a `json_type` & `tool_type` field to LLM provider objects; when 
automatically determining the route towards structured output (in 
`answer_as_json()`) and tool use (in `answer_using_tools()`), this can override
the type decided by the `api_type` field (e.g., user can use this field to force
the text-based type, for instance when using an OpenAI type LLM provider but
with a model which does not support the typical OpenAI API parameters for 
structured output)

* Update how responses are streamed (with `httr2::req_perform_connection()`, 
since `httr2::req_perform_stream()` is being deprecated)

* Fix bug where the LLM provider object was not properly passed on to
`modify_fn` in `prompt_wrap()`, which could lead to errors when dynamically
constructing prompt text based on the LLM provider type

# tidyprompt 0.1.0

* New prompt wraps `answer_as_category()` and `answer_as_multi_category()`

* New `llm_break_soft()` interrupts prompt evaluation without error

* New experimental provider `llm_provider_ellmer()` for `ellmer` chat objects

* Ollama provider gains `num_ctx` parameter to control context window size

* `set_option()` and `set_options()` are now available for the Ollama provider
to configure options

* Error messages are more informative when an LLM provider cannot be reached

* Google Gemini provider now works without errors in affected cases

* Chat history handling is safer; rows with `NA` values no longer cause errors 
in specific cases

* Final-answer extraction in chain-of-thought prompts is more flexible

* Printed LLM responses now use `message()` instead of `cat()`

* Moved repository to https://github.com/KennispuntTwente/tidyprompt

# tidyprompt 0.0.1

* Initial CRAN release

# tidyprompt 0.0.0.9000

* Initial development version available on GitHub
