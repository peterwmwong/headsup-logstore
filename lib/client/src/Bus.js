
define(['util/LocationSearch'], function(LocationSearch) {
  var socks;
  socks = [io.connect(LocationSearch.source || window.location.host), io.connect(LocationSearch.source2 || window.location.host)];
  return {
    on: function(cat, cb) {
      var s, _i, _len, _results;
      _results = [];
      for (_i = 0, _len = socks.length; _i < _len; _i++) {
        s = socks[_i];
        _results.push(s.on(cat, cb));
      }
      return _results;
    }
  };
});
