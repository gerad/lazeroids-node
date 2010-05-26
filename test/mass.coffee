helpers.extend global, require('./test-helper')

test "has id", (t) ->
  m: new Lz.Mass()

  t.expect 1
  t.ok m.id, 'mass has a UUID'
  t.done()

run(__filename)