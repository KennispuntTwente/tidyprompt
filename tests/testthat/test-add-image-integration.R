openai_provider <- llm_provider_openai(parameters = list(model = "gpt-4o-mini"))
ellmer_provider <- llm_provider_ellmer(ellmer::chat_openai(model = "gpt-4o-mini"))
ollama_provider <- llm_provider_ollama(parameters = list(model = "qwen3-vl:2b"))

cat_img_file <- tempfile(fileext = ".jpg")
download.file(
  "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg",
  destfile = cat_img_file,
  mode = "wb"
)

cat_plot <- ggplot2::ggplot() +
  ggplot2::annotate(
    "text", x = 0.5, y = 0.5,
    label = "cat", size = 50, hjust = 0.5, vjust = 0.5
  ) +
  ggplot2::theme_void()

cat_mentioned <- function(text) {
  grepl("cat", text, ignore.case = TRUE)
}

img_file_prompt <- "Describe this image" |>
  add_image(cat_img_file)

img_plot_prompt <- "Describe this image" |>
  add_image(cat_plot)

testthat::test_that("openai provider - add_image works (file)", {
  skip_test_if_no_openai()

  result <- send_prompt(
    img_file_prompt,
    llm_provider = openai_provider
  )

  testthat::expect_true(
    cat_mentioned(result)
  )
})

testthat::test_that("openai provider - add_image works (plot)", {
  skip_test_if_no_openai()

  result <- send_prompt(
    img_plot_prompt,
    llm_provider = openai_provider
  )

  testthat::expect_true(
    cat_mentioned(result)
  )
})

testthat::test_that("ellmer provider - add_image works (file)", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  result <- send_prompt(
    img_file_prompt,
    llm_provider = ellmer_provider
  )

  testthat::expect_true(
    cat_mentioned(result)
  )
})

testthat::test_that("ellmer provider - add_image works (plot)", {
  skip_test_if_no_openai()
  skip_if_not_installed("ellmer")

  result <- send_prompt(
    img_plot_prompt,
    llm_provider = ellmer_provider
  )

  testthat::expect_true(
    cat_mentioned(result)
  )
})

testthat::test_that("ollama provider - add_image works (file)", {
  skip_test_if_no_ollama()

  result <- send_prompt(
    img_file_prompt,
    llm_provider = ollama_provider
  )

  testthat::expect_true(
    cat_mentioned(result)
  )
})

testthat::test_that("ollama provider - add_image works (url)", {
  skip_test_if_no_ollama()

  result <- send_prompt(
    img_url_prompt,
    llm_provider = ollama_provider
  )

  testthat::expect_true(
    cat_mentioned(result)
  )
})

testthat::test_that("ollama provider - add_image works (plot)", {
  skip_test_if_no_ollama()

  result <- send_prompt(
    img_plot_prompt,
    llm_provider = ollama_provider
  )

  testthat::expect_true(
    cat_mentioned(result)
  )
})
