path = require 'path'
fs = require 'fs'
util = require 'util'

newlineRx = /\r?\n/
pollInterval = 100

module.exports =

  watch: (file, opts, cb)->

    # If no options provided...
    if cb is undefined and typeof opts is 'function'
      cb = opts
      opts = {}

    # File exists?
    if not path.existsSync(file) or not (prev = fs.statSync(file)).isFile()
      cb "#{file} is NOT a file"

    else
      unwatch = false
      watcher = undefined
      fs.open file, 'r', (err,fd)-> if err then cb err else
        fs.stat file, (err,prev)-> if err then cb err else
          if not unwatch
            prevLine = ""
            buf = new Buffer 10*1024*1024
            handleChange = (cur,done)->
              pos = prev.size
              size = cur.size - pos

              # Handle file roll over (non-append)
              if size <= 0
                pos = 0
                size = cur.size

              prev = cur

              fs.read fd, buf, 0, size, pos, (err,bytesRead,buffer)-> if err then done err else
                lines = buffer.slice(0, bytesRead).toString().split newlineRx
                oldPrevLine = prevLine
                prevLine = lines.pop()
                if lines?.length
                  lines[0] = oldPrevLine + lines[0]
                  done undefined, lines

            if opts?.poll is true
              poll = ->
                if not unwatch
                  fs.stat file, (err,cur)-> if err then cb err else
                    if (cur.size > 0) and ((prev.size isnt cur.size) or (prev.mtime.getTime() isnt cur.mtime.getTime()))
                      handleChange cur, (err,lines)->
                        cb err, lines
                        setTimeout poll, pollInterval
                    else
                      setTimeout poll, pollInterval
              poll()

            else
              watcher = fs.watch file, (ev, fname)->
                if fname and not unwatch and ev is 'change'
                  fs.stat file, (err,cur)-> if err then cb err else
                    handleChange cur, cb

      unwatch: ->
        unwatch = true
        watcher?.close()
        watcher = undefined