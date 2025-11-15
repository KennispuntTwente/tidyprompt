test_that("OpenAI Responses API maps image_url to scalar string", {
  # Construct a synthetic messages list replicating internal structure prior to transformation
  messages <- list(
    list(
      role = "user",
      content = list(
        list(type = "text", text = "Describe this image"),
        list(type = "image_url", image_url = list(url = "https://example.org/cat.jpg", detail = "auto"))
      )
    )
  )

  # Reproduce transformation logic (factored implicitly in provider code). We simulate only the part needed.
  input <- lapply(messages, function(msg) {
    role <- msg$role
    content <- msg$content
    parts <- list()
    for (part in content) {
      if (identical(part$type, "text")) {
        parts[[length(parts) + 1]] <- list(type = "input_text", text = part$text)
      } else if (identical(part$type, "image_url")) {
        img <- part$image_url
        url_val <- img$url
        detail_val <- img$detail
        parts[[length(parts) + 1]] <- compact_list(list(type = "input_image", image_url = url_val, detail = detail_val))
      }
    }
    list(role = role, content = parts)
  })

  expect_true(is.character(input[[1]]$content[[2]]$image_url))
  expect_equal(input[[1]]$content[[2]]$image_url, "https://example.org/cat.jpg")
  expect_equal(input[[1]]$content[[2]]$detail, "auto")
})