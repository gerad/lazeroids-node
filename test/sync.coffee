helpers.extend global, require('./test-helper')

sockets: universes: null
before ->
  sockets: []
  universes: []
  createUniverse() for i in [0...2]

test "setup", (t) ->
  t.expect 2
  t.ok universes[0], "first universe exists"
  t.ok universes[1], "second universe exists"
  t.done()

test "sync", (t) ->
  t.expect 2
  [u0, u1]: universes
  u.network() for u in universes
  t.equals 2, u0.masses.length, 'first universe gets both masses'
  t.equals 2, u1.masses.length, 'second universe gets both masses'
  t.done()

createUniverse: ->
  u: new Lz.Universe()
  m: new Lz.Mass()
  u.add m
  u.setupConnection()
  universes.push u

class EchoSocket
  constructor: ->
    @o: new Lz.Observable()
    @addEvent: @o.observe <- @o
    @trigger: @o.trigger <- @o
  connect: ->
    sockets.push this
  send: (msg) ->
    s.trigger('message', msg) for s in sockets
this.io: { Socket: EchoSocket }

run(__filename)