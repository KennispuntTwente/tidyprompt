# Streaming LLM responses to Shiny with ipc

This vignette shows a minimal example of how to stream a LLM response
gathered with ‘tidyprompt’ to a Shiny app in real-time.

Shiny apps run on a single R process, meaning that when you call an LLM
synchronously, the UI will be blocked until the response is complete.
Therefore, you typically want to use
[`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md)
in an asynchronous manner (e.g., with the ‘future’ and ‘promises’
packages).

If you just want to show the final LLM response after it is complete,
this is straightforward. But if you show the response as it streams in
token-by-token, this is more complicated.

For LLM providers created with ‘tidyprompt’ that support streaming
responses, you can provide a `stream_callback` function that is called
for each token (or text chunk) as it arrives from the LLM. We can
leverage this to push the tokens into the Shiny app in real-time. Using
the ‘ipc’ package, we can send messages from the background R process
(where the LLM call runs) back to the main Shiny R process to update a
reactive value that holds the streamed text.

Below is a minimal example of how to achieve this. We will:

- create an `llm_provider` with streaming enabled;
- define a `stream_callback` that writes tokens into an
  `ipc::shinyQueue`;
- start a `future` in a separate R process
  (`future::plan(multisession)`) where we call
  [`send_prompt()`](https://kennispunttwente.github.io/tidyprompt/reference/send_prompt.md);
- consume the queue from the Shiny main process to update the UI,
  showing a live stream of LLM output

## Example app

``` r
packages <- c("shiny", "ipc", "future", "tidyprompt")
for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}
library(shiny)
library(ipc)
library(future)
library(promises)
library(tidyprompt)

# Enable asynchronous processing
future::plan(future::multisession)

# Base provider (OpenAI, streaming enabled by default)
base_provider <- llm_provider_openai()

ui <- fluidPage(
  titlePanel("tidyprompt streaming demo"),

  sidebarLayout(
    sidebarPanel(
      textInput(
        "prompt",
        "Prompt",
        value = "Tell me a short story about a cat and a robot."
      ),
      actionButton("run", "Ask model"),
      helpText("Tokens will appear below as they stream in.")
    ),

    mainPanel(
      verbatimTextOutput("partial_response")
    )
  )
)

server <- function(input, output, session) {
  # Queue to bridge async future back into Shiny
  queue <- shinyQueue()
  queue$consumer$start(100)  # process queue every 100 ms

  # Reactive that holds the accumulated streamed text
  partial_response <- reactiveVal("")

  # Streaming callback run inside the provider
  stream_cb <- function(token, meta) {
    # meta$partial_response is the accumulated text so far
    queue$producer$fireAssignReactive(
      "partial_response",
      meta$partial_response
    )
    invisible(TRUE)
  }

  # Clone provider for this session and attach callback + streaming
  provider <- base_provider$clone()
  provider$parameters$stream <- TRUE
  provider$stream_callback <- stream_cb

  # Expose the reactive value to the UI
  output$partial_response <- renderText({
    req(partial_response())
    partial_response()
  })

  observeEvent(input$run, {
    # Reset current streamed text on each run
    partial_response("")

    user_prompt <- input$prompt

    future_promise(
      {
        tidyprompt::send_prompt(
          prompt = user_prompt,
          llm_provider = provider,
          return_mode = "only_response"
        )
      },
      globals = list(
        user_prompt = user_prompt,
        provider = provider
      )
    ) %>%
      then(
        onFulfilled = function(value) {
          # Final response once streaming finishes
          partial_response(value)
        },
        onRejected = function(error) {
          showNotification(
            paste("Error:", error$message),
            type = "error"
          )
          print(error)
        }
      )

    NULL
  })
}

shinyApp(ui = ui, server = server)
```
