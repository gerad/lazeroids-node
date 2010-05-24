helpers.extend global, require('./test-helper')

test "exists", (t) ->
  t.expect 2
  t.ok Lz, "Lz exists"
  t.ok Lz.Connection, "Connection exists"
  t.done()

test "initialize", (t) ->
  t.expect 1
  t.ok new Lz.Connection(), "Can initialize"
  t.done()

mockSocket: null
before ->
  mockSocket: new Mock()
  mockSocket.expect('connect').expect('addEvent')
  this.io: {
    Socket: ->
      mockSocket
  }

run()
