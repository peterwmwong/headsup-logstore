var __slice = Array.prototype.slice;
define(['require', './allSpecs'], function(require, allSpecs) {
  return require(allSpecs, function() {
    var jasmineEnv, spec, specs, trivialReporter, _i, _len;
    specs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    for (_i = 0, _len = specs.length; _i < _len; _i++) {
      spec = specs[_i];
      spec();
    }
    trivialReporter = new jasmine.TrivialReporter();
    jasmineEnv = jasmine.getEnv();
    jasmineEnv.updateInterval = 5000;
    jasmineEnv.addReporter(trivialReporter);
    jasmineEnv.specFilter = function(spec) {
      return trivialReporter.specFilter(spec);
    };
    return jasmineEnv.execute();
  });
});