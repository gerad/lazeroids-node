this.exports = this.Lz = {}

$ ->
  con: new Lz.Connection()
  $('form').submit ->
    con.send $('input[type=text]', this).val()
    this.reset()
    false
  con.receive (data) ->
    $('#message').append "${data.msg}<br />"
  $('input:first').select()

  u: new Lz.Universe { canvas: $('canvas').get(0) }
  u.start()

class Lz.Universe
  constructor: (options) ->
    @masses: []
    @tick: 0
    @canvas: options.canvas

  add: (mass) ->
    @masses.push mass

  start: ->
    this.loop()

  loop: ->
    this.step 1
    setTimeout this.loop, 1000/24

  step: (dt) ->
    mass.step(dt) for mass in @masses

class Lz.Mass
  constructor: (options) ->
    { tick: @tick
      position: @postion
      velocity: @velocity
      acceleration: @acceleration
    }: options

  step: (dt) ->
    @tick += dt
    @position = @position.plus @velocity.times dt
    @velocity = @velocity.plus @acceleration.times dt
    @velocity.zeroSmall

    # drag
    @acceleration = @acceleration.times 0.5
    @acceleration.zeroSmall

class Lz.Vector
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

  zeroSmall: ->
    @x: 0 if Math.abs(@x) < 0.01
    @y: 0 if Math.abs(@y) < 0.01

class Lz.Connection
  constructor: ->
    @o: new Lz.Observable()
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

class Lz.Observable
  bind: (name, fn) ->
    this.observers(name).push fn

  trigger: (name, args...) ->
    callback args... for callback in this.observers(name)

  observers: (name) ->
    (@_observers ||= {})[name] ||= []
