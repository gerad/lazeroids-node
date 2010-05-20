this.exports = this.Lz = {}

$ ->
  con: new Connection()
  $('form').submit ->
    con.send $('input[type=text]', this).val()
    @reset()
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
  u.ship: s
  for i in [0 .. 4]
    u.add new Asteroid()

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

class Bounds
  BUFFER: 40

  constructor: (canvas) ->
    [@l, @t] = [0, 0]
    @width = @r = canvas.width
    @height = @b = canvas.height
    @dx = @dy = 0

  check: (ship) ->
    p: ship.position

    if p.x < @l+@BUFFER
      @dx: -@width * 0.75
    else if p.x > @r-@BUFFER
      @dx: +@width * 0.75

    if p.y < @t+@BUFFER
      @dy: -@height * 0.75
    else if p.y > @b-@BUFFER
      @dy: +@height * 0.75

    if @dx != 0
      dx: parseInt @dx / 8
      @l += dx; @r += dx
      @dx -= dx
      @dx: 0 if Math.abs(@dx) < 3

    if @dy != 0
      dy: parseInt @dy / 8
      @t += dy; @b += dy
      @dy -= dy
      @dy: 0 if Math.abs(@dy) < 3

  translate: (ctx) ->
    ctx.translate(-@l, -@t)

  randomPosition: ->
    new Vector @width * Math.random() + @l, @height * Math.random() + @t

class Universe
  constructor: (options) ->
    { canvas: @canvas }: options || {}
    @masses: []
    @tick: 0

    @bounds: new Bounds @canvas
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
    @render()
    setTimeout @loop <- this, 1000/24

  step: (dt) ->
    @tick += dt
    mass.step dt for mass in @masses
    @bounds.check @ship

  render: ->
    ctx: @ctx
    ctx.clearRect 0, 0, @canvas.width, @canvas.height
    ctx.save()

    @bounds.translate ctx
    mass.render ctx for mass in @masses

    ctx.restore()

  #injectAsteroids: (howMany) ->
    #return if @masses.length > 80
    #for i in [1 .. howMany || 1]
      #var b = this._bounds, w = this._bounds.width, h = this._bounds.height;
      #var inside = b.randomPosition();
      #var outside = new Vector(w*Math.random()-w/2+b.l, h*Math.random()-h/2+b.t);
      #if (outside.x > b.l) outside.x += w; if (outside.y > b.t) outside.y += h;
      #var centripetal = inside.minus(outside).normalized().times(3 * Math.random() + 1);

      #@add(new Asteroid({ position: outside, velocity: centripetal }));

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

class Asteroid extends Mass
  RADIUS_BIG: 40
  RADIUS_SMALL: 20

  constructor: (options) ->
    options: or {}
    options.radius: or @RADIUS_BIG
    options.velocity: or new Vector(6 * Math.random() - 3, 6 * Math.random() - 3)
    options.rotationalVelocity: or Math.random() * 0.1 - 0.05

    super options

    unless (@points = options.points)?
      l: 4 * Math.random() + 8
      @points: new Vector(2 * Math.PI * i / l).times(@radius * Math.random() + @radius / 3) for i in [0 .. l]

  _render: (ctx) ->
    p: @points
    ctx.beginPath()
    ctx.moveTo p[0].x, p[0].y
    ctx.lineTo p[i].x, p[i].y for i in [1 ... p.length]
    ctx.closePath()
    ctx.stroke()

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

class Observable
  bind: (name, fn) ->
    @observers(name).push fn

  trigger: (name, args...) ->
    callback args... for callback in @observers(name)

  observers: (name) ->
    (@_observers ||= {})[name] ||= []
