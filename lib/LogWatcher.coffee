path = require 'path'
fs = require 'fs'

module.exports =

  watch: (file, cb)->
    # File exists?
    if not path.existsSync(file) or not (prev = fs.statSync(file)).isFile()
      cb "#{file} is NOT a file"

    else
      watcher = undefined
      fs.open file, 'r', (err,fd)->
        if err then cb err
        else fs.stat file, (err,prev)->
          if err then cb err
          else
            buf = new Buffer 128*1024
            prevLine = ""
            watcher = fs.watch file, (ev,fname)->
              if watcher and ev is 'change'
                fs.stat file, (err,cur)->
                  if err then cb err
                  else
                    pos = prev.size
                    size = cur.size - pos

                    # Handle Log roll over (non-append)
                    if size <= 0
                      pos = 0
                      size = cur.size

                    prev = cur

                    fs.read fd, buf, 0, size, pos, (err,bytesRead,buffer)->
                      if err then cb err
                      else
                        lines = buffer.slice(0, bytesRead).toString().split '\n'
                        oldPrevLine = prevLine
                        prevLine = lines.pop()
                        if lines?.length
                          lines[0] = oldPrevLine + lines[0]
                          cb undefined, lines

      unwatch: ->
        watcher?.close()
        watcher = undefined