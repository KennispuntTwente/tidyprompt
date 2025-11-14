# Creating prompt wraps

### Creating prompt wraps

Using
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
you can create your own prompt wraps. An input for
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
wrap may be string or a tidyprompt object. If you pass a string, it will
be automatically turned into a tidyprompt object.

Under the hood, a tidyprompt object is just a list with a base prompt (a
string) and a series of prompt wraps.
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
adds a new prompt wrap to the list of prompt wraps. Each prompt wrap is
a list with a modification function, an extraction function, and/or a
validation function (at least one of these functions must be present).
The modification function alters the prompt text, the extraction
function applies a transformation to the LLM’s response, and the
validation function checks if the (transformed) LLM’s response is valid.

Both extraction and validation functions can return feedback to the LLM,
using
[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md).
When an extraction or validation function returns this, a message is
sent back to the LLM, and the LLM can retry answering the prompt
according to the feedback. Feedback messages may be a reiteration of
instruction or a specific error message which occured during extraction
or validation. When all extractions and validations have been applied
without resulting in feedback, the LLM’s response (after transformations
by the extraction functions) will be returned.
([`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
is responsible for executing this process.)

Below is a simple example of a prompt wrap, which just adds some text to
the base prompt:

``` r
prompt <- "Hi there!" |>
  prompt_wrap(
    modify_fn = function(base_prompt) {
      paste(base_prompt, "How are you?", sep = "\n\n")
    }
  )
```

Shorter notation of the above would be:

``` r
prompt <- "Hi there!" |>
  prompt_wrap(\(x) paste(x, "How are you?", sep = "\n\n"))
```

Often times, it may be preferred to make a function which takes a prompt
and returns a wrapped prompt:

``` r
my_prompt_wrap <- function(prompt) {
  modify_fn <- function(base_prompt) {
    paste(base_prompt, "How are you?", sep = "\n\n")
  }

  prompt_wrap(prompt, modify_fn)
}
prompt <- "Hi there!" |>
  my_prompt_wrap()
```

Take look at the source code of
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
which also uses extraction:

``` r
answer_as_boolean <- function(
    prompt,
    true_definition = NULL,
    false_definition = NULL,
    add_instruction_to_prompt = TRUE
) {
  instruction <- "You must answer with only TRUE or FALSE (use no other characters)."
  if (!is.null(true_definition))
    instruction <- paste(instruction, glue::glue("TRUE means: {true_definition}."))
  if (!is.null(false_definition))
    instruction <- paste(instruction, glue::glue("FALSE means: {false_definition}."))

  modify_fn <- function(original_prompt_text) {
    if (!add_instruction_to_prompt) {
      return(original_prompt_text)
    }

    glue::glue("{original_prompt_text}\n\n{instruction}")
  }

  extraction_fn <- function(x) {
    normalized <- tolower(trimws(x))
    if (normalized %in% c("true", "false")) {
      return(as.logical(normalized))
    }
    return(llm_feedback(instruction))
  }

  prompt_wrap(prompt, modify_fn, extraction_fn)
}
```

Take a look at the source code of, for instance,
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md),
and
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
for more advanced examples of prompt wraps.

#### Breaking out of the evaluation loop

In some cases, you may want to exit the extraction or validation process
early. For instance, your LLM may indicate that it is unable to answer
the prompt. In such cases, you can have your extraction or validation
function return
[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md).
This will cause the evaluation loop to break, forwarding to the return
statement of
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md).
See
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md)
for an example of this.

#### Extraction versus validation functions

Both extraction and validation functions can return
[`llm_break()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_break.md)
or
[`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md).
The difference between extraction and validation functions is only that
an extraction may transform the LLM response and pass it on to the next
extraction and/or validation functions, while a validation function only
checks if the LLM response passes a logical test (without altering the
response). Thus, if you wish, you can perform validations in an
extraction function.

#### Prompt wrap types and order of application

When constructing the prompt text and when evaluating a prompt, prompt
wraps are applied prompt wrap after prompt wrap (e.g., first the
extraction and validation functions of one wrap, then of the other).

The order in which prompt wraps are applied is important. Currently,
four types of prompt wraps are distinguished: ‘unspecified’, ‘break’,
‘mode’, and ‘tool’.

When constructing the prompt text, prompt wraps are applied in the order
of these types. Prompt wraps will be automatically reordered if
necesarry (keeping intact the order of prompt wraps of the same type).

When evaluating the prompt, prompt wraps are applied in the reverse
order of types (i.e., first ‘tool’, then ‘mode’, then ‘break’, and
finally ‘unspecified’). This is because ‘tool’ prompt wraps may return a
value to be used in the final answer, ‘mode’ prompt wraps alter how a
LLM forms a final answer, ‘break’ prompt wraps quit evaluation early
based on a specific final answer, and ‘unspecified’ prompt wraps are the
most general type of prompt wraps which force a final answer to be in a
specific format.

#### Configuring a LLM provider with a prompt wrap

Advanced prompt wraps may wish to configure certain settings of a LLM
provider. For instance,
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
configures certain parameters of the LLM provider, based on which LLM
provider is being used (Ollama and OpenAI have different API parameters
available for JSON output). This is done by defining a `parameter_fn`
within the prompt wrap; `parameter_fn` is a function which takes the LLM
provider as input and returns a list of parameters, which will be set as
the parameters of the LLM provider before sending the prompt. See
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
documentation and
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md)
for an example.

#### Configuring a prompt wrap based on the LLM provider or HTTP responses

`modify_fn`, `extraction_fn`, and `validation_fn` may take the LLM
provider as the second argument and the `http_list` (a list of all HTTP
responses made during
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md))
as the third argument. This allows for advanced configuration of the
prompt and the extraction and validation logic based on the LLM provider
and any data available the HTTP responses.

#### Configuring a prompt wrap based on other prompt wraps

`modify_fn`, `extraction_fn`, and `validation_fn` all have access to the
`self` object, which represents the `tidyprompt-class` object that they
are a part of. This allows for advanced configuration of the prompt and
the extraction and validation logic based on other prompt wraps. Inside
these functions, simply use `self$` to access the `tidyprompt-class`
object.

#### Handler functions

Prompt wraps may also include ‘handler functions’. These are functions
which are called upon every received chat completion. This allows for
advanced processing of the LLM’s responses, such as logging, tracking
tokens, or other custom processing. See the
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
documentation for more information; see the source code of
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
for an example of a handler function.
