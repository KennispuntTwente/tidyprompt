# R/ellmer-compat.R

ellmer_available <- function() {
  requireNamespace("ellmer", quietly = TRUE)
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
  if (is.null(cls)) return(FALSE)
  all(cls %in% class(x))
}

is_ellmer_type <- function(x) {
  if (is.null(.ELLMER_CLASS_SIGNATURES)) return(FALSE)
  any(vapply(.ELLMER_CLASS_SIGNATURES, has_all_classes, logical(1), x = x))
}

# --- JSON Schema -> ellmer::type_* -----------------------------------------

# Recursively build an ellmer type from a JSON Schema (list)
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
      schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "number")) {
    return(ellmer::type_number(
      schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "integer")) {
    return(ellmer::type_integer(
      schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "boolean")) {
    return(ellmer::type_boolean(
      schema$description %||% NULL,
      required = required
    ))
  }
  if (identical(t, "array")) {
    item_schema <- schema$items %||% list(type = "string")
    return(ellmer::type_array(
      item = json_schema_to_ellmer_type(
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

    # Build named args: each property becomes name = type_*(..., required=...)
    ellmer_fields <- lapply(names(props), function(p) {
      json_schema_to_ellmer_type(
        props[[p]],
        required = isTRUE(p %in% req),
        strict = strict
      )
    })
    names(ellmer_fields) <- names(props)

    # Additional properties (unknown keys)
    addl <- schema$additionalProperties
    addl_flag <- if (is.null(addl)) !isTRUE(strict) else isTRUE(addl)

    return(do.call(
      ellmer::type_object,
      c(
        ellmer_fields,
        list(
          description = schema$description %||% NULL,
          .additional_properties = addl_flag,
          required = required
        )
      )
    ))
  }

  # Fallback: a permissive "anything" object if we can't infer
  ellmer::type_object(
    description = schema$description %||% NULL,
    .additional_properties = TRUE,
    required = required
  )
}

# --- ellmer::type_* -> JSON Schema (best-effort) ----------------------------

ellmer_type_to_json_schema <- function(x, strict = FALSE, description = NULL) {
  if (is.null(.ELLMER_CLASS_SIGNATURES)) {
    stop("ellmer is not installed; cannot convert ellmer types to JSON Schema.")
  }

  sig <- .ELLMER_CLASS_SIGNATURES

  # Scalars
  if (has_all_classes(x, sig$string)) {
    return(compact_list(list(type = "string", description = description)))
  }
  if (has_all_classes(x, sig$number)) {
    return(compact_list(list(type = "number", description = description)))
  }
  if (has_all_classes(x, sig$integer)) {
    return(compact_list(list(type = "integer", description = description)))
  }
  if (has_all_classes(x, sig$boolean)) {
    return(compact_list(list(type = "boolean", description = description)))
  }
  if (has_all_classes(x, sig$enum)) {
    # Try to read choices off the object; if not, use placeholder
    vals <- attr(x, "values", exact = TRUE)
    if (is.null(vals)) vals <- attr(x, "levels", exact = TRUE)
    return(compact_list(list(
      enum = vals %||% character(),
      description = description
    )))
  }

  # Array
  if (has_all_classes(x, sig$array)) {
    item <- attr(x, "item", exact = TRUE)
    return(compact_list(list(
      type = "array",
      items = ellmer_type_to_json_schema(item, strict = strict),
      description = description
    )))
  }

  # Object
  if (has_all_classes(x, sig$object)) {
    # ellmer::type_object stores fields as attributes; we duck-type by scanning
    # for ellmer-typed attributes (not perfect, but works in practice).
    at <- attributes(x) %||% list()
    # pull out additional properties flag if present
    addl <- at$.additional_properties %||% !isTRUE(strict)

    # properties = every attribute that itself looks like an ellmer type
    prop_names <- names(at)
    prop_names <- setdiff(
      prop_names,
      c(".additional_properties", "class", "description", "required")
    )

    properties <- list()
    required <- character()
    for (nm in prop_names) {
      val <- at[[nm]]
      if (is_ellmer_type(val)) {
        properties[[nm]] <- ellmer_type_to_json_schema(val, strict = strict)
        # Try to detect optionality (ellmer scalars/fields accept required=FALSE)
        req_flag <- attr(val, "required", exact = TRUE)
        if (!identical(req_flag, FALSE)) required <- c(required, nm)
      }
    }

    out <- compact_list(list(
      type = "object",
      properties = properties,
      required = if (length(required)) unique(required) else NULL,
      additionalProperties = isTRUE(addl),
      description = description %||% attr(x, "description", exact = TRUE)
    ))
    return(out)
  }

  # Fallback permissive
  compact_list(list(
    type = "object",
    additionalProperties = TRUE,
    description = description
  ))
}

compact_list <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

# --- Public: normalize a schema for a given target --------------------------

# Returns a list with both representations when possible:
# $json_schema and $ellmer_type, so callers can pick what they need.
normalize_schema_dual <- function(schema, strict = FALSE) {
  if (is.null(schema)) return(list(json_schema = NULL, ellmer_type = NULL))

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
