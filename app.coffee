require.paths.unshift './lib/express/lib'
require 'express'

get '/', -> this.redirect '/hello/world'
get '/hello/world', -> 'Hello World'

run parseInt(process.env.PORT || 8000), null