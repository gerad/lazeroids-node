helpers.extend global, require('./test-helper')

u: m: null
before ->
  u: new Lz.Universe()
  m: new Lz.Mass()
  u.add m

test "initialize", (t) ->
  t.expect 1
  t.ok new Lz.Universe(), 'can initialize universe'
  t.done()

test "add", (t) ->
  t.expect 2
  t.equals m.universe, u, 'mass has correct universe'
  t.equals 1, u.masses.length, 'universe has 1 mass'
  t.done()

test "step", (t) ->
  t.expect 1
  start: m.position.clone()
  velocity: new Lz.Vector(1, 0)
  m.velocity: velocity.clone()
  u.step 1
  t.same start.plus(velocity), m.position
  t.done()

run()