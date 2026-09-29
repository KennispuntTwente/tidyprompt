# Preserve array shape when checking ellmer's already-coerced R result. Return
# the original value to callers; validation must not change its R classes.
validate_native_schema <- function(value, schema, strict = FALSE) {
  if (is.null(schema)) return(invisible(TRUE))
  if (!jsonvalidate_installed()) {
    if (strict || schema_has_constraints(schema)) {
      stop("Install 'jsonvalidate' to validate native results against this schema.")
    }
    return(invisible(TRUE))
  }
  as_json_value <- function(x, s) {
    if (identical(s$type, "array")) {
      if (is.data.frame(x)) x <- lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE]))
      return(lapply(as.list(x), as_json_value, s = s$items %||% list()))
    }
    if (is.list(x) && !is.null(names(x))) {
      for (nm in names(x)) {
        # Ellmer represents absent optional scalar fields as NA.
        if (!nm %in% (s$required %||% character()) &&
            is.atomic(x[[nm]]) && length(x[[nm]]) == 1L && is.na(x[[nm]])) {
          x[nm] <- NULL
        } else {
          x[nm] <- list(as_json_value(x[[nm]], s$properties[[nm]] %||% list()))
        }
      }
    }
    x
  }
  json <- jsonlite::toJSON(as_json_value(value, schema), auto_unbox = TRUE,
    null = "null", na = "null", dataframe = "rows")
  valid <- jsonvalidate::json_validate(json, schema_json(schema), engine = "ajv",
    verbose = TRUE, strict = strict)
  if (!isTRUE(valid)) {
    return(llm_feedback(paste0("Your response did not match the expected JSON schema.\n",
      paste(capture.output(print(attr(valid, "errors"))), collapse = "\n"))))
  }
  invisible(TRUE)
}

schema_has_constraints <- function(schema) {
  if (!is.list(schema)) return(FALSE)
  schema_requires_native_json(schema) ||
    any(vapply(schema$properties %||% list(), schema_has_constraints, logical(1))) ||
    (!is.null(schema$items) && schema_has_constraints(schema$items))
}
