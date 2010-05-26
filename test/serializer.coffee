helpers.extend global, require('./test-helper')

cc: cc2: serialized: null
before ->
  cc: new Cereal('Captain Crunch')
  serialized: cc.pack()
  cc2: Lz.Serializer.unpack(serialized)

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

NameSpace: {}

class Milk
  serialize: ['Milk', { allowNesting: true }]
  constructor: (organic) ->
    @organic: organic
  healthy: -> @organic
NameSpace.Milk: Milk

class Cereal
  serialize: 'Cereal'
  constructor: (name) ->
    @name: name
    @milk: new Milk(true)
  are_for_kids: ->
    @name + ' are for kids'
NameSpace.Cereal: Cereal

Lz.Serializer.blessAll(NameSpace)

run(__filename)