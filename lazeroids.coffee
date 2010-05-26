json: JSON.stringify

get '/', ->
  @render 'index.html.haml'

get '/*.js', (file) ->
  try
    @render "${file}.js.coffee", { layout: false }
  catch e
    @pass "/${file}.js"

get '/*.css', (file) ->
  @render "${file}.css.sass", { layout: false }

get '/*', (file) ->
  @pass "/public/${file}"

server: run parseInt(process.env.PORT || 8000), null

# handle web sockets
sio: require './lib/socket.io/lib/socket.io'
comet: sio.listen server, {
  resource: 'comet'
  transports: 'websocket htmlfile xhr-multipart xhr-polling'.split(' ')
  onClientConnect: (client) ->
    comet.broadcast json({ message: "${client.sessionId} connected" })
  onClientDisconnect: (client) ->
    client.broadcast json({ message: "${client.sessionId} disconnected" })
  onClientMessage: (message, client) ->
    comet.broadcast message
}
