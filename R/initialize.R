
#' Start a process
#'
#' @param self this
#' @param private this$private
#' @param command Command to run, string scalar.
#' @param args Command arguments, character vector.
#' @param stdin Standard input, NULL to ignore.
#' @param stdout Standard output, NULL to ignore, TRUE for temp file.
#' @param stderr Standard error, NULL to ignore, TRUE for temp file.
#' @param connections Connections to inherit in the child process.
#' @param env Environment vaiables.
#' @param cleanup Kill on GC?
#' @param wd working directory (or NULL)
#' @param echo_cmd Echo command before starting it?
#' @param supervise Should the process be supervised?
#' @param encoding Assumed stdout and stderr encoding.
#' @param post_process Post processing function.
#'
#' @keywords internal
#' @importFrom utils head tail

process_initialize <- function(self, private, command, args,
                               stdin, stdout, stderr, connections, env,
                               cleanup, wd, echo_cmd, supervise,
                               windows_verbatim_args, windows_hide_window,
                               encoding, post_process) {

  "!DEBUG process_initialize `command`"

  assert_that(is_string(command))
  assert_that(is.character(args))
  assert_that(is_string_or_null(stdin))
  assert_that(is_string_or_null(stdout))
  assert_that(is_string_or_null(stderr))
  assert_that(is_connection_list(connections))
  assert_that(is.null(env) || is_named_character(env))
  assert_that(is_flag(cleanup))
  assert_that(is_string_or_null(wd))
  assert_that(is_flag(echo_cmd))
  assert_that(is_flag(windows_verbatim_args))
  assert_that(is_flag(windows_hide_window))
  assert_that(is_string(encoding))
  assert_that(is.function(post_process) || is.null(post_process))

  private$command <- command
  private$args <- args
  private$cleanup <- cleanup
  private$wd <- wd
  private$pstdin <- stdin
  private$pstdout <- stdout
  private$pstderr <- stderr
  private$connections <- connections
  private$env <- env
  private$echo_cmd <- echo_cmd
  private$windows_verbatim_args <- windows_verbatim_args
  private$windows_hide_window <- windows_hide_window
  private$encoding <- encoding
  private$post_process <- post_process

  if (echo_cmd) do_echo_cmd(command, args)

  if (!is.null(env)) env <- enc2utf8(paste(names(env), sep = "=", env))

  "!DEBUG process_initialize exec()"
  private$status <- .Call(
    c_processx_exec,
    command, c(command, args), stdin, stdout, stderr, connections, env,
    windows_verbatim_args, windows_hide_window,
    private, cleanup, wd, encoding
  )
  private$starttime <- Sys.time()

  if (is.character(stdin) && stdin != "|")
    stdin <- full_path(stdin)
  if (is.character(stdout) && stdout != "|")
    stdout <- full_path(stdout)
  if (is.character(stderr) && stderr != "|")
    stderr <- full_path(stderr)

  ## Store the output and error files, we'll open them later if needed
  private$stdin  <- stdin
  private$stdout <- stdout
  private$stderr <- stderr

  if (supervise) {
    supervisor_watch_pid(self$get_pid())
    private$supervised <- TRUE
  }

  invisible(self)
}
