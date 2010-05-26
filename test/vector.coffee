helpers.extend global, require('./test-helper')

v1: v2: null
before ->
  v1: new Lz.Vector(1, 2)
  v2: new Lz.Vector(5, 6)

test "initialize", (t) ->
  t.ok v: new Lz.Vector(3, 4)
  t.equals 3, v.x
  t.equals 4, v.y

  t.ok v: new Lz.Vector(Math.PI / 2)
  t.equals 0, v.x
  t.equals 1, v.y
  t.done()

test "plus", (t) ->
  t.ok sum: v1.plus(v2)
  t.equals 6, sum.x
  t.equals 8, sum.y
  t.done()

test "minus", (t) ->
  t.ok diff: v1.minus(v2)
  t.equals(-4, diff.x)
  t.equals(-4, diff.y)
  t.done()

test "times", (t) ->
  t.ok scaled: v1.times(4)
  t.equals 4, scaled.x
  t.equals 8, scaled.y
  t.equals 1, v1.x
  t.done()

test "length", (t) ->
  t.ok easy: new Lz.Vector(3, 4)
  t.equals 5, easy.length()
  t.done()

test "normalized", (t) ->
  easy: new Lz.Vector(2, 0)
  t.ok unit: easy.normalized()
  t.equals 1, unit.x
  t.equals 0, unit.y
  t.done()

test "clone", (t) ->
  t.ok c: v1.clone()
  t.equals c.x, v1.x
  t.equals c.y, v1.y
  [v1.x, v1.y]: [5, 0]
  t.equals 1, c.x
  t.equals 2, c.y
  t.done()

test "zeroSmall", (t) ->
  t.ok small: v1.times(0.001)
  t.equals 0, small.x
  t.equals 0, small.y
  t.done()

run(__filename)
