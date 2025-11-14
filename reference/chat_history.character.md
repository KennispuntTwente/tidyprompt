# Method for `chat_history()` when the input is a single string

Creates a `chat_history` object from a single string.

## Usage

``` r
# S3 method for class 'character'
chat_history(chat_history)
```

## Arguments

- chat_history:

  A single string

## Value

A valid chat history `data.frame` (of class `chat_history`), with the
'role' set to 'user' and the 'content' set to the input string
