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

# Send prompt to different LLM providers
# (example is not run because it requires configured LLM providers)
\dontrun{
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
}

# Create a prompt with a plot (e.g., 'ggplot2' plot)
\dontrun{
if (requireNamespace("ggplot2", quietly = TRUE)) {
  plot <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point()

  plot_prompt <- "Describe this plot" |>
    add_image(plot)

  send_prompt(plot_prompt, llm_provider_openai())
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # Describe this plot
  # --- Receiving response from LLM provider: ---
  # The plot is a scatter plot depicting the relationship between two variables:
  # "mpg" (miles per gallon) on the x-axis and "disp" (displacement) on
  # the y-axis. (...)
}
}
