# tidyprompt 0.2.0

* Add provider-level prompt wraps (`provider_prompt_wrap()`) these are prompt
wraps which can be attached to a LLM provider object. They can be applied to
any prompt which is sent through this LLM provider, either before or after
prompt-specific prompt wraps. This is useful when you want to achieve 
certain behavior for various prompts, without having to re-apply the same
prompt wrap to each prompt

* `answer_as_json()`: support 'ellmer' definitions of structured ouput
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

* Add a `json_type` field to LLM provider objects; when automatically
determining the route towards structured output, this can override the type 
decided by the `api_type` field (e.g., user can use this field to force the 
text-based type, for instance when using an OpenAI type LLM provider but with a 
model which does not support the typical OpenAI API parameters for structured 
output)

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
