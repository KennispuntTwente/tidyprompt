# minimal test for tidyprompt + ellmer tools with llm_provider_ellmer()
devtools::load_all()
library(ellmer)

## 1) Define tools ------------------------------------------------------------

# A) ellmer-native tool (ToolDef)
get_current_time <- ellmer::tool(
  function(tz = "UTC") format(Sys.time(), tz = tz, usetz = TRUE),
  name = "get_current_time",
  description = "Returns the current time.",
  arguments = list(
    tz = ellmer::type_string("IANA time zone, e.g. 'Europe/Amsterdam'.", required = FALSE)
  )
)

# B) tidyprompt-style tool (plain R function + docs)
calc_sum <- function(a, b) a + b
calc_sum <- tools_add_docs(
  calc_sum,
  list(
    name = "calc_sum",
    description = "Add two numbers.",
    arguments = list(
      a = list(type = "numeric", description = "First addend"),
      b = list(type = "numeric", description = "Second addend")
    ),
    return = list(description = "The numeric sum of a and b")
  )
)

## 2) Make provider (ellmer backend) -----------------------------------------
lp <- llm_provider_ellmer(ellmer::chat_openai(model = "gpt-4o-mini"))

## 3) Build prompt with tool calling -----------------------------------------
p <- tidyprompt("
  You can call tools if needed.
  1) Get the current time for Europe/Amsterdam (use get_current_time).
  2) Add 2 and 3 (use calc_sum).
  Then reply with a single short sentence mentioning both results.
")

p_tools <- answer_using_tools(
  p,
  tools = list(get_current_time, calc_sum), # mix of ToolDef + function
  type  = "auto"                            # will resolve to 'ellmer' for your provider
)

## 4) Send it -----------------------------------------------------------------
res <- send_prompt(p_tools, llm_provider = lp, return_mode = "full")

res
