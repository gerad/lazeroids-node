require('../lib/coffee/lib/coffee');
!function() {
  var helpers = exports.helpers = require('../lib/coffee/lib/coffee-script/lib/helpers').helpers;
  helpers.extend(exports, require('../lib/coffee/lib/coffee-test'));

  require('../public/javascripts/underscore');
  exports.Lz = require('../views/application');
  exports.sys = require('sys');
}();
