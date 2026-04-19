# Method for `chat_history()` when the input is a `data.frame`

Creates a `chat_history` object from a data frame.

## Usage

``` r
# S3 method for class 'data.frame'
chat_history(chat_history)
```

## Arguments

- chat_history:

  A data frame with 'role' and 'content' columns, where 'role' is either
  'user', 'assistant', or 'system', and 'content' is a character string
  representing a chat message

## Value

A valid chat history `data.frame` (of class `chat_history`), with the
'role' and 'content' columns as specified in the input data frame
