MockRedis = require '../spec/util/MockRedis'
path = require 'path'
fs = require 'fs'
{spawn} = require 'child_process'
redis = require 'redis'

L = console.log.bind console
logWatcherFile = path.resolve './lib/LogWatcher.coffee'

if not process.env.TEST_REDIS_HOST and not process.env.TEST_REDIS_PORT
  throw "This bench requires an external redis server, please specify using environment variables TEST_REDIS_HOST and TEST_REDIS_PORT"

execLogWatcher = (args...)->
  s = spawn process.execPath, [logWatcherFile].concat(args)
  s.stdout.on 'data', (data)-> console.log "LogWatcher OUT:", data.toString()
  s.stderr.on 'data', (data)-> console.log "LogWatcher ERR:", data.toString()

mockLogBuffer = fs.readFileSync path.resolve './bench/fixture/example_log.txt'
mockLogEnd = mockLogBuffer.length - 1

dir = path.resolve "#{process.env.TEMP or '/tmp'}/LogWatcher-#{Date.now()}"
console.log dir

fs.mkdir dir, "0777", ->

  curdbid = 0
  new MockRedis (mr)->
    mockRedis = mr
    db = redis.createClient mockRedis.port, mockRedis.host

    db.select curdbid
    jsonfile = path.resolve "#{dir}/goodConfig.json"
    fs.writeFileSync jsonfile, JSON.stringify
      context: 'test'
      redis_host: mockRedis.host
      redis_port: mockRedis.port
      redis_dbid: curdbid

    logfile = path.resolve "#{dir}/logFile.txt"
    fs.writeFileSync logfile, ''

    lw = execLogWatcher jsonfile, logfile

    curPos = 0
    maxChunkSize = 256*5
    maxInterval = 1000
    minInterval = 50

    writeChunk = ->
      endPos = Math.min(mockLogEnd, ~~(maxChunkSize * Math.random()) + curPos)
      ws = fs.createWriteStream logfile, flags: 'a', start: fs.statSync(logfile).size
      ws.end mockLogBuffer.slice curPos, endPos
      if (curPos = endPos) >= mockLogEnd
        curPos = 0
      setTimeout writeChunk, Math.max(minInterval, maxInterval*Math.random())
    setTimeout writeChunk, 500
  