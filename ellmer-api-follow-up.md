# Public structured-stream capability and extraction helpers

Status: upstream request draft, not submitted. Checked against ellmer
0.5.0 and the upstream development exports on 2026-09-29.

Tidyprompt needs to choose between native structured streaming and
blocking extraction before issuing a request, then obtain the same typed
R value that `Chat$chat_structured()` would return. A fallback after a
stream starts would issue a second model request and could repeat tool
side effects or exceed a request budget.

The public `Chat$stream(type = ...)`, `Chat$last_turn()`,
`Chat$get_provider()` and `Chat$get_model_object()` methods provide part
of this workflow. There is currently no exported equivalent for the four
helpers used by `R/helper_ellmer_stream.R`:
`uses_tool_structured_output`, `type_needs_wrapper`,
`wrap_type_if_needed`, and `extract_data`.

Proposed upstream request:

- Expose a provider/model/type-aware capability query that reports
  whether structured streaming is supported or requires tool-based
  blocking extraction.
- Expose completed structured-value extraction from a Chat/Turn, with
  typed and raw JSON modes, handling provider wrappers internally.
  Ideally callers pass their original type and do not need separate
  wrapping helpers.
- Specify behavior for absent JSON, partial/cancelled turns, and
  multiple JSON content blocks, and whether either API can issue a
  request (we need neither to).

Acceptance examples for a public replacement: scalar roots; arrays of
enums and objects; empty arrays; nested list columns and nullable
fields; raw JSON schemas; native versus tool-based extraction; missing
JSON; and extraction failure without a second request. The offline
contracts live in `tests/testthat/test-ellmer_stream_contract.R` and the
other ellmer protocol tests.

Sources:

- [Public Chat API](https://ellmer.tidyverse.org/reference/Chat.html)
- [0.5.0 extraction
  implementation](https://github.com/tidyverse/ellmer/blob/v0.5.0/R/chat-structured.R)
- [Development
  exports](https://github.com/tidyverse/ellmer/blob/main/NAMESPACE)
- [Upstream tool-based streaming
  limitation](https://github.com/tidyverse/ellmer/issues/977)

Until public replacements exist, private lookup and signature checks
stay in one boundary. Missing/incompatible contracts fall back before
the request. Preparation errors also fall back; extraction errors after
streaming propagate. The contract suite deliberately fails if upstream
removes the helpers, even though runtime use can fall back, so
maintainers see the compatibility change.

The optional `ellmer-devel.yaml` workflow runs manually. Set the
repository variable `ELLMER_DEVEL_CHECK=true` to enable weekly checks.
It is nonblocking and complements the pinned 0.3.0/0.5.0 release checks.
