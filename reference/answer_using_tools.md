# Enable LLM to call R functions (and/or MCP server tools)

This function adds the ability for the a LLM to call R functions. Users
can specify a list of functions that the LLM can call, and the prompt
will be modified to include information, as well as an accompanying
extraction function to call the functions (handled by
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)).
Documentation for the functions is extracted from the help file (if
available), or from documentation added by
[`tools_add_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_add_docs.md).
Users can also provide an 'ellmer' tool definition (see
[`ellmer::tool()`](https://ellmer.tidyverse.org/reference/tool.html);
['ellmer'
documentation](https://ellmer.tidyverse.org/articles/tool-calling.html)).
Model Context Protocol (MCP) tools from MCP servers, as returned from
[`mcptools::mcp_tools()`](https://posit-dev.github.io/mcptools/reference/client.html),
may also be used. Regardless of which type of tool definition is
provided, the function will work with both 'ellmer' and regular LLM
providers (the function converts between the two types as needed).

## Usage

``` r
answer_using_tools(
  prompt,
  tools = list(),
  type = c("auto", "openai", "ollama", "ellmer", "text-based")
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- tools:

  An R function, an 'ellmer' tool definition (from
  [`ellmer::tool()`](https://ellmer.tidyverse.org/reference/tool.html)),
  or a list of either, which the LLM will be able to call. If an R
  function is passed which has been documented in a help file (e.g.,
  because it is part of a package), the documentation will be parsed
  from the help file. If it is a custom function, documentation should
  be added with
  [`tools_add_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_add_docs.md)
  or with
  [`ellmer::tool()`](https://ellmer.tidyverse.org/reference/tool.html).
  Note that you can also provide Model Context Protocol (MCP) tools from
  MCP servers as returned from
  [`mcptools::mcp_tools()`](https://posit-dev.github.io/mcptools/reference/client.html)

- type:

  (optional) The way that tool calling should be enabled. "auto" will
  automatically determine the type based on `llm_provider$api_type` or
  'llm_provider\$tool_type' (if set; 'tool_type' overrides 'api_type'
  determination) (note that this may not consider model compatibility,
  and could lead to errors; set 'type' manually if errors occur).
  "openai" and "ollama" will set the relevant API parameters. "ellmer"
  will register the tool in the 'ellmer' chat object of the LLM
  provider; note that this will only work for an
  [`llm_provider_ellmer()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_provider_ellmer.md)
  ("auto" will always set the type to "ellmer" if you are using an
  'ellmer' LLM provider). "text-based" will provide function definitions
  in the prompt, extract function calls from the LLM response, and call
  the functions, providing the results back via
  [`llm_feedback()`](https://kennispunttwente.github.io/tidyprompt/reference/llm_feedback.md).
  "text-based" always works, but may be inefficient for APIs that
  support tool calling natively. Note that when using "openai",
  "ollama", or "ellmer", tool calls are not counted as interactions by
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
  and may continue indefinitely unless restricted by other means

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will allow the LLM to call the given R functions when evaluating
the prompt with
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)

## Details

Note that conversion between 'tidyprompt' and 'ellmer' tool definitions
is experimntal and might contain bugs.

## See also

[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md)
[`tools_get_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_get_docs.md)

Other pre_built_prompt_wraps:
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md),
[`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md),
[`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md),
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_sql()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_sql.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other answer_using_prompt_wraps:
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_sql()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_sql.md)

Other tools:
[`tools_add_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_add_docs.md),
[`tools_get_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_get_docs.md)

## Examples

``` r
# When using functions from base R or R packages,
#   documentation is automatically extracted from help files:
prompt_with_dir_function <- "What are the files in my current directory?" |>
  answer_using_tools(dir) # The 'dir' function is from base R
#> ! `answer_using_tools()`:
#> * Automatically determining type based on 'llm_provider$api_type';
#> (or 'llm_provider$tool_type' if set); this does not consider model compatability
#> * Manually set argument 'type' if errors occur ("text-based" always works)
#> * Use `options(tidyprompt.warn.auto.tools = FALSE)` to suppress this warning
if (FALSE) { # \dontrun{
  send_prompt(prompt_with_dir_function)
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   What are the files in my current directory?
  #   --- Receiving response from LLM provider: ---
  #   Calling function 'nm' with arguments:
  #   {
  #     "all.files": true,
  #     "full.names": false,
  #     "ignore.case": false,
  #     "include.dirs": false,
  #     "no..": false,
  #     "path": "./",
  #     "pattern": "*",
  #     "recursive": false
  #   }
  # Result:
  #   .git, .github, .gitignore, .Rbuildignore, .Rhistory, ...
  # The files in your current directory are:
  #   .git, .github, .gitignore, .Rbuildignore, .Rhistory, ...
  # [1] "The files in your current directory are:\n\n .git, .github, ..."
} # }

# Users may provide custom functions in two ways:
#   1) as a function object, optionally documented with `tools_get_docs()`, or
#   2) as an 'ellmer' tool definition, using `ellmer::tool()`

# Take this fake weather function as an example:
temperature_in_location <- function(
  location = c("Amsterdam", "Utrecht", "Enschede"),
  unit = c("Celcius", "Fahrenheit")
) {
  location <- match.arg(location)
  unit <- match.arg(unit)

  temperature_celcius <- switch(
    location,
    "Amsterdam" = 32.5,
    "Utrecht" = 19.8,
    "Enschede" = 22.7
  )

  if (unit == "Celcius") {
    return(temperature_celcius)
  } else {
    return(temperature_celcius * 9/5 + 32)
  }
}


# 1: `tools_add_docs()` --------------------------------------------------------

# Generate documentation for a function, based on formals & help file
docs <- tools_get_docs(temperature_in_location)

# The types get inferred from the function's formals
# However, descriptions are still missing as the function is not from a package
# We can modify the documentation object to add descriptions:
docs$description <- "Get the temperature in a location"
docs$arguments$unit$description <- "Unit in which to return the temperature"
docs$arguments$location$description <- "Location for which to return the temperature"
docs$return$description <- "The temperature in the specified location and unit"
# (See `?tools_add_docs` for more details on the structure of the documentation)

# When we are satisfied with the documentation, we can add it to the function:
temperature_in_location <- tools_add_docs(temperature_in_location, docs)

prompt_with_weather_function <-
  "What is the weather in Enschede? Give me Celcius degrees" |>
  answer_using_tools(temperature_in_location)
#> ! `answer_using_tools()`:
#> * Automatically determining type based on 'llm_provider$api_type';
#> (or 'llm_provider$tool_type' if set); this does not consider model compatability
#> * Manually set argument 'type' if errors occur ("text-based" always works)
#> * Use `options(tidyprompt.warn.auto.tools = FALSE)` to suppress this warning
if (FALSE) { # \dontrun{
  send_prompt(prompt_with_weather_function)
  # --- Sending request to LLM provider (llama3.1:8b): ---
  #   What is the weather in Enschede? Give me Celcius degrees
  #   --- Receiving response from LLM provider: ---
  #   Calling function 'temperature_in_location' with arguments:
  #   {
  #     "location": "Enschede",
  #     "unit": "Celcius"
  #   }
  # Result:
  #   22.7
  # The temperature in Enschede is 22.7 Celcius degrees.
  # [1] "The temperature in Enschede is 22.7 Celcius degrees."
} # }

# 2: `ellmer::tool()` -----------------------------------------------

# Alternatively, we can define the function as an 'ellmer' tool

temperature_in_location_ellmer <- ellmer::tool(
  temperature_in_location,
  name = "get_temperature",
  description = "Get the temperature in a location",
  arguments = list(
    location = ellmer::type_string(
      "Location for which to return the temperature", required = TRUE
    ),
    unit = ellmer::type_string(
      "Unit in which to return the temperature", required = TRUE
    )
  )
)

prompt_with_weather_function_ellmer <-
  "What is the weather in Utrecht? Give me Fahrenheit degrees" |>
  answer_using_tools(temperature_in_location_ellmer)
#> ! `answer_using_tools()`:
#> * Automatically determining type based on 'llm_provider$api_type';
#> (or 'llm_provider$tool_type' if set); this does not consider model compatability
#> * Manually set argument 'type' if errors occur ("text-based" always works)
#> * Use `options(tidyprompt.warn.auto.tools = FALSE)` to suppress this warning
if (FALSE) { # \dontrun{
  send_prompt(prompt_with_weather_function_ellmer)
  # ...
} # }

# Because `mcptools::mcp_tools()` returns a list of `ellmer:tool()` tools,
#   you can also use Model Context Protocol (MCP) server tools with
#   `answer_using_tools()`:
if (FALSE) { # \dontrun{
  prompt_using_mcp_tools <- mcptools::mcp_tools()
  "Push my latest commit to GitHub" |>
    answer_using_tools(mcp_tools)
  send_prompt(prompt_using_mcp_tools)
} # }

# `answer_using_tools()` will automatically attempt to use the most appropriate
#   way of sending the tool to the LLM

# If you use a LLM provider of type 'ollama' or 'openai',
#   it will automatically convert the tool definition to parameters
#   appropriate for those APIs
# If you use a LLM provider of type 'ellmer', it will call the appropriate
#   ellmer function directly which will handle the tool call for various
#   providers
# Note that both tool definitions from `tools_add_docs()` and `ellmer::tool()`
#   will work with any LLM provider; `answer_using_tools()` can convert
#   the two types of tool definitions to each other when needed
if (FALSE) { # \dontrun{
  ollama <- llm_provider_ollama()
  # Ollama LLM provider:
  "What is the weather in Amsterdam? Give me Fahrenheit degrees" |>
    answer_using_tools(temperature_in_location) |>
    send_prompt(ollama)

  # Ollama LLM provider also works with `ellmer::tool()` definitions:
  "What is the weather in Amsterdam? Give me Celcius degrees" |>
    answer_using_tools(temperature_in_location_ellmer) |>
    send_prompt(ollama)

  # Similar for OpenAI API:
  openai <- llm_provider_openai()
  "What is the weather in Amsterdam? Give me Celcius degrees" |>
    answer_using_tools(temperature_in_location) |>
    send_prompt(openai)
  # ...

  # Ellmer LLM provider:
  ellmer <- llm_provider_ellmer(ellmer::chat_openai())
  "What is the weather in Amsterdam? Give me Celcius degrees" |>
    answer_using_tools(temperature_in_location_ellmer) |>
    send_prompt(ellmer)

  # Also works with `tools_add_docs()` definition:
  "What is the weather in Amsterdam? Give me Celcius degrees" |>
    answer_using_tools(temperature_in_location) |>
    send_prompt(ellmer)
} # }
```
