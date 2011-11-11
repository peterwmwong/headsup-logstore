define [
  'util/LocationSearch'
], (LocationSearch)->
  sock = io.connect LocationSearch.source or "http://172.16.19.148:8888"