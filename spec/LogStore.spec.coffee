LogStore = require '../lib/LogStore'
LogPublisher = require '../lib/LogPublisher'
MockRedis = require './util/MockRedis'
{isWindows,notyet,mocklog,runUntil,addIdContext} = require './util/SpecHelpers'
redis = require 'redis'

if isWindows() and (not process.env.TEST_REDIS_HOST or not process.env.TEST_REDIS_PORT)
  throw "Windows: Cannot run LogStore.spec without an external redis-server host and port specified (TEST_REDIS_HOST, TEST_REDIS_PORT)"

L = console.log.bind console
DEFAULT_LIMIT = LogStore.DEFAULT_LIMIT

describe "LogStore", ->
  ls = null
  db = null
  mockRedis = null
  curdbid = 0

  beforeEach ->
    runUntil (done)->
      if not db or not mockRedis
        new MockRedis (mr)->
          mockRedis = mr
          db = redis.createClient mockRedis.port, mockRedis.host
          done()
      else done()
    runs ->
      ls = new LogStore host:mockRedis.host, port:mockRedis.port, dbid: ++curdbid
      db.select curdbid

  afterEach -> ls?.end()

  describe ".end()", ->
    it "closes connection, get() sends error to callbacks", ->
      ls.end()
      ls.get {}, (e)->
        expect(e).toBe "Connection closed"


  describe ".on('log', callback)", ->
    it 'calls callback, when Log Entry is published', ->
      lp = new LogPublisher
        context:'test'
        host:mockRedis.host
        port:mockRedis.port
        dbid: curdbid

      logstores = for i in [0...3]
        new LogStore
          host:mockRedis.host
          port:mockRedis.port
          dbid: curdbid

      @after -> for logstore in [lp, logstores...] then logstore.end()

      mlogs = [mocklog()]
      logsReceived = 0
      for logstore in logstores
        logstore.on 'log', (log)->
          expect(log).toEqual do->
            for l in mlogs
              l.context = 'test'
              l
          ++logsReceived

      runs -> lp.log mlogs
      waitsFor -> logsReceived >= 3

  describe ".get({},callback)", ->
    mlogs = null

    it "returns last #{DEFAULT_LIMIT} log entries", ->
      lp = new LogPublisher context:'test', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> lp.end()
      mlogs = (mocklog(date: Date.now()+1000*i) for i in [0..DEFAULT_LIMIT+5])

      received = undefined
      runUntil (done)-> lp.log mlogs, done
      runs -> ls.get {}, (err, entries)-> received = entries
      waitsFor -> received
      runs -> expect(received).toEqual do->
        for l in mlogs.reverse().slice(0,DEFAULT_LIMIT)
          addIdContext l, l.id, 'test'

    it "returns last X log entries, if X < #{DEFAULT_LIMIT}", ->
      lp = new LogPublisher context:'test', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> lp.end()
      mlogs = (mocklog(date: Date.now()+1000*i) for i in [0...(DEFAULT_LIMIT-1)])

      received = undefined
      runUntil (done)-> lp.log mlogs, done
      runs -> ls.get {}, (err, entries)-> received = entries
      waitsFor -> received
      runs -> expect(received).toEqual do->
        for l in mlogs.reverse()
          addIdContext l, l.id, 'test'

  describe ".get({filterBy: {context}})", ->

    it "returns last #{DEFAULT_LIMIT} log entries, from specified context", ->
      lpOne = new LogPublisher context:'one', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      lpTwo = new LogPublisher context:'two', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> lp.end() for lp in [lpOne, lpTwo]
      oneLogs = (mocklog {category: 'oneCat', date: Date.now()+1000*i} for i in [0...1])
      twoLogs = (mocklog {category: 'twoCat', date: Date.now()+1000*i} for i in [0...1])

      receivedOne = undefined
      receivedTwo = undefined
      runUntil (done)-> lpOne.log oneLogs, done
      runUntil (done)-> lpTwo.log twoLogs, done
      runs ->
        ls.get {filterBy: {context: 'one'}}, (err, entries)-> receivedOne = entries
        ls.get {filterBy: {context: 'two'}}, (err, entries)-> receivedTwo = entries
      waitsFor -> receivedOne and receivedTwo
      runs ->
        expect(receivedOne).toEqual do->
          for l in oneLogs.reverse().slice(0,DEFAULT_LIMIT)
            addIdContext l, l.id, 'one'
        expect(receivedTwo).toEqual do->
          for l in twoLogs.reverse().slice(0,DEFAULT_LIMIT)
            addIdContext l, l.id, 'two'


  describe ".get({filterBy: {clientip}})", ->
    mlogs = undefined

    beforeEach ->
      lp = new LogPublisher context:'test', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> lp.end()
      mlogs = (mocklog {date: Date.now()+1000*i} for i in [0...5])
      mlogs[0].clientInfo = ip: '1'
      mlogs[1].clientInfo = ip: '2'
      mlogs[2].clientInfo = ip: '1'
      mlogs[3].clientInfo = ip: '3'
      mlogs[4].clientInfo = ip: '1'
      runUntil (done)-> lp.log mlogs, done

    it "returns nothing, when clientip is bogus", ->
      runUntil (done)->
        ls.get {filterBy:{clientip:'4'}}, (err,entries)->
          expect(entries).toEqual []
          done()

    it "returns last #{DEFAULT_LIMIT} log entries, from specified clientip", ->
      runUntil (done)->
        ls.get {filterBy:{clientip:'1'}}, (err,entries)->
          expect(entries).toEqual [
            addIdContext mlogs[4], 4, 'test'
            addIdContext mlogs[2], 2, 'test'
            addIdContext mlogs[0], 0, 'test'
          ]
          done()


  describe ".get({start})", ->
    mlogs = undefined

    beforeEach ->
      lp = new LogPublisher context:'test', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> lp.end()
      mlogs = (mocklog(date: Date.now()+1000*i) for i in [0...5])
      runUntil (done)-> lp.log mlogs, done

    it 'calls callback with error, when not log has id of {start}' , ->
      runUntil (done)->
        ls.get {start: 100}, (err, entries)->
          expect(err).toEqual "Start log id 100 doesn't exist"
          done()

    it "returns last #{DEFAULT_LIMIT} log entries, starting with logid of {start}", ->
      runUntil (done)->
        ls.get {start: 2}, (err, entries)->
          expect(err).toBe undefined
          expect(entries).toEqual do->
            start = 2
            for l in mlogs.slice(0,3).reverse()
              addIdContext l, start--, 'test'
          done()


  describe "._toLog([],id)", ->
    it "converts hash to Log Entry", ->
      l = mocklog()
      l.id = 77
      data = [
        l.date
        l.context
        l.category
        l.codeSource
        l.msg
        l.clientInfo.ip
        l.clientInfo.id
        l.clientInfo.siteid
        l.clientInfo.userid
      ]
      expect(ls._toLog data, l.id).toEqual l

    it "doesn't add clientInfo if ci_ip, ci_id, ci_siteid, or ci_userid or present", ->
      l = mocklog()
      l.id = 88
      delete l.clientInfo
      data = [
        l.date
        l.context
        l.category
        l.codeSource
        l.msg
      ]
      expect(ls._toLog data, 88).toEqual l

  it "MOCK REDIS TEARDOWN", ->
    if db
      db.flushall()
      db.end()
    mockRedis?.shutdown()
    ls?.end()
    runUntil (done)-> setTimeout done, 100
