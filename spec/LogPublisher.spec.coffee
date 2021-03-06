LogStore = require '../lib/LogStore'
LogPublisher = require '../lib/LogPublisher'
MockRedis = require './util/MockRedis'
{isWindows,mocklog,runUntil,randint} = require './util/SpecHelpers'
redis = require 'redis'

L = console.log.bind console

describe "LogPublisher", ->
  context = "test#{randint 10}"
  lp = null
  db = null
  mockRedis = null
  curdbid = 0
  onConnectArgs = undefined

  beforeEach ->
    onConnectArgs = undefined
    runUntil (done)->
      if not db or not mockRedis
        new MockRedis (mr)->
          mockRedis = mr
          db = redis.createClient mockRedis.port, mockRedis.host
          done()
      else done()
    runs ->
      lp = new LogPublisher
        context: context
        host: mockRedis.host
        port: mockRedis.port
        dbid: ++curdbid
        onConnect: (err)-> onConnectArgs = [err]
      db.select curdbid

  afterEach -> lp?.end()

  describe "new LogPublisher()", ->
    it 'throws an error when no @context is given', ->
      expect( ->
        new LogPublisher port:mockRedis.port, host:mockRedis.host, dbid: curdbid
      ).toThrow 'No @context was supplied.'

    it 'calls onConnect with error when unable to make connection', ->
      lp2 = null
      @after -> lp2?.end()
      runUntil (done)->
        lp2 = new LogPublisher
          context: context
          port: 7
          host: '127.127.127.127'
          dbid: curdbid
          disableRetryConnect: true
          onConnect: (err)->
            expect(err).toBe "Could not connect to 127.127.127.127:7"
            done()

    it 'calls onConnect with no errors', ->
      waitsFor -> onConnectArgs
      runUntil (done)->
        expect(onConnectArgs).toEqual [undefined]
        done()
  
  describe ".log([], callback)", ->

    it "calls callback with error, when passed non-Array", ->
      for input in [null,undefined,5,'blarg']
        lp.log input, (e)-> expect(e).toBe "Log entries must be an Array"

    it 'calls callback with error = {numFailed}, when log entries are null, undefined, number, string', ->
      lp.log [undefined,null,5,'blarg'], (e)-> expect(e).toEqual numFailed: 4

    it 'publishes logs', ->
      received = undefined
      client = redis.createClient mockRedis.port, mockRedis.host
      client.on 'message', (chan,msg)->
        received =
          channel: chan
          logs: JSON.parse msg
      client.subscribe 'log'
      @after -> client.end()

      logs = for i in [0...5] then mocklog date: Date.now()+1000*i
      runs -> lp.log logs
      waitsFor -> received
      runs ->
        expect(received).toEqual
          channel: 'log'
          logs: for l,i in logs
            l.id = i
            l.context = context
            l

    it 'logs multiple log entries', ->
      runUntil (done)->
        logs = for i in [0...2001]
          mocklog
            date: Date.now()+1000*i
            clientInfo:
              ip: "127.0.0.#{i}"

        lp.log logs, (e)->
          expect(e).toBeUndefined()
          $M = db.multi()
          $M.get "nextlogid"
          for log,i in logs
            bucket = ~~(i/1000)
            minor = i % 1000

            $M.hmget "logs:#{bucket}",
              "#{minor}:date"
              "#{minor}:context"
              "#{minor}:category"
              "#{minor}:codeSource"
              "#{minor}:msg"
              "#{minor}:ci_ip"
              "#{minor}:ci_district"
              "#{minor}:ci_id"
              "#{minor}:ci_siteid"
              "#{minor}:ci_userid"

            $M.zscore "context:#{context}", "#{i}"
            $M.zscore "context_ip:#{context}:#{log.clientInfo.ip}", "#{i}"
            $M.zscore "ip:#{log.clientInfo.ip}", "#{i}"
            $M.zscore "all", "#{i}"
          
          $M.exec (err,data)->
            try
              exp = ['2001']
              for log,i in logs
                exp.push [
                  log.date.toString()
                  context
                  log.category
                  log.codeSource
                  log.msg
                  log.clientInfo.ip
                  log.clientInfo.district
                  log.clientInfo.id.toString()
                  log.clientInfo.siteid.toString()
                  log.clientInfo.userid.toString()
                ]
                exp = exp.concat [
                  "#{log.date*1000}"
                  "#{log.date*1000}"
                  "#{log.date*1000}"
                  "#{log.date*1000}"
                ]
              expect(data).toEqual exp
            finally
              done()

  describe ".end()", ->
    it "closes connection, log() sends error to callbacks", ->
      lp.end()
      lp.log mocklog(), (e)->
        expect(e).toBe "Connection closed"

  describe "._toHash()", ->

    it "hashes full Log Entry", ->
      l = mocklog()
      expect(lp._toHash(l, 10, 'testContext')).toEqual
        '10:context': 'testContext'
        '10:msg': l.msg
        '10:date': l.date
        '10:category': l.category
        '10:codeSource': l.codeSource
        '10:ci_district': l.clientInfo.district
        '10:ci_ip': l.clientInfo.ip
        '10:ci_id': l.clientInfo.id
        '10:ci_siteid': l.clientInfo.siteid
        '10:ci_userid': l.clientInfo.userid


    it "hashes Log Entry with NO client info", ->
      l = mocklog()
      delete l.clientInfo
      expect(lp._toHash(l, 5, 'testContext')).toEqual
        '5:context': 'testContext'
        '5:msg': l.msg
        '5:date': l.date
        '5:category': l.category
        '5:codeSource': l.codeSource


  describe "._saltDate(date)", ->

    it "returns date * 1000 + salt", -> expect(lp._saltDate 1).toBe 1000

    it "increments salt, when date is same as previous 'salted' date", ->
      lp._saltDate 1
      expect(lp._saltDate 1).toBe 1001
      expect(lp._saltDate 1).toBe 1002
      expect(lp._saltDate 1).toBe 1003

    it "resets salt, when date is different from previous 'salted' date", ->
      lp._saltDate 1
      expect(lp._saltDate 1).toBe 1001
      expect(lp._saltDate 2).toBe 2000
      expect(lp._saltDate 2).toBe 2001
      expect(lp._saltDate 3).toBe 3000

  it "MOCK REDIS TEARDOWN", ->
    if db
      db.flushall()
      db.end()
    mockRedis?.shutdown()
    lp?.end()
    runUntil (done)-> setTimeout done, 100