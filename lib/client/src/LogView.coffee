define [
  'Bus'
], (Bus)->
  _ = cell::$R

  machineMap =
    test: 'http://www.google.com'
    test1: 'http://destiny-test1'
    test2: 'http://destiny-test2'
    test3b: 'http://destiny-test3b'
    test4b: 'http://destiny-test4b'
    sc: 'http://destinysc'
    '10-0vm': 'http://destiny10-0vm'
    'stage': 'http://172.31.223.245'

  padTime = (t)->
    t =
      if t < 10 then "0#{t}"
      else t
  
  padTime3 = (t)->
    t =
      if t < 10 then "00#{t}"
      else if t < 100 then "0#{t}"
      else "#{t} "

  formatDate = (d)->
    d = new Date d
    hours = d.getHours()
    ampm =
      if hours > 11
        hours = hours - 11
        "PM"
      else
        "AM"
    "#{padTime hours}:#{padTime d.getMinutes()}:#{padTime d.getSeconds()}:#{padTime3 d.getMilliseconds()} #{ampm}"

  renderLogs = (logs)->
    for l in logs
      _ "<div class='log' data-logid='#{l.id}'>",
        _ "<a class='context' #{(url = machineMap[l.context]) and "href='http://#{url}' or ''"}>", l.context
        _ 'p.ip', l.clientInfo?.ip or ''
        _ 'p.date', l.date and formatDate l.date or ''
        _ 'p.siteid', l.clientInfo?.siteid or ''
        _ 'p.cat', l.category
        _ '.msg', l.msg
    
  afterRender: ->
    $el = @$el
    Bus.on 'log', (logs)=>
      $el.append renderLogs logs
      $(window).scrollTop $el.height()
