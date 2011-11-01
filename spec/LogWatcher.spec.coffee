LogStore = require '../lib/LogStore'
MockRedis = require './util/MockRedis'
path = require 'path'
fs = require 'fs'
{spawn,fork} = require 'child_process'
{notyet,mocklog,runUntil} = require './util/SpecHelpers'
redis = require 'redis'

L = console.log.bind console

logWatcherFile = path.resolve './lib/LogWatcher.coffee'
execLogWatcher = (args...)->
  spawn process.execPath, [path.resolve('./node_modules/coffee-script/bin/coffee'), logWatcherFile].concat(args)

describe "LogWatcher", ->

  dir = null

  beforeEach ->
    dir = path.resolve "#{process.env.TEMP or '/tmp'}/LogWatcher-#{Date.now()}"
    runUntil (done)-> fs.mkdir dir, "0666", done

  afterEach -> runUntil (done)-> fs.rmdir dir, done

  describe "given bad config or arguments", ->

    it "exits with error when json config does NOT exist", ->
      lw = execLogWatcher 'ASDFASDFASDF.json'

      runUntil (done)->
        lw.stdout.on 'data', (data)->
          expect(data.toString()).toEqual "ASDFASDFASDF.json is not a file.\n"
          done()

    it "exits with error when ./headsup-config.json is not JSON parseable", ->
      json = path.resolve "#{dir}/NonJSON.json"
      fs.writeFileSync json, "nonjson"

      lw = execLogWatcher json
      runUntil (done)->
        lw.stdout.on 'data', (data)->
          expect(data.toString()).toEqual "#{json} does not contain JSON.\n"
          done()

    it "exits with error when context, redis_host, redis_port, and/or redis_dbid are NOT specified in headsup-config.json", ->
      json = path.resolve "#{dir}/JSONWithoutRedis.json"
      fs.writeFileSync json, JSON.stringify {blah:5}

      lw = execLogWatcher json
      runUntil (done)->
        lw.stdout.on 'data', (data)->
          expect(data.toString()).toEqual "#{json} does not contain context, redis_port, redis_host, and/or redis_dbid.\n"
          done()

    it "exits with error when redis server cannot be reached", ->
      json = path.resolve "#{dir}/config.json"
      fs.writeFileSync json, JSON.stringify {context:'test', redis_host:(host = '127.127.127.127'), redis_port:(port = 9), redis_dbid:0}

      logfile = path.resolve "#{dir}/logFile.txt"
      fs.writeFileSync logfile, ''

      lw = execLogWatcher json, logfile
      runUntil (done)->
        lw.stdout.on 'data', (data)->
          expect(data.toString()).toEqual "Could not connect to redis server at #{host}:#{port}\n"
          done()

    it "exits with error when NO log file is specified", ->
      json = path.resolve "#{dir}/JSONWithoutRedis.json"
      fs.writeFileSync json, JSON.stringify {context:'test', redis_host:'127.0.0.1', redis_port:50, redis_dbid:0}

      lw = execLogWatcher json, 'BOGUS'
      runUntil (done)->
        lw.stdout.on 'data', (data)->
          expect(data.toString()).toEqual "BOGUS is not a file.\n"
          done()

  describe "given proper config and arguments", ->
    db = null
    mockRedis = null
    curdbid = 0

    beforeEach ->

      runUntil (done)->
        dir = path.resolve "#{process.env.TEMP or '/tmp'}/LogWatcher-#{Date.now()}"
        fs.mkdir dir, "0666", done
      runUntil (done)->
        if not db or not mockRedis
          new MockRedis (mr)->
            mockRedis = mr
            db = redis.createClient mockRedis.port, mockRedis.host
            done()
        else done()
      runs ->
        db.select curdbid++

    it "publishes log entries when ./serverlog.txt is written to", ->
      json = path.resolve "#{dir}/goodConfig.json"
      fs.writeFileSync json, JSON.stringify {context:'test', redis_host:mockRedis.host, redis_port:mockRedis.port, redis_dbid:curdbid}

      logfile = path.resolve "#{dir}/logFile.txt"
      fs.writeFileSync logfile, ''
      ws = fs.createWriteStream logfile, flags: 'a'

      lw = execLogWatcher json, logfile
      ls = new LogStore host:mockRedis.host, port:mockRedis.port, dbid: curdbid
      @after ->
        try ws?.writable and ws?.end()
        try ls?.end()
        try lw?.kill()

      mockLogs = [{
        date: new Date(2010, 10, 12, 8, 41, 31).getTime()
        category: 'INFO'
        codeSource: 'Catalina'
        clientInfo:
          ip: '127.0.0.1'
          id: '2'
          siteid: '10'
          userid: '101'
        msg: 'Initialization processed in 422 ms'
      }]

      runUntil (done)->
        ls.on 'log', (logs)->
          expect(logs).toEqual mockLogs
          ls.get {}, (err, entries)->
            expect(entries).toEqual mockLogs
            done()

      setTimeout (->
        ws.end "2010-10-12 08:41:31\tINFO\tCatalina\t(127.0.0.1 ID:2 siteID:10 userID:101)\t Initialization processed in 422 ms\n"
      ), 500

    it "MOCK REDIS TEARDOWN", ->
      if db
        db.flushall()
        db.end()
      mockRedis?.shutdown()
      runUntil (done)-> setTimeout done, 100
    
