# Create an `llm_break` object

This object is used to break a extraction and validation loop defined in
a
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
as evaluated by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).
When an extraction or validation function returns this object, the loop
will be broken and no further extraction or validation functions are
applied; instead,
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
will be able to return the result at that point. This may be useful in
scenarios where it is determined the LLM is unable to provide a response
to a prompt.

## Usage

``` r
llm_break(object_to_return = NULL, success = FALSE)
```

## Arguments

- object_to_return:

  The object to return as the response result from
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  when this object is returned from an extraction or validation function

- success:

  A logical indicating whether the
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  loop break should nonetheless be considered as a successful completion
  of the extraction and validation process. If `FALSE`, the
  `object_to_return` must be `NULL` (as the response result of
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  will always be 'NULL' when the evaluation was unsuccessful); if
  `FALSE`,
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  will also print a warning about the unsuccessful evaluation. If
  `TRUE`, the `object_to_return` will be returned as the response result
  of
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  (and
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md))
  will print no warning about unsuccessful evaluation)

## Value

An list of class "llm_break" containing the object to return and a
logical indicating whether the evaluation was successful

## See also

[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)

Other prompt_wrap:
[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)

Other prompt_evaluation:
[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md),
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

## Examples

``` r
# Example usage within an extraction function similar to the one in 'quit_if()':
extraction_fn <- function(x) {
  quit_detect_regex <- "NO ANSWER"

  if (grepl(quit_detect_regex, x)) {
      return(llm_break(
        object_to_return = NULL,
        success = TRUE
      ))
  }

  return(x)
}

if (FALSE) { # \dontrun{
  result <- "How many months old is the cat of my uncle?" |>
    answer_as_integer() |>
    prompt_wrap(
      modify_fn = function(prompt) {
        paste0(
          prompt, "\n\n",
          "Type only 'NO ANSWER' if you do not know."
        )
      },
      extraction_fn = extraction_fn,
      type = "break"
    ) |>
    send_prompt()
  result
  # NULL
} # }
```
