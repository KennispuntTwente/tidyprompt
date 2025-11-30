# R/helper_ellmer_json_compatability.R

ellmer_available <- function() {
  requireNamespace("ellmer", quietly = TRUE)
}

if (!ellmer_available()) {
  install.packages("ellmer", repos = "https://cran.rstudio.com")
}

# --- Detectors --------------------------------------------------------------

is_json_schema_list <- function(x) {
  is.list(x) &&
    (any(c("$schema", "type", "properties", "items", "enum") %in% names(x)) ||
      # Top-level "name/schema/strict" wrapper we sometimes build:
      identical(sort(names(x)), sort(c("name", "schema", "strict"))) ||
      # Loose heuristic for object schemas:
      (!is.null(x$type) && is.character(x$type)))
}

# Cache class signatures of ellmer prototypes (robust detection)
.ELLMER_CLASS_SIGNATURES <- local({
  sig <- NULL
  if (ellmer_available()) {
    try(
      {
        sig <- list(
          string = class(ellmer::type_string()),
          number = class(ellmer::type_number()),
          integer = class(ellmer::type_integer()),
          boolean = class(ellmer::type_boolean()),
          enum = class(ellmer::type_enum(c("a", "b"))),
          array = class(ellmer::type_array(ellmer::type_string())),
          object = class(ellmer::type_object(x = ellmer::type_string()))
        )
      },
      silent = TRUE
    )
  }
  sig
})

has_all_classes <- function(x, cls) {
  if (is.null(cls)) {
    return(FALSE)
  }
  all(cls %in% class(x))
}

is_ellmer_type <- function(x) {
  if (is.null(.ELLMER_CLASS_SIGNATURES)) {
    return(FALSE)
  }
  any(vapply(.ELLMER_CLASS_SIGNATURES, has_all_classes, logical(1), x = x))
}

# --- JSON Schema -> ellmer::type_* -----------------------------------------

json_schema_to_ellmer_type <- function(
  schema,
  required = TRUE,
  strict = FALSE
) {
  if (!ellmer_available()) {
    stop("ellmer is not installed; cannot convert JSON Schema to ellmer types.")
  }

  # Unwrap "json_schema" wrapper shape {name, schema, strict}
  if (!is.null(schema$schema) && is.list(schema$schema)) {
    schema <- schema$schema
  }

  # Handle enum
  if (!is.null(schema$enum)) {
    return(ellmer::type_enum(
      schema$enum,
      description = schema$description %||% NULL,
      required = required
    ))
  }

  t <- schema$type %||% NULL

  if (identical(t, "string")) {
    return(ellmer::type_string(
      description = schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "number")) {
    return(ellmer::type_number(
      description = schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "integer")) {
    return(ellmer::type_integer(
      description = schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "boolean")) {
    return(ellmer::type_boolean(
      description = schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "array")) {
    item_schema <- schema$items %||% list(type = "string")
    return(ellmer::type_array(
      items = json_schema_to_ellmer_type(
        item_schema,
        required = TRUE,
        strict = strict
      ),
      description = schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "object") || !is.null(schema$properties)) {
    props <- schema$properties %||% list()
    req <- schema$required %||% character()

    ellmer_fields <- lapply(names(props), function(p) {
      json_schema_to_ellmer_type(
        props[[p]],
        required = isTRUE(p %in% req),
        strict = strict
      )
    })
    names(ellmer_fields) <- names(props)

    addl <- schema$additionalProperties
    addl_flag <- if (is.null(addl)) !isTRUE(strict) else isTRUE(addl)

    args <- c(
      ellmer_fields,
      list(
        .description = schema$description %||% NULL,
        .additional_properties = addl_flag,
        .required = required
      )
    )

    # Drop NULLs so nothing bogus leaks into `...`
    args <- args[!vapply(args, is.null, logical(1))]

    return(do.call(ellmer::type_object, args))
  }

  # Fallback: permissive object
  ellmer::type_object(
    .description = schema$description %||% NULL,
    .additional_properties = TRUE,
    .required = required
  )
}

# --- ellmer::type_* -> JSON Schema (best-effort) ----------------------------

ellmer_type_to_json_schema <- function(x, strict = FALSE, description = NULL) {
  if (is.null(.ELLMER_CLASS_SIGNATURES)) {
    stop("ellmer is not installed; cannot convert ellmer types to JSON Schema.")
  }

  sig <- .ELLMER_CLASS_SIGNATURES
  desc <- description %||% attr(x, "description", exact = TRUE)

  # --- Basic scalars: prefer S7 'type' property over class signatures ----
  basic_type <- attr(x, "type", exact = TRUE)
  if (
    is.character(basic_type) &&
      length(basic_type) == 1 &&
      basic_type %in% c("string", "number", "integer", "boolean")
  ) {
    return(compact_list(list(type = basic_type, description = desc)))
  }

  # --- Enum: prefer attribute-based detection for robustness --------------
  enum_vals <- attr(x, "values", exact = TRUE) %||%
    attr(x, "levels", exact = TRUE)
  if (!is.null(enum_vals) || has_all_classes(x, sig$enum)) {
    if (is.null(enum_vals)) {
      enum_vals <- character()
    }
    return(compact_list(list(enum = enum_vals, description = desc)))
  }

  # --- Array ---------------------------------------------------------------
  if (has_all_classes(x, sig$array)) {
    items <- attr(x, "items", exact = TRUE) %||% attr(x, "item", exact = TRUE)
    return(compact_list(list(
      type = "array",
      description = desc, # <-- move before items
      items = if (!is.null(items)) {
        ellmer_type_to_json_schema(items, strict = strict)
      } else {
        NULL
      }
    )))
  }

  # --- Object --------------------------------------------------------------
  if (has_all_classes(x, sig$object)) {
    addl_attr <- attr(x, ".additional_properties", exact = TRUE)
    if (is.null(addl_attr)) {
      addl_attr <- attr(x, "additional_properties", exact = TRUE)
    }
    addl <- if (is.null(addl_attr)) !isTRUE(strict) else isTRUE(addl_attr)

    props <- attr(x, "properties", exact = TRUE)
    if (is.null(props)) {
      at <- attributes(x) %||% list()
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

    properties <- list()
    required <- character()
    if (length(props)) {
      for (nm in names(props)) {
        val <- props[[nm]]
        if (is_ellmer_type(val)) {
          properties[[nm]] <- ellmer_type_to_json_schema(val, strict = strict)
          req_flag <- attr(val, "required", exact = TRUE)
          if (!identical(req_flag, FALSE)) required <- c(required, nm)
        }
      }
    }

    return(compact_list(list(
      type = "object",
      description = desc,
      properties = properties,
      required = if (length(required)) unique(required) else NULL,
      additionalProperties = isTRUE(addl)
    )))
  }

  # --- Fallback permissive -------------------------------------------------
  compact_list(list(
    type = "object",
    additionalProperties = TRUE,
    description = desc
  ))
}


compact_list <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

# --- Public: normalize a schema for a given target --------------------------

# Returns a list with both representations when possible:
# $json_schema and $ellmer_type, so callers can pick what they need.
normalize_schema_dual <- function(schema, strict = FALSE) {
  if (is.null(schema)) {
    return(list(json_schema = NULL, ellmer_type = NULL))
  }

  if (is_ellmer_type(schema)) {
    # ellmer type supplied; attempt reverse conversion for OpenAI/Ollama
    json_s <- tryCatch(
      ellmer_type_to_json_schema(schema, strict = strict),
      error = function(e) NULL
    )
    return(list(json_schema = json_s, ellmer_type = schema))
  }

  if (is_json_schema_list(schema)) {
    # JSON Schema supplied; convert forward for ellmer
    ellmer_t <- tryCatch(
      json_schema_to_ellmer_type(schema, required = TRUE, strict = strict),
      error = function(e) NULL
    )
    return(list(json_schema = schema, ellmer_type = ellmer_t))
  }

  stop(
    "`schema` must be either a JSON Schema list or an ellmer type_*() object."
  )
}
