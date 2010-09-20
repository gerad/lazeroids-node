class MockSocket extends Mock
  constructor: ->
    super()
    @transport = { sessionid: 'mocksocket' }
    @o = new Lz.Observable()
    @expect 'connect'

  sendMessage: (data) ->
    @o.trigger 'message', data

  on: (name, fn) ->
    @o.observe 'message', fn

MockSocket.io = ->
  sock = new MockSocket()
  global.io = { Socket: -> sock }
  sock

global.MockSocket = MockSocket