# Add an image to a tidyprompt (multimodal)

**\[experimental\]** Attach an image to the last user message by adding
a
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
that configures providers to send image content alongside the text
prompt.

Supports 'ollama', 'openai' (completions & responses) and
'ellmer'-backed providers. Can convert from and to 'ellmer' content
image objects as needed.

## Usage

``` r
add_image(
  prompt,
  image,
  alt = NULL,
  detail = c("auto", "low", "high"),
  mime = NULL
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- image:

  An image reference. One of:

  - a local file path (e.g., "path/to/image.png")

  - a URL (e.g., "https://.../image.jpg")

  - a base64 string (optionally with data URL prefix)

  - a raw vector of bytes

  - a plot object (e.g., base `recordedplot`, `ggplot`, or grid grob) to
    be rasterized automatically

  - an 'ellmer' content object created by
    [`ellmer::content_image_url()`](https://ellmer.tidyverse.org/reference/content_image_url.html),
    [`ellmer::content_image_file()`](https://ellmer.tidyverse.org/reference/content_image_url.html),
    or
    [`ellmer::content_image_plot()`](https://ellmer.tidyverse.org/reference/content_image_url.html)
    (this will work with both regular providers and 'ellmer'-backed
    providers)#' For OpenAI Responses API, URLs must point directly to
    an image resource (not an HTML page) and are transmitted as a scalar
    string `image_url` with optional `detail`. Supplying a webpage URL
    (e.g. a Wikipedia media viewer link) will result in a provider 400
    error expecting an image URL string.

- alt:

  Optional alternative text/alt description

- detail:

  Detail hint for some providers (OpenAI): one of "auto", "low", "high"

- mime:

  Optional mime-type if providing raw/base64 without data URL (e.g.,
  "image/png")

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with a multimodal
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
attached

## See also

Other pre_built_prompt_wraps:
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
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other miscellaneous_prompt_wraps:
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)
