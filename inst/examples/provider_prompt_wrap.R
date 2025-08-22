ollama <- llm_provider_ollama()

# Add a "short answer" mode (provider-level post prompt wrap)
ollama$add_prompt_wrap(
  provider_prompt_wrap(
    modify_fn = \(txt) paste0(
      txt,
      "\n\nPlease answer concisely (< 2 sentences)."
    )
  ),
  position = "post"
)

# Use as usual: wraps are applied automatically
\dontrun{
"What's a vignette in R?" |> send_prompt(ollama)
}
