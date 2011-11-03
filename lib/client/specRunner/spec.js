define({
  load: function(name, req, load, config) {
    return req(["" + name + "Spec"], function(Spec) {
      return load(function() {
        var ctxPostfix;
        ctxPostfix = 0;
        return describe(name, function() {
          var ctx, specRequire;
          specRequire = null;
          ctx = null;
          beforeEach(function() {
            var ctxName;
            specRequire = require.config({
              context: ctxName = "specs" + (ctxPostfix++),
              baseUrl: '/src/'
            });
            return ctx = window.require.s.contexts[ctxName];
          });
          afterEach(function() {
            return $("[data-requirecontext='" + ctx.contextName + "']").remove();
          });
          return Spec((function() {
            return {
              mockModules: function(map) {
                var k, v, _results;
                _results = [];
                for (k in map) {
                  v = map[k];
                  ctx.defined[k] = v;
                  _results.push(ctx.specified[k] = ctx.loaded[k] = true);
                }
                return _results;
              },
              loadModule: function(cb) {
                var module;
                module = void 0;
                runs(function() {
                  return specRequire([name], function(mod) {
                    return module = mod;
                  });
                });
                waitsFor((function() {
                  return module !== void 0;
                }), "'" + name + "' Module to load", 1000);
                return runs(function() {
                  return cb(module);
                });
              }
            };
          })());
        });
      });
    });
  }
});