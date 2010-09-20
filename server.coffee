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

comet = require('socket.io').listen app, (client) ->
  client.on 'message', ->
    comet.broadcast message
  client.on 'disconnect', ->
    client.broadcast [['disconnect', client.sessionId]]