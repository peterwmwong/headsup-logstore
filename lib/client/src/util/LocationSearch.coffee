define ->
  opts = {}
  for kv in window.location.search.slice(1).split '?'
    [k,v] = kv.split '='
    opts[k] = v
  opts