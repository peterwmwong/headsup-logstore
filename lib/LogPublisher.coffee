{inherits} = require 'util'
{EventEmitter} = require 'events'
redis = require 'redis'

LogPublisher = ({@context,port,host,dbid,onConnect})->
  if not @context? then throw 'No @context was supplied.'
  if typeof onConnect isnt 'function'
    onConnect = undefined

  for conn in ['_db','_pub']
    c = @[conn] = redis.createClient port, host
    c.retry_delay = 750
    c.select dbid if dbid
    if onConnect
      c.once 'error', ->
        if oc = onConnect
          onConnect = undefined
          try oc? "Could not connect to #{host}:#{port}"
      c.once 'ready', ->
        if oc = onConnect
          onConnect = undefined
          try oc()

  # Salting a date prevents equal scores of log entries of the same date
  # (log entries on the same millisecond)
  prevdate = -1
  prevsalt = 0
  @_saltDate = (date)->
    pdate = prevdate
    prevdate = date
    date * 1000 +
      if date is pdate then ++prevsalt
      else prevsalt = 0

  this

LogPublisher.prototype =
  end: ->
    @_disconnected = true
    for conn in ['_db','_pub']
      @[conn].end()
      @[conn].removeAllListeners 'error'

  log: (entries,cb=->)->
    if @_checkConn cb
      if not (entries instanceof Array) then cb "Log entries must be an Array"
      else
        logs = []
        hashes = for el in entries when el and typeof el is 'object'
          logs.push el
          @_toHash el
        numFailed = entries.length - hashes.length

        # No worthy log entries
        if hashes.length is 0
          if numFailed then cb {numFailed}
          else cb()

        else
          # Reserve X number of log ids (X = hashes.length)
          @_db.incrby "nextlogid", hashes.length, (e,logid)=>
            logid = logid - hashes.length
            $M = @_db.multi()
            for h in hashes
              h.logid = logid
              $M.hmset "log:#{logid}", h
              $M.zadd "context:#{@context}", (sdate = @_saltDate(h.date)), logid
              if ip = h.ci_ip
                $M.zadd "ip:#{ip}", sdate, logid
                $M.zadd "context_ip:#{@context}:#{ip}", sdate, logid
              $M.zadd "all", sdate, logid
              ++logid
            $M.exec (dbError)=>
              @_pub.publish 'log', JSON.stringify logs
              if numFailed or dbError then cb {numFailed,dbError}
              else cb()

  _checkConn: (cb)->
    if @_disconnected
      cb "Connection closed"
      false
    else
      true

  _toHash: (e)->
    hash =
      date: e.date
      category: e.category
      codeSource: e.codeSource
      msg: e.msg

    if ci = e.clientInfo
      hash.ci_ip = ci.ip if ci.ip
      hash.ci_id = ci.id if ci.id
      hash.ci_siteid = ci.siteid if ci.siteid
      hash.ci_userid = ci.userid if ci.userid

    hash

module.exports = LogPublisher