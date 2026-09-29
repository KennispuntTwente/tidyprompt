#' @title
#' Have LLM check the result of a prompt (LLM-in-the-loop)
#'
#' @description
#' This function will wrap a prompt with a check for a LLM to accept or decline
#' the result of the prompt, providing feedback if the result is declined.
#' The evaluating LLM will be presented with the original prompt and the result
#' of the prompt, and will be asked to verify if the answer is satisfactory
#' (using chain of thought reasoning to arrive at a boolean decision). If
#' the result is declined, the chain of thought responsible for the decision
#' will be summarized and sent back to the original LLM that was asked to
#' evaluate the prompt, so that it may retry the prompt.
#'
#' Note that this function is experimental and, because it relies on chain of
#' thought reasoning by a LLM about the answer of another LLM, it may not
#' always provide accurate results and can increase the token cost of
#' evaluating a prompt.
#'
#' @details The original prompt text shown to the LLM is built from
#' the base prompt as well as all prompt wraps that have a modify function
#' but do not have an extraction or validation function. This is to ensure
#' that no redundant validation is performed by the evaluating LLM on
#' instructions which have already been validated by functions in those
#' prompt wraps.
#' The verifier receives the complete answer: text is sent directly, and other
#' R values are serialized with [base::dput()], including all rows, columns and
#' nested values. Console printing and tibble display limits do not apply.
#' No size limit or automatic truncation is applied here; the complete answer
#' must fit within the verifier model's context window. To review selected fields
#' or chunks instead, split or select them explicitly before verification.
#'
#' @param prompt A single string or a [tidyprompt-class] object
#'
#' @param question The question to ask the LLM to verify the result of the prompt.
#' The LLM will be presented the original prompt, its result, and this question.
#' The LLM will be asked to provide a boolean answer to this question. If TRUE,
#' the result of the prompt will be accepted; if FALSE, the result will be declined
#'
#' @param llm_provider A [llm_provider-class] object or an 'ellmer' Chat
#'  which will be used to verify the evaluation led to a satisfactory result.
#' If not provided, the same LLM provider as the prompt was originally
#'  evaluated with will be used
#' (with its base configuration, without the answer's prompt-specific settings).
#' Verification and feedback-summary requests share the original evaluation's
#' request limit, including when a separate verifier provider is supplied.
#' Raw Chats are cloned and their existing turns cleared for verification, as
#' in [send_prompt()]; the caller's Chat is unchanged.
#'
#' @param max_words_feedback The maximum number of words allowed in the summary of
#'  why the result was declined.
#' This summary is sent back to the LLM originally asked to evaluate the prompt
#'
#' @return A [tidyprompt-class] with an added [prompt_wrap()] which
#'  will add a check for a LLM to accept or decline the result of the prompt,
#'  providing feedback if the result is declined
#'
#' @export
#'
#' @example inst/examples/llm_verify.R
llm_verify <- function(
  prompt,
  question = "Is the answer satisfactory?",
  llm_provider = NULL,
  max_words_feedback = 50
) {
  prompt <- tidyprompt(prompt)

  # Verify & install provided LLM provider
  llm_provider <- as_llm_provider(llm_provider)
  stopifnot(
    is.null(llm_provider) || inherits(llm_provider, "LlmProvider")
  )
  super_llm_provider <- llm_provider

  validation_fn <- function(response, llm_provider) {
    answer_provider <- llm_provider
    request_guard <- llm_provider$parameters$.request_guard
    source_provider <- super_llm_provider %||% llm_provider
    llm_provider <- (source_provider$parameters$.evaluation_base_provider %||%
      source_provider)$clone()
    # Provider-wide answer wraps must not recursively apply to the judge.
    llm_provider$pre_prompt_wraps <- list()
    llm_provider$post_prompt_wraps <- list()
    llm_provider$parameters$.request_guard <- request_guard
    llm_provider$parameters$.request_guard_needs_hook <- is.function(
      request_guard
    )
    llm_provider$parameters$.request_limit_cleanup <- NULL

    prompt_text <- self$base_prompt
    prompt_wraps <- self$get_prompt_wraps("modification")
    for (wrap in prompt_wraps) {
      if (is.null(wrap$modify_fn)) {
        next
      }
      # We skip prompt wraps that have extraction or validation functions;
      #   we assume that potential instructions added by these wraps
      #   have been properly validated by these functions;
      #   adding them to the prompt text here would lead to
      #   redundant validation by the LLM
      if (!is.null(wrap$extraction_fn) || !is.null(wrap$validation_fn)) {
        next
      }

      prompt_text <- wrap$modify_fn(prompt_text, answer_provider)
    }

    result_as_text <- llm_verify_serialize(response)

    satisfied <- glue::glue(
      ">>> An assistant was asked:\n\n",
      "{prompt_text}\n\n",
      ">>> The assistant answered:\n\n",
      "  ",
      paste(result_as_text, collapse = "\n  "),
      "\n\n",
      ">>> {question}",
      .trim = FALSE
    ) |>
      answer_as_boolean() |>
      answer_by_chain_of_thought() |>
      send_prompt(llm_provider, return_mode = "full")

    if (isTRUE(satisfied$response)) {
      return(TRUE)
    }
    if (!identical(satisfied$response, FALSE)) {
      return(llm_feedback(
        "The verifier could not reach a decision. Check your answer."
      ))
    }

    # Create summary of why the response was declined
    feedback <- glue::glue(
      "An assistant's answer was declined by another assistant.",
      "The declining assistant provided their chain of thought:\n\n",
      satisfied$chat_history |>
        dplyr::select(c("role", "content")) |>
        df_to_string(),
      "\n\n",
      "Summarize why the result was declined."
    ) |>
      answer_as_text(max_words = max_words_feedback) |>
      send_prompt(llm_provider)

    return(
      llm_feedback(
        paste0(
          "Your answer was rejected for this reason:\n\n",
          feedback
        )
      )
    )
  }

  prompt_wrap(
    prompt,
    validation_fn = validation_fn,
    type = "check"
  )
}

llm_verify_serialize <- function(response) {
  if (is.character(response) && length(response) == 1L && !is.na(response)) {
    return(response)
  }
  # dput() represents the full value independently of print methods, max.print,
  # tibble dimensions and pillar options. Preserve types, attributes and NA.
  paste(utils::capture.output(dput(
    response,
    control = c("keepNA", "keepInteger", "niceNames", "showAttributes", "digits17")
  )), collapse = "\n")
}
