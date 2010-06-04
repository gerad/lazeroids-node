Lz: if process? then exports else this.Lz: {}

class Controller
  constructor: (canvas) ->
    @canvas: canvas
    @setupCanvas()
    @start()

  setupCanvas: ->
    [@canvas.width, @canvas.height]: [$(window).width(), $(window).height()]

  setupInput: ->
    @setupKeys()
    @setupTouch()

  setupKeys: ->
    $(window).keydown (e) =>
      ship: @universe.ship
      switch e.which
        when 32       # space bar = shoot
          ship.shoot()
        when 37       # left
          ship.rotate(-1)
        when 39       # right
          ship.rotate(+1)
        when 38       # up
          ship.thrust()
        when 40       # down
          ship.brake()
        when 87       # w = warp
          ship.warp()
        when 72, 191  # h, ? = help
          $('#help').animate { opacity: 'toggle' }
        when 78       # n = toggle names
          @universe.renderNames: !@universe.renderNames
        when 90       # z = zoom
          if @universe.zoom == 1
            @universe.zoom: 0.4
            play 'zoom_out'
          else
            @universe.zoom: 1
            play 'zoom_in'

    $(window).keyup (e) =>
      switch e.which
        when 37, 39
          @universe.ship.rotate(0)

  setupTouch: ->
    x0: y0: x1: y1: null
    $(document.body).bind 'touchstart', (e) ->
      { screenX: x0, screenY: y0 }: e.originalEvent.targetTouches[0]
      [x1, y1]: [x0, y0]
    $(document.body).bind 'touchmove', (e) ->
      { screenX: x1, screenY: y1 }: e.originalEvent.targetTouches[0]
    $(document.body).bind 'touchend', (e) =>
      [dx, dy]: [x1-x0, y1-y0]
      [absX, absY]: [Math.abs(dx), Math.abs(dy)]
      x0: y0: x1: y1: null
      ship: @universe.ship
      if absX < 20 and absY < 20
        ship.shoot()
      else if absX > 20 and absX > absY
        ship.rotate(dx)
      else if absY > 20 and absY > absX
        if dy > 0
          ship.brake()
        else
          ship.thrust()

  setName: (name) ->
    @universe.startShip name

  start: ->
    @universe: new Universe { canvas: @canvas }
    @universe.start()
Lz.Controller: Controller

class IOQueue
  constructor: ->
    @outbox: []
    @inbox: []
    @connection: new Connection()

  send: (args...) ->
    @outbox.push args

  flush: ->
    return unless @outbox.length and @connection.id?
    @connection.send @outbox
    @outbox: []

  read: ->
    ret: @inbox
    @inbox: []
    ret

  connect: ->
    @connection.observe 'message', (data) =>
      @inbox: @inbox.concat data
    @connection.connect()

class MassStorage
  constructor: (keyField) ->
    @keyField: keyField or 'id'
    @items: {}
    @length: 0

  get: (key) ->
    @items[key]

  find: (mass) ->
    @items[@key mass]

  add: (mass) ->
    return if @find(mass)?
    @update mass

  update: (mass) ->
    @length++ unless @find(mass)?
    @items[@key mass]: mass

  remove: (mass) ->
    return unless @find(mass)?
    @length--
    delete @items[@key mass]

  key: (mass) ->
    mass[@keyField]

class Universe
  constructor: (options) ->
    @canvas: options?.canvas
    @masses: new MassStorage()
    @ships: new MassStorage('connectionId')
    @tick: 0
    @zoom: 1
    @renderNames: true
    @io: new IOQueue()
    @silent: false
    @buildShip()

  send: (action, mass, force) ->
    return if @silent and !force
    mass.ntick: @tick
    @io.send action, mass

  silently: (fn) ->
    prev: @silent
    @silent: true
    fn()
    @silent: prev

  add: (mass) ->
    @masses.add mass
    @ships.add mass if mass.ship?
    mass.universe: this
    mass.tick ?= @tick
    status { objects: @masses.length }
    @send 'add', mass

  update: (mass) ->
    existing: @masses.find(mass)
    if not existing?
      @add mass
    else if existing.ntick < mass.ntick
      mass.universe: this
      @masses.update mass
      @send 'update', mass

  remove: (mass) ->
    @masses.remove mass
    @ships.remove mass if mass.ship?
    status { objects: @masses.length }
    @send 'remove', mass

  connect: (ship) ->
    return if @ships.find ship
    @status "$ship.name connected"
    @silently =>
      @add ship
    @send 'connect', @ship

  disconnect: (connectionId) ->
    ship: @ships.get connectionId
    @remove ship if ship?

  requestSync: ->
    @send 'sync', @ship

  sync: (near) ->
    return unless @shipStarted()
    @send 'update', @ship, true

  start: ->
    @setupCanvas()
    @setupConnection()
    @requestSync()
    @loop()

    if document?.domain is 'lazeroids.com'
      @injectAsteroids 5
      setInterval (@injectAsteroids <- this, 3), 5000

    play 'ambient', { loop: true }

  loop: ->
    @network()
    @step 1
    @render()
    setTimeout (@loop <- this), 1000/24

  step: (dt) ->
    @tick += dt
    mass.step() for id, mass of @masses.items
    @checkCollisions() if @ship?

  network: ->
    @silently =>
      for [method, data] in @io.read()
        @tick: data.ntick if data.ntick? and data.ntick > @tick
        @perform method, data
    @io.flush()

  perform: (method, data) ->
    console.log "Performing $method with:"
    console.dir data
    this[method] data

  status: (message) ->
    status { message: message }

  render: ->
    @bounds.check @ship if @ship?

    ctx: @ctx
    ctx.clearRect 0, 0, @canvas.width, @canvas.height
    ctx.save()

    if @zoom != 1
      ctx.scale @zoom, @zoom
      ctx.translate @bounds.width*0.75, @bounds.height*0.75
    @bounds.translate ctx
    mass.render ctx for id, mass of @masses.items

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

  buildShip: ->
    [w, h]: [@canvas?.width, @canvas?.height]
    [x, y]: [Math.random() * w/2 + w/4, Math.random() * h/2 + h/4]

    @ship: new Ship {
      position: new Vector x, y
      rotation: -Math.PI / 2
      name: @ship?.name
    }
    @ship.observe 'explode', =>
      @buildShip()
      @add @ship

  startShip: (name) ->
    @ship.name: name
    @connect @ship

  shipStarted: ->
    @masses.find @ship

  checkCollisions: ->
    return unless @shipStarted()

    # ship collisions
    for id, m of @masses.items
      if m.overlaps @ship
        @ship.explode()
        break

    # bullet collisions
    for b in @ship.bullets
      for id, m of @masses.items
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
    @ctx.font: '8pt Monaco, monospace'
    @ctx.textAlign: 'center'

  setupConnection: ->
    @observeConnection()
    @io.connect()

  observeConnection: ->
    @io.connection.observe 'connect', =>
      @ship.connectionId: @io.connection.id
    @io.connection.observe 'disconnect', =>
      @status "Connection lost."
Lz.Universe: Universe

class Observable
  observe: (name, fn) ->
    @observers(name).push fn

  trigger: (name, args...) ->
    callback args... for callback in @observers(name)

  observers: (name) ->
    (@_observers ||= {})[name] ||= []
Lz.Observable: Observable

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
      play 'flip'

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

class Mass extends Observable
  serialize: 'Mass'

  constructor: (options) ->
    o: options or {}
    @id: Math.uuid()
    @radius: o.radius or 1
    @position: o.position or new Vector()
    @velocity: o.velocity or new Vector()
    @acceleration: o.acceleration or new Vector()
    @rotation: o.rotation or 0
    @rotationalVelocity: o.rotationalVelocity or 0
    @lifetime: o.lifetime or 24 * 60

  explode: ->
    @remove()

  remove: ->
    @universe.remove this

  solid: true
  overlaps: (other) ->
    return false unless @solid and other.solid and other != this
    diff: other.position.minus(@position).length()

    diff < @radius or diff < other.radius

  step: ->
    dt: @universe.tick - @tick
    return @remove() if (@lifetime -= dt) < 0

    for t in [0...dt]
      @velocity: @velocity.plus @acceleration
      @position: @position.plus @velocity
      @acceleration: @acceleration.times 0.5 # drag
      @rotation += @rotationalVelocity

    @tick: @universe.tick

  render: (ctx) ->
    ctx.save()

    ctx.translate @position.x, @position.y
    if 'fillText' in ctx and @universe.renderNames and @name?
      ctx.fillText @name, 0, 2 * @radius
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
  serialize: ['Ship', { exclude: 'bullets' }]
  ship: true

  constructor: (options) ->
    options: or {}
    options.radius: or 16
    super options

    @name: options.name
    @bullets: []

  step: ->
    @lifetime += (@universe.tick - @tick) if this is @universe.ship
    super()

  explode: ->
    return unless this is @universe.ship
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
    @universe.update this

  brake: ->
    @acceleration: @acceleration.plus(new Vector(@rotation).times(-1))
    @universe.update this

  shoot: ->
    p: new Vector(@rotation)
    b: new Bullet { ship: this }
    @universe.add b
    @bullets.push b

  warp: ->
    @position: @universe.bounds.randomPosition()
    @velocity: new Vector()
    @acceleration: new Vector()
    play 'warp'

  removeBullet: (b) ->
    @bullets: _.without @bullets, b

  rotate: (dir) ->
    if (dir > 0 && @rotationalVelocity <= 0)
      @rotationalVelocity += Math.PI / 16
    else if (dir < 0 && @rotationalVelocity >= 0)
      @rotationalVelocity -= Math.PI / 16
    else if dir == 0
      @rotationalVelocity: 0
    @universe.update this
Lz.Ship: Ship

class Asteroid extends Mass
  serialize: 'Asteroid'
  RADIUS_BIG: 40
  RADIUS_SMALL: 20

  constructor: (options) ->
    options: or {}
    options.radius: or @RADIUS_BIG
    options.velocity: or new Vector(6 * Math.random() - 3, 6 * Math.random() - 3)
    options.position: (options.position or new Vector()).plus options.velocity.times(10)
    options.rotationalVelocity: or Math.random() * 0.1 - 0.05

    super options

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

  _render: (ctx) ->
    p: @points
    ctx.beginPath()
    ctx.moveTo p[0].x, p[0].y
    ctx.lineTo p[i].x, p[i].y for i in [1 ... p.length]
    ctx.closePath()
    ctx.stroke()
Lz.Asteroid: Asteroid

class Bullet extends Mass
  serialize: 'Bullet'

  constructor: (options) ->
    @ship: options.ship
    rotation: new Vector(@ship.rotation).times(@ship.radius)

    options: or {}
    options.radius: or 2
    options.position: or @ship.position.plus rotation
    options.velocity: new Vector(@ship.rotation).times(12)
    options.lifetime: or 24 * 3

    super options

    play 'shoot'

  remove: ->
    super()
    @ship.removeBullet this if @ship?

  _render: (ctx) ->
    ctx.beginPath()
    ctx.arc 0, 0, @radius, 0, Math.PI * 2, true
    ctx.closePath()
    ctx.stroke()
Lz.Bullet: Bullet

class Explosion extends Mass
  serialize: 'Explosion'
  STRINGS: ['BOOM!', 'POW!', 'KAPOW!', 'BAM!', 'EXPLODE!']

  constructor: (options) ->
    if options.from
      options.position: options.from.position
      options.velocity: options.from.velocity

    super(options)

    @text: @STRINGS[parseInt(Math.random()*@STRINGS.length)]
    @lifetime: 36  # frames
    play 'explode'

  solid: false
  overlaps: (other) ->
    @solid

  _render: (ctx) ->
    if 'fillText' in ctx
      ctx.fillText(@text, 0, 0)
Lz.Explosion: Explosion

class Vector
  serialize: ['Vector', { allowNesting: true }]

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

class Connection extends Observable
  constructor: ->
    @socket: new io.Socket null, {
      rememberTransport: false
      resource: 'comet'
      port: 8000
    }
    @observingSocket: {}

  send: (obj) ->
    @socket.send Serializer.pack obj

  observe: (msg, fn) ->
    super msg, fn
    @observeSocket msg

  connect: ->
    @observe "connect", =>
      @id: @socket.transport.sessionid
    @socket.connect()

  observeSocket: (eventName) ->
    return if @observingSocket[eventName]
    @observingSocket[eventName]: true

    @socket.addEvent eventName, (data) =>
      @trigger eventName, Serializer.unpack data

Lz.Connection: Connection

class Serializer
  constructor: (klass, name, options) ->
    [@klass, @name]: [klass, name]

    @allowNesting: options?.allowNesting
    @allowed: {}
    for i in _.compact _.flatten [options?.exclude]
      @allowed[i]: false

    # constructorless copy of the class
    @copy: -> # empty constructor
    @copy.prototype: @klass.prototype # same prototype

  shouldSerialize: (name, value) ->
    return false unless value?
    @allowed[name] ?= _.isString(value) or
      _.isNumber(value) or
      _.isBoolean(value) or
      _.isArray(value) or
      value.serializer?.allowNesting

  pack: (instance) ->
    packed: { serializer: @name }
    for k, v of instance when @shouldSerialize(k, v)
      packed[k]: Serializer.pack v
    packed

  unpack: (data) ->
    unpacked: new @copy()
    for k, v of data when k isnt 'serializer'
      unpacked[k]: Serializer.unpack v
    unpacked

_.extend Serializer, {
  instances: {}

  pack: (data) ->
    if s: data?.serializer
      s.pack data
    else if _.isArray(data)
      Serializer.pack i for i in data
    else
      data

  unpack: (data) ->
    if s: Serializer.instances[data?.serializer]
      s.unpack data
    else if _.isArray(data)
      Serializer.unpack i for i in data
    else
      data

  bless: (klass) ->
    [name, options]: _.flatten [ klass::serialize ]
    klass::serializer: new Serializer(klass, name, options)
    Serializer.instances[name]: klass::serializer

  blessAll: (namespace) ->
    for k, v of namespace when v::serialize?
      Serializer.bless v
}
Lz.Serializer: Serializer
Serializer.blessAll(Lz)

class Sound
  constructor: (preload, options) ->
    @base: 'http://lazeroids.com.s3.amazonaws.com/'
    @options: options
    @sounds: {}
    @load(s) for s in preload || []

  load: (sound) ->
    unless sound in @sounds
      @sounds[sound]: new Audio @base + sound + '.mp3'
      _.extend @sounds[sound], @options
    @sounds[sound]

  play: (sound, options) ->
    s: @load(sound)
    _.extend s, options
    if s.currentTime == 0
      s.play()
    else
      s.currentTime: 0
    s
Lz.play: play: Sound.prototype.play <- new Sound(['ambient', 'explode', 'flip', 'shoot', 'warp', 'zoom_in', 'zoom_out'], { volume: 0.25 })

Lz.status: status: (msg) -> $('#status .' + k).text v for k, v of msg if $?
