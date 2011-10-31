{createServer} = require './redis-remote'

MockRedis = (onSetupDone)->
  # Windows/Redis on remote machine
  if process.env.TEST_REDIS_HOST and process.env.TEST_REDIS_PORT
    @host = process.env.TEST_REDIS_HOST
    @port = process.env.TEST_REDIS_PORT
    onSetupDone this

  # Linux: use redis-remote to start and down
  else
    @host = '127.0.0.1'
    createServer ((err,mock)=>
      @_dbmgr = mock
      @port = @_dbmgr.port
      onSetupDone this
    ), 100

MockRedis::[k] = v for k,v of do->
  shutdown: -> @_dbmgr?.stop()

module.exports = MockRedis
    