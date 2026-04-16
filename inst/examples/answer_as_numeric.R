\dontrun{
  "What is 10 divided by 4?" |>
    answer_as_numeric() |>
    send_prompt()
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   What is 10 divided by 4?
  #
  #   You must answer with only a number (use no other characters).
  # --- Receiving response from LLM provider: ---
  #   2.5
  # [1] 2.5
}