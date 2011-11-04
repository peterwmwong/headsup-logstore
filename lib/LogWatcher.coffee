fs = require 'fs'
path = require 'path'
redis = require 'redis'
FileWatcher = require './FileWatcher'
LogPublisher = require './LogPublisher'
{parse} = require './LogParser'
L = console.log.bind(console)

config = process.argv[2]
logfile = process.argv[3]

processConfig = (cfgFile, cb)->
  if not path.existsSync(cfgFile) or not fs.lstatSync(cfgFile).isFile()
    L "#{config} is not a file."
  else
    try
      if c = JSON.parse fs.readFileSync(config).toString()
        if not c.context or not c.redis_host or not c.redis_port or not c.redis_dbid?
          L "#{config} does not contain context, redis_port, redis_host, and/or redis_dbid."
          return

    if not c then L "#{config} does not contain JSON."
    else cb c

processConfig config, ({context, redis_host, redis_port, redis_dbid})->
  if not path.existsSync(logfile) or not fs.lstatSync(logfile).isFile()
    L "#{logfile} is not a file."
  else
    lp = new LogPublisher
      context: context
      host: redis_host
      port: redis_port
      dbid: redis_dbid
      onConnect: (err)->
        if err then L "Could not connect to redis server at #{redis_host}:#{redis_port}"
        else
          ctx = undefined
          watcher = FileWatcher.watch logfile, (err, lines)->
            if err
              L "Error watching #{logfile}, err=", err
              watcher.unwatch()
            else
              lp.log (ctx = parse(l, ctx) for l in lines when l)
