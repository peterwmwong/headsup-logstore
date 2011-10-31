LogStore = require '../lib/LogStore'
LogPublisher = require '../lib/LogPublisher'
{createServer} = require './util/redis-remote'
{isWindows,mocklog,runUntil,toHash} = require './util/SpecHelpers'
redis = require 'redis'

if isWindows() and (not process.env.TEST_REDIS_HOST or not process.env.TEST_REDIS_PORT)
  throw "Windows: Cannot run LogStore.spec without an external redis-server host and port specified (TEST_REDIS_HOST, TEST_REDIS_PORT)"

L = console.log.bind console

describe "LogPublisher", ->
  context = 'test'
  lp = null
  db = null
  redishost = null
  redisport = null
  dbmgr = null
  curdbid = 0

  beforeEach ->
    if not db
      # Windows/Redis on remote machine
      if process.env.TEST_REDIS_HOST and process.env.TEST_REDIS_PORT
        redishost = process.env.TEST_REDIS_HOST
        redisport = process.env.TEST_REDIS_PORT
        db = redis.createClient redisport, redishost

      # Linux: use redis-remote to start and down
      else
        redishost = '127.0.0.1'
        runUntil (done)->
          createServer ((err,mock)->
            dbmgr = mock
            redisport = dbmgr.port
            db = redis.createClient redisport, redishost
            lp = new LogPublisher context: context, host:redishost, port: redisport
            done()
          ), 100
    else
      db.select ++curdbid
      lp = new LogPublisher context: context, host:redishost, port:redisport, dbid: curdbid

  afterEach -> lp?.end()

  describe "new LogParser()", ->
    it 'throws an error when no @context is given', ->
      expect( ->
        new LogPublisher port:redishost, dbid: redisport, dbid: curdbid
      ).toThrow 'No @context was supplied.'

  describe ".log([], callback)", ->

    it "calls callback with error, when passed non-Array", ->
      for input in [null,undefined,5,'blarg']
        lp.log input, (e)-> expect(e).toBe "Log entries must be an Array"

    it 'calls callback with error = {numFailed}, when log entries are null, undefined, number, string', ->
      lp.log [undefined,null,5,'blarg'], (e)-> expect(e).toEqual numFailed: 4

    it 'publishes logs', ->
      received = undefined
      client = redis.createClient redisport, redishost
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
          logs: logs

    it 'logs multiple log entries', ->
      runUntil (done)->
        logs = for i in [0...5]
          mocklog
            date: Date.now()+1000*i
            clientInfo:
              ip: "127.0.0.#{i}"

        lp.log logs, (e)->
          expect(e).toBeUndefined()
          $M = db.multi()
          $M.get "nextlogid"
          for log,i in logs
            $M.hgetall "log:#{i}"
            $M.zscore "context:#{context}", "#{i}"
            $M.zscore "context_ip:#{context}:#{log.clientInfo.ip}", "#{i}"
            $M.zscore "ip:#{log.clientInfo.ip}", "#{i}"
            $M.zscore "all", "#{i}"
          $M.exec (err,data)->
            try
              exp = ['5']
              for log,i in logs
                exp = exp.concat [
                  toHash log, i
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
      expect(lp._toHash(l = mocklog())).toEqual
        date: l.date
        category: l.category
        codeSource: l.codeSource
        ci_ip: l.clientInfo.ip
        ci_id: l.clientInfo.id
        ci_siteid: l.clientInfo.siteid
        ci_userid: l.clientInfo.userid


    it "hashes Log Entry with NO client info", ->
      l = mocklog()
      delete l.clientInfo
      expect(lp._toHash(l)).toEqual
        date: l.date
        category: l.category
        codeSource: l.codeSource


  describe "._saltDate(date)", ->

    it "date * 1000 + salt", -> expect(lp._saltDate 1).toBe 1000

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


  it 'TEST TEARDOWN', ->
    db.flushall()
    db.end()
    dbmgr?.stop()
    lp.end()
    runUntil (done)-> setTimeout done, 100