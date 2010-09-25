# setup globals
require '../../public/javascripts/underscore'
require '../../public/javascripts/Math.uuid'

# mock out audio for headless testing
global.Audio = (->);
global.Audio.prototype.play = (->);

global.Lz = require '../../lazeroids'
global.sys = require 'sys'

dsl = require 'nodeunit-dsl'
global.test = dsl.test
global.before = dsl.before
global.run = dsl.run

global.assert = require 'assert'
class Mock
  constructor: ->
    @expectations = []
  expect: (name, fn) ->
    this[name] ||= @mockFn(name)
    @expectations.push [name, fn]
    this
  mockFn: (calledName) ->
    return (args...) ->
      [name, fn] = @expectations.pop()
      assert.equal name, calledName, "Mock expected #{name} to be called. Got #{calledName}."
      fn(args...) if fn?
global.Mock = Mock