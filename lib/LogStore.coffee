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

LogStore.DEFAULT_LIMIT = (DEFAULT_LIMIT = 50)

LogStore::[k]=v for k,v of do->

  end: ->
    @_sub?.unsubscribe()
    for conn in ['_db','_sub']
      @[conn]?.end()
      delete @[conn]

  get: ({filterBy,limit,start},cb)->
    if not @_db then cb "Connection closed"
    else
      if start?
        @_db.zrevrank "all", start, (err,rank)=>
          if err then cb err
          else if not rank? then cb "Start log id #{start} doesn't exist"
          else @_get filterBy, limit, rank, cb
      else
        @_get filterBy, limit, 0, cb

  _get: (filterBy, limit, startrank, cb)->
    limit = if limit? and limit < DEFAULT_LIMIT then limit else DEFAULT_LIMIT
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
            minor = id % 1000
            bucket = ~~(id/1000)
            $M.hmget "logs:#{bucket}",
              "#{minor}:date"
              "#{minor}:context"
              "#{minor}:category"
              "#{minor}:codeSource"
              "#{minor}:msg"
              "#{minor}:ci_district"
              "#{minor}:ci_ip"
              "#{minor}:ci_id"
              "#{minor}:ci_siteid"
              "#{minor}:ci_userid"

          $M.exec (err,logs)=>
            if err then cb err
            else
              for log,i in logs then logs[i] = @_toLog log, ids[i]
              cb undefined, logs

  _toLog: (e, id)->
    rtn =
      id: Number id
      date: Number e[0]
      context: e[1]
      category: e[2]
      codeSource: e[3]
      msg: e[4]

    if e[5] or e[6] or e[7] or e[8] or e[9]
      rtn.clientInfo = ci = {}
      ci.district = e[5] if e[5]
      ci.ip = e[6] if e[6]
      ci.id = e[7] if e[7]
      ci.siteid = e[8] if e[8]
      ci.userid = e[9] if e[9]
    rtn

module.exports = LogStore
