var CoffeeScript = require('./coffee-script/lib/coffee-script'),
    haml = require('haml');

exports.render = function(content, options) {
  return CoffeeScript.compile(content);
};

haml.filters.coffeescript = function(str) {
  return ['<script>', exports.render(str), '</script>'].join("\n");
};
