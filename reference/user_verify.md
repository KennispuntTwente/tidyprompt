# Have user check the result of a prompt (human-in-the-loop)

This function is used to have a user check the result of a prompt. After
evaluation of the prompt and applying prompt wraps, the user is
presented with the result and asked to accept or decline. If the user
declines, they are asked to provide feedback to the large language model
(LLM) so that the LLM can retry the prompt.

## Usage

``` r
user_verify(prompt)
```

## Arguments

- prompt:

  A single string or a
  [tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
  object

## Value

A
[tidyprompt](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt-class.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will add a check for the user to accept or decline the result of
the prompt, providing feedback if the result is declined

## Examples

``` r
if (FALSE) { # \dontrun{
  "Tell me a fun fact about yourself!" |>
    user_verify() |>
    send_prompt()
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # Tell me a fun fact about yourself!
  # --- Receiving response from LLM provider: ---
  # I don't have personal experiences or feelings, but a fun fact about me is that
  # I can generate text in multiple languages! From English to Spanish, French, and
  # more, I'm here to help with diverse linguistic needs.
  #
  # --- Evaluation of tidyprompt resulted in:
  # [1] "I don't have personal experiences or feelings, but a fun fact about me is
  # that I can generate text in multiple languages! From English to Spanish, French,
  # and more, I'm here to help with diverse linguistic needs."
  #
  # --- Accept or decline
  # * If satisfied, type nothing
  # * If not satisfied, type feedback to the LLM
  # Type: Needs to be funnier!
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # Needs to be funnier!
  # --- Receiving response from LLM provider: ---
  # Alright, how about this: I once tried to tell a joke, but my punchline got lost
  # in translation! Now, I just stick to delivering 'byte-sized' humor!
  #
  # --- Evaluation of tidyprompt resulted in:
  # [1] "Alright, how about this: I once tried to tell a joke, but my punchline got
  # lost in translation! Now, I just stick to delivering 'byte-sized' humor!"
  #
  # --- Accept or decline
  # * If satisfied, type nothing
  # * If not satisfied, type feedback to the LLM
  # Type:
  # * Result accepted
  # [1] "Alright, how about this: I once tried to tell a joke, but my punchline got
  # lost in translation! Now, I just stick to delivering 'byte-sized' humor!"
} # }
```
