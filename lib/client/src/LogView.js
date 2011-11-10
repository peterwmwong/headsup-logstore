
define(['Bus'], function(Bus) {
  var MAX_LOGS, formatDate, logCount, machineMap, padTime, padTime3, renderLogs, _;
  _ = cell.prototype.$R;
  logCount = 0;
  MAX_LOGS = 5000;
  machineMap = {
    test1: 'http://destiny-test1',
    test2: 'http://destiny-test2',
    test3b: 'http://destiny-test3b',
    test5b: 'http://destiny-test5b',
    test6: 'http://destiny-test6',
    sc: 'http://destinysc',
    '10vm': 'http://destiny10-0vm',
    stage: 'http://172.31.223.245'
  };
  padTime = function(t) {
    return t = t < 10 ? "0" + t : t;
  };
  padTime3 = function(t) {
    return t = t < 10 ? "00" + t : t < 100 ? "0" + t : "" + t + " ";
  };
  formatDate = function(d) {
    var ampm, hours;
    d = new Date(d);
    hours = d.getHours();
    ampm = hours > 11 ? (hours = hours - 11, "PM") : "AM";
    return "" + (padTime(hours)) + ":" + (padTime(d.getMinutes())) + ":" + (padTime(d.getSeconds())) + ":" + (padTime3(d.getMilliseconds())) + " " + ampm;
  };
  renderLogs = function(logs) {
    var ci, l, url, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = logs.length; _i < _len; _i++) {
      l = logs[_i];
      ci = l.clientInfo;
      _results.push(_("<div class='log " + l.category + "' data-logid='" + l.id + "'>", _("<a class='context' " + ((url = machineMap[l.context]) && ("href='" + url + "' target='_blank'") || '') + ">", l.context), _('p.ip', (ci != null ? ci.ip : void 0) || ''), _('p.date', l.date && formatDate(l.date || '')), _('p.siteid', (ci != null ? ci.siteid : void 0) || ''), _('p.district', (ci != null ? ci.district : void 0) && ("(" + ci.district + ")") || ''), _('p.cat', l.category), _('.msg', l.msg)));
    }
    return _results;
  };
  return {
    afterRender: function() {
      var $, $el, $window;
      $el = this.$el;
      $ = this.$;
      $window = $(window);
      return Bus.on('log', function(logs) {
        var after, before;
        if ((logCount += logs.length) > MAX_LOGS) {
          $('.log').slice(0, logCount - MAX_LOGS).remove();
          logCount = MAX_LOGS;
        }
        before = $window.scrollTop();
        $window.scrollTop($window.scrollTop() + 1);
        after = $window.scrollTop();
        $el.append(renderLogs(logs));
        if (before !== after) {
          return $window.scrollTop(before);
        } else {
          return $window.scrollTop($el.height());
        }
      });
    }
  };
});
