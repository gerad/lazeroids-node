helpers.extend global, require('./test-helper')

test "false", (t) ->
  t.expect 1
  t.ok false, "this assertion should not pass"
  t.done()

test "true", (t) ->
  t.expect 1
  t.ok true, "this assertion should pass"
  t.done()

test "fail expects", (t) ->
  t.expect 1
  t.done()

run()
