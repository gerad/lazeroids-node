sys: require 'sys'
nodeunit: require '../../nodeunit/lib/nodeunit'

red:   (str) -> "\033[31m$str\033[39m"
green: (str) -> "\033[32m$str\033[39m"
bold:  (str) -> "\033[1m$str\033[22m"

tests: {}
exports.test: (name, fn) ->
  tests[name]: fn

exports.run: ->
  name: __filename
  sys.puts bold "\n$name"
  nodeunit.runModule tests, {
    name: name
    testDone: (name, assertions) ->
      if not assertions.failures
        sys.puts "✔ $name"
      else
        sys.puts red "✖ $name"
        for assertion in assertions when assertion.failed()
          sys.puts assertion.error.stack + "\n"
    moduleDone: (name, assertions) ->
      if assertions.failures
        sys.puts bold(red(
          "\nFAILURES ${assertions.failures} / ${assertions.length} " +
          " assertions failed (${assertions.duration} ms)"))
      else
        sys.puts bold(green(
          "\nOK: ${assertions.length} assertions(${assertions.duration} ms)"))
  }