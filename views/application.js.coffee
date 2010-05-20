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

  c = $('canvas').get 0
  [c.width, c.height]: [$(window).width()-3, $(window).height()-3]

  u: new Lz.Universe { canvas: c }
  u.start($('canvas').get(0))
  u.add(new Lz.Mass({
    position: new Lz.Vector c.width/2, c.height/2
    velocity: new Lz.Vector Math.PI/2
    radius: 10
  }))

class Lz.Universe
  constructor: (options) ->
    { canvas: @canvas }: options || {}
    @masses: []
    @tick: 0
    @ctx: @canvas.getContext '2d'
    @ctx.lineCap: 'round'
    @ctx.lineJoin: 'round'
    @ctx.strokeStyle: 'rgb(255,255,255)'
    @ctx.fillStyle: 'rgb(255,255,255)'
    @ctx.font: '9pt Monaco, Monospace'
    @ctx.textAlign: 'center'

  add: (mass) ->
    @masses.push mass

  start: ->
    this.loop()

  loop: ->
    this.step 1
    setTimeout this.loop <- this, 1000/24

  step: (dt) ->
    mass.step dt for mass in @masses
    this.render()

  render: ->
    ctx: @ctx
    ctx.clearRect 0, 0, @canvas.width, @canvas.height
    mass.render ctx for mass in @masses

class Lz.Mass
  constructor: (options) ->
    { tick: @tick
      position: @position
      velocity: @velocity
      acceleration: @acceleration
      rotation: @rotation
      radius: @radius
    }: options || {}
    @radius: or 1
    @position: or new Lz.Vector()
    @velocity: or new Lz.Vector()
    @acceleration: or new Lz.Vector()
    @rotation: or new Lz.Vector(0)

  step: (dt) ->
    @tick += dt
    @position: @position.plus @velocity.times(dt)
    @velocity: @velocity.plus @acceleration.times(dt)
    @velocity.zeroSmall()

    # drag
    @acceleration: @acceleration.times 0.5
    @acceleration.zeroSmall()

  render: (ctx) ->
    ctx.save()

    ctx.translate @position.x, @position.y
    ctx.rotate @rotation
    this._render ctx

    ctx.restore()

  _render: (ctx) ->
    # debug
    ctx.save()
    ctx.strokeStyle: 'rgb(255,0,0)'
    ctx.beginPath()
    ctx.arc 0, 0, @radius, 0, Math.PI * 2, true
    ctx.closePath()
    ctx.stroke()
    ctx.restore()

class Lz.Vector
  # can pass either x, y coords or radians for a unit vector
  constructor: (x, y) ->
    [@x, @y]: if y? then [x, y] else [Math.cos(x), Math.sin(x)]
    @x: or 0
    @y: or 0

  plus: (v) ->
    new Lz.Vector @x + v.x, @y + v.y

  minus: (v) ->
    new Lz.Vector @x - v.x, @y - v.y

  times: (s) ->
    new Lz.Vector @x * s, @y * s

  length: ->
    Math.sqrt @x * @x + @y * @y

  normalized: ->
    this.times 1.0 / this.length()

  clone: ->
    new Lz.Vector @x, @y

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
