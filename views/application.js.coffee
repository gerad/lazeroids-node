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

  c = $('canvas').get 0
  [c.width, c.height]: [$(window).width()-3, $(window).height()-3]

  u: new Universe { canvas: c }
  s: new Spaceship {
    position: new Vector c.width/2, c.height/2
  }
  u.add s
  u.start c

  $(window).keydown (e) ->
    switch e.which
      when 37  # left
        s.rotate(-1)
      when 39  # right
        s.rotate(+1)
      when 38  # up
        s.thrust()
      when 40  # down
        s.brake()

  $(window).keyup (e) ->
    switch e.which
      when 37  # left
        s.rotate(+1)
      when 39  # right
        s.rotate(-1)

class Universe
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
    @loop()

  loop: ->
    @step 1
    setTimeout @loop <- this, 1000/24

  step: (dt) ->
    mass.step dt for mass in @masses
    @render()

  render: ->
    ctx: @ctx
    ctx.clearRect 0, 0, @canvas.width, @canvas.height
    mass.render ctx for mass in @masses
Lz.Universe: Universe

class Mass
  constructor: (options) ->
    o: options or {}
    @tick: o.tick or 0
    @radius: o.radius or 1
    @position: o.position or new Vector()
    @velocity: o.velocity or new Vector()
    @acceleration: o.acceleration or new Vector()
    @rotation: o.rotation or 0
    @rotationalVelocity: o.rotationalVelocity or 0

  step: (dt) ->
    @tick += dt

    for t in [0...dt]
      @velocity: @velocity.plus @acceleration
      @position: @position.plus @velocity
      # drag
      @acceleration: @acceleration.times 0.5

      @rotation += @rotationalVelocity

  render: (ctx) ->
    ctx.save()

    ctx.translate @position.x, @position.y
    ctx.rotate @rotation
    @_render ctx

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

class Spaceship extends Mass
  constructor: (options) ->
    options: or {}
    options.radius: or 16
    super options

  _render: (ctx) ->
    ctx.save()
    ctx.beginPath()
    ctx.moveTo @radius, 0
    ctx.lineTo 0, @radius / 2.6
    ctx.lineTo 0, @radius / -2.6
    ctx.closePath()
    ctx.stroke()
    ctx.restore()

  thrust: ->
    @acceleration: @acceleration.plus(new Vector(@rotation))

  brake: ->
    @acceleration: @acceleration.plus(new Vector(@rotation).times(-1))

  rotate: (dir) ->
    if (dir > 0 && @rotationalVelocity <= 0)
      @rotationalVelocity += Math.PI / 32
    else if (dir < 0 && @rotationalVelocity >= 0)
      @rotationalVelocity -= Math.PI / 32
Lz.Spaceship: Spaceship

class Vector
  # can pass either x, y coords or radians for a unit vector
  constructor: (x, y) ->
    [@x, @y]: if y? then [x, y] else [Math.cos(x), Math.sin(x)]
    @x: or 0
    @y: or 0
    @_zeroSmall()

  plus: (v) ->
    new Vector @x + v.x, @y + v.y

  minus: (v) ->
    new Vector @x - v.x, @y - v.y

  times: (s) ->
    new Vector @x * s, @y * s

  length: ->
    Math.sqrt @x * @x + @y * @y

  normalized: ->
    @times 1.0 / @length()

  clone: ->
    new Vector @x, @y

  _zeroSmall: ->
    @x: 0 if Math.abs(@x) < 0.01
    @y: 0 if Math.abs(@y) < 0.01
Lz.Vector: Vector

class Connection
  constructor: ->
    @socket: new io.Socket null, {
      rememberTransport: false
      resource: 'comet'
      port: 8000
    }
    @_setupObservers()
    @socket.connect()

  send: (message) ->
    @socket.send message

  receive: (fn) ->
    @bind "message", fn

  _setupObservers: () ->
    o: new Observable()
    @trigger: o.trigger
    @bind: o.bind
    @observers: o.observers

    @socket.addEvent 'message', (json) =>
      data: JSON.parse json
      @trigger "message", data
Lz.Connection: Connection

class Observable
  bind: (name, fn) ->
    @observers(name).push fn

  trigger: (name, args...) ->
    callback args... for callback in @observers(name)

  observers: (name) ->
    (@_observers ||= {})[name] ||= []
