
context("extra connections")

test_that("writing to extra connection", {

  skip_on_cran()

  msg <- "foobar"
  cmd <- c(get_tool("px"), "echo", "3", "1", nchar(msg))

  pipe <- conn_create_pipepair()

  expect_silent(
    p <- process$new(cmd[1], cmd[-1],
      stdout = "|", stderr = "|", connections = list(pipe[[1]])
    )
  )

  on.exit(p$kill())

  conn_write(pipe[[2]], msg)
  p$poll_io(-1)
  expect_equal(p$read_all_output_lines(), msg)
  expect_equal(p$read_all_error_lines(), character())
})

test_that("reading from extra connection", {

  skip_on_cran()

  cmd <- c(
    get_tool("px"), "sleep", "0.5", "write", "3", "foobar\r\n", "out", "ok")

  pipe <- conn_create_pipepair()

  on.exit(p$kill())
  expect_silent(
    p <- process$new(cmd[1], cmd[-1], stdout = "|", stderr = "|",
      connections = list(pipe[[2]])
    )
  )

  ## Nothing to read yet
  expect_equal(conn_read_lines(pipe[[1]]), character())

  ## Wait until there is output
  p$poll_io(-1)
  expect_equal(conn_read_lines(pipe[[1]]), "foobar")
  expect_equal(p$read_all_output_lines(), "ok")
  expect_equal(p$read_all_error_lines(), character())
})

test_that("reading and writing to extra connection", {

  skip_on_cran()

  msg <- "foobar\n"
  cmd <- c(get_tool("px"), "echo", "3", "4", nchar(msg), "outln", "ok")

  pipe1 <- conn_create_pipepair()
  pipe2 <- conn_create_pipepair()

  expect_silent(
    p <- process$new(cmd[1], cmd[-1], stdout = "|", stderr = "|",
      connections = list(pipe1[[1]], pipe2[[2]])
    )
  )

  on.exit(p$kill())

  conn_write(pipe1[[2]], msg)
  p$poll_io(-1)
  expect_equal(conn_read_chars(pipe2[[1]]), msg)
  expect_equal(p$read_output_lines(), "ok")
})
