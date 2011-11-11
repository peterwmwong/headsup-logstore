
define(function() {
  var k, kv, opts, v, _i, _len, _ref, _ref2;
  opts = {};
  _ref = window.location.search.slice(1).split('?');
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    kv = _ref[_i];
    _ref2 = kv.split('='), k = _ref2[0], v = _ref2[1];
    opts[k] = v;
  }
  return opts;
});
