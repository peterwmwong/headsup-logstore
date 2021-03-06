os = require 'os'
module.exports =
  
  randint: randint = (max)-> Math.ceil Math.random()*max

  isWindows: -> not not /^Windows/.exec os.type()

  notyet: -> @fail '>> Not implemented yet <<'

  mocklog: (overrides)->
    {date,category,codeSource,clientInfo} = overrides or {}
    {ip,id,siteid,userid} = clientInfo or {}
    msg: "Random msg #{randint 256}"
    date: date or Date.now()
    category: category or "MOK#{randint 10}"
    codeSource: codeSource or 'mockCodeSource'
    clientInfo:
      district: "district#{randint 256}"
      ip: ip or "172.167.182.#{randint 256}"
      id: id or "#{randint 10}"
      siteid: siteid or "#{randint 256}"
      userid: userid or "#{randint 256}"

  runUntil: (cb)->
    isdone = false
    runs ->
      cb -> isdone = true
    waitsFor (-> isdone),2000
  
  addIdContext: (l,id,ctx)->
    l.id = Number id
    l.context = ctx
    l