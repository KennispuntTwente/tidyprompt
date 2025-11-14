# Convert a named or unnamed list/vector to a string representation

Converts a named or unnamed list/vector to a string format, intended for
sending it to an LLM (or for display or logging).

## Usage

``` r
vector_list_to_string(obj, how = c("inline", "expanded"))
```

## Arguments

- obj:

  A list or vector (named or unnamed) to be converted to a string.

- how:

  In what way the object should be converted to a string; either
  "inline" or "expanded". "inline" presents all key-value pairs or
  values as a single line. "expanded" presents each key-value pair or
  value on a separate line.

## Value

A single string representing the list/vector.

## See also

Other text_helpers:
[`df_to_string()`](https://kennispunttwente.github.io/tidyprompt/reference/df_to_string.md),
[`skim_with_labels_and_levels()`](https://kennispunttwente.github.io/tidyprompt/reference/skim_with_labels_and_levels.md)

## Examples

``` r
named_vector <- c(x = 10, y = 20, z = 30)

vector_list_to_string(named_vector, how = "inline")
#> [1] "x: 10, y: 20, z: 30"

vector_list_to_string(named_vector, how = "expanded")
#> [1] "x: 10\ny: 20\nz: 30"
```
