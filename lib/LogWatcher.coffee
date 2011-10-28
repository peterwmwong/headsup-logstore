path = require 'path'
fs = require 'fs'

module.exports =

  watch: (file, cb)->
    # File exists?
    if not path.existsSync(file) or not (prev = fs.statSync(file)).isFile()
      console.log "#{file} is NOT a file"

    else
      watcher = undefined
      fs.open file, 'r', (err, fd)->
        if err
          console.log "Error opening file #{file}:", err

        else
          console.log "Watching: #{file}"

          buf = new Buffer 128*1024
          prevLine = ""
          watcher = fs.watchFile file, (cur,prev)->
            pos = prev.size
            size = cur.size - pos


            # Handle Log roll over (non-append)
            if size <= 0
              pos = 0
              size = cur.size

            fs.read fd, buf, 0, size, pos, (err,bytesRead,buffer)->
              lines = buffer.slice(0, bytesRead).toString().split '\n'
              oldPrevLine = prevLine
              prevLine = lines.pop()
              if lines?.length
                lines[0] = oldPrevLine + lines[0]
                cb undefined, lines

      unwatch: -> fs.unwatchFile file