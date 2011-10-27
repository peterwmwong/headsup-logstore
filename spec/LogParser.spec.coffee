{parse,parseClientInfo} = require '../lib/LogParser'

describe 'LogParser', ->

  describe 'parse()', ->

    it 'parses message only Log Entry', ->
      msg = '123 1241 sdflksd 87324 sk !@%!@%'
      expect(parse msg).toEqual [ msg: msg ]

    it 'parses message only Log Entry, uses parse context', ->
      msg = '123 1241 sdflksd 87324 sk !@%!@%'
      ctx =
        date: Date.now()
        category: 'cat'
        codeSource: 'codesrc'
        clientInfo: 'ci'
      
      expect(parse msg, ctx).toEqual [
        date: ctx.date
        category: ctx.category
        codeSource: ctx.codeSource
        clientInfo: ctx.clientInfo
        msg: msg
      ]

    it 'parses full Log Entry', ->
      entry = '2010-10-12 08:41:31\tINFO\tCatalina\t(127.0.0.1 ID:2 siteID:10 userID:101)\t Initialization processed in 422 ms'
      expect(parse entry).toEqual [
        date: new Date 2010, 10, 12, 8, 41, 31
        category: 'INFO'
        codeSource: 'Catalina'
        clientInfo:
          ip: '127.0.0.1'
          id: '2'
          siteid: '10'
          userid: '101'
        msg: 'Initialization processed in 422 ms'
      ]

    it 'parses Log Entry with NO clientInfo', ->
      entry = '2010-10-12 08:41:31\tINFO\tCatalina\t()\t Initialization processed in 422 ms'
      expect(parse entry).toEqual [
        date: new Date 2010, 10, 12, 8, 41, 31
        category: 'INFO'
        codeSource: 'Catalina'
        msg: 'Initialization processed in 422 ms'
      ]

    it 'parses multiple Log Entries', ->
      entries =
        """ 
        2010-10-12 08:41:30\tINFO0\tCatalina0\t(127.0.0.0 ID:0 siteID:10 userID:100)\t Initialization processed in 420 ms
        2010-10-12 08:41:31\tINFO1\tCatalina1\t(127.0.0.1 ID:1 siteID:11 userID:101)\t Initialization processed in 421 ms
        2010-10-12 08:41:32\tINFO2\tCatalina2\t(127.0.0.2 ID:2 siteID:12 userID:102)\t Initialization processed in 422 ms
        2010-10-12 08:41:33\tINFO3\tCatalina3\t(127.0.0.3 ID:3 siteID:13 userID:103)\t Initialization processed in 423 ms
        2010-10-12 08:41:34\tINFO4\tCatalina4\t(127.0.0.4 ID:4 siteID:14 userID:104)\t Initialization processed in 424 ms
        """

      expect(parse entries).toEqual do->
        for i in [0...5] then do->
          date: new Date 2010, 10, 12, 8, 41, 30+i
          category: "INFO#{i}"
          codeSource: "Catalina#{i}"
          clientInfo:
            ip: "127.0.0.#{i}"
            id: "#{i}"
            siteid: "1#{i}"
            userid: "10#{i}"
          msg: "Initialization processed in 42#{i} ms"

    it 'parses message only Log Entries, with context from previous Log Entries', ->
      entries =
        """
        2010-10-12 08:41:30\tINFO1\tCatalina1\t(127.0.0.1 ID:1 siteID:11 userID:101)\t Initialization processed in 421 ms
        Blarg1
        2010-10-12 08:41:31\tINFO2\tCatalina2\t(127.0.0.2 ID:2 siteID:12 userID:102)\t Initialization processed in 422 ms
        Blarg2
        Blarg3
        """
      expect(parse entries).toEqual [
        { 
          date: new Date 2010, 10, 12, 8, 41, 30
          category: 'INFO1'
          codeSource: 'Catalina1'
          clientInfo:
            ip: '127.0.0.1'
            id: '1'
            siteid: '11'
            userid: '101'
          msg: "Initialization processed in 421 ms" }
        { 
          date: new Date 2010, 10, 12, 8, 41, 30
          category: 'INFO1'
          codeSource: 'Catalina1'
          clientInfo:
            ip: "127.0.0.1"
            id: '1'
            siteid: '11'
            userid: '101'
          msg: "Blarg1" }
        { 
          date: new Date 2010, 10, 12, 8, 41, 31
          category: 'INFO2'
          codeSource: 'Catalina2'
          clientInfo:
            ip: "127.0.0.2"
            id: '2'
            siteid: '12'
            userid: '102'
          msg: "Initialization processed in 422 ms" }
        { 
          date: new Date 2010, 10, 12, 8, 41, 31
          category: 'INFO2'
          codeSource: 'Catalina2'
          clientInfo:
            ip: "127.0.0.2"
            id: '2'
            siteid: '12'
            userid: '102'
          msg: "Blarg2" }
        {
          date: new Date 2010, 10, 12, 8, 41, 31
          category: 'INFO2'
          codeSource: 'Catalina2'
          clientInfo:
            ip: "127.0.0.2"
            id: '2'
            siteid: '12'
            userid: '102'
          msg: "Blarg3" }
      ]


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
