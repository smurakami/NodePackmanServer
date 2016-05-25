class Socket
  constructor: ->
    @initWebSocket()
  initWebSocket: ->
    self = @
    host = window.document.location.host.replace(/:.*/, '')
    @ws = new WebSocket('ws://' + host + ':3010')
    @ws.onmessage = (event) ->
      if self.onmessage?
        self.onmessage JSON.parse(event.data)
    @ws.onopen = () ->
      if self.onopen?
        self.onopen()
    @ws.onerror = (error) ->
      console.log('WebSocket Error ' + error)
    @ws.onclose = (error) ->
      console.log('WebSocket Error ' + error)
  send: (data) ->
    @ws.send(JSON.stringify(data))

this.Socket = Socket
