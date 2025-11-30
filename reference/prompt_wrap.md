# Wrap a prompt with functions for modification and handling the LLM response

This function takes a single string or a
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
object and adds a new prompt wrap to it.

A prompt wrap is a set of functions that modify the prompt text, extract
a value from the LLM response, and validate the extracted value.

The functions are used to ensure that the prompt and LLM response are in
the correct format and meet the specified criteria; they may also be
used to provide the LLM with feedback or additional information, like
the result of a tool call or some evaluated code.

Advanced prompt wraps may also include functions that directly handle
the response from a LLM API or configure API parameters.

## Usage

``` r
prompt_wrap(
  prompt,
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

- prompt:

  A string or a
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object

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

A
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
object with the `prompt_wrap()` appended to it

## Details

For advanced use, modify_fn, extraction_fn, and validation_fn may take
the
[llm_provider](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
object (as used with
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md))
as second argument, and the 'http_list' (a list of all HTTP requests and
responses made during
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md))
as third argument. Use of these arguments is not required, but can be
useful for more complex prompt wraps which require additional
information about the LLM provider or requests made so far. The
functions (including parameter_fn) also have access to the object `self`
(not a function argument; it is attached to the environment of the
function) which contains the
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
object that the prompt wrap is a part of. This can be used to access
other prompt wraps, or to access the prompt text or other information
about the prompt. For instance, other prompt wraps can be accessed
through `self$get_prompt_wraps()`.

## See also

[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

Other prompt_wrap:
[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md),
[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)

Other pre_built_prompt_wraps:
[`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md),
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md),
[`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md),
[`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md),
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_sql()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_sql.md),
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

## Examples

``` r
# A custom prompt_wrap may be created during piping
prompt <- "Hi there!" |>
  prompt_wrap(
    modify_fn = function(base_prompt) {
      paste(base_prompt, "How are you?", sep = "\n\n")
    }
  )
prompt
#> <tidyprompt>
#> The base prompt is modified by a prompt wrap, resulting in:
#> > Hi there!
#> > 
#> > How are you? 
#> Use 'x$base_prompt' to show the base prompt text.
#> Use 'x$construct_prompt_text()' to get the full prompt text.
#> Use 'get_prompt_wraps(x)' to show the prompt wraps.
#> 

# (Shorter notation of the above:)
prompt <- "Hi there!" |>
  prompt_wrap(\(x) paste(x, "How are you?", sep = "\n\n"))

# It may often be preferred to make a function which takes a prompt and
#   returns a wrapped prompt:
my_prompt_wrap <- function(prompt) {
  modify_fn <- function(base_prompt) {
    paste(base_prompt, "How are you?", sep = "\n\n")
  }

  prompt_wrap(prompt, modify_fn)
}
prompt <- "Hi there!" |>
  my_prompt_wrap()

# For more advanced examples, take a look at the source code of the
#   pre-built prompt wraps in the tidyprompt package, like
#   answer_as_boolean, answer_as_integer, add_tools, answer_as_code, etc.
# Below is the source code for the 'answer_as_integer' prompt wrap function:
#' Make LLM answer as an integer (between min and max)
#'
#' @param prompt A single string or a [tidyprompt()] object
#' @param min (optional) Minimum value for the integer
#' @param max (optional) Maximum value for the integer
#' @param add_instruction_to_prompt (optional) Add instruction for replying
#' as an integer to the prompt text. Set to FALSE for debugging if extractions/validations
#' are working as expected (without instruction the answer should fail the
#' validation function, initiating a retry)
#'
#' @return A [tidyprompt()] with an added [prompt_wrap()] which
#' will ensure that the LLM response is an integer.
#'
#' @export
#'
#' @example inst/examples/answer_as_integer.R
#'
#' @family pre_built_prompt_wraps
#' @family answer_as_prompt_wraps
answer_as_integer <- function(
  prompt,
  min = NULL,
  max = NULL,
  add_instruction_to_prompt = TRUE
) {
  instruction <- "You must answer with only an integer (use no other characters)."

  if (!is.null(min) && !is.null(max)) {
    instruction <- paste(
      instruction,
      glue::glue(
        "Enter an integer between {min} and {max}."
      )
    )
  } else if (!is.null(min)) {
    instruction <- paste(
      instruction,
      glue::glue(
        "Enter an integer greater than or equal to {min}."
      )
    )
  } else if (!is.null(max)) {
    instruction <- paste(
      instruction,
      glue::glue(
        "Enter an integer less than or equal to {max}."
      )
    )
  }

  modify_fn <- function(original_prompt_text) {
    if (!add_instruction_to_prompt) {
      return(original_prompt_text)
    }

    glue::glue("{original_prompt_text}\n\n{instruction}")
  }

  extraction_fn <- function(x) {
    extracted <- suppressWarnings(as.numeric(x))
    if (is.na(extracted)) {
      return(llm_feedback(instruction))
    }
    return(extracted)
  }

  validation_fn <- function(x) {
    if (x != floor(x)) {
      # Not a whole number
      return(llm_feedback(instruction))
    }

    if (!is.null(min) && x < min) {
      return(
        llm_feedback(
          glue::glue(
            "The number should be greater than or equal to {min}."
          )
        )
      )
    }
    if (!is.null(max) && x > max) {
      return(
        llm_feedback(
          glue::glue(
            "The number should be less than or equal to {max}."
          )
        )
      )
    }
    return(TRUE)
  }

  prompt_wrap(
    prompt,
    modify_fn,
    extraction_fn,
    validation_fn,
    name = "answer_as_integer"
  )
}
```
