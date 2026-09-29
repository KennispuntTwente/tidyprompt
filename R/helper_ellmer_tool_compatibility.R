# R/helper_ellmer_tool_compatability.R

# Lazy cache for ellmer ToolDef class signature.
# Computed on first access so ellmer (a Suggests dependency) does not need
# to be available at tidyprompt load time.
.ellmer_tool_sig_env <- new.env(parent = emptyenv())
.ellmer_tool_sig_env$tooldef <- NULL
.ellmer_tool_sig_env$tooldef_resolved <- FALSE
.ellmer_tool_sig_env$builtin <- NULL
.ellmer_tool_sig_env$builtin_resolved <- FALSE

.get_ellmer_tooldef_sig <- function() {
  if (.ellmer_tool_sig_env$tooldef_resolved) {
    return(.ellmer_tool_sig_env$tooldef)
  }
  if (!ellmer_available()) {
    return(NULL)
  }
  sig <- tryCatch(
    {
      dummy_fun <- function(x = 1) x
      td <- ellmer::tool(
        dummy_fun,
        description = "dummy",
        arguments = list(x = ellmer::type_number())
      )
      class(td)
    },
    error = function(e) NULL
  )
  .ellmer_tool_sig_env$tooldef_resolved <- TRUE
  .ellmer_tool_sig_env$tooldef <- sig
  sig
}

.get_ellmer_builtin_sig <- function() {
  if (.ellmer_tool_sig_env$builtin_resolved) {
    return(.ellmer_tool_sig_env$builtin)
  }
  if (!ellmer_available()) {
    return(NULL)
  }
  sig <- tryCatch(
    {
      ellmer_ns <- asNamespace("ellmer")
      if (exists("ToolBuiltIn", envir = ellmer_ns, inherits = FALSE)) {
        tbi <- ellmer_ns$ToolBuiltIn(name = "dummy")
        class(tbi)
      }
    },
    error = function(e) NULL
  )
  .ellmer_tool_sig_env$builtin_resolved <- TRUE
  .ellmer_tool_sig_env$builtin <- sig
  sig
}

is_ellmer_tool <- function(x) {
  sig <- .get_ellmer_tooldef_sig()
  if (is.null(sig)) {
    return(FALSE)
  }
  has_all_classes(x, sig)
}

is_ellmer_builtin_tool <- function(x) {
  sig <- .get_ellmer_builtin_sig()
  if (is.null(sig)) {
    return(FALSE)
  }
  has_all_classes(x, sig)
}

is_ellmer_any_tool <- function(x) {
  is_ellmer_tool(x) || is_ellmer_builtin_tool(x)
}

# Keep tool objects intact; recursive parameter merging is not tool registration.
merge_ellmer_tools <- function(existing, added) {
  out <- list()
  for (tool in c(existing, added)) {
    name <- ellmer_tool_name(
      tool,
      fallback = if (is.list(tool)) tool$name else NULL
    )
    if (is.null(name)) {
      stop("An ellmer tool must have a name.")
    }
    if (!is.null(out[[name]]) && !identical(out[[name]], tool)) {
      stop(
        "Tool name collision: '",
        name,
        "'. Use distinct names across tool wraps.",
        call. = FALSE
      )
    }
    out[[name]] <- tool
  }
  out
}

ellmer_tool_name <- function(tool, fallback = NULL) {
  props <- tryCatch(
    S7::props(tool),
    error = function(e) NULL
  )
  name <- props$name %||%
    attr(tool, "name", exact = TRUE) %||%
    fallback

  if (is.null(name)) {
    return(NULL)
  }

  as.character(name)
}

rename_ellmer_tool <- function(tooldef, name) {
  stopifnot(is_ellmer_tool(tooldef))

  name <- as.character(name)
  if (!length(name) || !nzchar(name)) {
    stop("`name` must be a non-empty string.")
  }

  current_name <- ellmer_tool_name(tooldef)
  if (identical(current_name, name)) {
    return(tooldef)
  }

  # ToolDef is a value object. Reconstructing it from visible arguments loses
  # ignored formals and can change conversion or annotation metadata.
  S7::prop(tooldef, "name") <- name
  tooldef
}

# Internal: pull the list of <Type>s from a ToolDef's argument object
.ellmer_tool_properties <- function(tooldef) {
  # Prefer S7 slot if available, then fall back to attributes
  props <- tryCatch(tooldef@arguments@properties, error = function(e) NULL)
  if (!is.null(props)) {
    return(props)
  }

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

.ellmer_tool_formals <- function(tooldef) {
  fmls <- tryCatch(formals(tooldef), error = function(e) NULL)
  if (!is.null(fmls) && length(fmls)) {
    return(fmls)
  }

  arg_names <- names(.ellmer_tool_properties(tooldef))
  if (!length(arg_names)) {
    return(alist(... = ))
  }
  blanks <- rep(list(quote(expr = )), length(arg_names))
  names(blanks) <- arg_names
  as.pairlist(blanks)
}

.tidyprompt_arg_is_ignored <- function(arg) {
  if (is.null(arg)) {
    return(FALSE)
  }

  if (is.character(arg) && length(arg) == 1) {
    return(identical(arg, "ignore"))
  }

  if (!is.list(arg)) {
    return(FALSE)
  }

  is.character(arg$type) &&
    length(arg$type) == 1 &&
    identical(arg$type, "ignore")
}

# ---- JSON Schema -> tidyprompt docs (argument shape) -----------------------

# Return just the "type descriptor" used by tidyprompt docs:
# - atomic types are strings: "string", "integer", "numeric", "logical"
# - arrays become "vector <type>" where possible
# - objects become a *named list* of child type descriptors
.json_schema_to_tidyprompt_type_only <- function(s) {
  if (is.null(s)) {
    return("unknown")
  }

  if (isTRUE(s$`x-tidyprompt-ignore`)) {
    return("ignore")
  }

  # enums can't be expressed in nested named-lists in tidyprompt's type mini-DSL
  if (!is.null(s$enum)) {
    return("string")
  }

  t <- s$type %||% NULL
  if (identical(t, "string")) {
    return("string")
  }
  if (identical(t, "integer")) {
    return("integer")
  }
  if (identical(t, "number")) {
    return("numeric")
  }
  if (identical(t, "boolean")) {
    return("logical")
  }

  if (identical(t, "array")) {
    items <- s$items %||% list()
    it <- items$type %||% NULL
    if (identical(it, "integer")) {
      return("vector integer")
    }
    if (identical(it, "number")) {
      return("vector numeric")
    }
    if (identical(it, "boolean")) {
      return("vector logical")
    }
    if (identical(it, "string")) {
      return("vector string")
    }
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
    if (!is.null(s$description)) {
      res$description <- s$description
    }
    return(res)
  }

  res$type <- .json_schema_to_tidyprompt_type_only(s)
  if (!is.null(s$description)) {
    res$description <- s$description
  }
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
  arg_names <- names(.ellmer_tool_formals(tooldef))
  if (!length(arg_names)) {
    arg_names <- names(props)
  }

  args_docs <- list()
  if (length(arg_names)) {
    for (nm in arg_names) {
      if (!nm %in% names(props)) {
        args_docs[[nm]] <- list(type = "ignore")
        next
      }

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
    'return' = list() # we can't infer reliably; leave empty
  ))
}

# Create a plain R function wrapper around an ellmer ToolDef and attach docs
# so tidyprompt can use it directly.
ellmer_tool_to_tidyprompt <- function(tooldef) {
  stopifnot(is_ellmer_tool(tooldef))

  docs <- ellmer_tool_to_tidyprompt_docs(tooldef)

  wrapper <- function() {}
  formals(wrapper) <- .ellmer_tool_formals(tooldef)
  body(wrapper) <- quote({
    tool <- attr(sys.function(), "ellmer_tool", exact = TRUE)
    args <- lapply(
      as.list(match.call(expand.dots = TRUE))[-1],
      eval,
      envir = parent.frame()
    )
    do.call(tool, args)
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
  name = docs$name %||% NULL,
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

  # Build JSON Schema for the argument object using your helper.
  # Respect which formals have defaults: only formals without defaults are required.
  fn_formals <- formals(fun)
  has_default <- vapply(
    fn_formals,
    function(x) !identical(x, quote(expr = )),
    logical(1)
  )
  required_args <- names(fn_formals)[!has_default]

  js <- tools_docs_to_r_json_schema(
    docs,
    all_required = FALSE,
    additional_properties = FALSE
  )
  # Override the required list based on formals analysis
  if (length(required_args) > 0) {
    js$required <- intersect(required_args, names(js$properties %||% list()))
  } else {
    js$required <- NULL
  }

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
  for (nm in missing) {
    arg_doc <- docs$arguments[[nm]] %||% NULL
    if (
      .tidyprompt_arg_is_ignored(arg_doc) &&
        exists("type_ignore", envir = asNamespace("ellmer"), inherits = FALSE)
    ) {
      props[[nm]] <- ellmer_type_ignore_compat(
        description = arg_doc$description %||% NULL,
        required = FALSE
      )
    } else {
      props[[nm]] <- ellmer::type_string(required = FALSE)
    }
  }
  props <- props[fn_formals]

  ellmer::tool(
    fun,
    name = name,
    description = docs$description %||% "",
    arguments = props,
    convert = convert,
    annotations = annotations
  )
}

# Convenience: take a tidyprompt-style tool function and return an ellmer ToolDef
tidyprompt_tool_to_ellmer <- function(
  fun,
  name = NULL,
  convert = TRUE,
  annotations = list(),
  strict = TRUE
) {
  stopifnot(is.function(fun))
  original <- attr(fun, "ellmer_tool", exact = TRUE)
  if (!is.null(original)) {
    return(if (is.null(name)) original else rename_ellmer_tool(original, name))
  }
  docs <- tools_get_docs(fun, name = name %||% NULL)
  tidyprompt_docs_to_ellmer_tool(
    ellmer_tool_result_wrapper(fun),
    docs,
    name = name %||% docs$name %||% NULL,
    convert = convert,
    annotations = annotations,
    strict = strict
  )
}

is_native_tool_content <- function(x) {
  ellmer_available() && S7::S7_inherits(x, ellmer::Content)
}

normalize_tidyprompt_tool_result <- function(result, native = TRUE) {
  rich <- is_native_tool_content(result) ||
    (is.list(result) &&
      length(result) > 0L &&
      all(vapply(result, is_native_tool_content, logical(1))))
  pending <- inherits(result, "promise")
  if (rich || pending) {
    if (!native) {
      stop(
        "Rich content and asynchronous tool results require native ellmer execution."
      )
    }
    return(result)
  }
  if (is.null(result)) {
    return(if (native) NULL else "")
  }
  if (inherits(result, "json")) {
    return(result)
  }
  if (is.character(result)) {
    return(paste(result, collapse = "\n"))
  }
  # Serialize collections once, before ellmer's result contract is applied.
  # Named lists become objects; data frames become arrays of row objects.
  jsonlite::toJSON(result, auto_unbox = TRUE, dataframe = "rows", null = "null")
}

ellmer_tool_result_wrapper <- function(fun) {
  force(fun)
  wrapper <- function() {
    args <- as.list(match.call())[-1L]
    args <- lapply(args, eval, envir = parent.frame())
    normalize_tidyprompt_tool_result(do.call(fun, args))
  }
  formals(wrapper) <- formals(fun)
  wrapper
}

invoke_tidyprompt_tool <- function(tool, arguments) {
  native <- attr(tool, "ellmer_tool", exact = TRUE)
  if (is.null(native)) {
    # Ordinary R tools retain the historical simplified JSON arguments.
    arguments <- jsonlite::fromJSON(jsonlite::toJSON(
      arguments,
      auto_unbox = TRUE
    ))
    return(do.call(tool, arguments))
  }
  if (isTRUE(native@convert)) {
    extra <- setdiff(names(arguments), names(native@arguments@properties))
    if (length(extra)) {
      stop("Unused tool arguments: ", paste(extra, collapse = ", "))
    }
    # Ellmer has no exported argument-coercion API. Isolate this capability
    # check and test it across our supported versions rather than approximating
    # its factors, data frames, missing values and optional argument semantics.
    convert <- get0(
      "convert_from_type",
      envir = asNamespace("ellmer"),
      inherits = FALSE
    )
    if (!is.function(convert)) {
      stop("This ellmer version requires native tool execution.")
    }
    arguments <- convert(arguments, native@arguments)
    arguments <- Filter(Negate(is.null), arguments)
  }
  tryCatch(
    do.call(native, arguments),
    ellmer_error_tool_context_unavailable = function(e) {
      rlang::abort(
        "Tools using `ellmer::tool_context()` require an ellmer-backed provider.",
        parent = e
      )
    }
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
    # From ellmer ToolDef -> tidyprompt
    tp_fn <- ellmer_tool_to_tidyprompt(tool)
    return(list(tidyprompt_tool = tp_fn, ellmer_tool = tool))
  }

  if (is_ellmer_builtin_tool(tool)) {
    # ToolBuiltIn can only be used in native ellmer mode; no tidyprompt equivalent
    return(list(tidyprompt_tool = NULL, ellmer_tool = tool))
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
    "`tool` must be a function, ellmer ToolDef, or ellmer ToolBuiltIn."
  )
}
