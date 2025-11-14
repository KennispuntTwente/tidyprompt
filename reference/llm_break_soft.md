# Create an `llm_break_soft` object

This object is used to break a extraction and validation loop defined in
a
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
as evaluated by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).
When an extraction or validation function returns this object, it will
prevent any future interactions with the LLM provider for the current
prompt. Remaining extraction and validation functions will still be
applied and it will still be possible to pass these with the current
response from the LLM provider; only, no more new tries will be made if
the current response is not satisfactory.

This is useful when, e.g., the token limit for the LLM provider has been
reached, but the final response that we got may still be satisfactory.
In this case,
[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md)
cannot be used, as it would instantly return the current response as the
final result, which is not what we want. Instead, `llm_break_soft()` can
be used to prevent any further interactions with the LLM provider, but
still allow the remaining extraction and validation functions to be
applied (and have those decide the success of the current response).

## Usage

``` r
llm_break_soft(object_to_return = NULL)
```

## Arguments

- object_to_return:

  The object to return as the response result from
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  when this object is returned from an extraction or validation function

## Value

An list of class "llm_break_soft" containing the object to return

## Examples

``` r
# Quitting when total token count is exceeded (Google Gemini API example)
if (FALSE) { # \dontrun{
  "How are you?" |>
    # Forcing multi-response via initial error, for demonstration purposes
    answer_as_integer(add_instruction_to_prompt = FALSE) |>
    # Validation function to check total token count
    prompt_wrap(validation_fn = function(response, llm_provider, http_list) {
      total_tokens <- purrr::map_dbl(
        http_list$responses,
        ~ .x$body |>
          rawToChar() |>
          jsonlite::fromJSON() |>
          purrr::pluck("usageMetadata", "totalTokenCount")
      ) |> sum()
      if (total_tokens > 50) {
        warning("Token count exceeded; preventing further interactions")
        # Using llm_break_soft() to prevent further interactions
        return(llm_break_soft(response))
      }
    }) |>
    send_prompt(llm_provider_google_gemini(), return_mode = "full")
} # }
```
