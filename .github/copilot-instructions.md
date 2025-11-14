# tidyprompt: AI Coding Agent Instructions

These instructions summarize project-specific architecture, patterns, and workflows so an AI agent can contribute productively. Keep advice concrete and tied to existing code (not aspirational). Refer to files with backticks.

## Core Architecture
- Pipeline design: Prompts are progressively transformed via chained prompt wraps (see `R/prompt_wrap.R`) using native R pipe `|>`. Each wrap can modify text (`modify_fn`), extract, validate, handle provider responses (`handler_fn`), or set provider parameters (`parameter_fn`).
- Wrap type ordering (critical): Modification phase applies in order `check`, `unspecified`, `break`, `mode`, `tool`; evaluation phase reverses: `tool`, `mode`, `break`, `unspecified`, `check` (tests assert this in `tests/testthat/test-prompt_wrap.R`). Breaking this order will cause subtle extraction/validation failures.
- Interaction loop: `send_prompt()` (see `R/send_prompt.R`) drives retries until success or `max_interactions`. It applies extraction then validation for each wrap, sending `llm_feedback()` messages back for correction. `llm_break()` / `llm_break_soft()` short-circuit evaluation; on break, remaining `check` wraps may still run.
- Provider abstraction: R6 class `llm_provider-class` (`R/llm_provider.R`) exposes `$complete_chat()`, `$add_handler_fn()`, `$add_prompt_wrap()`. Concrete providers implemented in `R/llm_providers.R` (Ollama, OpenAI, Mistral, Groq, OpenRouter, etc.) wrap HTTP calls in a uniform response object with `completed`, `http`, optional `ellmer_chat`.
- Provider-level wraps: Use `provider_prompt_wrap()` + `$add_prompt_wrap(position = "pre"|"post")` to enforce global behaviors. They are injected before user wraps in `send_prompt()`.
- Streaming: Controlled by provider `parameters$stream`; optional `stream_callback` (see field in `llm_provider-class`) receives `(chunk, meta)` for incremental output (examples in vignette `streaming_shiny_ipc.Rmd`). Agents adding streaming features must respect existing callback signature.

## Key Conventions & Patterns
- Function naming: User-facing wraps start with `answer_` / `answer_by_` / verbs like `add_` (`answer_as_json.R`, `answer_by_chain_of_thought.R`, `add_text.R`). Internal helpers prefixed `helper_` or `internal_` (e.g. `internal_request_llm_provider.R`). Maintain these prefixes when adding similar functionality.
- Wrap construction: At least one of `modify_fn`, `extraction_fn`, `validation_fn`, `handler_fn`, `parameter_fn` must be non-NULL (enforced in `prompt_wrap_internal`). Type `check` allows ONLY `validation_fn`.
- Arity normalization: `prompt_wrap_internal()` auto-expands formals so extraction/validation/modify functions optionally accept `(x, llm_provider, http_list)`. When adding new wrap functions, write the first argument (content) only; extra params are appended automatically.
- Feedback protocol: Extraction/validation return either the processed value, `llm_feedback()` (triggers another provider request), or `llm_break()` / `llm_break_soft()` objects to halt. Ensure new feedback objects inherit correct S3 class so loop logic detects them.
- Tool use & structured output: `answer_using_tools()` and `answer_as_json()` handle native provider modes vs text-based fallback. They map provider `$api_type` or explicit `$tool_type` / `$json_type` to behavior. New structured modes should follow this pattern: detect native support; else inject instructions via `modify_fn` and parse with `extraction_fn`.
- Environment passing for tools: `prompt_wrap_internal()` copies an `environment` attribute onto extraction functions (tool execution context). Preserve this when extending tool functionality.
- Handler loop semantics: Provider `$complete_chat()` runs added handler functions until `response$done != FALSE`; a handler can set `break = TRUE` to abort (see `llm_provider.R`). Handlers must return the full response shape; tests enforce invariants.

## Testing Workflow
- Tests live in `tests/testthat/`; each feature has a dedicated file (e.g. `test-answer-as-json.R`, `test-send_prompt.R`). Follow this granularity when adding features.
- Fake provider: Use `llm_provider_fake()` (defined in provider sources) for deterministic tests (see `test-general.R`, `test-send_prompt.R`). Prefer fake over live HTTP in unit tests.
- Assertions: Use `expect_s3_class`, `expect_length`, `expect_true`, `expect_equal`, `expect_no_error`. Mirror existing style; avoid custom matchers unless necessary.
- To run: In R: `devtools::test()`; full checks: `devtools::check()` or shell: `R CMD check .`.

## Development Workflow
- Roxygen: Add documentation headers similar to existing files (e.g. `@family` tags group wrap types). Run `devtools::document()` after changes.
- Adding a new provider: Implement local `complete_chat(chat_history)` capturing messages, building a request via `httr2`, then delegate to `request_llm_provider()`. Expose provider-specific helpers (see Ollama `$set_option()` pattern) through an extended R6 subclass.
- Adding a new prompt wrap helper (e.g. `answer_as_matrix()`): 1) Create `R/answer_as_matrix.R` with a user-facing function assembling a call to `prompt_wrap()`; 2) Provide `modify_fn` instructions; 3) Write `extraction_fn` parsing text to target structure and returning `llm_feedback()` on failure; 4) Optional `validation_fn` for stricter constraints; 5) Add tests mirroring integer/list pattern.
- Performance considerations: Use `clean_chat_history = TRUE` in high-retry contexts to trim earlier failed assistant messages (only last attempt kept). Respect existing shape when modifying loop logic.

## Integration Points
- Ellmer compatibility: When provider is built from ellmer chat object (`llm_provider_ellmer()`), updated `ellmer_chat` is synced before handler execution enabling cost/budget checks. Preserve this sync if extending handlers.
- MCP tool definitions: `answer_using_tools()` supports MCP via ellmer tool objects; ensure any new tool abstraction returns compatible definitions.

## Guardrails for Agents
- Do NOT change wrap ordering logic or break arity normalization without updating corresponding tests.
- Avoid sending internal parameters (prefixed with `.`) to external APIs (OpenAI code filters these out). Replicate that pattern for new providers.
- Keep handler side effects idempotent; they may run multiple cycles while `done == FALSE`.
- Preserve S3 class names (`Tidyprompt`, `prompt_wrap`) to avoid downstream method breakage.

## Quick Reference
- Build + docs: `devtools::document()`
- Run tests: `devtools::test()`
- Full check: `R CMD check .`
- Example prompt: `"What is 2+2?" |> answer_as_integer() |> send_prompt(llm_provider_ollama())`

Provide feedback if adding new features; ensure tests and documentation accompany changes.
