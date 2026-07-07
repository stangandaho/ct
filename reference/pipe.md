# Pipe operators

Re-exported from the magrittr package. `%>%` pipes the left-hand side
into the first argument (or the `.` placeholder) of the right-hand side;
`%<>%` does the same but assigns the result back to the left-hand side.

## Usage

``` r
lhs %>% rhs

lhs %<>% rhs
```

## Arguments

- lhs:

  A value to pipe into the right-hand side expression.

- rhs:

  A function call using the magrittr semantics; the value of `lhs` is
  placed into its first argument (or wherever the `.` placeholder
  appears).

## Value

The result of calling `rhs` with `lhs` inserted, as documented in
`magrittr::%>%()`. `%<>%` returns that result invisibly after assigning
it back to `lhs`.
