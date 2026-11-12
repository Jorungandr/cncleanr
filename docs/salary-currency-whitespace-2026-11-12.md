# Currency markers containing whitespace

The salary example accepted `月薪R M B3000`, `月薪C N Y3000` and
`月薪人 民 币3000` with `currency = "USD"`, yielding parsed amounts labelled USD.
The core parser removes whitespace inside currency markers before parsing.
The example inspected the original spacing and missed the explicit markers.

Currency inspection now removes the same ASCII whitespace, nonbreaking space,
narrow nonbreaking space and ideographic space recognized by the core.
The amount passed to the parser retains its spacing for digit-group validation.

Regression coverage combines seventeen marker spellings with ten whitespace
settings and five supplied-label settings, including NULL. This exercises 850
synthetic input/context combinations through the existing aggregate assertions.
An additional assertion checks rejection of `R M B1 23元` and acceptance of
`C N Y1 234元` with CNY context.

Local validation passed 150 cumulative salary assertions, 288 generated wrapper
cases, nineteen attributed source cases and 46 runnable bilingual guide blocks.
