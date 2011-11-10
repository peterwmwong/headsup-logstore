define [
  'Bus'
], (Bus)->
  _ = cell::$R
  logCount = 0
  MAX_LOGS = 5000

  machineMap =
    test1: 'http://destiny-test1'
    test2: 'http://destiny-test2'
    test3b: 'http://destiny-test3b'
    test5b: 'http://destiny-test5b'
    test6: 'http://destiny-test6'
    sc: 'http://destinysc'
    '10vm': 'http://destiny10-0vm'
    stage: 'http://172.31.223.245'

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
      ci = l.clientInfo
      _ "<div class='log #{l.category}' data-logid='#{l.id}'>",
        _ "<a class='context' #{(url = machineMap[l.context]) and "href='#{url}' target='_blank'" or ''}>", l.context
        _ 'p.ip', ci?.ip or ''
        _ 'p.date', l.date and formatDate l.date or ''
        _ 'p.siteid', ci?.siteid or ''
        _ 'p.district', ci?.district and "(#{ci.district})" or ''
        _ 'p.cat', l.category
        _ '.msg', l.msg
    
  afterRender: ->
    $el = @$el
    $ = @$
    $window = $(window)

    Bus.on 'log', (logs)->

      # Slice off old logs if MAX_LOGS has been reached
      if (logCount += logs.length) > MAX_LOGS
        $('.log').slice(0,logCount - MAX_LOGS).remove()
        logCount = MAX_LOGS

      before = $window.scrollTop()
      $window.scrollTop $window.scrollTop()+1
      after = $window.scrollTop()

      $el.append renderLogs logs

      # Don't touch that scroll bar!
      if before isnt after
        $window.scrollTop before
        
      # Scrolled to all the way to the bottom? Auto-Scroll!
      else
        $window.scrollTop $el.height()
