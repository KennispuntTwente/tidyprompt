test_that("answer_as_json (text-based) works without schema", {
  skip_test_if_no_openai()

  response <- "Create a very short persona" |>
    answer_as_json(type = "text-based") |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/responses"
      )$set_parameters(list(model = "gpt-4.1-mini"))
    )

  expect_true(is.list(response), info = "Response should be a list")
})

test_that("answer_as_json (text-based) works with json schema", {
  skip_test_if_no_openai()

  schema <- list(
    "$schema" = "http://json-schema.org/draft-04/schema#",
    title = "Persona",
    type = "object",
    properties = list(
      name = list(type = "string", description = "The persona's name"),
      age = list(
        type = "integer",
        minimum = 0,
        description = "The persona's age"
      ),
      gender = list(
        type = "string",
        enum = c("Male", "Female", "Non-binary", "Other"),
        description = "The persona's gender"
      ),
      hobbies = list(
        type = "array",
        items = list(type = "string"),
        description = "List of hobbies"
      ),
      pet = list(
        type = "object",
        description = "Information about the persona's pet",
        properties = list(
          name = list(type = "string", description = "The pet's name"),
          age = list(
            type = "integer",
            minimum = 0,
            description = "The pet's age"
          ),
          species = list(
            type = "string",
            enum = c("Dog", "Cat", "Fish", "Bird", "Other"),
            description = "The pet's species"
          )
        ),
        required = c("name", "age", "species")
      )
    ),
    required = c("name", "age", "gender", "hobbies", "pet"),
    additionalProperties = FALSE
  )

  r_json_schema_to_example(schema)

  response <- "Create a persona" |>
    answer_as_json(schema, schema_strict = TRUE, type = "text-based") |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/responses"
      )$set_parameters(list(model = "gpt-4.1-mini"))
    )

  expect_true(is.list(response), info = "Response should be a list")

  # Validate top-level properties
  expect_true(
    all(
      c(
        "name",
        "age",
        "gender",
        "hobbies",
        "pet"
      ) %in%
        names(response)
    )
  )

  # Validate `name`
  expect_true(is.character(response$name), info = "`name` should be a string")
  expect_true(nchar(response$name) > 0, info = "`name` should not be empty")

  # Validate `age`
  expect_true(is.numeric(response$age), info = "`age` should be numeric")
  expect_true(response$age >= 0, info = "`age` should be non-negative")

  # Validate `ge  nder`
  expect_true(
    is.character(response$gender),
    info = "`gender` should be a string"
  )
  expect_true(
    response$gender %in% c("Male", "Female", "Non-binary", "Other"),
    info = "`gender` should be one of the allowed values"
  )

  # Validate `hobbies`
  expect_true(
    is.list(response$hobbies) || is.character(response$hobbies),
    info = "`hobbies` should be a list or a character vector"
  )
  expect_true(
    all(sapply(response$hobbies, is.character)),
    info = "All items in `hobbies` should be strings"
  )

  # Validate `pet` object
  expect_true(is.list(response$pet), info = "`pet` should be a list")
  expect_true(
    is.character(response$pet$name),
    info = "`pet$name` should be a string"
  )
  expect_true(
    nchar(response$pet$name) > 0,
    info = "`pet$name` should not be empty"
  )
  expect_true(
    is.numeric(response$pet$age),
    info = "`pet$age` should be numeric"
  )
  expect_true(response$pet$age >= 0, info = "`pet$age` should be non-negative")
  expect_true(
    is.character(response$pet$species),
    info = "`pet$species` should be a string"
  )
  expect_true(
    response$pet$species %in% c("Dog", "Cat", "Fish", "Bird", "Other"),
    info = "`pet$species` should be one of the allowed values"
  )
})

test_that("answer_as_json (openai via auto) works", {
  skip_test_if_no_openai()

  schema <- list(
    "$schema" = "http://json-schema.org/draft-04/schema#",
    title = "Persona",
    type = "object",
    properties = list(
      name = list(type = "string", description = "The persona's name"),
      age = list(type = "integer", description = "The persona's age"),
      gender = list(
        type = "string",
        enum = c("Male", "Female", "Non-binary", "Other"),
        description = "The persona's gender"
      ),
      hobbies = list(
        type = "array",
        items = list(type = "string"),
        description = "List of hobbies"
      )
    ),
    required = c("name", "age", "gender", "hobbies"),
    additionalProperties = FALSE
  )

  expect_no_error(
    "Create a persona" |>
      answer_as_json(schema, type = "auto") |>
      send_prompt(llm_provider_openai())
  )

  expect_no_error(
    "Create a very short persona" |>
      answer_as_json(type = "auto") |>
      send_prompt(llm_provider_openai())
  )
})

test_that("answer_as_json (ollama via auto) works", {
  skip_test_if_no_ollama()

  schema <- list(
    "$schema" = "http://json-schema.org/draft-04/schema#",
    title = "Persona",
    type = "object",
    properties = list(
      name = list(type = "string", description = "The persona's name"),
      age = list(type = "integer", description = "The persona's age"),
      gender = list(
        type = "string",
        enum = c("Male", "Female", "Non-binary", "Other"),
        description = "The persona's gender"
      ),
      hobbies = list(
        type = "array",
        items = list(type = "string"),
        description = "List of hobbies"
      )
    ),
    required = c("name", "age", "gender", "hobbies"),
    additionalProperties = FALSE
  )

  expect_no_error(
    "Create a persona" |>
      answer_as_json(schema, type = "auto") |>
      send_prompt(llm_provider_ollama())
  )

  expect_no_error(
    "Create a very short persona" |>
      answer_as_json(type = "auto") |>
      send_prompt(llm_provider_ollama())
  )
})

test_that("answer_as_json (compatability with ellmer) works", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  # Persona validation function
  is_valid_persona <- function(persona) {
    if (!is.list(persona)) return(FALSE)

    required_fields <- c("name", "age", "hobbies")
    if (!all(required_fields %in% names(persona))) return(FALSE)

    if (!is.character(persona$name) || length(persona$name) != 1) return(FALSE)
    if (!is.numeric(persona$age) || length(persona$age) != 1) return(FALSE)
    if (
      !is.vector(persona$hobbies) || !all(sapply(persona$hobbies, is.character))
    )
      return(FALSE)

    TRUE
  }

  # Ellmer LLM provider
  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  # Ellmer schema
  ellmer_schema <- ellmer::type_object(
    name = ellmer::type_string(),
    age = ellmer::type_integer(),
    hobbies = ellmer::type_array(ellmer::type_string())
  )

  # Ellmer LLM provider with Ellmer schema
  result_ellmer_x_ellmer <- "Create a persona" |>
    answer_as_json(ellmer_schema) |>
    send_prompt(ellmer_openai)
  expect_true(is_valid_persona(result_ellmer_x_ellmer))

  # Regular LLM provider with Ellmer schema
  result_tidyrpompt_x_ellmer <- "Create a persona" |>
    answer_as_json(ellmer_schema) |>
    send_prompt(
      llm_provider_openai(
        url = "https://api.openai.com/v1/responses"
      )$set_parameters(list(model = "gpt-4.1-mini"))
    )
  expect_true(is_valid_persona(result_tidyrpompt_x_ellmer))

  # Regular schema
  schema <- list(
    "$schema" = "http://json-schema.org/draft-04/schema#",
    title = "Persona",
    type = "object",
    properties = list(
      name = list(type = "string", description = "The persona's name"),
      age = list(type = "integer", description = "The persona's age"),
      hobbies = list(
        type = "array",
        items = list(type = "string"),
        description = "List of hobbies"
      )
    ),
    required = c("name", "age", "hobbies"),
    additionalProperties = FALSE
  )

  # Ellmer LLM provider with regular schema
  result_ellmer_x_regular <- "Create a persona" |>
    answer_as_json(schema) |>
    send_prompt(ellmer_openai)
  expect_true(is_valid_persona(result_ellmer_x_regular))
})

test_that("answer_as_json + llm_provider_ellmer: scalar types", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  # type_string()
  res_str <- "Return the string 'hello' only." |>
    answer_as_json(ellmer::type_string()) |>
    send_prompt(ellmer_openai)
  expect_true(is.character(res_str) && length(res_str) == 1)

  # type_integer()
  res_int <- "Return the integer 7 only." |>
    answer_as_json(ellmer::type_integer()) |>
    send_prompt(ellmer_openai)
  expect_true(is.numeric(res_int) && length(res_int) == 1)
  expect_equal(as.integer(res_int), 7L)

  # type_number()
  res_num <- "Return the number 3.14 only." |>
    answer_as_json(ellmer::type_number()) |>
    send_prompt(ellmer_openai)
  expect_true(is.numeric(res_num) && length(res_num) == 1)
  expect_gt(res_num, 3)
  expect_lt(res_num, 3.2)

  # type_boolean()
  res_bool <- "Return the boolean true only." |>
    answer_as_json(ellmer::type_boolean()) |>
    send_prompt(ellmer_openai)
  expect_true(is.logical(res_bool) && length(res_bool) == 1)

  # type_enum()
  allowed <- c("Technology", "Sports", "Politics")
  res_enum <- "Categorize: 'AI chips surge in demand'. Choose one of Technology, Sports, Politics; return only the category." |>
    answer_as_json(ellmer::type_enum(allowed)) |>
    send_prompt(ellmer_openai)
  enum_val <- if (is.factor(res_enum)) as.character(res_enum) else res_enum
  expect_true(is.character(enum_val) && enum_val %in% allowed)
})

test_that("answer_as_json + llm_provider_ellmer: arrays of scalars", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  # vector of integers
  res_int_vec <- "Return exactly: 18, 21, 30." |>
    answer_as_json(ellmer::type_array(ellmer::type_integer())) |>
    send_prompt(ellmer_openai)
  expect_true(is.numeric(res_int_vec))
  expect_length(res_int_vec, 3)
  expect_equal(as.integer(res_int_vec), c(18L, 21L, 30L))

  # vector of numbers
  res_num_vec <- "Return exactly: 1.5, 2.0, 2.5." |>
    answer_as_json(ellmer::type_array(ellmer::type_number())) |>
    send_prompt(ellmer_openai)
  expect_true(is.numeric(res_num_vec))
  expect_equal(length(res_num_vec), 3)
  expect_true(all(res_num_vec > 0))

  # vector of enums
  allowed <- c("red", "green", "blue")
  res_enum_vec <- "Return these colours in order: red, green, blue." |>
    answer_as_json(ellmer::type_array(ellmer::type_enum(allowed))) |>
    send_prompt(ellmer_openai)
  expect_true(is.character(res_enum_vec) || is.factor(res_enum_vec))
  if (is.factor(res_enum_vec)) res_enum_vec <- as.character(res_enum_vec)
  expect_equal(res_enum_vec, allowed)
})

test_that("answer_as_json + llm_provider_ellmer: arrays of objects -> data.frame", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  prompt <- r"(
    * John Smith. Age: 30. Height: 180 cm. Weight: 80 kg.
    * Jane Doe. Age: 25. Height: 165 cm. Weight: 50 kg.
    * Jose Rodriguez. Age: 40. Height: 190 cm. Weight: 90 kg.
  )"

  type_person <- ellmer::type_object(
    name = ellmer::type_string(),
    age = ellmer::type_integer(),
    height = ellmer::type_number("in cm"),
    weight = ellmer::type_number("in kg")
  )
  type_people <- ellmer::type_array(type_person)

  df <- prompt |>
    answer_as_json(type_people) |>
    send_prompt(ellmer_openai)

  expect_s3_class(df, "data.frame")
  expect_true(all(c("name", "age", "height", "weight") %in% names(df)))
  expect_equal(nrow(df), 3)
  expect_true(is.character(df$name))
  expect_true(
    is.numeric(df$age) && is.numeric(df$height) && is.numeric(df$weight)
  )
})

test_that("answer_as_json + llm_provider_ellmer: optional fields (required = FALSE)", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  type_person_opt <- ellmer::type_object(
    name = ellmer::type_string(required = FALSE),
    age = ellmer::type_integer(required = FALSE)
  )

  # Only age present
  res_age_only <- "I'm 33 years old." |>
    answer_as_json(type_person_opt) |>
    send_prompt(ellmer_openai)
  expect_true(is.list(res_age_only))
  expect_true(all(names(res_age_only) %in% c("name", "age")))
  if ("age" %in% names(res_age_only)) {
    expect_true(is.numeric(res_age_only$age) && length(res_age_only$age) == 1)
  }

  # Only name present
  res_name_only <- "My name is Taylor." |>
    answer_as_json(type_person_opt) |>
    send_prompt(ellmer_openai)
  expect_true(is.list(res_name_only))
  expect_true(all(names(res_name_only) %in% c("name", "age")))
  if ("name" %in% names(res_name_only)) {
    expect_true(
      is.character(res_name_only$name) && nchar(res_name_only$name) > 0
    )
  }
})

test_that("answer_as_json + llm_provider_ellmer: arrays of enums and objects combined", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  ellmer_openai <- llm_provider_ellmer(ellmer::chat_openai(
    model = "gpt-4.1-mini"
  ))

  # Object with an enum and an array of enums
  type_pref <- ellmer::type_object(
    primary = ellmer::type_enum(c("red", "green", "blue")),
    fallback = ellmer::type_array(ellmer::type_enum(c("red", "green", "blue")))
  )

  res_pref <- "Primary colour is green; fallbacks are red then blue." |>
    answer_as_json(type_pref) |>
    send_prompt(ellmer_openai)

  expect_true(is.list(res_pref))
  primary <- if (is.factor(res_pref$primary))
    as.character(res_pref$primary) else res_pref$primary
  expect_true(primary %in% c("red", "green", "blue"))

  fallbacks <- res_pref$fallback
  if (is.factor(fallbacks)) fallbacks <- as.character(fallbacks)
  expect_true(is.character(fallbacks))
  expect_true(all(fallbacks %in% c("red", "green", "blue")))
})
