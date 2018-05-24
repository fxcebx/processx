
context("poll connections")

test_that("poll a connection", {

  px <- get_tool("px")
  p <- process$new(px, c("sleep", ".5", "outln", "foobar"), stdout = "|")
  out <- p$get_output_connection()

  ## Timeout
  expect_equal(poll(list(out), 0)[[1]], "timeout")

  expect_equal(poll(list(out), 2000)[[1]], "ready")

  p$read_output_lines()
  expect_equal(poll(list(out), 2000)[[1]], "ready")

  close(out)
  expect_equal(poll(list(out), 0)[[1]], "closed")
})

test_that("poll a connection and a process", {

  px <- get_tool("px")
  p1 <- process$new(px, c("sleep", ".5", "outln", "foobar"), stdout = "|")
  p2 <- process$new(px, c("sleep", ".5", "outln", "foobar"), stdout = "|")
  out <- p1$get_output_connection()

  ## Timeout
  expect_equal(
    poll(list(out, p2), 0),
    list("timeout", c(output = "timeout", error = "nopipe")))

  ## At least one of them is ready...
  pr <- poll(list(out, p2), 2000)
  expect_true(pr[[1]] == "ready"  || pr[[2]]$output == "ready")

  p1$poll_io(2000)
  p2$poll_io(2000)
  p1$read_output_lines()
  p2$read_output_lines()
  expect_equal(
    poll(list(out, p2), 2000),
    list("ready", c(output = "ready", error = "nopipe")))

  p1$kill()
  p2$kill()
  expect_equal(
    poll(list(out, p2), 2000),
    list("ready", c(output = "ready", error = "nopipe")))

  close(out)
  close(p2$get_output_connection())
  expect_equal(
    poll(list(out, p2), 2000),
    list("closed", c(output = "closed", error = "nopipe")))
})