# Skim a dataframe and include labels and levels

This function takes a `data.frame` and returns a skim summary with
variable names, labels, and levels for categorical variables. It is a
wrapper around the
[`skimr::skim()`](https://docs.ropensci.org/skimr/reference/skim.html)
function.

## Usage

``` r
skim_with_labels_and_levels(data)
```

## Arguments

- data:

  A `data.frame` to be skimmed

## Value

A `data.frame` with variable names, labels, levels, and a skim summary

## See also

Other text_helpers:
[`df_to_string()`](https://kennispunttwente.github.io/tidyprompt/reference/df_to_string.md),
[`vector_list_to_string()`](https://kennispunttwente.github.io/tidyprompt/reference/vector_list_to_string.md)

## Examples

``` r
# First add some labels to 'mtcars':
mtcars$car <- rownames(mtcars)
mtcars$car <- factor(mtcars$car, levels = rownames(mtcars))
attr(mtcars$car, "label") <- "Name of the car"

# Then skim the data:
mtcars |>
  skim_with_labels_and_levels()
#>    variable     description       levels skim_type n_missing complete_rate
#> 1        am            <NA>           NA   numeric         0             1
#> 2       car Name of the car Mazda RX....    factor         0             1
#> 3      carb            <NA>           NA   numeric         0             1
#> 4       cyl            <NA>           NA   numeric         0             1
#> 5      disp            <NA>           NA   numeric         0             1
#> 6      drat            <NA>           NA   numeric         0             1
#> 7      gear            <NA>           NA   numeric         0             1
#> 8        hp            <NA>           NA   numeric         0             1
#> 9       mpg            <NA>           NA   numeric         0             1
#> 10     qsec            <NA>           NA   numeric         0             1
#> 11       vs            <NA>           NA   numeric         0             1
#> 12       wt            <NA>           NA   numeric         0             1
#>    factor.ordered factor.n_unique              factor.top_counts numeric.mean
#> 1              NA              NA                           <NA>     0.406250
#> 2           FALSE              32 Maz: 1, Maz: 1, Dat: 1, Hor: 1           NA
#> 3              NA              NA                           <NA>     2.812500
#> 4              NA              NA                           <NA>     6.187500
#> 5              NA              NA                           <NA>   230.721875
#> 6              NA              NA                           <NA>     3.596563
#> 7              NA              NA                           <NA>     3.687500
#> 8              NA              NA                           <NA>   146.687500
#> 9              NA              NA                           <NA>    20.090625
#> 10             NA              NA                           <NA>    17.848750
#> 11             NA              NA                           <NA>     0.437500
#> 12             NA              NA                           <NA>     3.217250
#>     numeric.sd numeric.p0 numeric.p25 numeric.p50 numeric.p75 numeric.p100
#> 1    0.4989909      0.000     0.00000       0.000        1.00        1.000
#> 2           NA         NA          NA          NA          NA           NA
#> 3    1.6152000      1.000     2.00000       2.000        4.00        8.000
#> 4    1.7859216      4.000     4.00000       6.000        8.00        8.000
#> 5  123.9386938     71.100   120.82500     196.300      326.00      472.000
#> 6    0.5346787      2.760     3.08000       3.695        3.92        4.930
#> 7    0.7378041      3.000     3.00000       4.000        4.00        5.000
#> 8   68.5628685     52.000    96.50000     123.000      180.00      335.000
#> 9    6.0269481     10.400    15.42500      19.200       22.80       33.900
#> 10   1.7869432     14.500    16.89250      17.710       18.90       22.900
#> 11   0.5040161      0.000     0.00000       0.000        1.00        1.000
#> 12   0.9784574      1.513     2.58125       3.325        3.61        5.424
#>    numeric.hist
#> 1         ▇▁▁▁▆
#> 2          <NA>
#> 3         ▇▂▅▁▁
#> 4         ▆▁▃▁▇
#> 5         ▇▃▃▃▂
#> 6         ▇▃▇▅▁
#> 7         ▇▁▆▁▂
#> 8         ▇▇▆▃▁
#> 9         ▃▇▅▁▂
#> 10        ▃▇▇▂▁
#> 11        ▇▁▁▁▆
#> 12        ▃▃▇▁▂
```
