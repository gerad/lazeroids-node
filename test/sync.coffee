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

test "update ticks", (t) ->
  universes[0].startShip()
  universes[0].step 100
  universes[1].requestSync()
  network()
  t.equals universes[0].tick, universes[1].tick
  t.done()

test "masses sync at different speed", (t) ->
  universes[0].startShip()
  universes[0].step 100
  universes[1].requestSync()
  network()
  universes[1].step 0
  for id, mass of universes[1].masses.items
    other: universes[0].masses.find mass
    t.ok other
    t.same Lz.Serializer.pack(mass), Lz.Serializer.pack(other)
  t.done()

createUniverse: ->
  u: new Lz.Universe()
  m: new Lz.Mass()
  m.velocity: randomVector()
  u.add m
  u.setupConnection()
  universes.push u

randomVector: (max) ->
  max ?= 10
  [x, y]: Math.floor(max * (2*Math.random()-1)) for i in [1..2]
  new Lz.Vector(x, y)

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
