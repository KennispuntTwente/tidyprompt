devtools::load_all()

"What is in this image?" |>
  add_image(image = "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg") |>
  send_prompt(llm_provider_openai())

"What is in this image?" |>
  add_image(image = "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg") |>
  send_prompt(llm_provider_ellmer(ellmer::chat_openai()))
