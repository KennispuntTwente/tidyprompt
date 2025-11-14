# Add tidyprompt function documentation to a function

This function adds documentation to a custom function. This
documentation is used to extract information about the function's name,
description, arguments, and return value. This information is used to
provide an LLM with information about the functions, so that the LLM can
call R functions. The intended use of this function is to add
documentation to custom functions that do not have help files;
[`tools_get_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_get_docs.md)
may generate documentation from a help file when the function is part of
base R or a package.

If a function already has documentation, the documentation added by this
function may overwrite it. If you wish to modify existing documentation,
you may make a call to
[`tools_get_docs()`](https://kennispunttwente.github.io/tidyprompt/reference/tools_get_docs.md)
to extract the existing documentation, modify it, and then call
`tools_add_docs()` to add the modified documentation.

## Usage

``` r
tools_add_docs(func, docs)
```

## Arguments

- func:

  A function object

- docs:

  A list with the following elements:

  - 'name': (optional) The name of the function. If not provided, the
    function name will be extracted from the function object. Use this
    parameter to override the function name if necessary

  - 'description': A description of the function and its purpose

  - 'arguments': A named list of arguments with descriptions. Each
    argument is a list which may contain:

    - 'description': A description of the argument and its purpose. Not
      required or used for native function calling (e.g., with OpenAI),
      but recommended for text-based function calling

    - 'type': The type of the argument. This should be one of:
      'integer', 'numeric', 'logical', 'string', 'match.arg', 'vector
      integer', 'vector numeric', 'vector logical', 'vector string'. For
      arguments which are named lists, 'type' should be a named list
      which contains the types of the elements. For type 'match.arg',
      the possible values should be passed as a vector under
      'default_value'. 'type' is required for native function calling
      (with, e.g., OpenAI) but may also be useful to provide for
      text-based function calling, in which it will be added to the
      prompt introducing the function

    - 'default_value': The default value of the argument. This is only
      required when 'type' is set to 'match.arg'. It should then be a
      vector of possible values for the argument. In other cases, it is
      not required; for native function calling, it is not used in other
      cases; for text-based function calling, it may be useful to
      provide the default value, which will be added to the prompt
      introducing the function

  - 'return': A list with the following elements:

    - 'description': A description of the return value or the side
      effects of the function

## Value

The function object with the documentation added as an attribute
('tidyprompt_tool_docs')

## See also

Other tools:
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md),
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
