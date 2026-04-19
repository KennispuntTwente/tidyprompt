test_that("answer_as_dataframe extracts a data frame from structured JSON", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      reply <- jsonlite::toJSON(
        list(
          rows = list(
            list(name = "Alice", age = 32L),
            list(name = "Bob", age = 28L)
          )
        ),
        auto_unbox = TRUE
      )
      reply <- as.character(reply)

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
    verbose = FALSE
  )

  schema <- list(
    type = "object",
    properties = list(
      name = list(type = "string"),
      age = list(type = "integer")
    ),
    required = c("name", "age"),
    additionalProperties = FALSE
  )

  result <- "Extract the people in the text." |>
    answer_as_dataframe(schema, type = "text-based") |>
    send_prompt(provider, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(names(result), c("name", "age"))
  expect_equal(nrow(result), 2)
  expect_equal(result$name, c("Alice", "Bob"))
  expect_equal(result$age, c(32L, 28L))
})

test_that("answer_as_dataframe accepts array-of-rows schemas", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      reply <- jsonlite::toJSON(
        list(
          rows = list(
            list(name = "Alice", age = 32L),
            list(name = "Bob", age = 28L)
          )
        ),
        auto_unbox = TRUE
      )
      reply <- as.character(reply)

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
    verbose = FALSE
  )

  schema <- list(
    type = "array",
    items = list(
      type = "object",
      properties = list(
        name = list(type = "string"),
        age = list(type = "integer")
      ),
      required = c("name", "age"),
      additionalProperties = FALSE
    )
  )

  result <- "Extract the people in the text." |>
    answer_as_dataframe(schema, type = "text-based") |>
    send_prompt(provider, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(result$age, c(32L, 28L))
})

test_that("answer_as_dataframe accepts wrapper-object schemas with extra fields", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      reply <- jsonlite::toJSON(
        list(
          rows = list(
            list(name = "Alice", age = 32L),
            list(name = "Bob", age = 28L)
          )
        ),
        auto_unbox = TRUE
      )
      reply <- as.character(reply)

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
    verbose = FALSE
  )

  # Wrapper schema with rows + an extra field (count)
  schema <- list(
    type = "object",
    properties = list(
      rows = list(
        type = "array",
        items = list(
          type = "object",
          properties = list(
            name = list(type = "string"),
            age = list(type = "integer")
          ),
          required = c("name", "age"),
          additionalProperties = FALSE
        )
      ),
      count = list(type = "integer")
    ),
    required = c("rows", "count")
  )

  result <- "Extract the people." |>
    answer_as_dataframe(schema, type = "text-based") |>
    send_prompt(provider, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(names(result), c("name", "age"))
  expect_equal(result$name, c("Alice", "Bob"))
})

test_that("answer_as_dataframe unwraps wrapper with object-valued sibling", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      reply <- jsonlite::toJSON(
        list(
          rows = list(
            list(name = "Alice", age = 32L),
            list(name = "Bob", age = 28L)
          )
        ),
        auto_unbox = TRUE
      )
      reply <- as.character(reply)

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
    verbose = FALSE
  )

  # Wrapper schema with rows + an object-valued metadata field
  schema <- list(
    type = "object",
    properties = list(
      rows = list(
        type = "array",
        items = list(
          type = "object",
          properties = list(
            name = list(type = "string"),
            age = list(type = "integer")
          ),
          required = c("name", "age"),
          additionalProperties = FALSE
        )
      ),
      meta = list(
        type = "object",
        properties = list(
          total = list(type = "integer")
        )
      )
    ),
    required = c("rows")
  )

  result <- "Extract the people." |>
    answer_as_dataframe(schema, type = "text-based") |>
    send_prompt(provider, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(names(result), c("name", "age"))
  expect_equal(result$name, c("Alice", "Bob"))
})

test_that("answer_as_dataframe treats row schema with a 'rows' column correctly", {
  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      reply <- jsonlite::toJSON(
        list(
          rows = list(
            list(
              id = 1L,
              rows = 10L
            ),
            list(
              id = 2L,
              rows = 20L
            )
          )
        ),
        auto_unbox = TRUE
      )
      reply <- as.character(reply)

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
    verbose = FALSE
  )

  # Row schema where "rows" is a regular integer column, not a wrapper
  schema <- list(
    type = "object",
    properties = list(
      id = list(type = "integer"),
      rows = list(type = "integer")
    ),
    required = c("id", "rows")
  )

  result <- "Extract data." |>
    answer_as_dataframe(schema, type = "text-based") |>
    send_prompt(provider, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true("id" %in% names(result))
  expect_true("rows" %in% names(result))
  expect_equal(result$id, c(1L, 2L))
  expect_equal(result$rows, c(10L, 20L))
})

test_that("answer_as_dataframe retries when row bounds are violated", {
  state <- new.env(parent = emptyenv())
  state$call_n <- 0L

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      state <- self$parameters$.test_state
      state$call_n <- state$call_n + 1L

      rows <- if (state$call_n == 1L) {
        list(
          list(name = "Alice", age = 32L),
          list(name = "Bob", age = 28L),
          list(name = "Cara", age = 41L)
        )
      } else {
        list(
          list(name = "Alice", age = 32L),
          list(name = "Bob", age = 28L)
        )
      }

      reply <- jsonlite::toJSON(list(rows = rows), auto_unbox = TRUE)
      reply <- as.character(reply)

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

  schema <- list(
    type = "object",
    properties = list(
      name = list(type = "string"),
      age = list(type = "integer")
    ),
    required = c("name", "age"),
    additionalProperties = FALSE
  )

  result <- "Extract exactly two people." |>
    answer_as_dataframe(
      schema,
      min_rows = 2,
      max_rows = 2,
      type = "text-based"
    ) |>
    send_prompt(provider, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_equal(state$call_n, 2L)
})

test_that("answer_as_dataframe uses native ellmer structured results", {
  skip_if_not_installed("ellmer")

  provider <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      list(
        completed = dplyr::bind_rows(
          chat_history,
          data.frame(
            role = "assistant",
            content = "Structured result",
            stringsAsFactors = FALSE
          )
        ),
        http = list(request = NULL, response = NULL),
        native_structured_result = list(
          rows = data.frame(
            name = c("Alice", "Bob"),
            age = c(32, 28),
            stringsAsFactors = FALSE
          )
        )
      )
    },
    verbose = FALSE,
    api_type = "ellmer"
  )

  schema <- ellmer::type_object(
    name = ellmer::type_string(),
    age = ellmer::type_integer()
  )

  result <- "Extract the people in the text." |>
    answer_as_dataframe(schema) |>
    send_prompt(provider, verbose = FALSE)

  expect_s3_class(result, "data.frame")
  expect_equal(result$name, c("Alice", "Bob"))
  expect_equal(result$age, c(32, 28))
})
