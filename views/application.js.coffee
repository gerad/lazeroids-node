this.exports = this.Lz = {}

$ ->
  con: new Connection()
  $('form').submit ->
    con.send $('input[type=text]', this).val()
    this.reset()
    false
  con.receive (data) ->
    $('#message').append "${data.msg}<br />"
  $('input:first').select()

class Vector
  constructor: (x, y) ->
    [@x, @y]: if y? then [x, y] else [Math.cos x, Math.sin x]

  plus: (v) ->
    new Vector @x + v.x, @y + v.y

  minus: (v) ->
    new Vector @x - v.x, @y - v.y

  times: (s) ->
    new Vector @x * s, @y * s

  length: ->
    Math.sqrt @x * @x + @y * @y

  normalized: ->
    this.times 1.0 / this.length()

  clone: ->
    new Vector @x, @y

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

class Observable
  bind: (name, fn) ->
    this.observers(name).push fn

  trigger: (name, args...) ->
    callback args... for callback in this.observers(name)

  observers: (name) ->
    (@_observers ||= {})[name] ||= []
