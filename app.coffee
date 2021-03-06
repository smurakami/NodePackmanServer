# app.coffee
# class Room
#   constructor: (ws, location) ->
#     @id = Room.count
#     Room.count++

#     @location = location
#     @ws_list = []
#     @addWS ws
#     @started = false
#     @finished = false
#     @able_to_start = false
#     @finish_scroll_val = 1000 # 後で書き換えられる

#     @team_num =
#       a: 0, b: 0
#     # チームごとの得点
#     @scroll_value =
#       a: 0, b: 0

#   addWS: (ws) ->
#     @ws_list.push ws
#     ws.room = @
#     @updateTeam()

#   removeWS: (ws) ->
#     ws.room = null
#     @ws_list = @ws_list.filter (x) -> x != ws

#   destroy: ->
#     @finished = true
#     Room.all = Room.all.filter (x) => x != @

#   updateTeam: ->
#     @team_num =
#       a: 0, b: 0
#     for ws in @ws_list
#       if ws.team == 'a'
#         @team_num.a++
#       if ws.team == 'b'
#         @team_num.b++
#     @able_to_start = @team_num.a > 0 and @team_num.b > 0
#     @broadcast
#       event: 'team'
#       team_num: @team_num
#       able_to_start: @able_to_start

#   start: ->
#     return unless @able_to_start
#     interval = 0.1
#     duration = 10
#     max_val = 20000
#     min_val = 1000
#     finish_val = new ValManager(max_val, min_val, duration, interval)
#     @finish_scroll_val = max_val
#     _loop = =>
#       return if @finished
#       @sendScroll()
#       @finish_scroll_val = finish_val.update()
#       return if @checkFinished()
#       setTimeout _loop, 1000 * interval
#     _loop()

#     @started = true
#     @broadcast
#       event: 'start'

#   checkFinished: ->
#     gap = @scroll_value.a - @scroll_value.b
#     if Math.abs(gap) > @finish_scroll_val
#       @finish()
#       true
#     else
#       false

#   finish: ->
#     gap = @scroll_value.a - @scroll_value.b
#     if gap > 0
#       winner = 'a'
#     else
#       winner = 'b'
#     @broadcast
#       event: 'finish'
#       winner: winner
#     @finished = true

#   sendScroll: ->
#     @broadcast
#       event: "scroll"
#       value: @scroll_value
#       finish_scroll_val: @finish_scroll_val

#   broadcast: (data) ->
#     message = JSON.stringify data
#     @ws_list.forEach (con, i) ->
#       con.send(message);

#   #: ---- class methods
#   @count = 0
#   @all = []
#   @find = (id) ->
#     for r in Room.all
#       if r.id == id
#         return r
#     return null
#   @save = (room) ->
#     Room.all.push room

#   locToPos = (loc) ->
#     a = loc.longitude / 180 * Math.PI
#     b = loc.latitude / 180 * Math.PI
#     radius = 6378137 # 地球半径[m]
#     sin = Math.sin
#     cos = Math.cos
#     x = cos(b) * cos(a) * radius
#     y = cos(b) * sin(a) * radius
#     z = sin(b) * radius
#     return {x: x, y: y, z: z}

#   dist = (a, b) ->
#     dx = a.x - b.x
#     dy = a.y - b.y
#     dz = a.z - b.z
#     return Math.sqrt(dx * dx + dy * dy + dz * dz)

#   @findByLocation = (loc) ->
#     console.log '@findbyLocation'
#     console.log 'location:'
#     console.log loc
#     loc_th = 5000 # [m] これよりも遠いお部屋には入れない
#     pos = locToPos(loc)
#     sorted = Room.all.concat().sort (a, b) ->
#       a_pos = locToPos(a.location)
#       b_pos = locToPos(a.location)
#       return dist(a_pos, pos) - dist(b_pos, pos)
#     sorted = Room.all.filter (room) ->
#       console.log room.id
#       not room.started
#     head = sorted[0]
#     console.log "head: #{head}"
#     return null unless head?
#     d = dist(locToPos(head.location), pos)
#     console.log "dist: #{d}"
#     return null if d > loc_th # 遠くにある部屋には入れない
#     return head


# class ValManager
#   constructor: (start_val, finish_val, duration, interval) ->
#     @start_val = start_val
#     @finish_val = finish_val
#     @duration = duration
#     @interval = interval
#     @counter = 0
#     @val = start_val

#   update: ->
#     @counter += 1
#     rate = @interval * @counter / @duration
#     if rate > 1
#       rate = 1
#     @val = @start_val + rate * (@finish_val - @start_val)
#     return @val

class Player
  @counter: 0
  constructor: (ws) ->
    @ws = ws
    ws.player = @
    @control = "none"
    @id = Player.counter
    Player.counter += 1

  remove: ->
    @ws.player = null
    @ws = null

  # update: ->
  #   return if control == null
  #   @ws.send JSON.stringify
  #     event: control
  #     control: control
  #   control = null

class Main
  constructor: ->
    @init()
    @setupWSS()
  init: ->
    @main_view = null
    @player_list = []
    setInterval =>
      @update()
    , 33
  setupWSS: ->
    WebSocketServer = require('ws').Server
    @WebSocket = require('ws')
    http = require('http')
    express = require('express')
    app = express();
    app.use(express.static(__dirname + '/'));
    server = http.createServer(app);

    self = @
    @wss = new WebSocketServer({server:server});
    @wss.on 'connection', (ws) ->
      console.log 'connected'
      ws.on 'close', ->
        self.closeConnection(ws)
      ws.on 'message', (message) ->
        self.onMessage ws, message
    server.listen 3010

  closeConnection: (ws) ->
    console.log 'close'
    if ws == @main_view
      @main_view = null
      return

    removeIndex = null
    for player, i in @player_list
      if player.ws == ws
        removeIndex = i
        break

    if removeIndex?
      @player_list.splice(removeIndex)
      @send @main_view,
        event: "remove"
        index: removeIndex

  onMessage: (ws, message) ->
    data = JSON.parse(message)
    console.log data
    switch data.event
      when "client_type"
        console.log "client_type"
        if data.client_type == 'main_view'
          console.log 'mainview'
          @player_list = []
          @main_view = ws
        if data.client_type == 'player'
          @createPlayer ws

      when "control"
        control = data.control
        console.log control
        ws.player.control = control

      when "color"
        color = data.color
        id = data.id
        for player in @player_list
          if player.id == id
            @send player.ws,
              event: "color"
              color: color
            break

  createPlayer: (ws) ->
    player = new Player(ws)
    console.log "player #{player.id}"
    @player_list.push player
    @send @main_view,
      event: "create_player",
      id: player.id

  send: (ws, object) -> 
    return unless ws
    if ws.readyState != @WebSocket.OPEN
      console.log 'closed!!'
      return
    ws.send JSON.stringify(object)

  update: ->
    control_list = (player.control for player in @player_list)
    # console.log control_list
    if @main_view?
      @send @main_view,
        event: "control"
        control: control_list
    for player in @player_list
      player.control = "none"

  # assignRoom: (ws, data) ->
  #   location = data.location
  #   room = Room.findByLocation(location)
  #   if room?
  #     room.addWS ws
  #   else
  #     room = new Room(ws, location)
  #     Room.save room
  #   @send ws,
  #     event: "location"
  #     room_id: ws.room.id

  # assignTeam: (ws, data) ->
  #   ws.team = data.team
  #   ws.room.updateTeam()

  # startGame: (ws) ->
  #   ws.room.start()

  # scroll: (ws, data) ->
  #   room = ws.room
  #   value = data.value
  #   team = data.team
  #   switch team
  #     when "a"
  #       room.scroll_value.a += value
  #     when "b"
  #       room.scroll_value.b += value


process.on 'uncaughtException', (err) ->
  console.log err

main = new Main()

