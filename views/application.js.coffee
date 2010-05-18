this.exports = this.Lz = {}

Lz.socket: new io.Socket null, {
  rememberTransport: false
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