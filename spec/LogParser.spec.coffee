{parse,parseClientInfo} = require '../lib/LogParser'

describe 'LogParser', ->

  describe '.parse(line, context)', ->

    it 'parses blank lines', ->
      expect(parse "").toEqual msg: ""
      expect(parse "   ").toEqual msg: "   "
      expect(parse "   \n").toEqual msg: "   \n"

    it 'parses message only Log Entry', ->
      msg = '123 1241 sdflksd 87324 sk !@%!@%'
      expect(parse msg).toEqual msg: msg

    it 'parses message only Log Entry, uses context to fill in date, category, codeSource, and clientInfo', ->
      msg = '123 1241 sdflksd 87324 sk !@%!@%'
      ctx =
        date: Date.now()
        category: 'cat'
        codeSource: 'codesrc'
        clientInfo: 'ci'
      
      expect(parse msg, ctx).toEqual
        date: ctx.date
        category: ctx.category
        codeSource: ctx.codeSource
        clientInfo: ctx.clientInfo
        msg: msg

    it 'parses full Log Entry', ->
      entry = '2010-10-12 08:41:31\tINFO\tCatalina\t(127.0.0.1 ID:2 siteID:10 userID:101)\t Initialization processed in 422 ms'
      expect(parse entry).toEqual
        date: new Date(2010, 10, 12, 8, 41, 31).getTime()
        category: 'INFO'
        codeSource: 'Catalina'
        clientInfo:
          ip: '127.0.0.1'
          id: '2'
          siteid: '10'
          userid: '101'
        msg: 'Initialization processed in 422 ms'

    it 'parses full Log Entry with district client info', ->
      entry = '2010-10-12 08:41:31\tINFO\tCatalina\t(127.0.0.1 Context:blargContext ID:2 siteID:10 userID:101)\t Initialization processed in 422 ms'
      expect(parse entry).toEqual
        date: new Date(2010, 10, 12, 8, 41, 31).getTime()
        category: 'INFO'
        codeSource: 'Catalina'
        clientInfo:
          ip: '127.0.0.1'
          id: '2'
          siteid: '10'
          userid: '101'
          district: 'blargContext'
        msg: 'Initialization processed in 422 ms'

    it 'parses Log Entry with NO clientInfo', ->
      entry = '2010-10-12 08:41:31\tINFO\tCatalina\t()\t Initialization processed in 422 ms'
      expect(parse entry).toEqual
        date: new Date(2010, 10, 12, 8, 41, 31).getTime()
        category: 'INFO'
        codeSource: 'Catalina'
        msg: 'Initialization processed in 422 ms'

  describe 'parseClientInfo', ->
    it 'return undefined on NON Client Info', ->
      expect(parseClientInfo '123 1241 sdflksd 87324 sk !@%!@%').toBe undefined

    it 'parses full Client Info', ->
      expect(parseClientInfo '127.0.0.1 ID:10 siteID:9 userID:8').toEqual
        ip: '127.0.0.1'
        id: '10'
        siteid: '9'
        userid: '8'
      
    it 'parses Client Info with NO userID or siteID', ->
      expect(parseClientInfo '127.0.0.1 ID:10').toEqual
        ip: '127.0.0.1'
        id: '10'

    it 'parses ClientInfo with NO userID', ->
      expect(parseClientInfo '127.0.0.1 ID:10 siteID:9').toEqual
        ip: '127.0.0.1'
        id: '10'
        siteid: '9'
      
    it 'parses full Client Info with district', ->
      expect(parseClientInfo '127.0.0.1 Context:blargContext ID:10 siteID:9 userID:8').toEqual
        ip: '127.0.0.1'
        id: '10'
        siteid: '9'
        userid: '8'
        district: 'blargContext'

    it 'parses full Client Info with district, but NO userID', ->
      expect(parseClientInfo '127.0.0.1 Context:blargContext2 ID:10 siteID:9').toEqual
        ip: '127.0.0.1'
        id: '10'
        siteid: '9'
        district: 'blargContext2'

    it 'parses full Client Info with district, but NO userID or siteID', ->
      expect(parseClientInfo '127.0.0.1 Context:blargContext3 ID:10').toEqual
        ip: '127.0.0.1'
        id: '10'
        district: 'blargContext3'
