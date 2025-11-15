# Create a prompt with an image
image_prompt <- "What is shown in this image?" |>
  add_image("https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg")

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
