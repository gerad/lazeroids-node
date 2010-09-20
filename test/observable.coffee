require './helpers/test-helper'

test "observe", (t) ->
  o = new Lz.Observable()
  o.observe "foo", ->
    t.ok true, 'foo observed'
  o.trigger 'foo'
  t.expect 1
  t.done()

run(__filename)