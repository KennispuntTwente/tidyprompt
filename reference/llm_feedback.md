# Create an `llm_feedback` object

This object is used to send feedback to a LLM when a LLM reply does not
succesfully pass an extraction or validation function (as handled by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
and defined using
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)).
The feedback text is sent back to the LLM. The extraction or validation
function should then return this object with the feedback text that
should be sent to the LLM.

## Usage

``` r
llm_feedback(text, tool_result = FALSE)
```

## Arguments

- text:

  A character string containing the feedback text. This will be sent
  back to the LLM after not passing an extractor or validator function

- tool_result:

  A logical indicating whether the feedback is a tool result. If TRUE,
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  will not remove it from the chat history when cleaning the context
  window during repeated interactions

## Value

An object of class "llm_feedback" (or "llm_feedback_tool_result")
containing the feedback text to send back to the LLM

## See also

[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md)

Other prompt_wrap:
[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)

Other prompt_evaluation:
[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md),
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

## Examples

``` r
# Example usage within a validation function similar to the one in 'answer_as_integer()':
validation_fn <- function(x, min = 0, max = 100) {
  if (x != floor(x)) { # Not a whole number
    return(llm_feedback(
      "You must answer with only an integer (use no other characters)."
    ))
  }
  if (!is.null(min) && x < min) {
    return(llm_feedback(glue::glue(
      "The number should be greater than or equal to {min}."
    )))
  }
  if (!is.null(max) && x > max) {
    return(llm_feedback(glue::glue(
      "The number should be less than or equal to {max}."
    )))
  }
  return(TRUE)
}

# This validation_fn would be part of a prompt_wrap();
#   see the `answer_as_integer()` function for an example of how to use it
```
