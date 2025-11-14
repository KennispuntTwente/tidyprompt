# Set ReAct mode for a prompt

This function enables ReAct mode for the evaluation of a prompt or a
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md).
In ReAct mode, the large language model (LLM) is asked to think step by
step, each time detailing a thought, action, and observation, to
eventually arrive at a final answer. It is hypothesized that this may
increase LLM performance at solving complex tasks. ReAct mode is
inspired by the method described in Yao et al. (2022).

## Usage

``` r
answer_by_react(
  prompt,
  extract_from_finish_brackets = TRUE,
  extraction_lenience = TRUE
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- extract_from_finish_brackets:

  A logical indicating whether the final answer should be extracted from
  the text inside the "FINISH[...](https://rdrr.io/r/base/dots.html)"
  brackets

- extraction_lenience:

  A logical indcating whether the extraction function should be lenient.
  If TRUE, the extraction function will attempt to extract the final
  answer even if it cannot be extracted from within the brackets, by
  extracting everything after the final occurence of 'FINISH' (if
  present). This may be useful for smaller LLMs which may not follow the
  output format as strictly

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the LLM follows the ReAct mode in answering the
prompt

## Details

Please note that ReAct mode may be most useful if in combination with
tools that the LLM can use. See, for example, 'add_tools()' for enabling
R function calling, or, for example, 'answer_as_code()' with
'output_as_tool = TRUE' for enabling R code evaluation as a tool.

## References

Yao, S., Wu, Y., Cheung, W., Wang, Z., Narasimhan, K., & Kong, L.
(2022). ReAct: Synergizing Reasoning and Acting in Language Models.
<doi:10.48550/arXiv.2210.03629>

## See also

[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md)

Other pre_built_prompt_wraps:
[`add_text()`](https://kennispunttwente.github.io/tidyprompt/reference/add_text.md),
[`answer_as_boolean()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_boolean.md),
[`answer_as_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_category.md),
[`answer_as_integer()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_integer.md),
[`answer_as_json()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_json.md),
[`answer_as_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_list.md),
[`answer_as_multi_category()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_multi_category.md),
[`answer_as_named_list()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_named_list.md),
[`answer_as_regex_match()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_regex_match.md),
[`answer_as_text()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_as_text.md),
[`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md),
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_sql()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_sql.md),
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other answer_by_prompt_wraps:
[`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  "What is 5 + 5?" |>
    answer_by_react() |>
    answer_as_integer() |>
    send_prompt()
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # You are given a user's prompt.
  # To answer the user's prompt, you need to think step by step,
  # take an action if needed, and then return a final answer.
  #
  # ----- START OF USER'S PROMPT -----
  # What is 5 + 5?
  #
  # You must answer with only an integer (use no other characters).
  # ----- END OF USER'S PROMPT -----
  #
  # Use the following structure:
  #   Thought: <describe your thought process>
  #   Action: <if needed, describe the action you take (e.g., look up information)>
  #   Observation: <describe the result or observation from the action>
  # (Repeat Thought -> Action -> Observation as necessary)
  #
  # When you are done, you must type:
  #   FINISH[<put here your final answer to the user's prompt>]
  #
  # Ensure your final answer aligns with your reasoning and observations.
  # --- Receiving response from LLM provider: ---
  # Thought: The problem is asking for the sum of two numbers, 5 and 5.
  #
  # Action: None needed, as this is a simple arithmetic operation that can be performed mentally.
  #
  # Observation: I can easily add these two numbers together in my mind to get the result.
  #
  # Thought: To find the sum, I will simply add the two numbers together: 5 + 5 = ?
  #
  # Action: Perform the addition.
  #
  # Observation: The result of adding 5 and 5 is 10.
  #
  # FINISH[10]
  # [1] 10
} # }
```
