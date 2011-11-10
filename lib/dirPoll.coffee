# HACKAROUND
# ==========
# Problem:
#   As observed on VM's (Hyper-V w/Windows 2008 Guest), node.js
#   fs.watch() doesn't seem to trigger on file changes.
# Solution:
#   Forcing the OS to get file stats seems to trigger it.
#   Running 'dir' does the trick.

fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

interval = 100
fname = path.resolve process.argv[2]

console.log "Dir polling file: #{fname}"
if not fs.statSync(fname).isFile() then console.log "#{fname} is not file"
else
  poll = ->
    exec "dir #{fname}"
    setTimeout poll, interval
  poll()
