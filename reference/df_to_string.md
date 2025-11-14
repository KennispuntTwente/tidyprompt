# Convert a dataframe to a string representation

Converts a data frame to a string format, intended for sending it to a
LLM (or for display or logging).

## Usage

``` r
df_to_string(df, how = c("wide", "long"))
```

## Arguments

- df:

  A `data.frame` object to be converted to a string

- how:

  In what way the df should be converted to a string; either "wide" or
  "long". "wide" presents column names on the first row, followed by the
  row values on each new row. "long" presents the values of each row
  together with the column names, repeating for every row after two
  lines of whitespace

## Value

A single string representing the df

## See also

Other text_helpers:
[`skim_with_labels_and_levels()`](https://kennispunttwente.github.io/tidyprompt/reference/skim_with_labels_and_levels.md),
[`vector_list_to_string()`](https://kennispunttwente.github.io/tidyprompt/reference/vector_list_to_string.md)

## Examples

``` r
cars |>
  head(5) |>
  df_to_string(how = "wide")
#> [1] "speed, dist\n4, 2\n4, 10\n7, 4\n7, 22\n8, 16"

cars |>
  head(5) |>
  df_to_string(how = "long")
#> [1] "speed: 4\ndist: 2\n\n\nspeed: 4\ndist: 10\n\n\nspeed: 7\ndist: 4\n\n\nspeed: 7\ndist: 22\n\n\nspeed: 8\ndist: 16\n\n\n"
```
