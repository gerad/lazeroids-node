express = require('express')

pub = __dirname + '/public'
app = express.createServer(
  express.compiler({ src: pub, enable: ['sass'] }),
  express.staticProvider(pub),
  express.logger(),
  express.errorHandler({ dumpExceptions: true, showStack: true }))

app.get '/', (req, res) ->
  res.render 'index.jade'

app.get '/lazeroids.js', (req, res) ->
  res.sendfile 'lazeroids.js'

app.listen(process.env.PORT || 8000)

socket = require('socket.io').listen app
socket.on 'connection', (client) ->
  client.on 'message', ->
    socket.broadcast message
  client.on 'disconnect', ->
    client.broadcast [['disconnect', client.sessionId]]
