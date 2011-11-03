module.exports =

  init: ({redis_host, redis_port})-> @port    
  on:
    get: (data,cb)->
      cb name: name, users: Object.keys(@users), chats: @chatBuffer

    setStreamOptions: (opts)->
      if opts?.filterBy
        opts.filterBy

          
      
