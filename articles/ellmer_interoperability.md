# Working with ellmer

[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
accepts an ellmer Chat directly or an
[`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md).
Pin the model when creating the chat if reproducibility matters;
provider defaults can change. The adapter preserves native turns,
content, usage, cost and citations in the full result.

## Callbacks and chat ownership

Each
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
evaluation deep-clones its native chat. Callback registries, tools and
conversation state on that working chat are independent of the original.
A callback’s R closure still refers to the variables it originally
captured. Register callbacks that modify history on the working chat,
inside a prompt wrap’s `parameter_fn`, which runs after cloning:

``` r

library(tidyprompt)
chat <- ellmer::chat_openai(model = "gpt-4.1-mini")
prompt <- prompt_wrap("Summarize the discussion", parameter_fn = function(llm_provider) {
  working <- llm_provider$get_chat()
  working$on_request_start(function(turns) {
    # Inspect `turns` and, if needed, call working$set_turns(...).
    message("Starting a model request")
  })
  list()
})
result <- send_prompt(prompt, chat, return_mode = "full")
result$ellmer_chat$get_turns()
```

Callbacks require the corresponding methods in your ellmer version. The
adapter honors history replacement performed by request callbacks,
including compaction, when preparing later feedback turns.

## Schemas and tool results

Closed objects use ellmer’s native types. Open objects and constraints
such as numeric bounds or schema composition use
[`ellmer::type_from_schema()`](https://ellmer.tidyverse.org/reference/type_boolean.html)
to preserve the schema. Provider/model support for these schemas still
varies. Raw schemas return JSON-shaped R values rather than ellmer’s
typed factors and data frames. Install `jsonvalidate` to validate
constraints locally; tidyprompt requires it when a schema has
constraints beyond the basic native types.

Tidyprompt-created tools serialize lists as JSON objects/arrays and data
frames as arrays of row objects. Return an explicit JSON string to
control serialization. Native ellmer tools retain their own result
contract. Rich content results and tools using
[`ellmer::tool_context()`](https://ellmer.tidyverse.org/reference/tool_context.html)
need native ellmer execution. Cross-provider tool conversion preserves
nested argument schemas and the native `convert` policy.

## Documents and uploaded files

Use
[`add_content()`](https://kennispunttwente.github.io/tidyprompt/reference/add_content.md)
for any native ellmer Content object, including documents, PDFs and
uploaded-file references. Ellmer remains responsible for file uploads,
expiry and provider restrictions. Attachments work with structured
output and streaming, and stay in native history during feedback without
being reattached.

``` r

document <- ellmer::content_document_file("report.txt")
result <- add_content("Summarize this document", document) |>
  send_prompt(chat, return_mode = "full")
```

## Structured streams

With ellmer 0.5.0,
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
and `stream = TRUE` stream raw JSON chunks through the usual
`stream_callback(chunk, meta)`. Final extraction keeps ellmer’s R
coercion, including data frames and factors. Providers/models that use
tool-based structured output, older ellmer versions, and custom adapters
without the required capabilities use blocking `chat_structured()`
instead.

## Stream events and recovery

Set provider parameter `stream_content = TRUE` to receive native events
in `meta$content`. The first callback argument remains a string:
non-text events such as citations, thinking and tool results receive
`""` and do not enter the accumulated answer. Inspect
`meta$content_type` to render these separately.

``` r

controller <- ellmer::stream_controller()
provider <- llm_provider_ellmer(chat, parameters = list(
  stream = TRUE, stream_content = TRUE, stream_controller = controller
))
provider$stream_callback <- function(chunk, meta) {
  cat(chunk)
  # Call controller$cancel() to stop after the next chunk boundary.
}
result <- tryCatch(
  send_prompt("Explain the report", provider),
  tidyprompt_stream_error = function(e) {
    # Also catches tidyprompt_stream_cancelled, a subclass.
    list(partial = e$partial_response, chat = e$ellmer_chat, turn = e$partial_turn)
  }
)
```

Cancellation and iteration failures stop validation and feedback
requests. The condition exposes the working chat and ellmer’s partial
turn; partial text is never treated as a successful answer. Iteration
failures do not trigger a second model request. Controllers require a
streaming-capable path; the blocking structured fallback cannot be
cancelled with a stream controller.

## Request limits and observability

`max_interactions` limits tidyprompt’s outer evaluation loop. Use
`send_prompt(prompt, chat, max_requests = 5)` or
`limit_requests(prompt, max_requests = 5)` to bound individual model
requests across tool calls and feedback for regular tidyprompt providers
and ‘ellmer’. If both limits are supplied, the smaller applies. The
`max_requests` argument defaults to `NULL`, which leaves any limit
attached to the prompt in effect. With an ‘ellmer’ provider, this
requires ‘ellmer’ 0.5.0 and counts the blocking structured path
explicitly, because that method bypasses its request hooks. The limit
stops before the next model request and raises
`tidyprompt_request_limit` with the working provider (and native chat
when applicable) attached. It does not prevent execution of tools
requested by an already completed model request, or bound
transport-level retries made within one model request.

``` r

prompt <- limit_requests("Research this question", 5)
prompt <- prompt_wrap(prompt, parameter_fn = function(llm_provider) {
  working <- llm_provider$get_chat()
  working$conversation_id <- "research-session-123"
  working$on_request_end(function(turn) {
    print(turn@tokens)
    print(turn@cost)
  })
  list()
})
result <- send_prompt(prompt, chat, return_mode = "full")
result$ellmer_chat$get_tokens()
```

Use native turn metadata and ellmer tracing for usage and latency; the
adapter’s HTTP fields do not represent native requests. `on_request_end`
itself does not fire on the blocking structured path in ellmer 0.5.0;
read the returned native turns there. Token estimates and recorded cost
cannot guarantee a final spending cap, because a request may exceed the
remaining estimate before it completes.

## Tools followed by structured extraction

Ellmer suppresses tools during native structured extraction, including
structured streaming. Tidyprompt diagnoses this combination for both
prompt-level tools and tools registered directly on the Chat. Use two
evaluations when a task needs both: first gather information using
tools, then extract a schema-constrained answer from that conversation.

``` r

research <- answer_using_tools("Find the relevant facts", tools = my_tools,
  type = "ellmer") |>
  send_prompt(chat, return_mode = "full")

# Tool results stay in the history; no new tools are needed for extraction.
extraction_chat <- research$ellmer_chat$clone(deep = TRUE)
extraction_chat$set_tools(list())
answer <- add_msg_to_chat_history(research$chat_history, "Extract the final result") |>
  answer_as_json(schema = ellmer::type_object(summary = ellmer::type_string()),
    type = "ellmer") |>
  send_prompt(extraction_chat)
```

## Async, parallel and batch boundaries

[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
is synchronous, including its extraction, validation and feedback loop.
Calling it from an ellmer async or batch helper does not make that loop
asynchronous. For Shiny, the separate-process approach in
[`vignette("streaming_shiny_ipc")`](https://kennispunttwente.github.io/tidyprompt/articles/streaming_shiny_ipc.md)
remains available. Construct each chat in its worker instead of sharing
a mutable Chat across concurrent evaluations.

Use ellmer’s native async/parallel/batch APIs directly for independent
native requests that do not need tidyprompt’s evaluation loop. A future
integrated path must define asynchronous validation and tools,
cancellation, and scheduling of data-dependent retries; those
capabilities are not implied by this adapter.
