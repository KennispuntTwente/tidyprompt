#' @title
#' Add an image to a tidyprompt (multimodal)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Attach an image to a [tidyprompt()] for use with multimodal LLMs.
#'
#' Supports 'ollama', 'openai' (completions & responses) and 'ellmer'-backed providers.
#' Can convert from and to 'ellmer' content image objects as needed.
#'
#' @param prompt A single string or a [tidyprompt()] object
#' @param image An image reference. One of:
#'   - a local file path (e.g., "path/to/image.png")
#'   - a URL (e.g., "https://.../image.jpg")
#'   - a base64 string (optionally with data URL prefix)
#'   - a raw vector of bytes
#'   - a plot object (e.g., base `recordedplot`, `ggplot`, or grid grob) to be
#'     rasterized automatically
#'   - an 'ellmer' content object created by `ellmer::content_image_url()`,
#'     `ellmer::content_image_file()`, or `ellmer::content_image_plot()`
#'     (this will work with both regular providers and 'ellmer'-backed providers)#'
#' For OpenAI Responses API, URLs must point directly to an image resource (not an HTML
#' page) and are transmitted as a scalar string `image_url` with optional `detail`.
#' Supplying a webpage URL (e.g. a Wikipedia media viewer link) will result in a
#' provider 400 error expecting an image URL string
#'
#' @param alt Optional alternative text/alt description
#' @param detail Detail hint for some providers (OpenAI): one of "auto", "low",
#' "high"
#' @param mime Optional mime-type if providing raw/base64 without data URL
#' (e.g., "image/png")
#'
#' @return A [tidyprompt()] with an added [prompt_wrap()] which will
#' attach an image to the prompt for use with multimodal LLMs
#'
#' @export
#'
#' @family pre_built_prompt_wraps
#' @family miscellaneous_prompt_wraps
#'
#' @example inst/examples/add_image.R
add_image <- function(
  prompt,
  image,
  alt = NULL,
  detail = c("auto", "low", "high"),
  mime = NULL
) {
  detail <- match.arg(detail)
  prompt <- tidyprompt(prompt)

  part <- .tp_normalize_image_input(
    image,
    mime = mime,
    alt = alt,
    detail = detail
  )

  parameter_fn <- function(llm_provider) {
    existing <- llm_provider$parameters$.add_image_parts %||% list()
    new_parts <- c(existing, list(part))
    llm_provider$parameters$.add_image_parts <- new_parts
    list(.add_image_parts = new_parts)
  }

  prompt_wrap(
    prompt = prompt,
    modify_fn = NULL,
    parameter_fn = parameter_fn,
    name = "add_image"
  )
}

# Internal: normalize input into a provider-agnostic image part
.tp_normalize_image_input <- function(
  image,
  mime = NULL,
  alt = NULL,
  detail = "auto"
) {
  stopifnot(!missing(image))

  # Pass-through for ellmer content objects (content_image_url/file/plot)
  if (isTRUE(requireNamespace("ellmer", quietly = TRUE))) {
    if (.tp_is_ellmer_content(image)) {
      if (!isTRUE(requireNamespace("S7", quietly = TRUE))) {
        stop(
          "The S7 package is required to handle ellmer content image objects, but is not installed."
        )
      }
      props <- S7::props(image)

      # Retrieve detail, prioritizing props over argument
      detail <- props[["detail"]] %||% detail

      # Retrieve url/data and set as 'image' to normalize with regular input
      image <- if (!is.null(props[["url"]])) {
        props[["url"]]
      } else if (!is.null(props[["data"]])) {
        props[["data"]]
      } else {
        stop(
          "'ellmer' content image must have either '@url' or '@data' property"
        )
      }
    }
  }

  # Plot objects (base recorded plots, ggplot, grid grobs, etc.)
  if (.tp_is_plot_object(image)) {
    plot_raw <- .tp_plot_to_png_raw(image)
    b64 <- jsonlite::base64_enc(plot_raw)
    return(list(
      kind = "image",
      source = "b64",
      data = as.character(b64),
      mime = "image/png",
      alt = alt,
      detail = detail
    ))
  }

  # raw vector
  if (is.raw(image)) {
    b64 <- jsonlite::base64_enc(image)
    return(list(
      kind = "image",
      source = "b64",
      data = as.character(b64),
      mime = mime %||% "image/png",
      alt = alt,
      detail = detail
    ))
  }

  # base64 data URL string
  if (
    is.character(image) && length(image) == 1 && grepl("^data:image/", image)
  ) {
    # data:image/<type>;base64,<payload>
    parts <- strsplit(image, ",", fixed = TRUE)[[1]]
    header <- parts[1]
    payload <- parts[length(parts)]
    mm <- sub("^data:(.*?);base64$", "\\1", header)
    return(list(
      kind = "image",
      source = "b64",
      data = as.character(payload),
      mime = mm %||% mime %||% "image/png",
      alt = alt,
      detail = detail
    ))
  }

  # bare base64 (heuristic: contains only base64 chars and is long)
  if (
    is.character(image) &&
      length(image) == 1 &&
      grepl("^[A-Za-z0-9+/=\n\r]+$", image) &&
      nchar(image) > 128
  ) {
    return(list(
      kind = "image",
      source = "b64",
      data = gsub("[\n\r]", "", image),
      mime = mime %||% "image/png",
      alt = alt,
      detail = detail
    ))
  }

  # URL
  if (is.character(image) && length(image) == 1 && grepl("^https?://", image)) {
    return(list(
      kind = "image",
      source = "url",
      data = as.character(image),
      mime = NULL,
      alt = alt,
      detail = detail
    ))
  }

  # File path
  if (is.character(image) && length(image) == 1 && file.exists(image)) {
    raw <- readBin(image, what = "raw", n = file.info(image)$size)
    b64 <- jsonlite::base64_enc(raw)
    # Try to infer mime from extension
    mm <- mime %||% .tp_guess_mime_from_path(image) %||% "image/png"
    return(list(
      kind = "image",
      source = "b64",
      data = as.character(b64),
      mime = mm,
      alt = alt,
      detail = detail
    ))
  }

  stop(sprintf(
    "Unsupported `image` input (class: %s); provide a url, file path, base64 string, or raw bytes.",
    paste(class(image), collapse = "/")
  ))
}

.tp_is_plot_object <- function(x) {
  if (is.null(x)) {
    return(FALSE)
  }
  inherits(x, "recordedplot") ||
    inherits(x, "ggplot") ||
    inherits(x, "grob") ||
    inherits(x, "gTree") ||
    inherits(x, "gtable") ||
    inherits(x, "trellis")
}

.tp_plot_to_png_raw <- function(
  plot_obj,
  width = 800,
  height = 600,
  res = 96,
  bg = "white"
) {
  file <- tempfile(fileext = ".png")
  on.exit(unlink(file), add = TRUE)

  device_open <- TRUE
  grDevices::png(
    filename = file,
    width = width,
    height = height,
    res = res,
    units = "px",
    bg = bg
  )
  on.exit(
    {
      if (device_open) {
        try(grDevices::dev.off(), silent = TRUE)
      }
    },
    add = TRUE
  )

  .tp_draw_plot_object(plot_obj)

  grDevices::dev.off()
  device_open <- FALSE

  size <- file.info(file)$size
  if (is.na(size) || size <= 0) {
    stop("Unable to convert plot to image; rendered file is empty.")
  }

  readBin(file, what = "raw", n = size)
}

.tp_draw_plot_object <- function(plot_obj) {
  if (inherits(plot_obj, "recordedplot")) {
    grDevices::replayPlot(plot_obj)
    return(invisible(NULL))
  }

  if (
    inherits(plot_obj, "grob") ||
      inherits(plot_obj, "gTree") ||
      inherits(plot_obj, "gtable")
  ) {
    if (!requireNamespace("grid", quietly = TRUE)) {
      stop(
        "'grid' package is required to handle 'grob'/'gTree'/'gtable' plot objects; please install it"
      )
    }
    grid::grid.newpage()
    grid::grid.draw(plot_obj)
    return(invisible(NULL))
  }

  if (inherits(plot_obj, "ggplot")) {
    print(plot_obj)
    return(invisible(NULL))
  }

  if (inherits(plot_obj, "trellis")) {
    print(plot_obj)
    return(invisible(NULL))
  }

  print(plot_obj)
  invisible(NULL)
}

.tp_guess_mime_from_path <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (identical(ext, "png")) {
    return("image/png")
  }
  if (identical(ext, "jpg") || identical(ext, "jpeg")) {
    return("image/jpeg")
  }
  if (identical(ext, "gif")) {
    return("image/gif")
  }
  if (identical(ext, "webp")) {
    return("image/webp")
  }
  if (identical(ext, "bmp")) {
    return("image/bmp")
  }
  NULL
}

# Heuristic: detect ellmer content objects (e.g., content_image_*())
.tp_is_ellmer_content <- function(x) {
  cl <- class(x)
  if (length(cl) == 0L) {
    return(FALSE)
  }
  any(grepl("^Content", cl)) ||
    any(grepl("^ellmer", cl)) ||
    any(grepl("S7_object", cl))
}

# Try to coerce an ellmer content object (content_image_url/file/plot)
# into a generic image part understood by non-ellmer providers.
# Returns a list like .tp_normalize_image_input() or NULL if not possible.
.tp_ellmer_to_generic_part <- function(obj, detail = NULL) {
  # Access helpers: support S4 slots and list/S7 fields
  get_field <- function(o, name) {
    # S4 slot
    if (base::isS4(o) && name %in% methods::slotNames(o)) {
      val <- tryCatch(methods::slot(o, name), error = function(e) NULL)
      if (!is.null(val)) return(val)
    }
    # list/S3/S7 via [[ or getElement
    val <- tryCatch(o[[name]], error = function(e) NULL)
    if (!is.null(val)) {
      return(val)
    }
    val <- tryCatch(getElement(o, name), error = function(e) NULL)
    if (!is.null(val)) {
      return(val)
    }
    # Fallback: programmatic `$` access (works for many S3/S7)
    val <- tryCatch(do.call("$", list(o, name)), error = function(e) NULL)
    if (!is.null(val)) {
      return(val)
    }
    NULL
  }

  obj_detail <- get_field(obj, "detail") %||% detail

  # Remote image via URL
  url <- get_field(obj, "url")
  if (!is.null(url) && is.character(url) && length(url) == 1 && nzchar(url)) {
    return(list(
      kind = "image",
      source = "url",
      data = as.character(url),
      mime = NULL,
      alt = NULL,
      detail = obj_detail %||% "auto"
    ))
  }

  # Local file image
  path <- get_field(obj, "path")
  if (
    !is.null(path) &&
      is.character(path) &&
      length(path) == 1 &&
      file.exists(path)
  ) {
    raw <- readBin(path, what = "raw", n = file.info(path)$size)
    b64 <- jsonlite::base64_enc(raw)
    mime <- get_field(obj, "content_type") %||%
      .tp_guess_mime_from_path(path) %||%
      "image/png"
    return(list(
      kind = "image",
      source = "b64",
      data = as.character(b64),
      mime = mime,
      alt = NULL,
      detail = obj_detail %||% "auto"
    ))
  }

  # Unknown form; cannot coerce generically (e.g., content_image_plot)
  NULL
}
