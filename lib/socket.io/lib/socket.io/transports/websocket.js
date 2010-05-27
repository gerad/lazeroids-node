var Client = require('../client').Client, 
		url = require('url'),
		Buffer = require('buffer').Buffer,
		crypto = require('crypto');

this.websocket = Client.extend({
  
	_onConnect: function(req, socket, head){
		var self = this;
		this.request = req;
		this.connection = socket;
		this.data = '';

		if (this.request.headers['upgrade'] !== 'WebSocket' || !this._verifyOrigin(this.request.headers['origin'])){
			this.listener.options.log('WebSocket connection invalid');
			this.connection.end();
		}
		
		this.connection.setTimeout(0);
		this.connection.setEncoding('utf8');
		this.connection.setNoDelay(true);
		this.connection.write([
			'HTTP/1.1 101 Web Socket Protocol Handshake', 
			'Upgrade: WebSocket', 
			'Connection: Upgrade',
			'WebSocket-Origin: ' + this.request.headers.origin,
			'WebSocket-Location: ws://' + this.request.headers.host + this.request.url,
			'Sec-WebSocket-Origin: ' + this.request.headers.origin,
			'Sec-WebSocket-Location: ws://' + this.request.headers.host + this.request.url,
      '', ''
		].join('\r\n'));
		this.connection.addListener('end', function(){ self._onClose(); });
		this.connection.addListener('data', function(data){ self._handle(data); });
		this._proveReception(head);
		this._payload();
	},
	
	_handle: function(data){
		this.data += data;
		chunks = this.data.split('\ufffd');
		chunk_count = chunks.length - 1;
		for (var i = 0; i < chunk_count; i++) {
			chunk = chunks[i];
			if (chunk[0] != '\u0000') {
				this.listener.options.log('Data incorrectly framed by UA. Dropping connection');
				this.connection.destroy();
				return false;
			}
			this._onMessage(chunk.slice(1));
		}
		this.data = chunks[chunks.length - 1];
	},
	
	_verifyOrigin: function(origin){
		var parts = url.parse(origin);
		return this.listener.options.origins.indexOf('*:*') !== -1
			|| this.listener.options.origins.indexOf(parts.host + ':' + parts.port) !== -1 
			|| this.listener.options.origins.indexOf(parts.host + ':*') !== -1 
			|| this.listener.options.origins.indexOf('*:' + parts.port) !== -1;
	},

	// http://www.whatwg.org/specs/web-apps/current-work/complete/network.html#opening-handshake
	_proveReception: function(head){
		var k1 = this.request.headers['sec-websocket-key1'],
		    k2 = this.request.headers['sec-websocket-key2'];
		if (k1 && k2) {
			var n = [k1, k2].map(function(k) {
				var x = '', spaces = 0;
				for (i in k) {
					var j = parseInt(k[i]);
					if (!isNaN(j))
						x += j;
					else if (k[i] === ' ')
						spaces++;
				}

				return parseInt(x) / spaces;
			});

			var buf = new Buffer(16),
					md5 = crypto.createHash('md5');

			buf[3] = n[0] & 0xff;
			buf[2] = (n[0] >>= 8) & 0xff;
			buf[1] = (n[0] >>= 8) & 0xff;
			buf[0] = (n[0] >>= 8) & 0xff;
			buf[7] = n[1] & 0xff;
			buf[6] = (n[1] >>= 8) & 0xff;
			buf[5] = (n[1] >>= 8) & 0xff;
			buf[4] = (n[1] >>= 8) & 0xff;
			buf.write(head.toString('binary'), 'binary', 8);

			var proof = md5.update(buf.toString('binary')).digest('binary');
			this.connection.write(proof, 'binary');
		}
	},
	
	_write: function(message){
		this.connection.write('\u0000', 'binary');
		this.connection.write(message, 'utf8');
		this.connection.write('\uffff', 'binary');
	}
  
});

this.websocket.httpUpgrade = true;
