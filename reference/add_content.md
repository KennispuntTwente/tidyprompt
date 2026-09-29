# Attach native ellmer content to a prompt

Attach documents, PDFs, uploaded-file references, or other native ellmer
Content objects. Requires an ellmer-backed provider. Ellmer handles
upload lifecycle and provider-specific content support. Content is
attached to the first request and retained in native history during
feedback and retries.

## Usage

``` r
add_content(prompt, content)
```

## Arguments

- prompt:

  A string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object.

- content:

  An ellmer Content object or a nonempty list of Content objects.

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an attachment
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md).

## See also

[`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md)
