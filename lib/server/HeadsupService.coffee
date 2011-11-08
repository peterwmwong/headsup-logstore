LogStore = require '../LogStore'
server = (connect = require 'connect')()
handlers = [ require './handlers/ServiceHandler' ]
path = "#{__dirname}/../client/"

server.use use for use in [
  connect.favicon()
  connect.static path, maxAge: 1, hidden: true
]
server.listen process.env.PORT or 8888
console.log "'serving #{path} on #{server.address().port}"

io = require('socket.io').listen server
io.enable 'browser client minification'
io.enable 'browser client etag'
io.enable 'browser client gzip'
io.set 'log level', 1
io.set 'origins', '*:*'
io.set 'transports', [
  'websocket'
  'flashsocket'
  'htmlfile'
  'xhr-polling'
  'jsonp-polling'
]

ctx = {}
io.sockets.on 'connection', (socket)->
  for handler in handlers
    for event, method of handler.on
      socket.on event, method.bind ctx

lsConfig =
  host: process.argv[2] or '127.0.0.1'
  port: process.argv[3] or '6379'
  dbid: process.argv[4] or '0'

console.log "Connecting to LogStore @ #{lsConfig.host}:#{lsConfig.port} DBID=#{lsConfig.dbid}..."
new LogStore(lsConfig).on 'log', (log)->
  console.log log
  io.sockets.emit 'log', log
