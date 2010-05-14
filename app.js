require.paths.unshift('./lib/express/lib', './lib/ext/lib')
require('express')

get('/', function(){
  this.redirect('/hello/world');
});

get('/hello/world', function(){
  return 'Hello World';
});

run(parseInt(process.env.PORT || 8000), null);