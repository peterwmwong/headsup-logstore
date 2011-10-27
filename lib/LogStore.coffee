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
  @_

  this

inherits LogStore, EventEmitter

LogStore::[k]=v for k,v of do->

  end: ->
    @_sub?.unsubscribe()
    for conn in ['_db','_sub']
      @[conn]?.end()
      delete @[conn]

  get: ({filterBy,limit,start},cb)->
    if @_checkConn cb
      if start?
        @_db.zrevrank "all", start, (err,rank)=>
          if err then cb err
          else if not rank? then cb "Start log id #{start} doesn't exist"
          else @_get filterBy, limit, rank, cb
      else
        @_get filterBy, limit, 0, cb

  _get: (filterBy, limit, startrank, cb)->
    limit = if limit? and limit < 25 then limit else 25
    zset =
      if not filterBy then "all"
      else
        {context,clientip} = filterBy
        if context and clientip then "context_ip:#{context}:#{clientip}"
        else if context then "context:#{context}"
        else if clientip then "ip:#{clientip}"
        else "all"

    @_db.zrevrangebyscore zset, '+inf', '-inf', 'LIMIT', startrank, limit,
      (err,ids)=>
        if err then cb err
        else
          $M = @_db.multi()
          for id in ids
            $M.hgetall "log:#{id}"
          $M.exec (err,logs)=>
            if err then cb err
            else
              for log,i in logs then logs[i] = @_toLog log
              cb undefined, logs

  _checkConn: (cb)->
    if not @_db?
      cb "Connection closed"
      false
    else
      true

  _toLog: (e)->
    rtn =
      date: Number e.date
      category: e.category
      codeSource: e.codeSource

    if e.ci_ip or e.ci_id or e.ci_siteid or e.ci_userid
      ci = {}
      ci.ip = e.ci_ip if e.ci_ip
      ci.id = Number e.ci_id if e.ci_id
      ci.siteid = Number e.ci_siteid if e.ci_siteid
      ci.userid = Number e.ci_userid if e.ci_userid
      rtn.clientInfo = ci
    rtn

module.exports = LogStore
