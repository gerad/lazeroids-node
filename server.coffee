require.paths.unshift './lib/express/lib'
require 'express'
require 'express/plugins'
use Static # require for public
use Logger
json: JSON.stringify

# required  for views
configure ->
  set 'root', __dirname

get '/', ->
  @render 'index.html.haml'

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