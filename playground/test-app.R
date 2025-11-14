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
# Note: install latest version, `devtools::load_all()` won't work for async process
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
