define({
  spyOnAll: function(o) {
    var k, v;
    for (k in o) {
      v = o[k];
      spyOn(o, k).andCallThrough();
    }
    return o;
  }
});