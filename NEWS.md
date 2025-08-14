# tidyprompt 0.1.0

* New prompt wraps `answer_as_category()` and `answer_as_multi_category()`
* New `llm_break_soft()` interrupts prompt evaluation without error
* New experimental provider `llm_provider_ellmer()` for `ellmer` chat objects
* Ollama provider gains `num_ctx` parameter to control context window size
* `set_option()` and `set_options()` are now available for the Ollama provider
to configure options
* Error messages are more informative when an LLM provider cannot be reached.
* Google Gemini provider now works without errors in affected cases
* Chat history handling is safer; rows with `NA` values no longer cause errors 
in specific cases
* Final-answer extraction in chain-of-thought prompts is more flexible
* Printed LLM responses now use `message()` instead of `cat()`
* Moved repository to https://github.com/KennispuntTwente/tidyprompt

# tidyprompt 0.0.1

* Initial CRAN release

# tidyprompt 0.0.0.9000

* Initial development version available on GitHub
