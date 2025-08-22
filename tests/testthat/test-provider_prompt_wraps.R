test_that("provider-level pre/post wraps modify initial user message via send_prompt()", {
  fake <- llm_provider_fake(verbose = FALSE)

  # Ensure a clean slate
  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  # Add provider-level wraps
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste0("PRE(", txt, ")"),
      type = "unspecified",
      name = "prov-pre"
    ),
    position = "pre"
  )
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste0("POST(", txt, ")"),
      type = "unspecified",
      name = "prov-post"
    ),
    position = "post"
  )

  # Prompt-level wrap too, to check ordering (pre -> prompt -> post)
  pr <- prompt_wrap(
    "Hi",
    modify_fn = \(txt, llm, http) paste0("PROMPT(", txt, ")"),
    type = "unspecified",
    name = "prompt-wrap"
  )

  out <- send_prompt(pr, fake, return_mode = "full")

  first_user <- subset(out$chat_history, role == "user")
  first_user <- first_user[1, , drop = FALSE]

  expect_equal(first_user$content, "POST(PROMPT(PRE(Hi)))")
})

test_that("provider-level handler_fn runs during completion", {
  fake <- llm_provider_fake(verbose = FALSE)

  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  fake$add_prompt_wrap(
    provider_prompt_wrap(
      handler_fn = function(response, llm_provider) {
        response$completed$content[nrow(
          response$completed
        )] <- "provider handled"
        response
      },
      name = "prov-handler"
    ),
    position = "pre"
  )

  res <- send_prompt("Hi there", fake)
  expect_identical(res, "provider handled")
})

test_that("provider-level parameter_fn is applied before first completion", {
  prov <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      # 'self' is the provider; parameter_fn should have set self$parameters$marker
      add <- data.frame(
        role = "assistant",
        content = paste0("marker:", self$parameters$marker),
        tool_result = FALSE
      )
      completed <- rbind(chat_history, add)
      list(
        completed = completed,
        http = list(request = NULL, response = NULL)
      )
    },
    verbose = FALSE
  )

  prov$add_prompt_wrap(
    provider_prompt_wrap(
      parameter_fn = function(llm_provider) list(marker = "XYZ"),
      name = "prov-params"
    ),
    position = "pre"
  )

  res <- send_prompt("Hello", prov)
  expect_identical(res, "marker:XYZ")
})

test_that("provider-level pre and post handlers both run", {
  fake <- llm_provider_fake(verbose = FALSE)

  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  fake$add_prompt_wrap(
    provider_prompt_wrap(
      handler_fn = function(response, llm_provider) {
        response$completed$content[nrow(response$completed)] <-
          paste0(response$completed$content[nrow(response$completed)], " +PREH")
        response
      },
      name = "prov-pre-handler"
    ),
    position = "pre"
  )

  fake$add_prompt_wrap(
    provider_prompt_wrap(
      handler_fn = function(response, llm_provider) {
        response$completed$content[nrow(response$completed)] <-
          paste0(
            response$completed$content[nrow(response$completed)],
            " +POSTH"
          )
        response
      },
      name = "prov-post-handler"
    ),
    position = "post"
  )

  res <- send_prompt("Ping", fake)
  expect_true(grepl("\\+PREH", res))
  expect_true(grepl("\\+POSTH", res))
})

test_that("provider_prompt_wrap enforces 'check' type constraints", {
  expect_error(
    provider_prompt_wrap(
      type = "check",
      modify_fn = \(x) x,
      validation_fn = \(x, llm, http) TRUE
    ),
    "only validation_fn is allowed"
  )

  expect_no_error(
    provider_prompt_wrap(
      type = "check",
      validation_fn = \(x, llm, http) TRUE
    )
  )
})

test_that("apply_prompt_wraps attaches named provider wraps to a tidyprompt", {
  fake <- llm_provider_fake(verbose = FALSE)

  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) txt,
      type = "unspecified",
      name = "prov-pre-a"
    ),
    position = "pre"
  )
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) txt,
      type = "unspecified",
      name = "prov-post-b"
    ),
    position = "post"
  )

  tp <- fake$apply_prompt_wraps(tidyprompt("X"))
  wraps <- tp$get_prompt_wraps(order = "modification")
  wrap_names <- vapply(wraps, \(w) w$name %||% NA_character_, character(1))

  expect_true(any(wrap_names == "prov-pre-a"))
  expect_true(any(wrap_names == "prov-post-b"))
})


test_that("construct_prompt_text applies provider pre/post wraps around prompt wraps in correct type order", {
  fake <- llm_provider_fake(verbose = FALSE)
  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  # Provider-level wraps:
  # order for modification: check, unspecified, break, mode, tool
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "[preU]"),
      type = "unspecified",
      name = "prov-pre-unspecified"
    ),
    position = "pre"
  )
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "[preB]"),
      type = "break",
      name = "prov-pre-break"
    ),
    position = "pre"
  )
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "[postM]"),
      type = "mode",
      name = "prov-post-mode"
    ),
    position = "post"
  )
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "[postT]"),
      type = "tool",
      name = "prov-post-tool"
    ),
    position = "post"
  )

  # Prompt-level wraps
  pr <- "Hi" |>
    prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "[promptU]"),
      type = "unspecified",
      name = "prompt-unspecified"
    ) |>
    prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "[promptB]"),
      type = "break",
      name = "prompt-break"
    )

  # Apply provider wraps, then build text
  pr <- fake$apply_prompt_wraps(pr)
  built <- construct_prompt_text(pr, llm_provider = fake)

  # Expected order:
  # unspecified: prov-pre -> prompt
  # break:       prov-pre -> prompt
  # mode:        prov-post
  # tool:        prov-post
  expect_identical(
    built,
    "Hi [preU] [promptU] [preB] [promptB] [postM] [postT]"
  )
})

test_that("construct_prompt_text: unspecified wraps keep relative order: pre -> prompt -> post", {
  fake <- llm_provider_fake(verbose = FALSE)
  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "Apre"),
      type = "unspecified",
      name = "Apre"
    ),
    position = "pre"
  )
  pr <- "Hi" |>
    prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "Bprompt"),
      type = "unspecified",
      name = "Bprompt"
    )
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "Cpost"),
      type = "unspecified",
      name = "Cpost"
    ),
    position = "post"
  )

  pr <- fake$apply_prompt_wraps(pr)
  built <- construct_prompt_text(pr, llm_provider = fake)
  expect_identical(built, "Hi Apre Bprompt Cpost")
})

test_that("construct_prompt_text provider modify_fn receives llm_provider", {
  fake <- llm_provider_fake(verbose = FALSE)
  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = function(txt, llm_provider, http) {
        if (inherits(llm_provider, "LlmProvider")) {
          return("text for fake provider via provider wrap")
        }
        return("other")
      },
      type = "unspecified"
    ),
    position = "pre"
  )

  pr <- tidyprompt("ignored")
  pr <- fake$apply_prompt_wraps(pr)
  built <- construct_prompt_text(pr, llm_provider = fake)
  expect_identical(built, "text for fake provider via provider wrap")
})

test_that("multiple provider wraps of same type preserve insertion order", {
  fake <- llm_provider_fake(verbose = FALSE)
  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()

  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "one"),
      type = "unspecified",
      name = "one"
    ),
    position = "pre"
  )
  fake$add_prompt_wrap(
    provider_prompt_wrap(
      modify_fn = \(txt, llm, http) paste(txt, "two"),
      type = "unspecified",
      name = "two"
    ),
    position = "pre"
  )

  pr <- tidyprompt("Hi")
  pr <- fake$apply_prompt_wraps(pr)
  built <- construct_prompt_text(pr, llm_provider = fake)
  expect_identical(built, "Hi one two")
})

test_that("apply_prompt_wraps preserves system prompt and prior chat history", {
  fake <- llm_provider_fake(verbose = FALSE)
  fake$pre_prompt_wraps <- list()
  fake$post_prompt_wraps <- list()
  fake$add_prompt_wrap(
    provider_prompt_wrap(modify_fn = \(txt, llm, http) paste0(txt, " [prov]")),
    position = "pre"
  )

  ch <- create_chat_df(
    role = c("system", "assistant", "user", "assistant", "user"),
    content = c("SYS", "A1", "U1", "A2", "U2"),
    tool_result = c(FALSE, FALSE, FALSE, FALSE, FALSE)
  )

  orig <- tidyprompt(ch)
  wrapped <- fake$apply_prompt_wraps(orig)

  # System prompt untouched
  expect_identical(orig$system_prompt, "SYS")
  expect_identical(wrapped$system_prompt, "SYS")

  # Non-final rows identical
  gh_o <- orig$get_chat_history()
  gh_w <- wrapped$get_chat_history(fake) # last user line will include [prov]
  expect_identical(gh_o[-nrow(gh_o), ], gh_w[-nrow(gh_w), ])

  # Only the last user message is modified by provider wraps
  expect_match(utils::tail(gh_w$content, 1), "\\[prov\\]$")
})

test_that("handler_fns order and loop semantics work", {
  prov <- `llm_provider-class`$new(
    complete_chat_function = function(chat_history) {
      add <- data.frame(role = "assistant", content = "ok", tool_result = FALSE)
      list(
        completed = rbind(chat_history, add),
        http = list(request = NULL, response = NULL)
      )
    },
    verbose = FALSE
  )

  seq_vec <- character(0)
  # provider-pre
  prov$add_prompt_wrap(
    provider_prompt_wrap(
      handler_fn = function(resp, llm) {
        seq_vec <<- c(seq_vec, "pre")
        resp$done <- FALSE # force another loop
        resp
      }
    ),
    position = "pre"
  )

  # prompt-level
  pr <- prompt_wrap(
    "X",
    handler_fn = function(resp, llm) {
      seq_vec <<- c(seq_vec, "prompt")
      resp
    },
    type = "unspecified"
  )

  # provider-post that ends the loop on 2nd pass
  pass <- 0L
  prov$add_prompt_wrap(
    provider_prompt_wrap(
      handler_fn = function(resp, llm) {
        seq_vec <<- c(seq_vec, "post")
        pass <<- pass + 1L
        resp$done <- pass >= 2L
        resp
      }
    ),
    position = "post"
  )

  send_prompt(pr, prov)
  expect_identical(seq_vec, c("pre", "prompt", "post", "pre", "prompt", "post"))
})

test_that("evaluation order across types is tool→mode→break→unspecified→check", {
  order <- character()
  # Fake provider that just echoes
  prov <- llm_provider_fake(verbose = FALSE)

  pr <- "base" |>
    prompt_wrap(
      extraction_fn = \(x, llm, http) {
        order <<- c(order, "tool")
        x
      },
      type = "tool"
    ) |>
    prompt_wrap(
      extraction_fn = \(x, llm, http) {
        order <<- c(order, "mode")
        x
      },
      type = "mode"
    ) |>
    prompt_wrap(
      extraction_fn = \(x, llm, http) {
        order <<- c(order, "break")
        x
      },
      type = "break"
    ) |>
    prompt_wrap(extraction_fn = \(x, llm, http) {
      order <<- c(order, "unspecified")
      x
    }) |>
    prompt_wrap(
      validation_fn = \(x, llm, http) {
        order <<- c(order, "check")
        TRUE
      },
      type = "check"
    )

  send_prompt(pr, prov)
  expect_identical(order, c("tool", "mode", "break", "unspecified", "check"))
})


test_that("ensure_three_arguments works for 1-arg funcs", {
  prov <- llm_provider_fake(verbose = FALSE)
  pr <- prompt_wrap(
    "Z",
    extraction_fn = function(resp) resp, # only 1 arg
    validation_fn = function(resp) TRUE # only 1 arg
  )
  expect_no_error(send_prompt(pr, prov))
})

test_that("parameter_fn must take exactly one argument", {
  expect_error(
    prompt_wrap("x", parameter_fn = function(a, b) list(foo = 1)),
    "takes one argument"
  )
  expect_error(
    provider_prompt_wrap(parameter_fn = function(a, b) list(bar = 2)),
    "must take one argument"
  )
})

test_that("apply_prompt_wraps returns a new prompt; original unchanged", {
  fake <- llm_provider_fake(verbose = FALSE)
  fake$pre_prompt_wraps <- list()
  fake$add_prompt_wrap(
    provider_prompt_wrap(name = "prov", modify_fn = function(x) {
      return(x)
    }),
    position = "pre"
  )

  orig <- tidyprompt("hello")
  wrapped <- fake$apply_prompt_wraps(orig)

  orig_names <- vapply(
    get_prompt_wraps(orig),
    \(w) w$name %||% NA_character_,
    ""
  )
  wrap_names <- vapply(
    get_prompt_wraps(wrapped),
    \(w) w$name %||% NA_character_,
    ""
  )

  expect_false("prov" %in% orig_names)
  expect_true("prov" %in% wrap_names)
})
