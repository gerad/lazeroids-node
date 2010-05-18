this.exports = this.Lz = {}

Lz.socket: new io.Socket window.location.hostname, {
  rememberTransport: false
  port: window.location.port or 80
  resource: 'comet'
}
Lz.socket.connect()

$ ->
  $('form').submit ->
    $textarea: $(this).find('textarea')
    Lz.socket.send $textarea.val()
    $textarea.val('')
    false
  Lz.socket.addEvent 'message', (data) ->
    $('#message').append JSON.parse(data).msg + '<br />'