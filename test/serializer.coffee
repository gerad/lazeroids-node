helpers.extend global, require('./test-helper')

class Cereal
  serialize: 'Cereal'
  constructor: (name) ->
    @name: name
  are_for_kids: ->
    @name + ' are for kids'
Lz.Serializer.bless(Cereal)

cc: cc2: null
before ->
  cc: new Cereal('Captain Crunch')
  serialized: cc.pack()
  cc2: Lz.Serializer.unpack(serialized)

test "serialize", (t) ->
  t.expect 1
  t.same cc, cc2, 'serialized and deserialized correctly'
  t.done()

test "methods", (t) ->
  t.expect 1
  t.ok cc2.are_for_kids(), 'method is still around'
  t.done()

run(__filename)