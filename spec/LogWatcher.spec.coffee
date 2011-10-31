LogStore = require '../lib/LogStore'
LogWatcher = require '../lib/LogWatcher'
MockRedis = require './util/MockRedis'
{isWindows,notyet,mocklog,runUntil} = require './util/SpecHelpers'
redis = require 'redis'

if isWindows() and (not process.env.TEST_REDIS_HOST or not process.env.TEST_REDIS_PORT)
  throw "Windows: Cannot run LogStore.spec without an external redis-server host and port specified (TEST_REDIS_HOST, TEST_REDIS_PORT)"

L = console.log.bind console
DEFAULT_COUNT = 25

describe "LogWatcher", ->

  describe "given bad config or arguments", ->
    it "exits with error when ./headsup-config.json does NOT exist", notyet
    it "exits with error when ./headsup-config.json is not JSON parseable", notyet
    it "exits with error when redis_host and/or redis_port are NOT specified in headsup-config.json", notyet
    it "exits with error when NO log file is specified", notyet

  describe "given proper config and arguments", ->
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
      runUntil (done)->
        db.select curdbid
        done()

    it "publishes log entries when ./serverlog.txt is written to", notyet

    it "MOCK REDIS TEARDOWN", ->
      if db
        db.flushall()
        db.end()
      mockRedis?.shutdown()
      runUntil (done)-> setTimeout done, 100
    
