devtools::load_all()

"What is in this image?" |>
  add_image(image = "https://en.wikipedia.org/wiki/Cat#/media/File:Cat_August_2010-4.jpg") |>
  send_prompt(llm_provider_openai())

"What is in this image?" |>
  add_image(image = "https://en.wikipedia.org/wiki/Cat#/media/File:Cat_August_2010-4.jpg") |>
  send_prompt(llm_provider_ellmer(ellmer::chat_openai()))
