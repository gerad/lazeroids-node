this.exports = this.Lz = {}

class Observable
  bind: (name, fn) ->
    this.observers(name).push fn

  trigger: (name, args...) ->
    callback args... for callback in this.observers(name)

  observers: (name) ->
    (@_observers ||= {})[name] ||= []

class Connection
  constructor: ->
    @o: new Observable()
    @socket: new io.Socket null, {
      rememberTransport: false
      resource: 'comet'
      port: 8000
    }
    this._setupObservers()
    @socket.connect()

  send: (message) ->
    @socket.send message

  receive: (fn) ->
    @o.bind "message", fn

  _setupObservers: (fn) ->
    @socket.addEvent 'message', (json) =>
      data: JSON.parse json
      @o.trigger "message", data

$ ->
  con: new Connection()

  $('form').submit ->
    con.send $('input[type=text]', this).val()
    this.reset()
    false

  $('input:first').select()

  con.receive (data) ->
    $('#message').append "${data.msg}<br />"
