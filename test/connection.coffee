helpers.extend global, require('./test-helper')
helpers.extend global, require('./helpers/mock-socket')

mockSocket: null
before ->
  mockSocket: MockSocket.io()

test "exists", (t) ->
  t.expect 2
  t.ok Lz, "Lz exists"
  t.ok Lz.Connection, "Connection exists"
  t.done()

test "initialize", (t) ->
  t.expect 1
  t.ok new Lz.Connection(), "Can initialize"
  t.done()

test "send", (t) ->
  message: 'What hath God wrought'
  c: new Lz.Connection()

  t.expect 1
  mockSocket.expect 'send', (msg) ->
    t.equals msg, message
  c.send(message)

  t.done()

test "receive", (t) ->
  message: 'How now brown cow?'
  c: new Lz.Connection()

  t.expect 1
  c.observe "message", (msg) ->
    t.equals msg, message
  mockSocket.sendMessage message

  t.done()
run(__filename)
