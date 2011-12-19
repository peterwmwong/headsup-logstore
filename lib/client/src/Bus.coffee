define [
  'util/LocationSearch'
], (LocationSearch)->
  socks = [
    io.connect LocationSearch.source or window.location.host
    io.connect LocationSearch.source2 or window.location.host # This is for the staging box (behind firewall that can't connect to the linux DB machine
  ]
  on: (cat, cb)->
    for s in socks
      s.on cat, cb
