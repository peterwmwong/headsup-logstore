FileWatcher = require './FileWatcher'
LogPublisher = require './LogPublisher'
fs = require 'fs'
{parse} = require './LogParser'
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

logFile = process.argv[2]
if (not logFile) or not (fs.statSync 'logFile').isFile()
  log

FileWatcher.watch logfile, {poll}, (err, lines)->
  if err
    L "Error watching #{logfile}, err=", err
    watcher.unwatch()
  else
    lp.log (ctx = parse(l, ctx) for l in lines when l)

console.log "Connecting to LogStore @ #{lsConfig.host}:#{lsConfig.port} DBID=#{lsConfig.dbid}..."
new LogStore(lsConfig).on 'log', (log)->
  io.sockets.emit 'log', log
