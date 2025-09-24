test_that("answer using r can create linear model with data", {
  skip_test_if_no_ollama()

  # Prompt to linear model object in R
  model <- paste0(
    "Using my data, create a statistical model",
    " investigating the relationship between two variables."
  ) |>
    answer_using_r(
      objects_to_use = list(data = mtcars),
      evaluate_code = TRUE,
      return_mode = "object"
    ) |>
    prompt_wrap(
      validation_fn = function(x) {
        if (!inherits(x, "lm"))
          return(llm_feedback("The output should be a linear model object."))
        return(x)
      }
    ) |>
    send_prompt(llm_provider_ollama(), verbose = FALSE)

  # Check if the model is a linear model object
  expect_true(inherits(model, "lm"))
})

test_that("answer_using_r handles complex objects in formatted_output", {
  # Test that complex objects (like lists, functions, etc.) can be handled
  # in the formatted_output without causing errors
  
  # This test doesn't require an LLM provider since we're testing the 
  # extraction function directly
  skip_if_not_installed("callr")
  
  # Create a tidyprompt with answer_using_r wrapper
  tp <- "test" |>
    answer_using_r(
      evaluate_code = TRUE,
      return_mode = "formatted_output"
    )
  
  # Get the extraction function
  wraps <- get_prompt_wraps(tp)
  extraction_fn <- wraps[[1]]$extraction_fn
  
  # Test with R code that produces a complex object (list)
  mock_response <- '```r
complex_obj <- list(
  data = mtcars[1:3, 1:3],
  func = function(x) x + 1,
  plot_like = structure(list(x = 1:3, y = 4:6), class = "custom_plot")
)
complex_obj
```'
  
  # This should not throw an error
  expect_no_error({
    result <- extraction_fn(mock_response)
  })
  
  # The result should be a character string (formatted output)
  expect_type(result, "character")
  expect_true(length(result) == 1)
  
  # Should contain the expected sections
  expect_true(grepl("--- R code: ---", result, fixed = TRUE))
  expect_true(grepl("--- Console output: ---", result, fixed = TRUE))
  expect_true(grepl("--- Last object: ---", result, fixed = TRUE))
})
