define(['SpecHelpers'], function(_arg) {
  var spyOnAll;
  spyOnAll = _arg.spyOnAll;
  return function(_arg2) {
    var Model, initObj, loadModule, model;
    loadModule = _arg2.loadModule;
    Model = void 0;
    model = void 0;
    initObj = void 0;
    beforeEach(function() {
      return loadModule(function(module) {
        Model = module;
        initObj = {
          a: 'A',
          b: 2,
          c: {},
          d: (function() {}),
          e: new Model({
            f: new Model({
              g: 3
            })
          })
        };
        return model = new Model(initObj);
      });
    });
    describe('Model.pathObj', function() {
      var itPaths, m;
      itPaths = function(o, path, expected) {
        return it("" + (JSON.stringify(o)) + " " + (JSON.stringify(path)) + " => " + expected, function() {
          return expect(Model.pathObj(o, path)).toBe(expected);
        });
      };
      itPaths(void 0, ['a', 'b'], void 0);
      itPaths({
        a: 0
      }, ['a'], 0);
      itPaths({
        a: m = {
          b: 2
        }
      }, ['a'], m);
      itPaths({
        a: {
          b: 2
        }
      }, ['a', 'b'], 2);
      itPaths({
        a: m = {
          b: {
            c: 3
          }
        }
      }, ['a'], m);
      itPaths({
        a: {
          b: m = {
            c: 3
          }
        }
      }, ['a', 'b'], m);
      return itPaths({
        a: {
          b: {
            c: 3
          }
        }
      }, ['a', 'b', 'c'], 3);
    });
    describe("new Model(/*{object}*/)", function() {
      return it("copies key/values from object passed into constructor", function() {
        var k, v, _results;
        _results = [];
        for (k in initObj) {
          v = initObj[k];
          _results.push(expect(model[k]).toBe(v));
        }
        return _results;
      });
    });
    describe(".on({'test': <func>})", function() {
      return it("calls <func> once when .trigger('test') called", function() {
        var binds, mHandler;
        mHandler = spyOn((binds = {
          test: function() {}
        }), 'test');
        model.on(binds);
        model.trigger('test');
        return expect(mHandler.callCount).toBe(1);
      });
    });
    describe(".onAndCall({'test': <func>})", function() {
      return it("calls <func> when handler is set AND once whenever .trigger('test') is called", function() {
        var mBinds, mHandler;
        mBinds = {
          test: (function() {})
        };
        mHandler = spyOn(mBinds, 'test');
        model.onAndCall(mBinds);
        expect(mHandler.callCount).toBe(1);
        expect(mHandler.argsForCall[0][0]).toEqual({
          model: model,
          type: 'test'
        });
        model.trigger('test');
        expect(mHandler.callCount).toBe(2);
        return expect(mHandler.argsForCall[1][0]).toEqual({
          model: model,
          type: 'test'
        });
      });
    });
    describe(".onAndCall({'change:a': <func>})", function() {
      return it("calls <func> when handler is set AND once whenever .set({a:<new value>) is called", function() {
        var mBinds, mHandler;
        mHandler = spyOn((mBinds = {
          'change:a': (function() {})
        }), 'change:a');
        model.onAndCall(mBinds);
        expect(mHandler.callCount).toBe(1);
        expect(mHandler.argsForCall[0][0]).toEqual({
          cur: 'A',
          property: 'a',
          model: model,
          type: 'change:a'
        });
        model.set({
          a: 'B'
        });
        expect(mHandler.callCount).toBe(2);
        return expect(mHandler.argsForCall[1][0]).toEqual({
          cur: 'B',
          prev: 'A',
          property: 'a',
          model: model,
          type: 'change:a'
        });
      });
    });
    describe(".onAndCall({'change:a.b.c': <func>})", function() {
      describe("handles nested properties initially undefined set to bindable values (instanceof Model)", function() {
        var hChild, hParent, hRoot, resetSpies;
        hRoot = void 0;
        hParent = void 0;
        hChild = void 0;
        resetSpies = function() {
          if (hRoot != null) {
            hRoot.reset();
          }
          if (hParent != null) {
            hParent.reset();
          }
          return hChild != null ? hChild.reset() : void 0;
        };
        beforeEach(function() {
          var _ref;
          return model.onAndCall((_ref = spyOnAll({
            'change:root': function() {},
            'change:root.parent': function() {},
            'change:root.parent.child': function() {}
          }), hRoot = _ref['change:root'], hParent = _ref['change:root.parent'], hChild = _ref['change:root.parent.child'], _ref));
        });
        it('@bindAndCall calls parent and child handlers', function() {
          expect(hRoot.callCount).toBe(1);
          expect(hParent.callCount).toBe(1);
          return expect(hChild.callCount).toBe(1);
        });
        it("@set({root:<NOT an Object>}) calls parent and child handlers, passing <undefined> to child handler", function() {
          resetSpies();
          model.set({
            root: 5
          });
          expect(hRoot.callCount).toBe(1);
          expect(hParent.callCount).toBe(1);
          return expect(hChild.callCount).toBe(1);
        });
        it("@set({root: {parent: {child:5} } }) calls parent and child handlers, passing 5 to child handler", function() {
          resetSpies();
          model.set({
            root: {
              parent: {
                child: 5
              }
            }
          });
          expect(hRoot.callCount).toBe(1);
          expect(hParent.callCount).toBe(1);
          expect(hChild.callCount).toBe(1);
          expect(hParent.argsForCall[0][0].cur).toEqual({
            child: 5
          });
          return expect(hChild.argsForCall[0][0].cur).toBe(5);
        });
        it("@set({root: new Model({parent: new Model({child:5})}) }) calls parent and child handlers, passing 5 to child handler", function() {
          var parent, root;
          resetSpies();
          model.set({
            root: root = new Model({
              parent: parent = new Model({
                child: 5
              })
            })
          });
          expect(hRoot.callCount).toBe(1);
          expect(hParent.callCount).toBe(1);
          expect(hChild.callCount).toBe(1);
          expect(hParent.argsForCall[0][0].cur).toBe(parent);
          return expect(hChild.argsForCall[0][0].cur).toBe(5);
        });
        return it("@set({root: new Model({parent: new Model({child:5})}) }), @root.parent.set({child: 6}), calls child handler twice passing (1) 5, (2) 6", function() {
          var parent, root;
          resetSpies();
          model.set({
            root: root = new Model({
              parent: parent = new Model({
                child: 5
              })
            })
          });
          expect(hParent.callCount).toBe(1);
          expect(hChild.callCount).toBe(1);
          expect(hChild.argsForCall[0][0].cur).toBe(5);
          model.root.parent.set({
            child: 6
          });
          expect(hParent.callCount).toBe(1);
          expect(hChild.callCount).toBe(2);
          return expect(hChild.argsForCall[1][0].cur).toBe(6);
        });
      });
      return it("calls <func> when handler is set AND once whenever .set({a:<new value>}) is called", function() {
        var hE, hEF, hEFG, newe, newf, olde, oldf, parentEvent, _ref;
        model.onAndCall((_ref = spyOnAll({
          'change:e': function() {},
          'change:e.f': function() {},
          'change:e.f.g': function() {}
        }), hE = _ref['change:e'], hEF = _ref['change:e.f'], hEFG = _ref['change:e.f.g'], _ref));
        expect(hE.callCount).toBe(1);
        expect(hEF.callCount).toBe(1);
        expect(hEFG.callCount).toBe(1);
        expect(hE.argsForCall[0][0]).toEqual({
          cur: model.e,
          property: 'e',
          model: model,
          type: 'change:e'
        });
        expect(hEF.argsForCall[0][0]).toEqual({
          cur: model.e.f,
          property: 'f',
          model: model.e,
          type: 'change:e.f'
        });
        expect(hEFG.argsForCall[0][0]).toEqual({
          cur: model.e.f.g,
          property: 'g',
          model: model.e.f,
          type: 'change:e.f.g'
        });
        olde = model.e;
        model.set({
          e: (newe = new Model({
            f: new Model({
              g: 4
            })
          }))
        });
        expect(hE.callCount).toBe(2);
        expect(hEF.callCount).toBe(2);
        expect(hEFG.callCount).toBe(2);
        expect(hE.argsForCall[1][0]).toEqual(parentEvent = {
          cur: newe,
          prev: olde,
          property: 'e',
          model: model,
          type: 'change:e'
        });
        expect(hEF.argsForCall[1][0]).toEqual({
          cur: newe.f,
          prev: olde.f,
          property: 'f',
          model: model.e,
          type: 'change:f',
          parentEvent: parentEvent
        });
        expect(hEFG.argsForCall[1][0]).toEqual({
          cur: newe.f.g,
          prev: olde.f.g,
          property: 'g',
          model: model.e.f,
          type: 'change:g',
          parentEvent: parentEvent
        });
        oldf = model.e.f;
        model.e.set({
          f: (newf = new Model({
            g: 4
          }))
        });
        expect(hE.callCount).toBe(2);
        expect(hEF.callCount).toBe(3);
        expect(hEFG.callCount).toBe(3);
        expect(hEF.argsForCall[2][0]).toEqual(parentEvent = {
          cur: newf,
          prev: oldf,
          property: 'f',
          model: model.e,
          type: 'change:f'
        });
        expect(hEFG.argsForCall[2][0]).toEqual({
          cur: newf.g,
          prev: oldf.g,
          property: 'g',
          model: newf,
          type: 'change:g',
          parentEvent: parentEvent
        });
        model.e.f.set({
          g: 5
        });
        expect(hE.callCount).toBe(2);
        expect(hEF.callCount).toBe(3);
        expect(hEFG.callCount).toBe(4);
        return expect(hEFG.argsForCall[3][0]).toEqual({
          cur: 5,
          prev: 4,
          property: 'g',
          model: model.e.f,
          type: 'change:g'
        });
      });
    });
    describe(".off({'test': <func>})", function() {
      return it("does no longer calls <func> whenever .trigger('test') called", function() {
        var mBinds;
        mBinds = {
          test: (function() {})
        };
        spyOn(mBinds, 'test');
        model.on(mBinds);
        model.trigger('test');
        expect(mBinds.test.callCount).toBe(1);
        expect(mBinds.test).toHaveBeenCalledWith({
          model: model,
          type: 'test'
        });
        model.off({
          'test': mBinds.test
        });
        model.trigger('test');
        return expect(mBinds.test.callCount).toBe(1);
      });
    });
    return describe(".set()", function() {
      describe("a.b.set( { c:'B' }, { event: 'data' } )", function() {
        return it("triggers 'change:a.b.c' AND passes event data", function() {
          var b, binds, eventData;
          model.a = new Model({
            b: new Model({
              c: 'A'
            })
          });
          binds = {};
          binds[b = "change:a.b.c"] = function() {};
          spyOn(binds, b);
          model.onAndCall(binds);
          model.a.b.set({
            c: 'B'
          }, eventData = {
            event: 'data'
          });
          expect(binds['change:a.b.c'].callCount).toBe(2);
          return expect(binds['change:a.b.c'].argsForCall[1][0]).toEqual({
            prev: 'A',
            cur: 'B',
            property: 'c',
            model: model.a.b,
            type: 'change:c',
            data: eventData
          });
        });
      });
      describe(".set( { a:'B', b:3 }, { event: 'data' } )", function() {
        return it("triggers 'change:a', 'change:b' AND passes event data", function() {
          var b, binds, eventData, p, _i, _len, _ref;
          binds = {};
          _ref = ['a', 'b', 'c', 'd'];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            p = _ref[_i];
            binds[b = "change:" + p] = function() {};
            spyOn(binds, b);
          }
          model.on(binds);
          model.set({
            a: 'B',
            b: 3
          }, eventData = {
            event: 'data'
          });
          expect(binds['change:a']).toHaveBeenCalledWith({
            prev: 'A',
            cur: 'B',
            property: 'a',
            model: model,
            type: 'change:a',
            data: eventData
          });
          return expect(binds['change:b']).toHaveBeenCalledWith({
            prev: 2,
            cur: 3,
            property: 'b',
            model: model,
            type: 'change:b',
            data: eventData
          });
        });
      });
      return describe(".set( { a:'B', b:3 } )", function() {
        return it("triggers 'change:a' and 'change:b'", function() {
          var b, binds, p, _i, _len, _ref;
          binds = {};
          _ref = ['a', 'b', 'c', 'd'];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            p = _ref[_i];
            binds[b = "change:" + p] = function() {};
            spyOn(binds, b);
          }
          model.on(binds);
          model.set({
            a: 'B',
            b: 3
          });
          expect(binds['change:a']).toHaveBeenCalledWith({
            prev: 'A',
            cur: 'B',
            property: 'a',
            model: model,
            type: 'change:a'
          });
          expect(binds['change:b']).toHaveBeenCalledWith({
            prev: 2,
            cur: 3,
            property: 'b',
            model: model,
            type: 'change:b'
          });
          expect(binds["change:c"]).not.toHaveBeenCalled();
          return expect(binds["change:d"]).not.toHaveBeenCalled();
        });
      });
    });
  };
});