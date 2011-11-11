
define(['util/LocationSearch'], function(LocationSearch) {
  var socks;
  socks = [io.connect(LocationSearch.source || "http://172.16.19.148:8888"), io.connect(LocationSearch.source2 || "http://172.31.223.245:8888")];
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
