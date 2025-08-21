# --- Tool conversion: ellmer <-> tidyprompt ---------------------------------

# Cache class signature for ellmer ToolDef so we can robustly detect it
.ELLMER_TOOLDEF_CLASS_SIG <- local({
  sig <- NULL
  if (ellmer_available()) {
    try(
      {
        dummy_fun <- function(x = 1) x
        td <- ellmer::tool(
          dummy_fun,
          description = "dummy",
          arguments = list(x = ellmer::type_number())
        )
        sig <- class(td)
      },
      silent = TRUE
    )
  }
  sig
})

is_ellmer_tool <- function(x) {
  if (is.null(.ELLMER_TOOLDEF_CLASS_SIG)) return(FALSE)
  has_all_classes(x, .ELLMER_TOOLDEF_CLASS_SIG)
}

# Internal: pull the list of <Type>s from a ToolDef's argument object
.ellmer_tool_properties <- function(tooldef) {
  # Prefer S7 slot if available, then fall back to attributes
  props <- tryCatch(tooldef@arguments@properties, error = function(e) NULL)
  if (!is.null(props)) return(props)

  # Fallback: robust attribute-based extraction
  at <- attributes(tooldef@arguments) %||% list()
  reserved <- c(
    ".additional_properties",
    "additional_properties",
    "class",
    "description",
    "required",
    "properties"
  )
  prop_names <- setdiff(names(at), reserved)
  props <- lapply(prop_names, function(nm) at[[nm]])
  names(props) <- prop_names
  props
}

# ---- JSON Schema -> tidyprompt docs (argument shape) -----------------------

# Return just the "type descriptor" used by tidyprompt docs:
# - atomic types are strings: "string", "integer", "numeric", "logical"
# - arrays become "vector <type>" where possible
# - objects become a *named list* of child type descriptors
.json_schema_to_tidyprompt_type_only <- function(s) {
  if (is.null(s)) return("unknown")

  # enums can't be expressed in nested named-lists in tidyprompt's type mini-DSL
  if (!is.null(s$enum)) return("string")

  t <- s$type %||% NULL
  if (identical(t, "string")) return("string")
  if (identical(t, "integer")) return("integer")
  if (identical(t, "number")) return("numeric")
  if (identical(t, "boolean")) return("logical")

  if (identical(t, "array")) {
    items <- s$items %||% list()
    it <- items$type %||% NULL
    if (identical(it, "integer")) return("vector integer")
    if (identical(it, "number")) return("vector numeric")
    if (identical(it, "boolean")) return("vector logical")
    if (identical(it, "string")) return("vector string")
    return("vector unknown")
  }

  if (identical(t, "object") || !is.null(s$properties)) {
    props <- s$properties %||% list()
    out <- lapply(props, .json_schema_to_tidyprompt_type_only)
    # Preserve names; nested enums degrade to "string" (see above)
    return(out)
  }

  "unknown"
}

# Turn a per-argument JSON Schema into a tidyprompt docs entry:
# list(type=..., [default_value=... for match.arg], [description=...])
.json_schema_to_tidyprompt_arg <- function(s) {
  res <- list()

  if (!is.null(s$enum)) {
    res$type <- "match.arg"
    res$default_value <- s$enum
    if (!is.null(s$description)) res$description <- s$description
    return(res)
  }

  res$type <- .json_schema_to_tidyprompt_type_only(s)
  if (!is.null(s$description)) res$description <- s$description
  res
}

# ---- ellmer ToolDef -> tidyprompt docs / function --------------------------

# Build a tidyprompt "docs" list from an ellmer ToolDef
ellmer_tool_to_tidyprompt_docs <- function(tooldef) {
  stopifnot(is_ellmer_tool(tooldef))

  # Name + description are S7 properties
  name <- tryCatch(tooldef@name, error = function(e) NULL)
  desc <- tryCatch(tooldef@description, error = function(e) NULL)

  props <- .ellmer_tool_properties(tooldef)

  args_docs <- list()
  if (length(props)) {
    for (nm in names(props)) {
      # Best-effort: use your ellmer -> JSON Schema converter
      s <- tryCatch(
        ellmer_type_to_json_schema(props[[nm]], strict = TRUE),
        error = function(e) NULL
      )
      if (is.null(s)) {
        args_docs[[nm]] <- list(type = "unknown")
      } else {
        args_docs[[nm]] <- .json_schema_to_tidyprompt_arg(s)
      }
    }
  }

  compact_list(list(
    name = name %||% "tool",
    description = desc %||% "",
    arguments = args_docs,
    return = list() # we can't infer reliably; leave empty
  ))
}

# Create a plain R function wrapper around an ellmer ToolDef and attach docs
# so tidyprompt can use it directly.
ellmer_tool_to_tidyprompt <- function(tooldef) {
  stopifnot(is_ellmer_tool(tooldef))

  docs <- ellmer_tool_to_tidyprompt_docs(tooldef)

  # Determine the correct formals for the wrapper
  get_tool_formals <- function(td) {
    # ToolDef inherits from function, so this usually works:
    fmls <- tryCatch(formals(td), error = function(e) NULL)
    if (!is.null(fmls) && length(fmls)) return(fmls)

    # Fallback: build empty formals from the ToolDef's argument names
    arg_names <- names(.ellmer_tool_properties(td))
    if (!length(arg_names)) return(alist(... = ))
    blanks <- rep(list(quote(expr = )), length(arg_names))
    names(blanks) <- arg_names
    as.pairlist(blanks)
  }

  wrapper <- function() { }
  formals(wrapper) <- get_tool_formals(tooldef)
  body(wrapper) <- quote({
    tool <- attr(sys.function(), "ellmer_tool", exact = TRUE)
    args <- as.list(match.call(expand.dots = TRUE))[-1]
    do.call(tool, args, quote = TRUE)
  })
  # Do NOT change environment(wrapper); just attach the ToolDef
  attr(wrapper, "ellmer_tool") <- tooldef

  tools_add_docs(wrapper, docs)
}

# ---- tidyprompt docs/function -> ellmer ToolDef ----------------------------

# Given tidyprompt docs + function, build an ellmer ToolDef.
# Uses: tools_docs_to_r_json_schema() -> json_schema_to_ellmer_type() -> properties -> tool()
tidyprompt_docs_to_ellmer_tool <- function(
  fun,
  docs,
  convert = TRUE,
  annotations = list(),
  strict = TRUE
) {
  stopifnot(is.function(fun), is.list(docs))

  if (!ellmer_available()) {
    stop(
      "ellmer is not installed; cannot convert tidyprompt docs to ellmer tool."
    )
  }

  # Build JSON Schema for the argument object using your helper
  js <- tools_docs_to_r_json_schema(
    docs,
    all_required = TRUE, # OpenAI-style; ellmer supports required flags but tool() also checks names
    additional_properties = FALSE
  )

  # Convert to a single ellmer Type (object)
  etype <- json_schema_to_ellmer_type(
    schema = js,
    required = TRUE,
    strict = isTRUE(strict)
  )

  # Extract per-argument Type list to feed to tool(arguments=)
  props <- attr(etype, "properties", exact = TRUE)
  if (is.null(props)) {
    # Attribute-based fallback (robust across ellmer versions)
    at <- attributes(etype) %||% list()
    reserved <- c(
      ".additional_properties",
      "additional_properties",
      "class",
      "description",
      "required",
      "properties"
    )
    prop_names <- setdiff(names(at), reserved)
    props <- lapply(prop_names, function(nm) at[[nm]])
    names(props) <- prop_names
  }

  # Ensure argument names match function formals (ellmer::tool() checks this)
  fn_formals <- names(formals(fun))
  # Fill any missing with permissive strings; drop extras
  missing <- setdiff(fn_formals, names(props))
  for (nm in missing) props[[nm]] <- ellmer::type_string(required = FALSE)
  props <- props[fn_formals]

  ellmer::tool(
    fun,
    name = docs$name %||% NULL,
    description = docs$description %||% "",
    arguments = props,
    convert = convert,
    annotations = annotations
  )
}

# Convenience: take a tidyprompt-style tool function and return an ellmer ToolDef
tidyprompt_tool_to_ellmer <- function(
  fun,
  convert = TRUE,
  annotations = list(),
  strict = TRUE
) {
  stopifnot(is.function(fun))
  docs <- tools_get_docs(fun)
  tidyprompt_docs_to_ellmer_tool(
    fun,
    docs,
    convert = convert,
    annotations = annotations,
    strict = strict
  )
}

# ---- Public: normalize a tool for a given target ---------------------------

# Returns a list with both representations when possible:
# $tidyprompt_tool (function with docs) and $ellmer_tool (ToolDef)
normalize_tool_dual <- function(
  tool,
  annotations = list(),
  convert = TRUE,
  strict = TRUE
) {
  if (is.null(tool)) {
    return(list(tidyprompt_tool = NULL, ellmer_tool = NULL))
  }

  if (is_ellmer_tool(tool)) {
    # From ellmer -> tidyprompt
    tp_fn <- ellmer_tool_to_tidyprompt(tool)
    return(list(tidyprompt_tool = tp_fn, ellmer_tool = tool))
  }

  if (is.function(tool)) {
    # From tidyprompt -> ellmer
    ell_tool <- tryCatch(
      tidyprompt_tool_to_ellmer(
        tool,
        convert = convert,
        annotations = annotations,
        strict = strict
      ),
      error = function(e) NULL
    )
    return(list(tidyprompt_tool = tool, ellmer_tool = ell_tool))
  }

  stop(
    "`tool` must be either an ellmer ToolDef or a function (tidyprompt tool)."
  )
}
