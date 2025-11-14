# Function to extract a specific element from a list

This function is intended as a helper function for piping with output
from
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
when using `return_mode = "full"`. It allows to extract a specific
element from the list returned by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md),
which can be useful for further piping.

## Usage

``` r
extract_from_return_list(list, name_of_element = "response")
```

## Arguments

- list:

  A list, typically the output from
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  with `return_mode = "full"`

- name_of_element:

  A character string with the name of the element to extract from the
  list

## Value

The extracted element from the list

## Examples

``` r
if (FALSE) { # \dontrun{
  response <- "Hi!" |>
    send_prompt(llm_provider_ollama(), return_mode = "full") |>
    extract_from_return_list("response")
  response
  # [1] "It's nice to meet you. Is there something I can help you with,
  # or would you like to chat?"
} # }
```
