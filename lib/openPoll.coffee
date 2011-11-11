# HACKAROUND
# ==========
# Problem:
#   As observed on VM's (Hyper-V w/Windows 2008 Guest), node.js
#   fs.watch() doesn't seem to trigger on file changes.
# Solution:
#   Defeating OS disk caching with opening and closing the file...

fs = require 'fs'
path = require 'path'
{exec} = require 'child_process'

interval = 1000
fname = path.resolve process.argv[2]

console.log "Dir polling file: #{fname}"
if not fs.statSync(fname).isFile() then console.log "#{fname} is not file"
else
  poll = ->
    fd = fs.openSync fname, 'r'
    fs.closeSync fd
    setTimeout poll, interval
  poll()
