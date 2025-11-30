# Add an image to a tidyprompt (multimodal)

**\[experimental\]**

Attach an image to a
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
for use with multimodal LLMs.

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
    error expecting an image URL string

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
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will attach an image to the prompt for use with multimodal LLMs

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

## Examples

``` r
# Create a prompt with a remote image (web URL)
image_prompt <- "What is shown in this image?" |>
  add_image("https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg")

# Create a prompt with a local image (file path)
# First save an image to a temporary file
cat_img_file <- tempfile(fileext = ".jpg")
download.file(
  "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg",
  destfile = cat_img_file,
  mode = "wb"
)
# Then build prompt with local image
local_image_prompt <- "What is shown in this image?" |>
  add_image(cat_img_file)

# Create a prompt with a plot (e.g., 'ggplot2' plot)
# \donttest{
if (requireNamespace("ggplot2", quietly = TRUE)) {
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point()
  plot_prompt <- "Describe this plot" |>
    add_image(plot)
}
#> Error in .tp_normalize_image_input(image, mime = mime, alt = alt, detail = detail): Unsupported `image` input (class: data.frame); provide a url, file path, base64 string, or raw bytes.
# }

# Send prompt to different LLM providers
# (example is not run because it requires configured LLM providers)
if (FALSE) { # \dontrun{
# OpenAI-compatible
send_prompt(image_prompt, llm_provider_openai(parameters = list(model = "gpt-4o-mini")))
# --- Sending request to LLM provider (gpt-4o-mini): ---
# What is shown in this image?
# --- Receiving response from LLM provider: ---
# The image shows a close-up of an orange tabby cat, characterized by its
# striped fur and distinctive golden eyes. The background appears blurred,
# suggesting a softly focused environment.

# Ollama-compatible
send_prompt(image_prompt, llm_provider_ollama(parameters = list(model = "qwen3-vl:2b")))
# ...

# 'ellmer'-compatible
send_prompt(image_prompt, llm_provider_ellmer(ellmer::chat_openai(model = "gpt-4o-mini")))
# ...
} # }
```
