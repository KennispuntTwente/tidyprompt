# Make LLM answer as JSON (with optional schema; structured output)

This functions wraps a prompt with settings that ensure the LLM response
is a valid JSON object, optionally matching a given JSON schema (also
known as 'structured output'/'structured data'). Users may provide
either an 'ellmer' type (e.g.
[`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html);
see ['ellmer'
documentation](https://ellmer.tidyverse.org/articles/structured-data.html))
or a JSON schema (as R list object) to enforce structure on the
response.

The function can work with all models and providers through text-based
handling, but also supports native settings for the OpenAI, Ollama, and
various 'ellmer' types of LLM providers. (See argument 'type'.) This
means that it is possible to easily switch between providers with
different levels of structured output support, while always ensuring the
response will be in the desired format.

## Usage

``` r
answer_as_json(
  prompt,
  schema = NULL,
  schema_strict = FALSE,
  schema_in_prompt_as = c("example", "schema"),
  type = c("auto", "text-based", "openai", "ollama", "openai_oo", "ollama_oo", "ellmer")
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- schema:

  Either a R list object which represents a JSON schema that the
  response should match, or an 'ellmer' definition of structured data
  (e.g.,
  [`ellmer::type_object()`](https://ellmer.tidyverse.org/reference/type_boolean.html);
  see ['ellmer'
  documentation](https://ellmer.tidyverse.org/articles/structured-data.html))

- schema_strict:

  If TRUE, the provided schema will be strictly enforced. This option is
  passed as part of the schema when using type "openai", "ollama", or
  "ellmer", and when using "ollama_oo", "openai_oo", or "text-based" it
  is passed to
  [`jsonvalidate::json_validate()`](https://docs.ropensci.org/jsonvalidate/reference/json_validate.html)
  when validating the response

- schema_in_prompt_as:

  If providing a schema and when using type "text-based", "openai_oo",
  or "ollama_oo", this argument specifies how the schema should be
  included in the prompt:

  - "example" (default): The schema will be included as an example JSON
    object (tends to work best).
    [`r_json_schema_to_example()`](https://kennispunttwente.github.io/tidyprompt/reference/r_json_schema_to_example.md)
    is used to generate the example object from the schema

  - "schema": The schema will be included as a JSON schema

- type:

  The way that JSON response should be enforced:

  - "auto": Automatically determine the type based on
    'llm_provider\$api_type' or 'llm_provider\$json_type' (if set;
    'json_type' overrides 'api_type' determination). This may not always
    consider model compatibility and could lead to errors; set 'type'
    manually if errors occur; use 'text-based' if unsure

  - "text-based": Instruction will be added to the prompt asking for
    JSON; when a schema is provided, this will also be included in the
    prompt (see argument 'schema_in_prompt_as'). JSON will be parsed
    from the LLM response and, when a schema is provided, it will be
    validated against the schema with
    [`jsonvalidate::json_validate()`](https://docs.ropensci.org/jsonvalidate/reference/json_validate.html).
    Feedback is sent to the LLM when the response is not valid. This
    option always works, but may in some cases may be less powerful than
    the other native JSON options

  - "openai" and "ollama": The response format will be set via the
    relevant API parameters, making the API enforce a valid JSON
    response. If a schema is provided, it will also be included in the
    API parameters and also be enforced by the API. When no schema is
    provided, a request for JSON is added to the prompt (as required by
    the APIs). Note that these JSON options may not be available for all
    models of your provider; consult their documentation for more
    information. If you are unsure or encounter errors, use "text-based"

  - "openai_oo" and "ollama_oo": Similar to "openai" and "ollama", but
    if a schema is provided it is not included in the API parameters.
    Schema validation will be done in R with
    [`jsonvalidate::json_validate()`](https://docs.ropensci.org/jsonvalidate/reference/json_validate.html).
    This can be useful if you want to use the API's JSON support, but
    their schema support is limited

  - "ellmer": A parameter will be added to the LLM provider, indicating
    that the response should be structured according to the provided
    schema. The native 'ellmer' `chat$chat_structured()` function will
    then be used to obtain the response. This type only useful when
    using an
    [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
    object. When `type` is set to "auto" and the `llm_provider` is an
    'ellmer' LLM provider, this type will be automatically selected (so
    it should not be necessary to set this option manually)

  Note that the "openai" and "ollama" types may also work for other APIs
  with a similar structure. Note furthermore that the "ellmer" type is
  still experimental and conversion between 'ellmer' schemas and R list
  schemas might contain bugs.

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the LLM response is a valid JSON object. Note
that the prompt wrap will parse the JSON response and return it as an R
object (usually a list)

## See also

Other pre_built_prompt_wraps:
[`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md),
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
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

Other answer_as_prompt_wraps:
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md)

Other json:
[`r_json_schema_to_example()`](https://kennispunttwente.github.io/tidyprompt/reference/r_json_schema_to_example.md)

## Examples

``` r
base_prompt <- "How can I solve 8x + 7 = -23?"

# This example will show how to enforce JSON format in the response,
#   with and without a schema, using the `answer_as_json()` prompt wrap.

# If you use type = 'auto', the function will automatically detect the
#   best way to enforce JSON based on the LLM provider you are using.

# `answer_as_json()` supports two ways of supplying a schema for structured output:
#   - 1) an 'ellmer' definition (e.g., `ellmer::type_object()`;
#         see https://ellmer.tidyverse.org/articles/structured-data.html)
#   - 2) a R list object representing a JSON schema
# `answer_as_json()` will convert the schema type which you supply to any
#   LLM provider; so, whether you use an ellmer LLM provider or another type,
#   you can supply either a R list object or an ellmer definition, and don't
#   have to worry about compatibility
# Supplying a schema as an ellmer definition is likely the easiest

# Below, we will show:
#  - 1) enforcing JSON with a schema; 'ellmer' definition
#  - 2) enforcing JSON with a schema; R list object
# -  3) enforcing JSON without a schema

#### Enforcing JSON with a schema (ellmer definition): ####

# Make an ellmer definition of structured output
#   For instance, a persona:
ellmer_schema <- ellmer::type_object(
  name = ellmer::type_string(),
  age = ellmer::type_integer(),
  hobbies = ellmer::type_array(ellmer::type_string())
)

if (FALSE) { # \dontrun{
  # Example Ellmer LLM provider
  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  # Example regular LLM provider
  tidyprompt_openai <- llm_provider_openai()$set_parameters(
    list(model = "gpt-4.1-mini")
  )

  # You can supply the ellmer definition to both types of LLM provider
  #   to generate an R list object adhering to the schema
  result_ellmer_x_ellmer <- "Create a persona" |>
    answer_as_json(ellmer_schema) |>
    send_prompt(ellmer_openai)

  result_tidyrpompt_x_ellmer <- "Create a persona" |>
    answer_as_json(ellmer_schema) |>
    send_prompt(tidyprompt_openai)
} # }


#### Enforcing JSON with a schema (R list object definition): ####

# Make a list representing a JSON schema,
#   which the LLM response must adhere to:
json_schema <- list(
  name = "steps_to_solve", # Required for OpenAI API
  description = NULL, # Optional for OpenAI API
  schema = list(
    type = "object",
    properties = list(
      steps = list(
        type = "array",
        items = list(
          type = "object",
          properties = list(
            explanation = list(type = "string"),
            output = list(type = "string")
          ),
          required = c("explanation", "output"),
          additionalProperties = FALSE
        )
      ),
      final_answer = list(type = "string")
    ),
    required = c("steps", "final_answer"),
    additionalProperties = FALSE
  )
  # 'strict' parameter is set as argument 'answer_as_json()'
)
# Note: when you are not using an OpenAI API, you can also pass just the
#   internal 'schema' list object to 'answer_as_json()' instead of the full
#   'json_schema' list object

# Generate example R object based on schema:
r_json_schema_to_example(json_schema)
#> $steps
#> $steps[[1]]
#> $steps[[1]]$explanation
#> [1] "..."
#> 
#> $steps[[1]]$output
#> [1] "..."
#> 
#> 
#> 
#> $final_answer
#> [1] "..."
#> 

if (FALSE) { # \dontrun{
  ## Text-based with schema (works for any provider/model):
  #   - Adds request to prompt for a JSON object
  #   - Adds schema to prompt
  #   - Extracts JSON from textual response (feedback for retry if no JSON received)
  #   - Validates JSON against schema with 'jsonvalidate' package (feedback for retry if invalid)
  #   - Parses JSON to R object
  json_4 <- base_prompt |>
    answer_as_json(schema = json_schema) |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # How can I solve 8x + 7 = -23?
  #
  # Your must format your response as a JSON object.
  #
  # Your JSON object should match this example JSON object:
  #   {
  #     "steps": [
  #       {
  #         "explanation": "...",
  #         "output": "..."
  #       }
  #     ],
  #     "final_answer": "..."
  #   }
  # --- Receiving response from LLM provider: ---
  # Here is the solution to the equation:
  #
  # ```
  # {
  #   "steps": [
  #     {
  #       "explanation": "First, we want to isolate the term with 'x' by
  #       subtracting 7 from both sides of the equation.",
  #       "output": "8x + 7 - 7 = -23 - 7"
  #     },
  #     {
  #       "explanation": "This simplifies to: 8x = -30",
  #       "output": "8x = -30"
  #     },
  #     {
  #       "explanation": "Next, we want to get rid of the coefficient '8' by
  #       dividing both sides of the equation by 8.",
  #       "output": "(8x) / 8 = (-30) / 8"
  #     },
  #     {
  #       "explanation": "This simplifies to: x = -3.75",
  #       "output": "x = -3.75"
  #     }
  #   ],
  #   "final_answer": "-3.75"
  # }
  # ```

  ## Ollama with schema:
  #   - Sets 'format' parameter to 'json', enforcing JSON
  #   - Adds request to prompt for a JSON object, as is recommended by the docs
  #   - Adds schema to prompt
  #   - Validates JSON against schema with 'jsonvalidate' package (feedback for retry if invalid)
  json_5 <- base_prompt |>
    answer_as_json(json_schema, type = "auto") |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # How can I solve 8x + 7 = -23?
  #
  # Your must format your response as a JSON object.
  #
  # Your JSON object should match this example JSON object:
  # {
  #   "steps": [
  #     {
  #       "explanation": "...",
  #       "output": "..."
  #     }
  #   ],
  #   "final_answer": "..."
  # }
  # --- Receiving response from LLM provider: ---
  # {
  #   "steps": [
  #     {
  #       "explanation": "First, subtract 7 from both sides of the equation to
  #       isolate the term with x.",
  #       "output": "8x = -23 - 7"
  #     },
  #     {
  #       "explanation": "Simplify the right-hand side of the equation.",
  #       "output": "8x = -30"
  #     },
  #     {
  #       "explanation": "Next, divide both sides of the equation by 8 to solve for x.",
  #       "output": "x = -30 / 8"
  #     },
  #     {
  #       "explanation": "Simplify the right-hand side of the equation.",
  #       "output": "x = -3.75"
  #     }
  #   ],
  #   "final_answer": "-3.75"
  # }

  ## OpenAI with schema:
  #   - Sets 'response_format' parameter to 'json_object', enforcing JSON
  #   - Adds json_schema to the API request, API enforces JSON adhering schema
  #   - Parses JSON to R object
  json_6 <- base_prompt |>
    answer_as_json(json_schema, type = "auto") |>
    send_prompt(llm_provider_openai())
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # How can I solve 8x + 7 = -23?
  # --- Receiving response from LLM provider: ---
  # {"steps":[
  # {"explanation":"Start with the original equation.",
  # "output":"8x + 7 = -23"},
  # {"explanation":"Subtract 7 from both sides to isolate the term with x.",
  # "output":"8x + 7 - 7 = -23 - 7"},
  # {"explanation":"Simplify the left side and the right side of the equation.",
  # "output":"8x = -30"},
  # {"explanation":"Now, divide both sides by 8 to solve for x.",
  # "output":"x = -30 / 8"},
  # {"explanation":"Simplify the fraction by dividing both the numerator and the
  # denominator by 2.",
  # "output":"x = -15 / 4"}
  # ], "final_answer":"x = -15/4"}

  # You can also use the R list object schema definition with an
  #  ellmer LLM provider; `answer_as_json()` will do the conversion for you
  json_7 <- base_prompt |>
    answer_as_json(json_schema) |>
    send_prompt(ellmer_openai)
} # }


#### Enforcing JSON without a schema: ####

if (FALSE) { # \dontrun{
  ## Text-based (works for any provider/model):
  #   Adds request to prompt for a JSON object
  #   Extracts JSON from textual response (feedback for retry if no JSON received)
  #   Parses JSON to R object
  json_1 <- base_prompt |>
    answer_as_json() |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # How can I solve 8x + 7 = -23?
  #
  # Your must format your response as a JSON object.
  # --- Receiving response from LLM provider: ---
  # Here is the solution to the equation formatted as a JSON object:
  #
  # ```
  # {
  #   "equation": "8x + 7 = -23",
  #   "steps": [
  #     {
  #       "step": "Subtract 7 from both sides of the equation",
  #       "expression": "-23 - 7"
  #     },
  #     {
  #       "step": "Simplify the expression on the left side",
  #       "result": "-30"
  #     },
  #     {
  #       "step": "Divide both sides by -8 to solve for x",
  #       "expression": "-30 / -8"
  #     },
  #     {
  #       "step": "Simplify the expression on the right side",
  #       "result": "3.75"
  #     }
  #   ],
  #   "solution": {
  #     "x": 3.75
  #   }
  # }
  # ```


  ## Ollama:
  #   - Sets 'format' parameter to 'json', enforcing JSON
  #   - Adds request to prompt for a JSON object, as is recommended by the docs
  #   - Parses JSON to R object
  json_2 <- base_prompt |>
    answer_as_json(type = "auto") |>
    send_prompt(llm_provider_ollama())
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # How can I solve 8x + 7 = -23?
  #
  # Your must format your response as a JSON object.
  # --- Receiving response from LLM provider: ---
  # {"steps": [
  #   "Subtract 7 from both sides to get 8x = -30",
  #   "Simplify the right side of the equation to get 8x = -30",
  #   "Divide both sides by 8 to solve for x, resulting in x = -30/8",
  #   "Simplify the fraction to find the value of x"
  # ],
  # "value_of_x": "-3.75"}


  ## OpenAI-type API without schema:
  #   - Sets 'response_format' parameter to 'json_object', enforcing JSON
  #   - Adds request to prompt for a JSON object, as is required by the API
  #   - Parses JSON to R object
  json_3 <- base_prompt |>
    answer_as_json(type = "auto") |>
    send_prompt(llm_provider_openai())
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # How can I solve 8x + 7 = -23?
  #
  # Your must format your response as a JSON object.
  # --- Receiving response from LLM provider: ---
  # {
  #   "solution_steps": [
  #     {
  #       "step": 1,
  #       "operation": "Subtract 7 from both sides",
  #       "equation": "8x + 7 - 7 = -23 - 7",
  #       "result": "8x = -30"
  #     },
  #     {
  #       "step": 2,
  #       "operation": "Divide both sides by 8",
  #       "equation": "8x / 8 = -30 / 8",
  #       "result": "x = -3.75"
  #     }
  #   ],
  #   "solution": {
  #     "x": -3.75
  #   }
  # }
} # }
```
