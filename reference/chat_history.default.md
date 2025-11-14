# Default method for `chat_history()`

Calls error which indicates that the input was not a `character` or
`data.frame`.

## Usage

``` r
# Default S3 method
chat_history(chat_history)
```

## Arguments

- chat_history:

  Object which is not `character` or `data.frame`

## Value

No return value; an error is thrown

## Details

When input is a `character` or `data.frame`, the appropriate method will
be called (see
\`[`chat_history.character()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.character.md)
and
[`chat_history.data.frame()`](https://kennispunttwente.github.io/tidyprompt/reference/chat_history.data.frame.md)).
