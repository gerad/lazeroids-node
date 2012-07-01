(function() {
  var Asteroid, BigAsteroid, Bounds, Bullet, Connection, Controller, Explosion, IOQueue, Lz, Mass, MassStorage, Observable, Score, Serializer, Ship, ShipStorage, SmallAsteroid, Sound, TextMass, Universe, Vector, _a, _b, _c, leaderboard, play, status;
  var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  }, __slice = Array.prototype.slice, __extends = function(child, parent) {
    var ctor = function(){};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__superClass__ = parent.prototype;
  }, __hasProp = Object.prototype.hasOwnProperty;
  if (typeof process !== "undefined" && process !== null) {
    Lz = exports;
  } else {
    Lz = (window.Lz = {});
    window.console = window.console || {};
    _b = ['log', 'dir', 'error', 'warn'];
    for (_a = 0, _c = _b.length; _a < _c; _a++) {
      (function() {
        var fn = _b[_a];
        return window.console[fn] = window.console[fn] || (function() {});
      })();
    }
  }
  Controller = function(canvas) {
    this.canvas = canvas;
    this.setupCanvas();
    this.start();
    return this;
  };
  Controller.prototype.setupCanvas = function() {
    var _d;
    _d = [$(window).width(), $(window).height()];
    this.canvas.width = _d[0];
    this.canvas.height = _d[1];
    return [this.canvas.width, this.canvas.height];
  };
  Controller.prototype.setupInput = function() {
    this.setupKeys();
    return this.setupTouch();
  };
  Controller.prototype.setupKeys = function() {
    $(window).keydown(__bind(function(e) {
      var _d, ship;
      ship = this.universe.ship;
      if ((_d = e.which) === 32) {
        return ship.shoot();
      } else if (_d === 37) {
        return ship.rotate(-1);
      } else if (_d === 39) {
        return ship.rotate(+1);
      } else if (_d === 38) {
        return ship.thrust();
      } else if (_d === 40) {
        return ship.brake();
      } else if (_d === 87) {
        return ship.warp();
      } else if (_d === 72 || _d === 191) {
        return $('#help').animate({
          opacity: 'toggle'
        });
      } else if (_d === 78) {
        return (this.universe.renderNames = !this.universe.renderNames);
      } else if (_d === 90) {
        if (this.universe.zoom === 1) {
          this.universe.zoom = 0.4;
          return play('zoom_out');
        } else {
          this.universe.zoom = 1;
          return play('zoom_in');
        }
      }
    }, this));
    return $(window).keyup(__bind(function(e) {
      var _d;
      if ((_d = e.which) === 37 || _d === 39) {
        return this.universe.ship.rotate(0);
      }
    }, this));
  };
  Controller.prototype.setupTouch = function() {
    var x0, x1, y0, y1;
    x0 = (y0 = (x1 = (y1 = null)));
    $(document.body).bind('touchstart', function(e) {
      var _d, _e;
      _d = e.originalEvent.targetTouches[0];
      x0 = _d.screenX;
      y0 = _d.screenY;
      _e = [x0, y0];
      x1 = _e[0];
      y1 = _e[1];
      return [x1, y1];
    });
    $(document.body).bind('touchmove', function(e) {
      var _d;
      _d = e.originalEvent.targetTouches[0];
      x1 = _d.screenX;
      y1 = _d.screenY;
      return {
        screenX: x1,
        screenY: y1
      };
    });
    return $(document.body).bind('touchend', __bind(function(e) {
      var _d, _e, absX, absY, dx, dy, ship;
      _d = [x1 - x0, y1 - y0];
      dx = _d[0];
      dy = _d[1];
      _e = [Math.abs(dx), Math.abs(dy)];
      absX = _e[0];
      absY = _e[1];
      x0 = (y0 = (x1 = (y1 = null)));
      ship = this.universe.ship;
      if (absX < 20 && absY < 20) {
        return ship.shoot();
      } else if (absX > 20 && absX > absY) {
        return ship.rotate(dx);
      } else if (absY > 20 && absY > absX) {
        return dy > 0 ? ship.brake() : ship.thrust();
      }
    }, this));
  };
  Controller.prototype.setName = function(name) {
    return this.universe.startShip(name);
  };
  Controller.prototype.start = function() {
    this.universe = new Universe({
      canvas: this.canvas
    });
    return this.universe.start();
  };
  Lz.Controller = Controller;
  IOQueue = function() {
    this.outbox = [];
    this.inbox = [];
    this.connection = new Connection();
    return this;
  };
  IOQueue.prototype.send = function() {
    var args;
    args = __slice.call(arguments, 0);
    return this.outbox.push(args);
  };
  IOQueue.prototype.flush = function() {
    var _d;
    if (!(this.outbox.length && (typeof (_d = this.connection.id) !== "undefined" && _d !== null))) {
      return null;
    }
    this.connection.send(this.outbox);
    return (this.outbox = []);
  };
  IOQueue.prototype.read = function() {
    var ret;
    ret = this.inbox;
    this.inbox = [];
    return ret;
  };
  IOQueue.prototype.connect = function() {
    this.connection.observe('message', __bind(function(data) {
      return (this.inbox = this.inbox.concat(data));
    }, this));
    return this.connection.connect();
  };
  MassStorage = function() {
    this.items = {};
    this.length = 0;
    return this;
  };
  MassStorage.prototype.find = function(mass) {
    return this.items[this.key(mass)];
  };
  MassStorage.prototype.add = function(mass) {
    var _d;
    if ((typeof (_d = this.find(mass)) !== "undefined" && _d !== null)) {
      return null;
    }
    this.length++;
    return this.set(mass);
  };
  MassStorage.prototype.update = function(mass) {
    var _d;
    return (typeof (_d = this.find(mass)) !== "undefined" && _d !== null) ? this.set(mass) : this.add(mass);
  };
  MassStorage.prototype.remove = function(mass) {
    var _d;
    if (!((typeof (_d = this.find(mass)) !== "undefined" && _d !== null))) {
      return null;
    }
    this.length--;
    return delete this.items[this.key(mass)];
  };
  MassStorage.prototype.key = function(mass) {
    return mass.id;
  };
  MassStorage.prototype.set = function(mass) {
    return (this.items[this.key(mass)] = mass);
  };
  ShipStorage = function() {
    return MassStorage.apply(this, arguments);
  };
  __extends(ShipStorage, MassStorage);
  ShipStorage.prototype.find = function(mass) {
    var ship;
    ship = ShipStorage.__superClass__.find.call(this, mass);
    if ((typeof ship === "undefined" || ship == undefined ? undefined : ship.id) === mass.id) {
      return ship;
    }
  };
  ShipStorage.prototype.key = function(mass) {
    return mass.connectionId;
  };
  ShipStorage.prototype.get = function(connectionId) {
    return this.items[connectionId];
  };
  ShipStorage.prototype.set = function(mass) {
    var toSet;
    toSet = this.items[mass.connectionId];
    return !(typeof toSet !== "undefined" && toSet !== null) || mass.id === toSet.id ? ShipStorage.__superClass__.set.call(this, mass) : null;
  };
  Universe = function(options) {
    this.canvas = typeof options === "undefined" || options == undefined ? undefined : options.canvas;
    this.masses = new MassStorage();
    this.ships = new ShipStorage();
    this.tick = 0;
    this.zoom = 1;
    this.renderNames = true;
    this.io = new IOQueue();
    this.silent = false;
    this.buildShip();
    return this;
  };
  Universe.prototype.send = function(action, mass, force) {
    if (this.silent && !force) {
      return null;
    }
    mass.ntick = this.tick;
    return this.io.send(action, mass);
  };
  Universe.prototype.silently = function(fn) {
    var prev;
    prev = this.silent;
    this.silent = true;
    fn();
    return (this.silent = prev);
  };
  Universe.prototype.add = function(mass) {
    var _d, _e;
    this.masses.add(mass);
    if ((typeof (_d = mass.ship) !== "undefined" && _d !== null)) {
      this.ships.add(mass);
    }
    mass.universe = this;
    mass.tick = (typeof (_e = mass.tick) !== "undefined" && _e !== null) ? mass.tick : this.tick;
    status({
      objects: this.masses.length
    });
    return this.send('add', mass);
  };
  Universe.prototype.update = function(mass) {
    var _d, existing;
    existing = this.masses.find(mass);
    if (!(typeof existing !== "undefined" && existing !== null) || existing.ntick < mass.ntick) {
      mass.universe = this;
      if ((typeof (_d = mass.ship) !== "undefined" && _d !== null)) {
        this.ships.update(mass);
      }
      this.masses.update(mass);
    }
    return this.send('update', mass);
  };
  Universe.prototype.remove = function(mass) {
    var _d;
    this.masses.remove(mass);
    if ((typeof (_d = mass.ship) !== "undefined" && _d !== null)) {
      this.ships.remove(mass);
    }
    status({
      objects: this.masses.length
    });
    return this.send('remove', mass);
  };
  Universe.prototype.connect = function(ship) {
    if (this.ships.find(ship)) {
      return null;
    }
    this.status(("" + (ship.name) + " connected"));
    this.silently(__bind(function() {
      return this.add(ship);
    }, this));
    return this.send('connect', ship);
  };
  Universe.prototype.disconnect = function(connectionId) {
    var ship;
    ship = this.ships.get(connectionId);
    if (typeof ship !== "undefined" && ship !== null) {
      return this.remove(ship);
    }
  };
  Universe.prototype.requestSync = function() {
    return this.send('sync', this.ship);
  };
  Universe.prototype.sync = function(near) {
    if (!(this.shipStarted())) {
      return null;
    }
    return this.send('update', this.ship, true);
  };
  Universe.prototype.start = function() {
    this.setupCanvas();
    this.setupConnection();
    this.requestSync();
    this.loop();
    this.injectAsteroids(5);
    setInterval((__bind(function() {
      return this.injectAsteroids(3);
    }, this)), 5000);
    setInterval(__bind(this.updateLeaderboard, this), 1000);
    return play('ambient', {
      loop: true
    });
  };
  Universe.prototype.loop = function() {
    this.network();
    this.step(1);
    this.render();
    return setTimeout(__bind(this.loop, this), 1000 / 24);
  };
  Universe.prototype.step = function(dt) {
    var _d, _e, id, mass;
    this.tick += dt;
    _d = this.masses.items;
    for (id in _d) {
      if (!__hasProp.call(_d, id)) continue;
      mass = _d[id];
      mass.step();
    }
    if ((typeof (_e = this.ship) !== "undefined" && _e !== null)) {
      return this.checkCollisions();
    }
  };
  Universe.prototype.network = function() {
    this.silently(__bind(function() {
      var _d, _e, _f, _g, _h, _i, data, method;
      _d = []; _f = this.io.read();
      for (_e = 0, _h = _f.length; _e < _h; _e++) {
        _g = _f[_e];
        method = _g[0];
        data = _g[1];
        _d.push((function() {
          if ((typeof (_i = data.ntick) !== "undefined" && _i !== null) && data.ntick > this.tick) {
            this.tick = data.ntick;
          }
          return this.perform(method, data);
        }).call(this));
      }
      return _d;
    }, this));
    return this.io.flush();
  };
  Universe.prototype.perform = function(method, data) {
    return this[method](data);
  };
  Universe.prototype.status = function(message) {
    return status({
      message: message
    });
  };
  Universe.prototype.render = function() {
    var _d, _e, ctx, id, mass;
    if ((typeof (_d = this.ship) !== "undefined" && _d !== null)) {
      this.bounds.check(this.ship);
    }
    ctx = this.ctx;
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    ctx.save();
    if (this.zoom !== 1) {
      ctx.scale(this.zoom, this.zoom);
      ctx.translate(this.bounds.width * 0.75, this.bounds.height * 0.75);
    }
    this.bounds.translate(ctx);
    _e = this.masses.items;
    for (id in _e) {
      if (!__hasProp.call(_e, id)) continue;
      mass = _e[id];
      mass.render(ctx);
    }
    return ctx.restore();
  };
  Universe.prototype.injectAsteroids = function(howMany) {
    var _d, _e, _f, b, centripetal, h, i, inside, outside, w;
    if (this.masses.length > 80) {
      return null;
    }
    _d = []; _e = (howMany || 1);
    for (i = 1; (1 <= _e ? i <= _e : i >= _e); (1 <= _e ? i += 1 : i -= 1)) {
      _d.push((function() {
        b = this.bounds;
        _f = [this.bounds.width, this.bounds.height];
        w = _f[0];
        h = _f[1];
        outside = new Vector(w * Math.random() - w / 2 + b.l, h * Math.random() - h / 2 + b.t);
        if (outside.x > b.l) {
          outside.x += w;
        }
        if (outside.y > b.t) {
          outside.y += h;
        }
        inside = b.randomPosition();
        centripetal = inside.minus(outside).normalized().times(3 * Math.random() + 1);
        return this.add(new BigAsteroid({
          position: outside,
          velocity: centripetal
        }));
      }).call(this));
    }
    return _d;
  };
  Universe.prototype.buildShip = function() {
    var _d, _e, h, w, x, y;
    _d = [this.canvas == undefined ? undefined : this.canvas.width, this.canvas == undefined ? undefined : this.canvas.height];
    w = _d[0];
    h = _d[1];
    _e = [Math.random() * w / 2 + w / 4, Math.random() * h / 2 + h / 4];
    x = _e[0];
    y = _e[1];
    this.ship = new Ship({
      position: new Vector(x, y),
      rotation: -Math.PI / 2,
      name: this.ship == undefined ? undefined : this.ship.name,
      score: this.ship == undefined ? undefined : this.ship.score,
      connectionId: this.ship == undefined ? undefined : this.ship.connectionId
    });
    return this.ship.observe('explode', __bind(function() {
      this.buildShip();
      return this.add(this.ship);
    }, this));
  };
  Universe.prototype.startShip = function(name) {
    this.ship.name = name;
    return this.connect(this.ship);
  };
  Universe.prototype.shipStarted = function() {
    return this.masses.find(this.ship);
  };
  Universe.prototype.checkCollisions = function() {
    var _d, _e, _f, _g, _h, _i, b, id, m;
    if (!(this.shipStarted())) {
      return null;
    }
    _d = this.masses.items;
    for (id in _d) {
      if (!__hasProp.call(_d, id)) continue;
      m = _d[id];
      if (m.overlaps(this.ship)) {
        this.updateScore(this.ship);
        this.ship.explode();
        break;
      }
    }
    _e = []; _g = this.ship.bullets;
    for (_f = 0, _h = _g.length; _f < _h; _f++) {
      b = _g[_f];
      _i = this.masses.items;
      for (id in _i) {
        if (!__hasProp.call(_i, id)) continue;
        m = _i[id];
        if (m.overlaps(b)) {
          this.updateScore(m);
          m.explode();
          b.explode();
          break;
        }
      }
    }
    return _e;
  };
  Universe.prototype.updateLeaderboard = function() {
    var _d, _e, k, scores, ship;
    scores = (function() {
      _d = []; _e = this.ships.items;
      for (k in _e) {
        if (!__hasProp.call(_e, k)) continue;
        ship = _e[k];
        _d.push({
          name: ship.name,
          value: ship.score,
          focus: ship === this.ship
        });
      }
      return _d;
    }).call(this);
    return leaderboard(scores);
  };
  Universe.prototype.updateScore = function(mass) {
    var value;
    value = mass === this.ship ? Math.floor(-mass.score / 2) : mass.value;
    this.silently(__bind(function() {
      var s;
      s = new Score({
        from: mass,
        value: value
      });
      return this.add(s);
    }, this));
    this.ship.score += value;
    return this.send('update', this.ship);
  };
  Universe.prototype.setupCanvas = function() {
    this.bounds = new Bounds(this.canvas);
    this.ctx = this.canvas.getContext('2d');
    this.ctx.lineCap = 'round';
    this.ctx.lineJoin = 'round';
    this.ctx.strokeStyle = 'rgb(255,255,255)';
    this.ctx.fillStyle = 'rgb(180,180,180)';
    this.ctx.font = '8pt Monaco, monospace';
    return (this.ctx.textAlign = 'center');
  };
  Universe.prototype.setupConnection = function() {
    this.observeConnection();
    return this.io.connect();
  };
  Universe.prototype.observeConnection = function() {
    this.io.connection.observe('connect', __bind(function() {
      return (this.ship.connectionId = this.io.connection.id);
    }, this));
    return this.io.connection.observe('disconnect', __bind(function() {
      return this.status("Connection lost.");
    }, this));
  };
  Lz.Universe = Universe;
  Observable = function() {};
  Observable.prototype.observe = function(name, fn) {
    return this.observers(name).push(fn);
  };
  Observable.prototype.trigger = function(name) {
    var _d, _e, _f, _g, args, callback;
    args = __slice.call(arguments, 1);
    _d = []; _f = this.observers(name);
    for (_e = 0, _g = _f.length; _e < _g; _e++) {
      callback = _f[_e];
      _d.push(callback.apply(this, args));
    }
    return _d;
  };
  Observable.prototype.observers = function(name) {
    return (this._observers = this._observers || {})[name] = (this._observers = this._observers || {})[name] || [];
  };
  Lz.Observable = Observable;
  Bounds = function(canvas) {
    var _d, _e;
    _d = [0, 0];
    this.l = _d[0];
    this.t = _d[1];
    _e = (function() {
      var _f;
      _f = [canvas.width, canvas.height];
      this.width = _f[0];
      this.height = _f[1];
      return [this.width, this.height];
    }).call(this);
    this.r = _e[0];
    this.b = _e[1];
    this.dx = (this.dy = 0);
    return this;
  };
  Bounds.prototype.BUFFER = 40;
  Bounds.prototype.check = function(ship) {
    var dx, dy, flip, p;
    p = ship.position;
    flip = false;
    if (p.x < this.l + this.BUFFER) {
      this.dx = -this.width * 0.75;
      flip = true;
    } else if (p.x > this.r - this.BUFFER) {
      this.dx = +this.width * 0.75;
      flip = true;
    }
    if (p.y < this.t + this.BUFFER) {
      this.dy = -this.height * 0.75;
      flip = true;
    } else if (p.y > this.b - this.BUFFER) {
      this.dy = +this.height * 0.75;
      flip = true;
    }
    flip ? play('flip') : null;
    if (this.dx !== 0) {
      dx = parseInt(this.dx / 8);
      this.l += dx;
      this.r += dx;
      this.dx -= dx;
      if (Math.abs(this.dx) < 3) {
        this.dx = 0;
      }
    }
    if (this.dy !== 0) {
      dy = parseInt(this.dy / 8);
      this.t += dy;
      this.b += dy;
      this.dy -= dy;
      if (Math.abs(this.dy) < 3) {
        return (this.dy = 0);
      }
    }
  };
  Bounds.prototype.translate = function(ctx) {
    return ctx.translate(-this.l, -this.t);
  };
  Bounds.prototype.randomPosition = function() {
    return new Vector(this.width * Math.random() + this.l, this.height * Math.random() + this.t);
  };
  Mass = function(options) {
    var o;
    o = options || {};
    this.id = Math.uuid();
    this.radius = o.radius || 1;
    this.position = o.position || new Vector();
    this.velocity = o.velocity || new Vector();
    this.acceleration = o.acceleration || new Vector();
    this.rotation = o.rotation || 0;
    this.rotationalVelocity = o.rotationalVelocity || 0;
    this.lifetime = o.lifetime || 24 * 60;
    return this;
  };
  __extends(Mass, Observable);
  Mass.prototype.serialize = 'Mass';
  Mass.prototype.value = 0;
  Mass.prototype.explode = function() {
    return this.remove();
  };
  Mass.prototype.remove = function() {
    return this.universe.remove(this);
  };
  Mass.prototype.solid = true;
  Mass.prototype.overlaps = function(other) {
    var diff;
    if (!(this.solid && other.solid && other !== this)) {
      return false;
    }
    diff = other.position.minus(this.position).length();
    return diff < this.radius || diff < other.radius;
  };
  Mass.prototype.step = function() {
    var dt, t;
    dt = this.universe.tick - this.tick;
    if ((this.lifetime -= dt) < 0) {
      return this.remove();
    }
    for (t = 0; (0 <= dt ? t < dt : t > dt); (0 <= dt ? t += 1 : t -= 1)) {
      this.velocity = this.velocity.plus(this.acceleration);
      this.position = this.position.plus(this.velocity);
      this.acceleration = this.acceleration.times(0.8);
      this.rotation += this.rotationalVelocity;
    }
    return (this.tick = this.universe.tick);
  };
  Mass.prototype.render = function(ctx) {
    var _d, _e, _f, _g;
    ctx.save();
    ctx.translate(this.position.x, this.position.y);
    !!(function(){ for (var _f=0, _g=ctx && this.universe.renderNames && (typeof (_d = this.name) !== "undefined" && _d !== null).length; _f<_g; _f++) if (ctx && this.universe.renderNames && (typeof (_e = this.name) !== "undefined" && _e !== null)[_f] === 'fillText') return true; }).call(this) ? ctx.fillText(this.name, 0, 2 * this.radius) : null;
    ctx.rotate(this.rotation);
    this._render(ctx);
    return ctx.restore();
  };
  Mass.prototype._render = function(ctx) {
    ctx.save();
    ctx.strokeStyle = 'rgb(255,0,0)';
    ctx.beginPath();
    ctx.arc(0, 0, this.radius, 0, Math.PI * 2, true);
    ctx.closePath();
    ctx.stroke();
    return ctx.restore();
  };
  Lz.Mass = Mass;
  Ship = function(options) {
    options = options || {};
    options.radius = options.radius || 16;
    Ship.__superClass__.constructor.call(this, options);
    this.name = options.name;
    this.energy = options.energy || this.maxEnergy;
    this.score = options.score || 0;
    this.connectionId = options.connectionId;
    this.bullets = [];
    return this;
  };
  __extends(Ship, Mass);
  Ship.prototype.serialize = [
    'Ship', {
      exclude: 'bullets'
    }
  ];
  Ship.prototype.ship = true;
  Ship.prototype.maxEnergy = 10;
  Ship.prototype.value = 1000;
  Ship.prototype.step = function() {
    var dt;
    if (this === this.universe.ship) {
      dt = this.universe.tick - this.tick;
      this.lifetime += dt;
      this.power(dt);
    }
    return Ship.__superClass__.step.call(this);
  };
  Ship.prototype.explode = function() {
    if (!(this === this.universe.ship)) {
      return null;
    }
    Ship.__superClass__.explode.call(this);
    this.universe.add(new Explosion({
      from: this
    }));
    return this.trigger('explode');
  };
  Ship.prototype._render = function(ctx) {
    ctx.save();
    ctx.beginPath();
    ctx.moveTo(this.radius, 0);
    ctx.lineTo(this.radius / -4, this.radius / 2.5);
    ctx.moveTo(0, this.radius * 0.32);
    ctx.lineTo(0, this.radius * -0.32);
    ctx.moveTo(this.radius / -4, this.radius / -2.5);
    ctx.lineTo(this.radius, 0);
    ctx.stroke();
    return ctx.restore();
  };
  Ship.prototype.thrust = function() {
    this.acceleration = this.acceleration.plus(new Vector(this.rotation).times(0.15));
    return this.universe.update(this);
  };
  Ship.prototype.brake = function() {
    return false;
    this.acceleration = this.acceleration.plus(new Vector(this.rotation).times(-0.05));
    return this.universe.update(this);
  };
  Ship.prototype.shoot = function() {
    var b, p;
    if (!(this.power(-10))) {
      return null;
    }
    p = new Vector(this.rotation);
    b = new Bullet({
      ship: this
    });
    this.universe.add(b);
    return this.bullets.push(b);
  };
  Ship.prototype.power = function(delta) {
    if (this.energy + delta < 0) {
      return false;
    }
    this.energy += delta;
    if (this.energy > this.maxEnergy) {
      this.energy = this.maxEnergy;
    }
    return true;
  };
  Ship.prototype.warp = function() {
    this.position = this.universe.bounds.randomPosition();
    this.velocity = new Vector();
    this.acceleration = new Vector();
    return play('warp');
  };
  Ship.prototype.removeBullet = function(b) {
    return (this.bullets = _.without(this.bullets, b));
  };
  Ship.prototype.rotate = function(dir) {
    if (dir > 0 && this.rotationalVelocity <= 0) {
      this.rotationalVelocity += Math.PI / 16;
    } else if (dir < 0 && this.rotationalVelocity >= 0) {
      this.rotationalVelocity -= Math.PI / 16;
    } else if (dir === 0) {
      this.rotationalVelocity = 0;
    }
    return this.universe.update(this);
  };
  Lz.Ship = Ship;
  Asteroid = function(options) {
    var _d, _e, i, l;
    options = options || {};
    options.velocity = options.velocity || new Vector(this.topSpeed * (Math.random() - 0.5), this.topSpeed * (Math.random() - 0.5));
    options.position = (options.position || new Vector()).plus(options.velocity.times(8));
    options.rotationalVelocity = options.rotationalVelocity || Math.random() * 0.1 - 0.05;
    options.lifetime = options.lifetime || 24 * 30;
    options.radius = options.radius || this.radius;
    Asteroid.__superClass__.constructor.call(this, options);
    if (!((typeof (_e = (this.corners = options.corners)) !== "undefined" && _e !== null))) {
      l = 4 * Math.random() + 8;
      this.corners = (function() {
        _d = [];
        for (i = 0; (0 <= l ? i <= l : i >= l); (0 <= l ? i += 1 : i -= 1)) {
          _d.push(new Vector(2 * Math.PI * i / l).times(this.radius * Math.random() + this.radius / 3));
        }
        return _d;
      }).call(this);
    }
    return this;
  };
  __extends(Asteroid, Mass);
  Asteroid.prototype.serialize = 'Asteroid';
  Asteroid.prototype.radius = 40;
  Asteroid.prototype.topSpeed = 5;
  Asteroid.prototype.value = 100;
  Asteroid.prototype.explode = function() {
    Asteroid.__superClass__.explode.call(this);
    return this.universe.add(new Explosion({
      from: this
    }));
  };
  Asteroid.prototype._render = function(ctx) {
    var _d, i, p;
    p = this.corners;
    ctx.beginPath();
    ctx.moveTo(p[0].x, p[0].y);
    _d = p.length;
    for (i = 1; (1 <= _d ? i < _d : i > _d); (1 <= _d ? i += 1 : i -= 1)) {
      ctx.lineTo(p[i].x, p[i].y);
    }
    ctx.closePath();
    return ctx.stroke();
  };
  Lz.Asteroid = Asteroid;
  BigAsteroid = function() {
    return Asteroid.apply(this, arguments);
  };
  __extends(BigAsteroid, Asteroid);
  BigAsteroid.prototype.serialize = 'BigAsteroid';
  BigAsteroid.prototype.explode = function() {
    var _d, _e, i;
    BigAsteroid.__superClass__.explode.call(this);
    _d = []; _e = parseInt(Math.random() * 2) + 2;
    for (i = 0; (0 <= _e ? i <= _e : i >= _e); (0 <= _e ? i += 1 : i -= 1)) {
      _d.push(this.universe.add(new SmallAsteroid({
        position: this.position.clone()
      })));
    }
    return _d;
  };
  Lz.BigAsteroid = BigAsteroid;
  SmallAsteroid = function() {
    return Asteroid.apply(this, arguments);
  };
  __extends(SmallAsteroid, Asteroid);
  SmallAsteroid.prototype.serialize = 'SmallAsteroid';
  SmallAsteroid.prototype.radius = 20;
  SmallAsteroid.prototype.topSpeed = 10;
  SmallAsteroid.prototype.value = 500;
  Lz.SmallAsteroid = SmallAsteroid;
  Bullet = function(options) {
    var rotation;
    this.ship = options.ship;
    rotation = new Vector(this.ship.rotation).times(this.ship.radius);
    options = options || {};
    options.radius = options.radius || 2;
    options.position = options.position || this.ship.position.plus(rotation);
    options.velocity = new Vector(this.ship.rotation).times(12).plus(this.ship.velocity);
    options.lifetime = options.lifetime || 24 * 3;
    Bullet.__superClass__.constructor.call(this, options);
    play('shoot');
    return this;
  };
  __extends(Bullet, Mass);
  Bullet.prototype.serialize = 'Bullet';
  Bullet.prototype.remove = function() {
    var _d;
    Bullet.__superClass__.remove.call(this);
    if ((typeof (_d = this.ship) !== "undefined" && _d !== null)) {
      return this.ship.removeBullet(this);
    }
  };
  Bullet.prototype._render = function(ctx) {
    ctx.beginPath();
    ctx.arc(0, 0, this.radius, 0, Math.PI * 2, true);
    ctx.closePath();
    return ctx.stroke();
  };
  Lz.Bullet = Bullet;
  TextMass = function() {
    return Mass.apply(this, arguments);
  };
  __extends(TextMass, Mass);
  TextMass.prototype.solid = false;
  TextMass.prototype._render = function(ctx) {
    var _d, _e;
    if (!!(function(){ for (var _d=0, _e=ctx.length; _d<_e; _d++) if (ctx[_d] === 'fillText') return true; }).call(this)) {
      return ctx.fillText(this.text, 0, 0);
    }
  };
  Explosion = function(options) {
    if (options.from) {
      options.position = options.from.position;
      options.velocity = options.from.velocity;
    }
    Explosion.__superClass__.constructor.call(this, options);
    this.text = this.STRINGS[parseInt(Math.random() * this.STRINGS.length)];
    this.lifetime = 36;
    play('explode');
    return this;
  };
  __extends(Explosion, TextMass);
  Explosion.prototype.serialize = 'Explosion';
  Explosion.prototype.STRINGS = ['BOOM!', 'POW!', 'KAPOW!', 'BAM!', 'EXPLODE!'];
  Lz.Explosion = Explosion;
  Score = function(options) {
    var sign, value;
    options = options || {};
    if (options.from) {
      options.position = options.from.position;
    }
    options.velocity = options.velocity || new Vector(0, -1.5);
    Score.__superClass__.constructor.call(this, options);
    this.lifetime = 20;
    value = options.value || 0;
    sign = value > 0 ? '+' : '-';
    this.text = ("" + (sign) + (Math.abs(value)));
    return this;
  };
  __extends(Score, TextMass);
  Lz.Score = Score;
  Vector = function(x, y) {
    var _d;
    _d = (typeof y !== "undefined" && y !== null) ? [x, y] : [Math.cos(x), Math.sin(x)];
    this.x = _d[0];
    this.y = _d[1];
    this.x = this.x || 0;
    this.y = this.y || 0;
    this._zeroSmall();
    return this;
  };
  Vector.prototype.serialize = [
    'Vector', {
      allowNesting: true
    }
  ];
  Vector.prototype.plus = function(v) {
    return new Vector(this.x + v.x, this.y + v.y);
  };
  Vector.prototype.minus = function(v) {
    return new Vector(this.x - v.x, this.y - v.y);
  };
  Vector.prototype.times = function(s) {
    return new Vector(this.x * s, this.y * s);
  };
  Vector.prototype.length = function() {
    return Math.sqrt(this.x * this.x + this.y * this.y);
  };
  Vector.prototype.normalized = function() {
    return this.times(1.0 / this.length());
  };
  Vector.prototype.clone = function() {
    return new Vector(this.x, this.y);
  };
  Vector.prototype._zeroSmall = function() {
    if (Math.abs(this.x) < 0.01) {
      this.x = 0;
    }
    if (Math.abs(this.y) < 0.01) {
      return (this.y = 0);
    }
  };
  Lz.Vector = Vector;
  Connection = function() {
    this.socket = io.connect();
    this.setupObservers();
    return this;
  };
  __extends(Connection, Observable);
  Connection.prototype.send = function(obj) {
    var data;
    data = Serializer.pack(obj);
    return this.socket.send(JSON.stringify(data));
  };
  Connection.prototype.observe = function(msg, fn) {
    Connection.__superClass__.observe.call(this, msg, fn);
    return this.observeSocket(msg);
  };
  Connection.prototype.connect = function() {
    //return this.socket.connect();
  };
  Connection.prototype.setupObservers = function() {
    this.observingSocket = {};
    return this.observe("connect", __bind(function() {
      return (this.id = this.socket.socket.sessionid);
    }, this));
  };
  Connection.prototype.observeSocket = function(eventName) {
    if (this.observingSocket[eventName]) {
      return null;
    }
    this.observingSocket[eventName] = true;
    return this.socket.on(eventName, __bind(function(json) {
      var data;
      if (json && json !== 'booted') {
        data = JSON.parse(json);
      }
      return this.trigger(eventName, Serializer.unpack(data));
    }, this));
  };
  Lz.Connection = Connection;
  Serializer = function(klass, name, options) {
    var _d, _e, _f, _g, i;
    _d = [klass, name];
    this.klass = _d[0];
    this.name = _d[1];
    this.allowNesting = typeof options === "undefined" || options == undefined ? undefined : options.allowNesting;
    this.allowed = {};
    _f = _.compact(_.flatten([typeof options === "undefined" || options == undefined ? undefined : options.exclude]));
    for (_e = 0, _g = _f.length; _e < _g; _e++) {
      i = _f[_e];
      this.allowed[i] = false;
    }
    this.copy = (function() {});
    this.copy.prototype = this.klass.prototype;
    return this;
  };
  Serializer.prototype.shouldSerialize = function(name, value) {
    var _d;
    if (!(typeof value !== "undefined" && value !== null)) {
      return false;
    }
    return this.allowed[name] = (typeof (_d = this.allowed[name]) !== "undefined" && _d !== null) ? this.allowed[name] : _.isString(value) || _.isNumber(value) || _.isBoolean(value) || _.isArray(value) || (value.serializer == undefined ? undefined : value.serializer.allowNesting);
  };
  Serializer.prototype.pack = function(instance) {
    var _d, k, packed, v;
    packed = {
      serializer: this.name
    };
    _d = instance;
    for (k in _d) {
      if (!__hasProp.call(_d, k)) continue;
      v = _d[k];
      this.shouldSerialize(k, v) ? (packed[k] = Serializer.pack(v)) : null;
    }
    return packed;
  };
  Serializer.prototype.unpack = function(data) {
    var _d, k, unpacked, v;
    unpacked = new this.copy();
    _d = data;
    for (k in _d) {
      if (!__hasProp.call(_d, k)) continue;
      v = _d[k];
      k !== 'serializer' ? (unpacked[k] = Serializer.unpack(v)) : null;
    }
    return unpacked;
  };
  _.extend(Serializer, {
    instances: {},
    pack: function(data) {
      var _d, _e, _f, _g, i, s;
      if (s = typeof data === "undefined" || data == undefined ? undefined : data.serializer) {
        return s.pack(data);
      } else if (_.isArray(data)) {
        _d = []; _f = data;
        for (_e = 0, _g = _f.length; _e < _g; _e++) {
          i = _f[_e];
          _d.push(Serializer.pack(i));
        }
        return _d;
      } else {
        return data;
      }
    },
    unpack: function(data) {
      var _d, _e, _f, _g, i, s;
      if (s = Serializer.instances[data == undefined ? undefined : data.serializer]) {
        return s.unpack(data);
      } else if (_.isArray(data)) {
        _d = []; _f = data;
        for (_e = 0, _g = _f.length; _e < _g; _e++) {
          i = _f[_e];
          _d.push(Serializer.unpack(i));
        }
        return _d;
      } else {
        return data;
      }
    },
    bless: function(klass) {
      var _d, name, options;
      _d = _.flatten([klass.prototype.serialize]);
      name = _d[0];
      options = _d[1];
      klass.prototype.serializer = new Serializer(klass, name, options);
      return (Serializer.instances[name] = klass.prototype.serializer);
    },
    blessAll: function(namespace) {
      var _d, _e, _f, k, v;
      _d = []; _e = namespace;
      for (k in _e) {
        if (!__hasProp.call(_e, k)) continue;
        v = _e[k];
        (typeof (_f = v.prototype.serialize) !== "undefined" && _f !== null) ? _d.push(Serializer.bless(v)) : null;
      }
      return _d;
    }
  });
  Lz.Serializer = Serializer;
  Serializer.blessAll(Lz);
  Sound = function(preload, options) {
    var _d, _e, _f, s;
    this.base = 'http://lazeroids.com.s3.amazonaws.com/';
    this.options = options;
    this.sounds = {};
    _e = preload || [];
    for (_d = 0, _f = _e.length; _d < _f; _d++) {
      s = _e[_d];
      this.load(s);
    }
    return this;
  };
  Sound.prototype.load = function(sound) {
    var _d, _e, _f;
    if (!(!!(function(){ for (var _e=0, _f=(_d = this.sounds).length; _e<_f; _e++) if (_d[_e] === sound) return true; }).call(this))) {
      this.sounds[sound] = new Audio(this.base + sound + '.mp3');
      _.extend(this.sounds[sound], this.options);
    }
    return this.sounds[sound];
  };
  Sound.prototype.play = function(sound, options) {
    var s;
    s = this.load(sound);
    _.extend(s, options);
    s.currentTime === 0 ? s.play() : (s.currentTime = 0);
    return s;
  };
  Lz.play = (play = __bind(Sound.prototype.play, new Sound(['ambient', 'explode', 'flip', 'shoot', 'warp', 'zoom_in', 'zoom_out'], {
    volume: 0.25
  })));
  Lz.status = (status = function(msg) {
    var _d, _e, k, v;
    if (typeof $ !== "undefined" && $ !== null) {
      _d = []; _e = msg;
      for (k in _e) {
        if (!__hasProp.call(_e, k)) continue;
        v = _e[k];
        _d.push($('#status .' + k).text(v));
      }
      return _d;
    }
  });
  Lz.leaderboard = (leaderboard = function(scores) {
    var _d, _e, _f, _g, score, sorted, tbody;
    if (!(typeof $ !== "undefined" && $ !== null)) {
      return null;
    }
    sorted = _.sortBy(scores, function(score) {
      return -score.value;
    });
    tbody = $('#score tbody').html('');
    _d = []; _f = sorted;
    for (_e = 0, _g = _f.length; _e < _g; _e++) {
      score = _f[_e];
      _d.push($('<tr>').addClass((function() {
        if (score.focus) {
          return 'focus';
        }
      })()).append($('<td>').text(score.name)).append($('<td>').text(score.value)).appendTo(tbody));
    }
    return _d;
  });
})();
