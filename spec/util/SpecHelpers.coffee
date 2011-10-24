randint = (max)-> Math.ceil Math.random()*max
module.exports =
  notyet: -> @fail '>> Not implemented yet <<'
  mocklog: (overrides)->
    {server,date,category,codeSource,clientInfo} = overrides or {}
    {ip,id,siteid,userid} = clientInfo or {}
    server: server or "mockServer"
    date: date or Date.now()
    category: category or "MOCK#{randint 10}"
    codeSource: codeSource or 'mockCodeSource'
    clientInfo:
      ip: ip or "172.16.18.#{randint 256}"
      id: id or randint 10
      siteid: siteid or randint 256
      userid: userid or randint 256

  runUntil: (cb)->
    isdone = false
    runs ->
      cb -> isdone = true
    waitsFor (-> isdone),2000

  toHash: (l)->
    server: l.server
    date: l.date.toString()
    category: l.category
    codeSource: l.codeSource
    ci_ip: l.clientInfo.ip
    ci_id: l.clientInfo.id.toString()
    ci_siteid: l.clientInfo.siteid.toString()
    ci_userid: l.clientInfo.userid.toString()
