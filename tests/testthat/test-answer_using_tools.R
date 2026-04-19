# Fake function to test; requires some numeric input, gives back random number
# To verify tool call worked we'll verify if random number is in LLM response
secret_number <- sample(1000000:9999999, 1)
get_secret_number <- function(input = 12345) {
  return(secret_number)
}

# Check if a number is present in a string, ignoring commas, dots, or spaces
number_present_in_string <- function(string, number) {
  if (is.null(string) || is.null(number)) {
    return(FALSE)
  }

  # extract just the digits from the number
  digits <- gsub("\\D", "", as.character(number))
  if (digits == "") {
    return(FALSE)
  }

  # build a regex that allows commas, dots, or spaces between digits
  pieces <- strsplit(digits, "")[[1]]
  pattern <- paste0("(?<!\\d)", paste(pieces, collapse = "[,\\. ]?"), "(?!\\d)")

  grepl(pattern, string, perl = TRUE)
}

base_prompt <- "Call the function and tell me the output number"

test_that("text-based function calling works with base r function", {
  skip_test_if_no_openai()

  result <- "What are the files in my current directory?" |>
    answer_using_tools(dir, type = "text-based") |>
    send_prompt(llm_provider_openai()$set_parameters(list(
      model = "gpt-4.1-mini"
    )))

  expect_true(!is.null(result))
})

test_that("text-based function calling works with custom function", {
  skip_test_if_no_openai()

  # Example fake weather function to add to the prompt:
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
      return(temperature_celcius * 9 / 5 + 32)
    }
  }

  # Generate documentation for a function
  #   (based on formals, & help file if available)
  docs <- tools_get_docs(temperature_in_location)
  docs$description <- "Get the temperature in a location"
  docs$arguments$unit$description <- "Unit in which to return the temperature"
  docs$arguments$location$description <- "Location for which to return the temperature"
  docs$
  return$description <- "The temperature in the specified location and unit"
  temperature_in_location <- tools_add_docs(temperature_in_location, docs)

  prompt <- "Hi, what is the weather in Enschede? Give me Celcius degrees" |>
    answer_using_tools(temperature_in_location, type = "text-based")

  result <- prompt |>
    send_prompt(llm_provider_openai()$set_parameters(list(
      model = "gpt-4.1-mini"
    )))

  expect_true(!is.null(result))
})

test_that("native ollama function calling works", {
  skip_test_if_no_ollama()

  result <- base_prompt |>
    answer_using_tools(get_secret_number) |>
    send_prompt(llm_provider_ollama())

  expect_true(number_present_in_string(result, secret_number))
})

test_that("native openai function calling works (chat completions API, stream)", {
  skip_test_if_no_openai()

  result <- base_prompt |>
    answer_using_tools(get_secret_number, type = "openai") |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/chat/completions"
      )$set_parameters(list(model = "gpt-4.1-mini")),
      stream = TRUE
    )

  expect_true(number_present_in_string(result, secret_number))
})

test_that("native openai function calling works (chat completions API, non-stream)", {
  skip_test_if_no_openai()

  result <- base_prompt |>
    answer_using_tools(get_secret_number, type = "openai") |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/chat/completions"
      )$set_parameters(list(model = "gpt-4.1-mini")),
      stream = FALSE
    )

  expect_true(number_present_in_string(result, secret_number))
})

test_that("native openai function calling works (responses API, stream)", {
  skip_test_if_no_openai()

  prompt <- "What files are in my current directory?" |>
    answer_using_tools(dir, type = "openai")

  result <- base_prompt |>
    answer_using_tools(get_secret_number, type = "openai") |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/responses"
      )$set_parameters(list(model = "gpt-4.1-mini")),
      stream = TRUE
    )

  expect_true(number_present_in_string(result, secret_number))
})

test_that("native openai function calling works (responses API, non-stream)", {
  skip_test_if_no_openai()

  result <- base_prompt |>
    answer_using_tools(get_secret_number, type = "openai") |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/responses"
      )$set_parameters(list(model = "gpt-4.1-mini")),
      stream = FALSE
    )

  expect_true(number_present_in_string(result, secret_number))
})

test_that("function calling works with ellmer llm provider", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  result <- base_prompt |>
    answer_using_tools(get_secret_number) |>
    send_prompt(ellmer_openai)

  expect_true(number_present_in_string(result, secret_number))
})

test_that("function calling works with direct ellmer chat", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_chat <- ellmer::chat_openai(model = "gpt-4.1-mini")

  result <- base_prompt |>
    answer_using_tools(get_secret_number) |>
    send_prompt(ellmer_chat)

  expect_true(number_present_in_string(result, secret_number))
  expect_length(ellmer_chat$get_turns(), 0)
})

test_that("function calling works with ellmer tool definition", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  tool_def <- ellmer::tool(
    get_secret_number,
    name = "get_secret_number",
    description = "Get a secret number",
    arguments = list(
      input = ellmer::type_number()
    )
  )

  # Using ellmer LLM provider
  result_ellmer_llm_provider <- base_prompt |>
    answer_using_tools(tool_def) |>
    send_prompt(ellmer_openai)
  expect_true(number_present_in_string(
    result_ellmer_llm_provider,
    secret_number
  ))

  # Using tidyprompt LLM provider
  result_tidyprompt_llm_provider <- base_prompt |>
    answer_using_tools(tool_def) |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/responses"
      )$set_parameters(list(model = "gpt-4.1-mini"))
    )
  expect_true(number_present_in_string(
    result_tidyprompt_llm_provider,
    secret_number
  ))
})

test_that("messages_from_history omits non-replayable rows", {
  history <- data.frame(
    role = c("user", "assistant", "assistant", "tool", "assistant"),
    content = c(
      "Question",
      "Reasoning step",
      "~>> Calling function 'tool' with arguments:\n{}",
      "~>> Result:\n42",
      "Answer"
    ),
    hidden_from_llm = c(FALSE, TRUE, FALSE, FALSE, FALSE),
    tool_call = c(FALSE, FALSE, TRUE, FALSE, FALSE),
    tool_result = c(FALSE, FALSE, FALSE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )

  messages <- .messages_from_history(history)

  expect_equal(
    vapply(messages, `[[`, character(1), "content"),
    c("Question", "~>> Result:\n42", "Answer")
  )
  expect_equal(
    vapply(messages, `[[`, character(1), "role"),
    c("user", "tool", "assistant")
  )
})

test_that("text-based dispatch uses ellmer tool's declared name, not R symbol", {
  skip_if_not_installed("ellmer")

  add_xy <- function(x, y) x + y

  td <- ellmer::tool(
    add_xy,
    name = "sum_two",
    description = "Add two numbers",
    arguments = list(
      x = ellmer::type_number(),
      y = ellmer::type_number()
    )
  )

  state <- new.env(parent = emptyenv())
  state$call_n <- 0L

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      state <- self$parameters$.test_state
      state$call_n <- state$call_n + 1L

      if (state$call_n == 1L) {
        # Model calls the tool by its declared name
        reply <- '{"function": "sum_two", "arguments": {"x": 3, "y": 4}}'
      } else {
        reply <- "The answer is 7"
      }

      list(
        completed = dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = reply,
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL)
      )
    },
    parameters = list(.test_state = state),
    verbose = FALSE
  )

  result <- "What is 3 + 4?" |>
    answer_using_tools(td, type = "text-based") |>
    send_prompt(provider, verbose = FALSE)

  # If dispatch failed, the tool call would error and we'd never reach call 2
  expect_equal(state$call_n, 2L)
  expect_equal(result, "The answer is 7")
})

test_that("openai path uses ellmer tool's declared name in API payload", {
  skip_if_not_installed("ellmer")

  add_xy <- function(x, y) x + y

  td <- ellmer::tool(
    add_xy,
    name = "sum_two",
    description = "Add two numbers",
    arguments = list(
      x = ellmer::type_number(),
      y = ellmer::type_number()
    )
  )

  # Build prompt and extract the parameter_fn to inspect the OpenAI tool payload
  prompt <- "What is 3 + 4?" |>
    answer_using_tools(td, type = "openai")

  wraps <- get_prompt_wraps(prompt)
  # Find the wrap with a parameter_fn
  param_wrap <- NULL
  for (w in wraps) {
    if (!is.null(w$parameter_fn)) {
      param_wrap <- w
      break
    }
  }
  expect_false(is.null(param_wrap))

  # Call parameter_fn with a mock provider
  mock_provider <- list(tool_type = "openai", api_type = "openai")
  params <- param_wrap$parameter_fn(mock_provider)

  # The tools payload should have function.name = "sum_two"
  expect_true(!is.null(params$tools))
  expect_equal(params$tools[[1]][["function"]]$name, "sum_two")
})

test_that("tools_get_docs overrides attribute name when caller provides one", {
  my_fn <- function(x) x + 1
  docs_attr <- list(
    name = "original_name",
    description = "A test function",
    arguments = list(x = list(type = "number", description = "A number"))
  )
  attr(my_fn, "tidyprompt_tool_docs") <- docs_attr

  # Without explicit name, docs$name stays as attribute value
  docs_default <- tools_get_docs(my_fn)
  expect_equal(docs_default$name, "original_name")

  # With explicit name, docs$name is overridden

  docs_override <- tools_get_docs(my_fn, name = "dispatch_key")
  expect_equal(docs_override$name, "dispatch_key")
})
