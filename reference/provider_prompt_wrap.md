# Create a provider-level prompt wrap

**\[experimental\]** Build a provider-specific prompt wrap, to store on
an
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
object (with `$add_prompt_wrap()`). These prompt wraps can be applied
before or after any prompt-specific prompt wraps. In this way, you can
ensure that certain prompt wraps are always applied when using a
specific LLM provider.

## Usage

``` r
provider_prompt_wrap(
  modify_fn = NULL,
  extraction_fn = NULL,
  validation_fn = NULL,
  handler_fn = NULL,
  parameter_fn = NULL,
  type = c("unspecified", "mode", "tool", "break", "check"),
  name = NULL
)
```

## Arguments

- modify_fn:

  A function that takes the previous prompt text (as first argument) and
  returns the new prompt text

- extraction_fn:

  A function that takes the LLM response (as first argument) and
  attempts to extract a value from it. Upon succesful extraction, the
  function should return the extracted value. If the extraction fails,
  the function should return a
  [`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)
  message to initiate a retry. A
  [`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md)
  can be returned to break the extraction and validation loop, ending
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

- validation_fn:

  A function that takes the (extracted) LLM response (as first argument)
  and attempts to validate it. Upon succesful validation, the function
  should return TRUE. If the validation fails, the function should
  return a
  [`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)
  message to initiate a retry. A
  [`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md)
  can be returned to break the extraction and validation loop, ending
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

- handler_fn:

  A function that takes a 'completion' object (a result of a request to
  a LLM, as returned by `$complete_chat()` of a
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object) as first argument and the
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object as second argument. The function should return a (modified or
  identical) completion object. This can be used for advanced side
  effects, like logging, or native tool calling, or keeping track of
  token usage. See
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  for more information; handler_fn is attached to the
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object that is being used. When using an
  [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md),
  the up-to-date ellmer_chat is synced onto the provider before handlers
  run. This allows handlers to access, for instance, the current cost of
  the conversation, and, for instance, to stop the conversation if a
  certain budget is exceeded. For example usage, see source code of
  [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)

- parameter_fn:

  A function that takes the
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object which is being used with
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  and returns a named list of parameters to be set in the
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object via its `$set_parameters()` method. This can be used to
  configure specific parameters of the
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object when evaluating the prompt. For example,
  [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  may set different parameters for different APIs related to JSON
  output. This function is typically only used with advanced prompt
  wraps that require specific settings in the
  [llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  object

- type:

  The type of prompt wrap. Must be one of:

  - "unspecified": The default type, typically used for prompt wraps
    which request a specific format of the LLM response, like
    [`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md)

  - "mode": For prompt wraps that change how the LLM should answer the
    prompt, like
    [`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md)
    or
    [`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md)

  - "tool": For prompt wraps that enable the LLM to use tools, like
    [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
    or
    [`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md)
    when 'output_as_tool' = TRUE

  - "break": For prompt wraps that may break the extraction and
    validation loop, like
    [`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md).
    These are applied before type "unspecified" as they may instruct the
    LLM to not answer the prompt in the manner specified by those prompt
    wraps

  - "check": For prompt wraps that apply a last check to the final
    answer, after all other prompt wraps have been evaluated. These
    prompt wraps may only contain a validation function, and are applied
    after all other prompt wraps have been evaluated. These prompt wraps
    are even applied after an earlier prompt wrap has broken the
    extraction and validation loop with
    [`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md)

  Types are used to determine the order in which prompt wraps are
  applied. When constructing the prompt text, prompt wraps are applied
  to the base prompt in the following order: 'check', 'unspecified',
  'break', 'mode', 'tool'. When evaluating the LLM response and applying
  extraction and validation functions, prompt wraps are applied in the
  reverse order: 'tool', 'mode', 'break', 'unspecified', 'check'. Order
  among the same type is preserved in the order they were added to the
  prompt.

- name:

  An optional name for the prompt wrap. This can be used to identify the
  prompt wrap in the
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object

## Value

A `provider_prompt_wrap` object, to be stored on an
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
object

## Examples

``` r
ollama <- llm_provider_ollama()

# Add a "short answer" mode (provider-level post prompt wrap)
ollama$add_prompt_wrap(
  provider_prompt_wrap(
    modify_fn = \(txt) paste0(
      txt,
      "\n\nPlease answer concisely (< 2 sentences)."
    )
  ),
  position = "post"
)

# Use as usual: wraps are applied automatically
if (FALSE) { # \dontrun{
"What's a vignette in R?" |> send_prompt(ollama)
} # }
```
