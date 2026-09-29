# Limit model requests during a prompt evaluation

Count model requests across initial responses, tool follow-ups and
feedback rounds, for regular tidyprompt providers and 'ellmer'. The
counter resets for each
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
evaluation. Streaming chunks and transport-level retries within a model
request do not count as additional model requests. Nested
[`llm_verify()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_verify.md)
evaluations, including rejection summaries, share the outer evaluation's
counter.

## Usage

``` r
limit_requests(prompt, max_requests)
```

## Arguments

- prompt:

  A string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object.

- max_requests:

  A positive whole number of allowed model requests.

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with a request limit. Exceeding the limit raises a
`tidyprompt_request_limit` error containing `requests`, `max_requests`
and the working `llm_provider`; 'ellmer' providers also include
`ellmer_chat`.

## Details

Alternatively, supply `max_requests` directly to
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).
Both use the same request counter mechanism. If both limits are
supplied, the smaller limit applies.
`send_prompt(max_interactions = ...)` separately limits the outer
extraction, validation and feedback loop, which does not count requests
within provider tool loops.

'ellmer' providers require 'ellmer' 0.5.0 request hooks to count
requests in native tool loops. Blocking structured extraction is counted
explicitly because that path does not run the hooks in 'ellmer' 0.5.0.

A custom provider's completion function counts as one request.
Additional calls through tidyprompt's internal `request_llm_provider()`
helper are counted when the working provider is passed as its
`llm_provider` argument. Requests made directly by custom code outside
these boundaries cannot be counted.

The limit stops the next model request. It does not prevent execution of
tools requested by a response already received, or guarantee a monetary
budget.

## See also

[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md),
[`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
