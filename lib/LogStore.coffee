{inherits} = require 'util'
{EventEmitter} = require 'events'
redis = require 'redis'

LogStore = (opts)->
  {port,host,dbid} = opts or {}

  for conn in ['_db','_sub']
    @[conn] = redis.createClient port, host
    @[conn].select dbid if dbid

  @_sub.on 'message', (chan,msg)=> @emit 'log', JSON.parse msg
  @_sub.subscribe 'log'

  this

inherits LogStore, EventEmitter

LogStore::[k]=v for k,v of do->

  end: ->
    @_sub?.unsubscribe()
    for conn in ['_db','_sub']
      @[conn]?.end()
      delete @[conn]

  get: (opts,cb)->
    @_checkConn cb

  _checkConn: (cb)->
    if not @_db?
      cb "Connection closed"
      false
    else
      true

module.exports = LogStore
