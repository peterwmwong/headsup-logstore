
define(['Bus', 'MachineMap', 'IPMap'], function(Bus, MachineMap, IPMap) {
  var MAX_LOGS, formatDate, logCount, padTime, renderLogs, zeroPad, _;
  _ = cell.prototype.$R;
  logCount = 0;
  MAX_LOGS = 2000;
  zeroPad = Array(3).join('0');
  padTime = function(t, digits) {
    var delta, s;
    if ((delta = digits - (s = "" + t).length) > 0) {
      return zeroPad.slice(0, delta) + s;
    } else {
      return s;
    }
  };
  formatDate = function(d) {
    var ampm, hours;
    if (!d) {
      return '';
    } else {
      d = new Date(d);
      hours = d.getHours();
      ampm = hours > 11 ? (hours = hours - 11, "PM") : "AM";
      return "" + (padTime(hours, 2)) + ":" + (padTime(d.getMinutes(), 2)) + ":" + (padTime(d.getSeconds(), 2)) + ":" + (padTime(d.getMilliseconds(), 3)) + " " + ampm;
    }
  };
  renderLogs = function(logs) {
    var ci, l, url, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = logs.length; _i < _len; _i++) {
      l = logs[_i];
      ci = l.clientInfo;
      _results.push(_("<div class='log " + l.category + "' data-logid='" + l.id + "'>", _("<a class='context' " + ((url = MachineMap[l.context]) && ("href='" + url + "' target='_blank'") || '') + ">", l.context), _('p.ip', (ci != null ? ci.ip : void 0) ? IPMap[ci.ip] || ci.ip : ''), _('p.date', formatDate(l.date)), _('p.siteid', (ci != null ? ci.siteid : void 0) || ''), _('p.district', (ci != null ? ci.district : void 0) && ("(" + ci.district + ")") || ''), _('p.cat', l.category), _('.msg', l.msg)));
    }
    return _results;
  };
  return {
    render: function(_) {
      return [_('.scrollLockIcon')];
    },
    afterRender: function() {
      var $window, prevScrollLock;
      var _this = this;
      $window = $(window);
      prevScrollLock = false;
      return Bus.on('log', function(logs) {
        var before, scrollLock;
        before = $window.scrollTop();
        $window.scrollTop($window.scrollTop() + 1);
        scrollLock = $window.scrollTop() !== before;
        if (scrollLock !== prevScrollLock) {
          _this.$el.toggleClass('scrollLock', scrollLock);
        }
        prevScrollLock = scrollLock;
        if (scrollLock) $window.scrollTop(before);
        _this.$el.append(renderLogs(logs));
        if (!scrollLock) $window.scrollTop(_this.$el.height());
        logCount += logs.length;
        if (logCount > (scrollLock ? 2 * MAX_LOGS : MAX_LOGS)) {
          _this.$('.log').slice(0, logCount - MAX_LOGS).remove();
          return logCount = MAX_LOGS;
        }
      });
    }
  };
});
