json: JSON.stringify

get '/', ->
  @render 'index.html.haml'

get '/application.js', ->
  @render 'application.js.coffee', { layout: false }

server: run parseInt(process.env.PORT || 8000), null

# handle web sockets
sio: require './lib/socket.io/lib/socket.io'
commet: sio.listen server, {
  resource: 'commet'
  transports: 'websocket htmlfile xhr-multipart xhr-polling'.split(' ')
  onClientConnect: (client) ->
    commet.broadcast json({ msg: "${client.sessionId} connected" })
  onClientDisconnect: (client) ->
    client.broadcast json({ msg: "${client.sessionId} disconnected" })
  onClientMessage: (message, client) ->
    commet.broadcast json({ msg: "${client.sessionId} wrote $message" })
}