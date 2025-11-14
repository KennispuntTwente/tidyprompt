# Package index

## Prompt wrapping and evaluation

### Tidyprompt

Functions to create and handle tidyprompt objects.

- [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  : Create a tidyprompt object
- [`tidyprompt-class`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  : Tidyprompt R6 Class
- [`is_tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/is_tidyprompt.md)
  : Check if object is a tidyprompt object
- [`construct_prompt_text()`](https://kennispunttwente.github.io/tidyprompt/reference/construct_prompt_text.md)
  : Construct prompt text from a tidyprompt object
- [`get_prompt_wraps()`](https://kennispunttwente.github.io/tidyprompt/reference/get_prompt_wraps.md)
  : Get prompt wraps from a tidyprompt object
- [`get_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/get_chat_history.md)
  : Get the chat history of a tidyprompt object
- [`set_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/set_chat_history.md)
  : Set the chat history of a tidyprompt object
- [`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)
  : Set system prompt of a tidyprompt object

### Prompt wrap

Functions for creating prompt wraps.

- [`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
  : Wrap a prompt with functions for modification and handling the LLM
  response

- [`provider_prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/provider_prompt_wrap.md)
  **\[experimental\]** : Create a provider-level prompt wrap

- [`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md)
  :

  Create an `llm_feedback` object

- [`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md)
  :

  Create an `llm_break` object

- [`llm_break_soft()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break_soft.md)
  :

  Create an `llm_break_soft` object

### Send prompt

Function to evaluate prompts with an LLM provider.

- [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  : Send a prompt to a LLM provider

## Prompt wrap library

A library of pre-built prompt wraps for common use cases.

### Answer as

Functions to have LLMs answer in a specific format (structured output).

- [`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md)
  : Make LLM answer as a boolean (TRUE or FALSE)
- [`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md)
  : Make LLM answer as a category
- [`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md)
  : Make LLM answer as an integer (between min and max)
- [`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
  : Make LLM answer as JSON (with optional schema; structured output)
- [`answer_as_key_value()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_key_value.md)
  : Make LLM answer as a list of key-value pairs
- [`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md)
  : Make LLM answer as a list of items
- [`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md)
  : Build prompt for categorizing a text into multiple categories
- [`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md)
  : Make LLM answer as a named list
- [`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md)
  : Make LLM answer match a specific regex
- [`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md)
  : Make LLM answer as a constrained text response

### Answer by

Functions to have LLMs answer in a specific way.

- [`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md)
  : Set chain of thought mode for a prompt
- [`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md)
  : Set ReAct mode for a prompt

### Answer using

Functions that give LLMs access to tools (function-calling) and code

- [`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md)
  : Enable LLM to draft and execute R code
- [`answer_using_sql()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_sql.md)
  : Enable LLM to draft and execute SQL queries on a database
- [`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
  : Enable LLM to call R functions (and/or MCP server tools)
- [`tools_add_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_add_docs.md)
  : Add tidyprompt function documentation to a function
- [`tools_get_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_get_docs.md)
  : Extract documentation from a function

### Miscellaneous

- [`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md)
  : Add text to a tidyprompt
- [`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md)
  : Make evaluation of a prompt stop if LLM gives a specific response
- [`user_verify()`](https://kennispunttwente.github.io/tidyprompt/reference/user_verify.md)
  : Have user check the result of a prompt (human-in-the-loop)
- [`llm_verify()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_verify.md)
  : Have LLM check the result of a prompt (LLM-in-the-loop)

## LLM providers & chat history

Functions to interact with LLM providers and manage chat history.

### LLM provider class

- [`llm_provider-class`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider-class.md)
  : LlmProvider R6 Class

### Pre-built LLM providers

- [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
  **\[experimental\]** :

  Create a new LLM provider from an
  [`ellmer::chat()`](https://ellmer.tidyverse.org/reference/chat-any.html)
  object

- [`llm_provider_google_gemini()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_google_gemini.md)
  **\[superseded\]** : Create a new Google Gemini LLM provider

- [`llm_provider_groq()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_groq.md)
  : Create a new Groq LLM provider

- [`llm_provider_mistral()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_mistral.md)
  : Create a new Mistral LLM provider

- [`llm_provider_ollama()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ollama.md)
  : Create a new Ollama LLM provider

- [`llm_provider_openai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openai.md)
  : Create a new OpenAI LLM provider

- [`llm_provider_openrouter()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_openrouter.md)
  : Create a new OpenRouter LLM provider

- [`llm_provider_xai()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_xai.md)
  : Create a new XAI (Grok) LLM provider

### Chat history

- [`chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.md)
  :

  Create or validate `chat_history` object

- [`add_msg_to_chat_history()`](https://kennispunttwente.github.io/tidyprompt/reference/add_msg_to_chat_history.md)
  : Add a message to a chat history

### Persistent chat

A helper class to have a persistent, manual conversation with a LLM
provider.

- [`persistent_chat-class`](https://kennispunttwente.github.io/tidyprompt/reference/persistent_chat-class.md)
  : PersistentChat R6 class

## Helper functions

### Text helpers

Functions to create text to be used in prompts.

- [`df_to_string()`](https://kennispunttwente.github.io/tidyprompt/reference/df_to_string.md)
  : Convert a dataframe to a string representation
- [`vector_list_to_string()`](https://kennispunttwente.github.io/tidyprompt/reference/vector_list_to_string.md)
  : Convert a named or unnamed list/vector to a string representation
- [`skim_with_labels_and_levels()`](https://kennispunttwente.github.io/tidyprompt/reference/skim_with_labels_and_levels.md)
  : Skim a dataframe and include labels and levels

### Other helper functions

- [`extract_from_return_list()`](https://kennispunttwente.github.io/tidyprompt/reference/extract_from_return_list.md)
  : Function to extract a specific element from a list
- [`r_json_schema_to_example()`](https://kennispunttwente.github.io/tidyprompt/reference/r_json_schema_to_example.md)
  : Generate an example object from a JSON schema
