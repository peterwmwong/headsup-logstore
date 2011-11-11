
define(['util/LocationSearch'], function(LocationSearch) {
  var sock;
  return sock = io.connect(LocationSearch.source || "http://172.16.19.148:8888");
});
