this.exports = this.Lz = {}

Lz.socket: new io.Socket null, {
  rememberTransport: false
  resource: 'comet'
}
Lz.socket.connect()

$ ->
  $('form').submit ->
    Lz.socket.send $('input[type=text]', this).val()
    this.reset()
    false

  $('input:first').select()

  Lz.socket.addEvent 'message', (data) ->
    $('#message').append JSON.parse(data).msg + '<br />'
