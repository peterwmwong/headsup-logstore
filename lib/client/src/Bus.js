
define(function() {
  var sock, _ref;
  return sock = io.connect(((_ref = window.headsup) != null ? _ref.socketurl : void 0) || "http://172.16.19.148:8888");
});
