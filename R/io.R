
process_has_input_connection <- function(self, private) {
  "!DEBUG process_has_input_connection `private$get_short_name()`"
  !is.null(private$stdin_pipe)
}

process_has_output_connection <- function(self, private) {
  "!DEBUG process_has_output_connection `private$get_short_name()`"
  !is.null(private$stdout_pipe)
}

process_has_error_connection <- function(self, private) {
  "!DEBUG process_has_error_connection `private$get_short_name()`"
  !is.null(private$stderr_pipe)
}

process_get_input_connection <- function(self, private) {
  "!DEBUG process_get_input_connection `private$get_short_name()`"
  if (!self$has_input_connection())
    stop("stdin is not a pipe.")
  private$stdin_pipe
}

process_get_output_connection <- function(self, private) {
  "!DEBUG process_get_output_connection `private$get_short_name()`"
  if (!self$has_output_connection())
    stop("stdout is not a pipe.")
  private$stdout_pipe
}

process_get_error_connection <- function(self, private) {
  "!DEBUG process_get_error_connection `private$get_short_name()`"
  if (!self$has_error_connection())
    stop("stderr is not a pipe.")
  private$stderr_pipe
}

process_read_output <- function(self, private, n) {
  "!DEBUG process_read_output `private$get_short_name()`"
  con <- process_get_output_connection(self, private)
  .Call(c_processx_connection_read_chars, con, n)
}

process_read_error <- function(self, private, n) {
  "!DEBUG process_read_error `private$get_short_name()`"
  con <- process_get_error_connection(self, private)
  .Call(c_processx_connection_read_chars, con, n)

}

process_read_output_lines <- function(self, private, n) {
  "!DEBUG process_read_output_lines `private$get_short_name()`"
  con <- process_get_output_connection(self, private)
  .Call(c_processx_connection_read_lines, con, n)
}

process_read_error_lines <- function(self, private, n) {
  "!DEBUG process_read_error_lines `private$get_short_name()`"
  con <- process_get_error_connection(self, private)
  .Call(c_processx_connection_read_lines, con, n)
}

process_is_incompelete_output <- function(self, private) {
  con <- process_get_output_connection(self, private)
  ! .Call(c_processx_connection_is_eof, con)
}

process_is_incompelete_error <- function(self, private) {
  con <- process_get_error_connection(self, private)
  ! .Call(c_processx_connection_is_eof, con)
}

process_read_all_output <- function(self, private) {
  result <- ""
  while (self$is_incomplete_output()) {
    self$poll_io(-1)
    result <- paste0(result, self$read_output())
  }
  result
}

process_read_all_error <- function(self, private) {
  result <- ""
  while (self$is_incomplete_error()) {
    self$poll_io(-1)
    result <- paste0(result, self$read_error())
  }
  result
}

process_read_all_output_lines <- function(self, private) {
  results <- character()
  while (self$is_incomplete_output()) {
    self$poll_io(-1)
    results <- c(results, self$read_output_lines())
  }
  results
}

process_read_all_error_lines <- function(self, private) {
  results <- character()
  while (self$is_incomplete_error()) {
    self$poll_io(-1)
    results <- c(results, self$read_error_lines())
  }
  results
}

process_write_input <- function(self, private, str, sep) {
  "!DEBUG process_write_input `private$get_short_name()`"
  con <- process_get_input_connection(self, private)
  if (is.character(str)) {
    pstr <- paste(str, collapse = sep)
    str <- iconv(pstr, "", private$encoding, toRaw = TRUE)[[1]]
  }
  invisible(.Call(c_processx_connection_write_bytes, con, str))
}

process_get_input_file <- function(self, private) {
  private$stdin
}

process_get_output_file <- function(self, private) {
  private$stdout
}

process_get_error_file <- function(self, private) {
  private$stderr
}

poll_codes <- c("nopipe", "ready", "timeout", "closed", "silent")

process_poll_io <- function(self, private, ms) {
  poll(list(self), ms)[[1]]
}

#' @export

close.processx_connection <- function(con, ...) {
  .Call(c_processx_connection_close, con)
}
