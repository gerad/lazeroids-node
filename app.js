require.paths.unshift('./lib/express/lib')
require('express')

get('/', function(){
  this.redirect('/hello/world');
});

get('/hello/world', function(){
  return 'Hello World'
});

run();