{existsSync} = require 'path'
{watchFile,read,open,statSync} = require 'fs'

file = process.argv[2]

# File exists?
if not existsSync(file) or not (prev = statSync(file)).isFile()
  console.log "#{file} is NOT a file"

else
  open file, 'r', (err, fd)->
    if err
      console.log "Error opening file #{file}:", err

    else
      console.log "Watching: #{file}"

      buf = new Buffer 8*1024
      watchFile file, (cur,prev)->
        pos = prev.size
        size = cur.size - pos

        # Handle Log roll over (non-append)
        if size <= 0
          pos = 0
          size = cur.size

        read fd, buf, 0, size, pos, (err,bytesRead,buffer)->
          console.log buffer.slice(0, size).toString()
