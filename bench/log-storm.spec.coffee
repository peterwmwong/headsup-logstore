LogStore = require '../lib/LogStore'
MockRedis = require '../spec/util/MockRedis'
path = require 'path'
fs = require 'fs'
{spawn,fork} = require 'child_process'
{notyet,mocklog,runUntil,addIdContext} = require '../spec/util/SpecHelpers'
redis = require 'redis'

L = console.log.bind console

logWatcherFile = path.resolve './lib/LogWatcher.coffee'
execLogWatcher = (args...)->
  s = spawn process.execPath, [path.resolve('./node_modules/coffee-script/bin/coffee'), logWatcherFile].concat(args)
  s.stdout.on 'data', (data)-> console.log "LogWatcher OUT:", data.toString()
  s.stderr.on 'data', (data)-> console.log "LogWatcher ERR:", data.toString()

mockLogBuffer = fs.readFileSync path.resolve './bench/fixture/example_log.txt'
mockLogEnd = mockLogBuffer.length - 1

describe "BENCH: log storm", ->

  dir = null

  beforeEach ->
    if not process.env.TEST_REDIS_HOST and not process.env.TEST_REDIS_PORT
      throw "This bench requires an external redis server, please specify using environment variables TEST_REDIS_HOST and TEST_REDIS_PORT"

    dir = path.resolve "#{process.env.TEMP or '/tmp'}/LogWatcher-#{Date.now()}"
    console.log dir
    runUntil (done)-> fs.mkdir dir, "0777", done

  afterEach -> runUntil (done)-> fs.rmdir dir, done

  describe "given proper config and arguments", ->
    db = null
    mockRedis = null
    curdbid = 0

    beforeEach ->
      jasmine.DEFAULT_TIMEOUT_INTERVAL =  1e9

      runUntil (done)->
        if not db or not mockRedis
          new MockRedis (mr)->
            mockRedis = mr
            db = redis.createClient mockRedis.port, mockRedis.host
            done()
        else done()


    it "publishes log entries when ./serverlog.txt is written to", ->
      db.select curdbid
      jsonfile = path.resolve "#{dir}/goodConfig.json"
      fs.writeFileSync jsonfile, JSON.stringify {
        context: 'test'
        redis_host: mockRedis.host
        redis_port: mockRedis.port
        redis_dbid: curdbid
      }

      logfile = path.resolve "#{dir}/logFile.txt"
      fs.writeFileSync logfile, ''

      lw = execLogWatcher jsonfile, logfile
      ###
      @after ->
        try ws?.writable and ws?.end()
        try lw?.kill()
        try
          fs.unlinkSync jsonfile
          fs.unlinkSync logfile
      ###

      curPos = 0
      maxChunkSize = 256 * 12

      writeChunk = ->
        endPos = Math.min(mockLogEnd, ~~(maxChunkSize * Math.random()) + curPos)
        ws = fs.createWriteStream logfile, flags: 'a', start: fs.statSync(logfile).size

        ws.end mockLogBuffer.slice curPos, mockLogEnd
        if (curPos = endPos) >= mockLogEnd
          curPos = 0
        setTimeout writeChunk, 1000
      setTimeout writeChunk, 500
      waitsFor -> false # Wait until we timeout...
    
