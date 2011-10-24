{inherits} = require 'util'
{EventEmitter} = require 'events'
redis = require 'redis'

LogPublisher = (opts)->
  {port,host,dbid} = opts or {}
  for conn in ['_db','_pub']
    @[conn] = redis.createClient port, host
    @[conn].select dbid if dbid

  prevdate = -1
  prevsalt = 0
  @_saltDate = (date)->
    pdate = prevdate
    prevdate = date
    date * 1000 +
      if date is pdate then ++prevsalt
      else prevsalt = 0

  this

LogPublisher::[k]=v for k,v of do->

  end: ->
    for conn in ['_db','_pub']
      @[conn]?.end()
      delete @[conn]

  log: (entry,cb)->
    if @_checkConn cb
      if not entry? then cb "Log entry was null or undefined"
      else
        {server,date,category,codeSource,clientInfo} = entry
        {ip,id,siteid,userid} = clientInfo or {}
        if not server? then cb "Log entry lacks 'server'"
        else
          @_db.incr "nextlogid:#{server}", (e,logid)=>
            if e then cb e 
            else
              @_db.multi()
                .hmset("log:#{server}:#{logid}", {
                  server: server
                  date: date
                  category: category
                  codeSource: codeSource
                  ci_ip: ip
                  ci_id: id
                  ci_siteid: siteid
                  ci_userid: userid
                })
                .zadd("timeline:#{server}", @_saltDate(date), logid)
                .exec cb 
              @_pub.publish 'log', JSON.stringify entry

  _checkConn: (cb)->
    if not @_db?
      cb "Connection closed"
      false
    else
      true

module.exports = LogPublisher