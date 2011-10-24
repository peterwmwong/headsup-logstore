ciregex = /([^ ]*) (ID:(\d*)( siteID:(\d*)( userID:(\d*))?)?)/
leregex = /^(\d\d\d\d)-(\d\d)-(\d\d)\s+(\d\d):(\d\d):(\d\d)\s+(\w*)\s+(\w*)\s+[(]([^)]*)[)]\s*(.*)\s*/


module.exports =
  
  parseClientInfo: parseClientInfo = (line)->
    if p = ciregex.exec(line.toString().trim())
      ip: p[1]
      id: p[3]
      siteid: p[5]
      userid: p[7]

  parse: (lines,ctx)->
    ctx ?= {};
    for line in lines.split('\n') when line = line.trim()
      if p = leregex.exec line
        ctx =
          server: ctx.server
          date: new Date p[1], p[2], p[3], p[4], p[5], p[6], 0
          category: p[7]
          codeSource: p[8]
          clientInfo: parseClientInfo p[9]
          msg: p[10]
      else
        server: ctx.server
        date: ctx.date
        category: ctx.category
        codeSource: ctx.codeSource
        clientInfo: ctx.clientInfo
        msg: line
