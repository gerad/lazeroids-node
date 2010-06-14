class MockSocket extends Mock
  constructor: ->
    super()
    @transport: { sessionid: 'mocksocket' }
    @o: new Lz.Observable()
    @expect 'connect'

  sendMessage: (data) ->
    @o.trigger 'message', data

  addEvent: (name, fn) ->
    @o.observe 'message', fn

MockSocket.io: ->
  sock: new MockSocket()
  global.io: { Socket: -> sock }
  sock

exports.MockSocket: MockSocket