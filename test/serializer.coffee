require './helpers/test-helper'
require './helpers/mock-socket'

cc = cc2 = serialized = null
before ->
  MockSocket.io()
  cc = new Cereal('Captain Crunch')
  serialized = Lz.Serializer.pack cc
  cc2 = Lz.Serializer.unpack serialized

test "serialize", (t) ->
  t.expect 1
  t.same cc, cc2
  t.done()

test "methods", (t) ->
  t.expect 3
  t.ok !serialized.are_for_kids?, 'method is not serialized'
  t.ok cc2.are_for_kids(), 'method is around after deserialization'
  t.ok cc2.milk.healthy(), 'nested methods work too'
  t.done()

test "array", (t) ->
  original = [1,2,3,[4,5,6]]
  unpacked = Lz.Serializer.unpack Lz.Serializer.pack original

  t.expect 1
  t.same original, unpacked
  t.done()

test "universe excluded", (t) ->
  u = new Lz.Universe()
  m = new Lz.Mass()
  u.add m
  data = Lz.Serializer.pack m

  t.expect 1
  t.ok !data.universe?, 'universe is not serialized'
  t.done()

test "bullet does not include ship", (t) ->
  u = new Lz.Universe()
  s = new Lz.Ship()
  u.add s
  s.shoot()
  b = s.bullets[0]

  t.expect 1
  t.ok !Lz.Serializer.pack(b).ship?, 'ship is not serialized'
  t.done()

test "ship does not include bullets", (t) ->
  u = new Lz.Universe()
  s = new Lz.Ship()
  u.add s
  s.shoot()
  s2 = Lz.Serializer.unpack Lz.Serializer.pack s

  t.expect 2
  t.equals s.bullets.length, 1
  t.ok !s2.bullets?
  t.done()

test "mass in object", (t) ->
  m = new Lz.Mass()
  j = JSON.parse JSON.stringify { add: m }

  t.expect 1
  t.ok j.add, 'data still added'
  t.done()

test "asteroid", (t) ->
  original = new Lz.Asteroid()
  unpacked = Lz.Serializer.unpack Lz.Serializer.pack original
  t.same original, unpacked
  t.done()

test "bullet", (t) ->
  s = new Lz.Ship()
  original = new Lz.Bullet({ ship: s })
  unpacked = Lz.Serializer.unpack Lz.Serializer.pack original
  delete original.ship
  t.same original, unpacked
  t.done()

NameSpace = {}

class Milk
  serialize: ['Milk', { allowNesting: true }]
  constructor: (organic) ->
    @organic = organic
  healthy: -> @organic
NameSpace.Milk = Milk

class Cereal
  serialize: 'Cereal'
  constructor: (name) ->
    @name = name
    @milk = new Milk(true)
  are_for_kids: ->
    @name + ' are for kids'
NameSpace.Cereal = Cereal

Lz.Serializer.blessAll(NameSpace)

run(__filename)