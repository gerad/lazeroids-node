Lz: if process? then exports else this.Lz: {}

class Controller
  constructor: (canvas) ->
    @canvas: canvas
    #@conn: new Connection()

    @setupCanvas()
    @setupKeys()
    @setupTouch()
    @start()

  setupCanvas: ->
    [@canvas.width, @canvas.height]: [$(window).width()-5, $(window).height()-5]

  setupKeys: ->
    $(window).keydown (e) =>
      switch e.which
        when 32  # space bar = shoot
          @ship.shoot()
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
            play('zoom_out')
          else
            @universe.zoom: 1
            play('zoom_in')

    $(window).keyup (e) =>
      switch e.which
        when 37, 39
          @ship.rotate(0)

  setupTouch: ->
    x0: y0: x1: y1: null
    $(document.body).bind 'touchstart', (e) ->
      { screenX: x0, screenY: y0 }: e.originalEvent.targetTouches[0]
      [x1, y1]: [x0, y0]
    $(document.body).bind 'touchmove', (e) =>
      { screenX: x1, screenY: y1 }: e.originalEvent.targetTouches[0]
    $(document.body).bind 'touchend', (e) =>
      [dx, dy]: [x1-x0, y1-y0]
      [absX, absY]: [Math.abs(dx), Math.abs(dy)]
      x0: y0: x1: y1: null
      if absX < 20 and absY < 20
        @ship.shoot()
      else if absX > 20 and absX > absY
        @ship.rotate(dx)
      else if absY > 20 and absY > absX
        if dy > 0
          @ship.brake()
        else
          @ship.thrust()

  buildShip: (universe) ->
    [w, h]: [@canvas.width, @canvas.height]
    [x, y]: [Math.random() * w/2 + w/4, Math.random() * h/2 + h/4]

    @ship: new Ship {
      position: new Vector x, y
      rotation: -Math.PI / 2
    }
    @ship.observe 'explode', @buildShip <- this, universe

    universe.add @ship
    universe.ship: @ship

  start: ->
    @universe: new Universe { canvas: @canvas }
    @buildShip @universe

    @universe.start()
Lz.Controller: Controller

class Bounds
  BUFFER: 40

  constructor: (canvas) ->
    [@l, @t]: [0, 0]
    [@r, @b]: [@width, @height]: [canvas.width, canvas.height]
    @dx: @dy: 0

  check: (ship) ->
    p: ship.position
    flip: false

    if p.x < @l+@BUFFER
      @dx: -@width * 0.75; flip: true
    else if p.x > @r-@BUFFER
      @dx: +@width * 0.75; flip: true

    if p.y < @t+@BUFFER
      @dy: -@height * 0.75; flip: true
    else if p.y > @b-@BUFFER
      @dy: +@height * 0.75; flip: true

    if flip
      play('flip')

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

  add: (mass) ->
    @masses.push mass
    mass.universe: this
    status { objects: @masses.length }

  remove: (mass) ->
    @masses: _.without @masses, mass
    status { objects: @masses.length }

  start: ->
    @setupCanvas()
    @loop()

    @injectAsteroids 5
    setInterval (@injectAsteroids <- this, 3), 5000

  loop: ->
    @step 1
    @render()
    setTimeout (@loop <- this), 1000/24

  step: (dt) ->
    @tick += dt
    mass.step dt for mass in @masses
    @checkCollisions()

  render: ->
    @bounds.check @ship

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
    return unless @ship?

    # ship collisions
    for m in @masses
      if m.overlaps @ship
        @ship.explode()
        break

    # bullet collisions
    for b in @ship.bullets
      for m in @masses
        if m.overlaps b
          m.explode()
          b.explode()
          break

  setupCanvas: ->
    @bounds: new Bounds @canvas
    @ctx: @canvas.getContext '2d'
    @ctx.lineCap: 'round'
    @ctx.lineJoin: 'round'
    @ctx.strokeStyle: 'rgb(255,255,255)'
    @ctx.fillStyle: 'rgb(255,255,255)'
    @ctx.font: '9pt Monaco, Monospace'
    @ctx.textAlign: 'center'
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

  explode: ->
    this.universe.remove this

  overlaps: (other) ->
    return false if other == this || other.TYPE == 'Explosion'
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
Lz.Mass: Mass

class Ship extends Mass
  constructor: (options) ->
    options: or {}
    options.radius: or 16
    super options

    @bullets: []
    _.extend(this, new Observable())

  explode: ->
    super()
    @universe.add(new Explosion({ from: this }))
    @trigger('explode')

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

  shoot: ->
    p: new Vector(@rotation)
    b: new Bullet { ship: this }
    @universe.add b
    @bullets.push b

  removeBullet: (b) ->
    @bullets: _.without @bullets, b

  rotate: (dir) ->
    if (dir > 0 && @rotationalVelocity <= 0)
      @rotationalVelocity += Math.PI / 16
    else if (dir < 0 && @rotationalVelocity >= 0)
      @rotationalVelocity -= Math.PI / 16
    else if dir == 0
      @rotationalVelocity: 0

class Asteroid extends Mass
  RADIUS_BIG: 40
  RADIUS_SMALL: 20

  constructor: (options) ->
    options: or {}
    options.radius: or @RADIUS_BIG
    options.velocity: or new Vector(6 * Math.random() - 3, 6 * Math.random() - 3)
    options.position: options.position.plus options.velocity.times(10)
    options.rotationalVelocity: or Math.random() * 0.1 - 0.05

    super options

    @lifetime: 24 * 60

    unless (@points: options.points)?
      l: 4 * Math.random() + 8
      @points: new Vector(2 * Math.PI * i / l).times(@radius * Math.random() + @radius / 3) for i in [0 .. l]

  explode: ->
    super()
    if @radius > @RADIUS_SMALL
      for i in [0 .. parseInt(Math.random()*2)+2]
        a: new Asteroid {
          radius: @RADIUS_SMALL
          position: @position.clone()
        }
        @universe.add a
    @universe.add(new Explosion({ from: this }))

  step: (dt) ->
    super dt
    @universe.remove this if (@lifetime -= dt) < 0

  _render: (ctx) ->
    p: @points
    ctx.beginPath()
    ctx.moveTo p[0].x, p[0].y
    ctx.lineTo p[i].x, p[i].y for i in [1 ... p.length]
    ctx.closePath()
    ctx.stroke()

class Bullet extends Mass
  constructor: (options) ->
    @ship: options.ship
    @lifetime: 24 * 3
    rotation: new Vector(@ship.rotation).times(@ship.radius)

    options: or {}
    options.radius: or 2
    options.position: or @ship.position.plus rotation
    options.velocity: new Vector(@ship.rotation).times(12)

    super options

    play('shoot')

  step: (dt) ->
    super dt
    @explode() if (@lifetime -= dt) < 0

  explode: ->
    super()
    @ship.removeBullet this

  _render: (ctx) ->
    ctx.beginPath()
    ctx.arc 0, 0, @radius, 0, Math.PI * 2, true
    ctx.closePath()
    ctx.stroke()

class Explosion extends Mass
  TYPE: 'Explosion'
  STRINGS: ['BOOM!', 'POW!', 'KAPOW!', 'BAM!', 'EXPLODE!']

  constructor: (options) ->
    if options.from
      options.position: options.from.position
      options.velocity: options.from.velocity

    super(options)

    @text: @STRINGS[parseInt(Math.random()*@STRINGS.length)]
    @lifetime: 36  # frames
    play('explode')

  overlaps: (other) ->
    false

  step: (dt) ->
    super(dt)
    @explode() if (@lifetime -= dt) < 0

  _render: (ctx) ->
    if 'fillText' in ctx
      ctx.fillText(@text, 0, 0)

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
    @setupObservers()
    @socket.connect()

  send: (message) ->
    @socket.send message

  receive: (fn) ->
    @observe "message", fn

  setupObservers: () ->
    o: new Observable()
    @trigger: o.trigger <- o
    @observe: o.observe <- o

    @socket.addEvent 'message', (json) =>
      data: JSON.parse json
      @trigger "message", data
Lz.Connection: Connection

class Observable
  observe: (name, fn) ->
    @observers(name).push fn

  trigger: (name, args...) ->
    callback args... for callback in @observers(name)

  observers: (name) ->
    (@_observers ||= {})[name] ||= []
Lz.Observable: Observable

class Sound
  constructor: (preload) ->
    @base: 'http://lazeroids.com.s3.amazonaws.com/'
    @sounds: {}
    @load(s) for s in preload || []

  load: (sound) ->
    unless sound in @sounds
      @sounds[sound]: s: new Audio(@base + sound + '.mp3')
    @sounds[sound]

  play: (sound, options) ->
    s: @load(sound)
    if s.currentTime == 0
      s.play()
    else
      s.currentTime: 0
    s
Lz.play: play: Sound.prototype.play <- new Sound(['explode', 'flip', 'shoot', 'warp', 'zoom_in', 'zoom_out'])

Lz.status: status: (msg) -> $('#status .' + k).text v for k, v of msg if $?
