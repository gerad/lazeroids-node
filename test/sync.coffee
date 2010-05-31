helpers.extend global, require('./test-helper')

universes: null
before ->
  EchoSocket.sockets: []
  universes: []
  createUniverse() for i in [0...2]
  network()

test "setup", (t) ->
  t.expect 2
  t.ok universes[0], "first universe exists"
  t.ok universes[1], "second universe exists"
  t.done()

test "sync", (t) ->
  t.expect 2
  [u0, u1]: universes

  t.equals 2, u0.masses.length, 'first universe gets both masses'
  t.equals 2, u1.masses.length, 'second universe gets both masses'

  t.done()

test "request sync", (t) ->
  universes[1].startShip()
  universes[0].requestSync()
  network()
  t.ok universes[0].masses.find universes[1].ship, "started ship sync'd"
  t.ok !universes[1].masses.find universes[0].ship, "unstarted ship not sync'd"
  t.done()

createUniverse: ->
  u: new Lz.Universe()
  m: new Lz.Mass()
  u.add m
  u.setupConnection()
  universes.push u

network: ->
  for i in [0...2]
    u.network() for u in universes

class EchoSocket
  constructor: ->
    @o: new Lz.Observable()

  connect: ->
    EchoSocket.sockets.push this

  send: (msg) ->
    s.trigger 'message', msg for s in EchoSocket.sockets

  trigger: (args...) ->
    @o.trigger args...

  addEvent: (args...) ->
    @o.observe args...
EchoSocket.sockets: []

this.io: { Socket: EchoSocket }

run(__filename)
