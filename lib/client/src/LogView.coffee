define [
  'Bus'
  'MachineMap'
  'IPMap'
], (Bus,MachineMap,IPMap)->
  _ = cell::$R
  logCount = 0
  MAX_LOGS = 5000
  zeroPad = Array(3).join '0'

  padTime = (t,digits)->
    if (delta = digits - (s = "#{t}").length) > 0
      zeroPad.slice(0,delta) + s
    else s

  formatDate = (d)->
    if not d then ''
    else
      d = new Date d
      hours = d.getHours()
      ampm =
        if hours > 12
          hours = hours - 12
          "PM"
        else
          "AM"
      "#{padTime hours, 2}:#{padTime d.getMinutes(), 2}:#{padTime d.getSeconds(), 2}:#{padTime d.getMilliseconds(), 3} #{ampm}"

  renderLogs = (logs)->
    for l in logs
      ci = l.clientInfo
      _ "<div class='log #{l.category}' data-logid='#{l.id}'>",
        _ "<a class='context' #{(url = MachineMap[l.context]) and "href='#{url}' target='_blank'" or ''}>", l.context
        _ 'p.ip',
          if ci?.ip
            IPMap[ci.ip] or ci.ip
          else ''
        _ 'p.date', formatDate l.date
        _ 'p.siteid', ci?.siteid or ''
        _ 'p.district', ci?.district and "(#{ci.district})" or ''
        _ 'p.cat', l.category
        _ '.msg', l.msg

  render: (_)-> [
    _ '.scrollLockIcon'
  ]
    
  afterRender: ->
    $window = $(window)
    prevScrollLock = false

    Bus.on 'log', (logs)=>

      # Figure out whether to scroll lock or not based on whether we're scrolled
      # all the way to the bottom.
      before = $window.scrollTop()
      $window.scrollTop $window.scrollTop()+1
      scrollLock = $window.scrollTop() isnt before

      # Show/Hide scroll when scroll lock state changes
      @$el.toggleClass 'scrollLock', scrollLock if scrollLock isnt prevScrollLock
      prevScrollLock = scrollLock

      # If the scroll bar isn't at the bottom, put it back.
      $window.scrollTop before if scrollLock

      @$el.append renderLogs logs
        
      # Scrolled to all the way to the bottom? Auto-Scroll!
      $window.scrollTop @$el.height() if not scrollLock

      # Slice off old logs if MAX_LOGS has been reached.
      # Do this ONLY if we're scrolled to the bottom,
      # otherwise it defeats the purpose of scrolling up
      # to lock onto a page of logs.
      # ... Unless we've accumulated twice MAX_LOGS.
      logCount += logs.length
      if logCount > (if scrollLock then 2*MAX_LOGS else MAX_LOGS)
        @$('.log').slice(0,logCount - MAX_LOGS).remove()
        logCount = MAX_LOGS
        
