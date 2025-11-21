# Set chain of thought mode for a prompt

This function enables chain of thought mode for evaluation of a prompt
or a
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md).
In chain of thought mode, the large language model (LLM) In chain of
thought mode, the large language model (LLM) is asked to think step by
step to arrive at a final answer. It is hypothesized that this may
increase LLM performance at solving complex tasks. Chain of thought mode
is inspired by the method described in Wei et al. (2022).

## Usage

``` r
answer_by_chain_of_thought(
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
  brackets.

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
which will ensure that the LLM follows the chain of thought mode in
answering the prompt

## References

Wei, J., Wang, X., Schuurmans, D., Bosma, M., Ichter, B., Xia, F., Chi,
E., Le, Q., & Zhou, D. (2022). Chain-of-Thought Prompting Elicits
Reasoning in Large Language Models. <doi:10.48550/arXiv.2201.11903>

## See also

Other pre_built_prompt_wraps:
[`add_image()`](https://kennispunttwente.github.io/tidyprompt/reference/add_image.md),
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
[`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md),
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_sql()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_sql.md),
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other answer_by_prompt_wraps:
[`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  "What is 5 + 5?" |>
    answer_by_chain_of_thought() |>
    answer_as_integer() |>
    send_prompt()
  # --- Sending request to LLM provider (llama3.1:8b): ---
  # You are given a user's prompt.
  # To answer the user's prompt, you need to think step by step to arrive at a final answer.
  #
  # ----- START OF USER'S PROMPT -----
  # What is 5 + 5?
  #
  # You must answer with only an integer (use no other characters).
  # ----- END OF USER'S PROMPT -----
  #
  # What are the steps you would take to answer the user's prompt?
  # Describe your thought process in the following format:
  #   >> step 1: <step 1 description>
  #   >> step 2: <step 2 description>
  #   (etc.)
  #
  # When you are done, you must type:
  #   FINISH[<put here your final answer to the user's prompt>]
  #
  # Make sure your final answer follows the logical conclusion of your thought process.
  # --- Receiving response from LLM provider: ---
  # >> step 1: Recognize that the user's prompt is a simple arithmetic question asking for
  # the sum of two numbers.
  #
  # >> step 2: Identify the specific numbers mentioned in the prompt, which are 5 and 5.
  #
  # >> step 3: Recall basic addition facts from memory or knowledge.
  # In this case, knowing that 5 + 0 = 5, 5 + 1 = 6, 5 + 2 = 7, and so on up to 5 + 4 = 9,
  # it is clear that the next step in adding 5 to itself would be to keep the same sum.
  #
  # >> step 4: Apply the addition principle by considering the original number (5) as being
  # added to itself once more. Since 5 + 1 = 6 and the process of adding 1 increases the total
  # sum, then 5 + 2 must equal 7, thus indicating a direct progression in the sum as the additive
  # amount increases.
  #
  # >> step 5: From steps 3 and 4, conclude that since 5 added to itself (once) would be 10,
  # then when it is added again (to itself), it would continue from the last result which was
  # achieved by adding one more than the original number. Therefore, it must follow the pattern
  # established in step 3 where each additional amount increases the total sum.
  #
  # >> step 6: Now knowing that the operation of adding a second 5 to the first one results in
  # increasing the sum to the next integer after 10 (based on steps 3 and 4), determine what the
  # next integer is after 10. Knowing that integers are whole numbers without fractions, it's
  # clear that if you add another unit to 10, it becomes 11.
  #
  # FINISH[10]
  # [1] 10
} # }
```
