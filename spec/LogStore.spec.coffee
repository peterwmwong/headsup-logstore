LogStore = require '../lib/LogStore'
LogPublisher = require '../lib/LogPublisher'
MockRedis = require './util/MockRedis'
{isWindows,notyet,mocklog,runUntil} = require './util/SpecHelpers'
redis = require 'redis'

if isWindows() and (not process.env.TEST_REDIS_HOST or not process.env.TEST_REDIS_PORT)
  throw "Windows: Cannot run LogStore.spec without an external redis-server host and port specified (TEST_REDIS_HOST, TEST_REDIS_PORT)"

L = console.log.bind console
DEFAULT_COUNT = 25

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
          db = redis.createClient mockRedis.port, mockRedis.port
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
      lp = new LogPublisher context:'test', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      logstores = for i in [0...3] then new LogStore host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> for logstore in [lp, logstores...] then logstore.end()

      mlogs = [mocklog()]
      logsReceived = 0
      for logstore in logstores
        logstore.on 'log', (log)->
          expect(log).toEqual mlogs
          ++logsReceived

      runs -> lp.log mlogs
      waitsFor -> logsReceived >= 3


  describe ".get({},callback)", ->
    mlogs = null

    it "returns last #{DEFAULT_COUNT} log entries", ->
      lp = new LogPublisher context:'test', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> lp.end()
      mlogs = (mocklog(date: Date.now()+1000*i) for i in [0..DEFAULT_COUNT+5])

      received = undefined
      runUntil (done)-> lp.log mlogs, done
      runs -> ls.get {}, (err, entries)-> received = entries
      waitsFor -> received
      runs -> expect(received).toEqual mlogs.reverse().slice(0,DEFAULT_COUNT)

    it "returns last X log entries, if X < #{DEFAULT_COUNT}", ->
      lp = new LogPublisher context:'test', host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after -> lp.end()
      mlogs = (mocklog(date: Date.now()+1000*i) for i in [0...3])

      received = undefined
      runUntil (done)-> lp.log mlogs, done
      runs -> ls.get {}, (err, entries)-> received = entries
      waitsFor -> received
      runs -> expect(received).toEqual mlogs.reverse()


  describe ".get({filterBy: {context}})", ->

    it "returns last #{DEFAULT_COUNT} log entries, from specified context", ->
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
        expect(receivedOne).toEqual oneLogs.reverse().slice(0,DEFAULT_COUNT)
        expect(receivedTwo).toEqual twoLogs.reverse().slice(0,DEFAULT_COUNT)


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

    it "returns last #{DEFAULT_COUNT} log entries, from specified clientip", ->
      runUntil (done)->
        ls.get {filterBy:{clientip:'1'}}, (err,entries)->
          expect(entries).toEqual [
            mlogs[4]
            mlogs[2]
            mlogs[0]
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

    it "returns last #{DEFAULT_COUNT} log entries, starting with logid of {start}", ->
      runUntil (done)->
        ls.get {start: 2}, (err, entries)->
          expect(err).toBe undefined
          expect(entries).toEqual mlogs.slice(0,3).reverse()
          done()


  describe "._toLog(hash)", ->
    it "converts hash to Log Entry", ->
      l = mocklog()
      hash = 
        date: l.date
        category: l.category
        codeSource: l.codeSource
        ci_ip: l.clientInfo.ip
        ci_id: l.clientInfo.id
        ci_siteid: l.clientInfo.siteid
        ci_userid: l.clientInfo.userid
      expect(ls._toLog hash).toEqual l

    it "doesn't add clientInfo if ci_ip, ci_id, ci_siteid, or ci_userid or present", ->
      l = mocklog()
      delete l.clientInfo
      hash = 
        date: l.date
        category: l.category
        codeSource: l.codeSource
      expect(ls._toLog hash).toEqual l


  it "MOCK REDIS TEARDOWN", ->
    if db
      db.flushall()
      db.end()
    mockRedis?.shutdown()
    ls?.end()
    runUntil (done)-> setTimeout done, 100
