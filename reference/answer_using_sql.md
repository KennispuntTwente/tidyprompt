# Enable LLM to draft and execute SQL queries on a database

Enable LLM to draft and execute SQL queries on a database

## Usage

``` r
answer_using_sql(
  prompt,
  add_text = paste0("You must code in SQL to answer this prompt.",
    " You must provide all SQL code between ```sql and ```.", "\n\n",
    "Never make assumptions about the possible values in the tables.\n",
    "Instead, execute SQL queries to retrieve information you need."),
  conn,
  list_tables = TRUE,
  describe_tables = TRUE,
  evaluate_code = FALSE,
  output_as_tool = FALSE,
  return_mode = c("full", "code", "object", "formatted_output", "llm_answer")
)
```

## Arguments

- prompt:

  A single string or a
  [`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
  object

- add_text:

  Single string which will be added to the prompt text, informing the
  LLM that they must use SQL to answer the prompt

- conn:

  A DBIConnection object to the SQL database

- list_tables:

  Logical indicating whether to list tables available in the database in
  the prompt text

- describe_tables:

  Logical indicating whether to describe the tables available in the
  database in the prompt text. If TRUE, the columns of each table will
  be listed

- evaluate_code:

  Logical indicating whether to evaluate the SQL code. If TRUE, the SQL
  code will be executed on the database and the results will be
  returned. Use with caution, as this allows the LLM to execute
  arbitrary SQL code

- output_as_tool:

  Logical indicating whether to return the output as a tool result. If
  TRUE, the output of the SQL query will be sent back to the LLM as a
  tool result. The LLM can then provide a final answer or try another
  query. This can continue until the LLM provides a final answer without
  any SQL code

- return_mode:

  Character string indicating the return mode. Options are:

  - "full": Return a list containing the SQL code, output, and formatted
    output

  - "code": Return only the SQL code

  - "object": Return only the query result object

  - "formatted_output": Return the formatted output: a string detailing
    the SQL code and query result object.This is identical to how the
    LLM would see the output when output_as_tool is TRUE

  - "llm_answer": Return the LLM answer. If output as tool is TRUE, the
    return mode will always be "llm_answer" (since the LLM uses SQL to
    provide a final answer)

## Value

A
[`tidyprompt()`](https://kennispunttwente.github.io/tidyprompt/reference/tidyprompt.md)
with an added
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md)
which will ensure that the LLM will use SQL to answer the prompt

## See also

Other pre_built_prompt_wraps:
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
[`answer_by_chain_of_thought()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_chain_of_thought.md),
[`answer_by_react()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_by_react.md),
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md),
[`prompt_wrap()`](https://kennispunttwente.github.io/tidyprompt/reference/prompt_wrap.md),
[`quit_if()`](https://kennispunttwente.github.io/tidyprompt/reference/quit_if.md),
[`set_system_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/set_system_prompt.md)

Other answer_using_prompt_wraps:
[`answer_using_r()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_r.md),
[`answer_using_tools()`](https://kennispunttwente.github.io/tidyprompt/reference/answer_using_tools.md)

## Examples

``` r
if (FALSE) { # \dontrun{
  # Create an in-memory SQLite database
  conn <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")

  # Create a sample table of customers
  DBI::dbExecute(conn, "
  CREATE TABLE
    customers (
      id INTEGER PRIMARY KEY,
      name TEXT,
      email TEXT,
      country TEXT
    );
  ")

  # Insert some sample customer data
  DBI::dbExecute(conn, "
  INSERT INTO
    customers (name, email, country)
  VALUES
    ('Alice', 'alice@example.com', 'USA'),
    ('Bob', 'bob@example.com', 'Canada'),
    ('Charlie', 'charlie@example.com', 'UK'),
    ('Diana', 'diana@example.com', 'USA');
  ")

  # Create another sample table for orders
  DBI::dbExecute(conn, "
  CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    product TEXT,
    amount REAL,
    order_date TEXT,
    FOREIGN KEY(customer_id) REFERENCES customers(id)
  );
  ")

  # Insert some sample orders
  DBI::dbExecute(conn, "
  INSERT INTO
    orders (customer_id, product, amount, order_date)
  VALUES
    (1, 'Widget', 19.99, '2024-01-15'),
    (1, 'Gadget', 29.99, '2024-01-17'),
    (2, 'Widget', 19.99, '2024-02-10'),
    (3, 'SuperWidget', 49.99, '2024-03-05'),
    (4, 'Gadget', 29.99, '2024-04-01'),
    (1, 'Thingamajig', 9.99, '2024-04-02');
  ")

  # Ask LLM a question which it will answer using the SQL database:
  "Where are my customers from?" |>
    answer_using_sql(
      conn = conn,
      evaluate_code = TRUE,
      output_as_tool = TRUE
    ) |>
    send_prompt(llm_provider_openai())
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # Where are my customers from?
  #
  # You must code in SQL to answer this prompt. You must provide all SQL code
  # between ```sql and ```.
  #
  # Never make assumptions about the possible values in the tables.
  # Instead, execute SQL queries to retrieve information you need.
  #
  # These tables are available in the database:
  #   customers, orders
  #
  # Table descriptions:
  #   - customers
  # Columns: id, name, email, country
  #
  # - orders
  # Columns: order_id, customer_id, product, amount, order_date
  #
  # Your SQL query will be executed on the database. The results will be sent back
  # to you. After seeing the results, you can either provide a final answer or try
  # another SQL query. When you provide your final answer, do not include any SQL code.
  # --- Receiving response from LLM provider: ---
  # ```sql
  # SELECT DISTINCT country FROM customers;
  # ```
  # --- Sending request to LLM provider (gpt-4o-mini): ---
  # --- SQL code: ---
  # SELECT DISTINCT country FROM customers;
  #
  # --- Query results: ---
  #   country
  # 1     USA
  # 2  Canada
  # 3      UK
  # --- Receiving response from LLM provider: ---
  # Based on the query results, your customers are from the following countries:
  # USA, Canada, and UK.
  # [1] "Based on the query results, your customers are from the following countries:
  # USA, Canada, and UK."
} # }
```
