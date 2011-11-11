define [
  'util/LocationSearch'
], (LocationSearch)->
  socks = [
    io.connect LocationSearch.source or "http://172.16.19.148:8888"
    io.connect LocationSearch.source2 or "http://172.31.223.245:8888"
  ]
  on: (cat, cb)->
    for s in socks
      s.on cat, cb
