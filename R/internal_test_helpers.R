#' @title Skip Tests if Ollama Server is Unavailable
#'
#' @description Helper function for unit tests that skips the test if the local
#' Ollama server is not running.
#'
#' @details The function sends a request to the Ollama server at
#' `http://localhost:11434`. If the server is not running or the request fails,
#'  the test is skipped with an appropriate message.
#'
#' @param do_not_run Logical indicating whether to skip the test even if the
#' Ollama server is running. Temporarily set to `TRUE` to skip the tests
#'
#' @return testthat skip object or NULL
#'
#' @noRd
#' @keywords internal
skip_test_if_no_ollama <- function(do_not_run = FALSE) {
  if (do_not_run) {
    return(
      testthat::skip("skip test: Skipping test even if Ollama is available")
    )
  }

  if (!ollama_available()) {
    return(testthat::skip("skip test: Ollama not available"))
  }

  return(invisible(NULL))
}

ollama_available <- function(
  url = Sys.getenv("OLLAMA_URL", unset = "http://localhost:11434")
) {
  req <- httr2::request(url)

  # Try performing the request and catch any errors
  ollama_running <- tryCatch(
    {
      resp <- httr2::req_perform(req)
      if (resp$status_code == 200) {
        TRUE
      } else {
        FALSE
      }
    },
    error = function(e) {
      FALSE # If there's an error, assume the server is not running
    }
  )

  return(ollama_running)
}

#' Skip tests if OpenAI model is unavailable
#'
#' Helper function for unit tests that skips the test if the OpenAI API is not available.
#' The function sends a request to the OpenAI API to check available models.
#' If there is no valid API key or the request fails, the test is skipped with an appropriate message.
#'
#' @param do_not_run Logical indicating whether to skip the test even if the
#' OpenAI API is available. Temporarily set to `TRUE` to skip the tests
#'
#' @return testthat skip object or NULL
#'
#' @noRd
#' @keywords internal
skip_test_if_no_openai <- function(do_not_run = FALSE) {
  if (do_not_run) {
    return(
      testthat::skip("skip test: Skipping test even if OpenAI is available")
    )
  }

  if (!openai_available()) {
    return(testthat::skip("skip test: OpenAI not available"))
  }

  return(invisible(NULL))
}

openai_available <- function(
  url = Sys.getenv("OPENAI_URL", unset = "https://api.openai.com"),
  api_key = Sys.getenv("OPENAI_API_KEY")
) {
  models_endpoint <- paste0(url, "/v1/models")

  if (is.null(api_key) | api_key == "") {
    return(testthat::skip("skip test: OpenAI API key not found"))
  }

  req <- httr2::request(models_endpoint) |>
    httr2::req_headers(
      "Content-Type" = "application/json",
      "Authorization" = paste("Bearer", api_key)
    )

  openai_available <- tryCatch(
    {
      resp <- httr2::req_perform(req)
      if (resp$status_code == 200) {
        TRUE
      } else {
        FALSE
      }
    },
    error = function(e) {
      FALSE
    }
  )

  return(openai_available)
}
