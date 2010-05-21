this.exports = this.Lz = {}

$ -> new Controller $('canvas').get(0)

class Controller
  constructor: (canvas) ->
    @canvas: canvas
    @conn: new Connection()

    @setupCanvas()
    @setupKeys()
    @start()

  setupCanvas: ->
    [@canvas.width, @canvas.height]: [$(window).width()-3, $(window).height()-3]

  setupKeys: ->
    $(window).keydown (e) =>
      switch e.which
        when 37  # left
          @ship.rotate(-1)
        when 39  # right
          @ship.rotate(+1)
        when 38  # up
          @ship.thrust()
        when 40  # down
          @ship.brake()
        when 90  # z = zoom
          if @universe.zoom == 1
            @universe.zoom: 0.4
          else
            @universe.zoom: 1

    $(window).keyup (e) =>
      switch e.which
        when 37  # left
          @ship.rotate(+1)
        when 39  # right
          @ship.rotate(-1)

  start: ->
    @universe: new Universe { canvas: @canvas }
    @ship: new Spaceship {
      position: new Vector @canvas.width/2, @canvas.height/2
      rotation: -Math.PI / 2
    }
    @universe.add @ship
    @universe.ship: @ship

    @universe.start()

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

    @zoom: 1
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
    mass.universe = this

  remove: (mass) ->
    @masses: _.without @masses, mass

  start: ->
    @loop()

    @injectAsteroids 5
    setInterval (@injectAsteroids <- this, 3), 5000

  loop: ->
    @step 1
    @render()
    setTimeout @loop <- this, 1000/24

  step: (dt) ->
    @tick += dt
    mass.step dt for mass in @masses
    @checkCollisions()
    @bounds.check @ship

  render: ->
    ctx: @ctx
    ctx.clearRect 0, 0, @canvas.width, @canvas.height
    ctx.save()

    if @zoom != 1
      ctx.scale @zoom, @zoom
      ctx.translate @bounds.width*0.75, @bounds.height*0.75
    @bounds.translate ctx
    mass.render ctx for mass in @masses

    ctx.restore()

  injectAsteroids: (howMany) ->
    return if @masses.length > 80

    for i in [1 .. howMany || 1]
      b: @bounds
      [w, h]: [@bounds.width, @bounds.height]
      outside: new Vector w*Math.random()-w/2+b.l, h*Math.random()-h/2+b.t
      outside.x += w if outside.x > b.l
      outside.y += h if outside.y > b.t
      inside: b.randomPosition()
      centripetal: inside.minus(outside).normalized().times(3*Math.random()+1)

      @add new Asteroid { position: outside, velocity: centripetal }

  checkCollisions: ->
    # ship collisions
    for m in @masses
      if m.overlaps @ship
        @ship.explode()
        break

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

  explode: ->
    this.universe.remove this

  overlaps: (other) ->
    return false if other == this
    diff: other.position.minus(@position).length()

    diff < @radius or diff < other.radius

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
