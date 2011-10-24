LogStore = require '../lib/LogStore'
LogPublisher = require '../lib/LogPublisher'
{createServer} = require './util/redis-remote'
{mocklog,runUntil,toHash} = require './util/SpecHelpers'
redis = require 'redis'

L = console.log.bind console

describe "LogPublisher", ->
  lp = null
  db = null
  dbmgr = null
  curdbid = 0

  beforeEach ->
    if not dbmgr?
      runUntil (done)->
        createServer ((err,mock)->
          dbmgr = mock
          db = redis.createClient dbmgr.port
          lp = new LogPublisher host:'127.0.0.1', port: dbmgr.port
          done()
        ), 100
    else
      db.select ++curdbid
      lp = new LogPublisher host:'127.0.0.1', port: dbmgr.port, dbid: curdbid

  afterEach -> lp.end()

  describe ".log {server,date,category,codeSource,clientInfo:{ip,id,siteid,userid}}, callback", ->

    it "when log entry lacks server, calls callback with error", ->
      lp.log {}, (e)-> expect(e).toBe "Log entry lacks 'server'"

    it "when log entry is null or undefined, calls callback with error", ->
      lp.log null, (e)-> expect(e).toBe "Log entry was null or undefined"
      lp.log undefined, (e)-> expect(e).toBe "Log entry was null or undefined"

    it """
       incr nextlogid:{server}
            adds hash log:{server}:{id}, with {server,date,category,codeSource,ci_ip,ci_id,ci_siteid,ci_userid}
            adds zset timeline:{server}, with {id}
            calls callback
       """, ->
      runUntil (done)->
        l = mocklog()

        lp.log l, (e)->
          expect(e).toBeNull()
          db.multi()
            .get("nextlogid:#{l.server}")
            .hgetall("log:#{l.server}:1")
            .zscore("timeline:#{l.server}","1")
            .exec (err, data)->
              expect(data).toEqual [
                '1'
                toHash l
                "#{l.date*1000}"
              ]

              lp.log l, (e)->
                expect(e).toBeNull()
                db.multi()
                  .get("nextlogid:#{l.server}")
                  .hgetall("log:#{l.server}:2")
                  .zscore("timeline:#{l.server}","2")
                  .exec (err, data)->
                    expect(data).toEqual [
                      '2'
                      toHash l
                      "#{l.date*1000 + 1}"
                    ]
                    done()

  describe ".end()", ->
    it "closes connection, log() sends error to callbacks", ->
      lp.end()
      lp.log mocklog(), (e)->
        expect(e).toBe "Connection closed"


  # Salting a date prevents equal scores of log entries of the same date
  # (log entries on the same millisecond)
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


  it 'TEST TEARDOWN', ->
    db.end()
    dbmgr.stop()
    lp.end()
    runUntil (done)-> setTimeout done, 100
