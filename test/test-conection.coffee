helpers.extend global, require('./test-helper')

test "exists", (t) ->
  t.expect 2
  t.ok Lz, "Lz exists"
  t.ok Lz.Connection, "Connection exists"
  t.done()

run()
