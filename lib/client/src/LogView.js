var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
define(['Bus'], function(Bus) {
  var formatDate, machineMap, padTime, padTime3, renderLogs, _;
  _ = cell.prototype.$R;
  machineMap = {
    test1: 'http://destiny-test1',
    test2: 'http://destiny-test2',
    test3b: 'http://destiny-test3b',
    test5b: 'http://destiny-test5b',
    test6: 'http://destiny-test6',
    sc: 'http://destinysc',
    '10-0vm': 'http://destiny10-0vm',
    'stage': 'http://172.31.223.245'
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
    var l, url, _i, _len, _ref, _ref2, _results;
    _results = [];
    for (_i = 0, _len = logs.length; _i < _len; _i++) {
      l = logs[_i];
      _results.push(_("<div class='log " + l.category + "' data-logid='" + l.id + "'>", _("<a class='context' " + ((url = machineMap[l.context]) && ("href='" + url + "' target='_blank'") || '') + ">", l.context), _('p.ip', ((_ref = l.clientInfo) != null ? _ref.ip : void 0) || ''), _('p.date', l.date && formatDate(l.date || '')), _('p.siteid', ((_ref2 = l.clientInfo) != null ? _ref2.siteid : void 0) || ''), _('p.cat', l.category), _('.msg', l.msg)));
    }
    return _results;
  };
  return {
    afterRender: function() {
      var $el;
      $el = this.$el;
      return Bus.on('log', __bind(function(logs) {
        $el.append(renderLogs(logs));
        console.log($(window).scrollTop(), $el.height());
        return $(window).scrollTop($el.height());
      }, this));
    }
  };
});