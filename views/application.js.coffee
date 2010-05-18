$ ->
  socket: new io.Socket 'localhost', {
    rememberTransport: false
    port: 8000
    resource: 'commet'
  }

  socket.connect()
  socket.send 'some data'
  socket.addEvent 'message', (data) ->
    console.log data