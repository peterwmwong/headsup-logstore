define(function() {
  var Model, changeEventRx, unshiftIfNotPresent;
  changeEventRx = /^change:(.*)/;
  unshiftIfNotPresent = function(ls, handler) {
    var l, _i, _len;
    for (_i = 0, _len = ls.length; _i < _len; _i++) {
      l = ls[_i];
      if (l === handler) {
        return;
      }
    }
    return ls.unshift(handler);
  };
  return Model = (function() {
    var parsePropChange, pathObj;
    Model.pathObj = pathObj = function(o, pathArray) {
      if (o) {
        for(var i=0, len=pathArray.length; i < len && (o = o[pathArray[i]]) != null; i++);
        return o;
      }
    };
    Model.parsePropChange = parsePropChange = function(type) {
      var _ref, _ref2;
      return (_ref = changeEventRx.exec(type)) != null ? (_ref2 = _ref[1]) != null ? _ref2.split('.') : void 0 : void 0;
    };
    function Model(attrs) {
      var k, v;
      this._ls = {};
      for (k in attrs) {
        v = attrs[k];
        this[k] = v;
      }
      return;
    }
    Model.prototype.set = function(kvMap, eventData) {
      var k, prev, v;
      for (k in kvMap) {
        v = kvMap[k];
        if (this[k] !== v) {
          prev = this[k];
          try {
            this.trigger({
              cur: (this[k] = v),
              prev: prev,
              property: k,
              type: "change:" + k,
              data: eventData
            });
          } catch (_e) {}
        }
      }
    };
    Model.prototype.trigger = function(evOrType, data) {
      var event, l, ls, _i, _len;
      event = typeof evOrType === 'string' ? {
        type: evOrType,
        data: data
      } : evOrType;
      event.model = this;
      if (ls = this._ls[event.type]) {
        for (_i = 0, _len = ls.length; _i < _len; _i++) {
          l = ls[_i];
          try {
            l(event);
          } catch (_e) {}
        }
      }
    };
    Model.prototype.onAndCall = function(binds) {
      var handler, self, type, _fn;
      self = this;
      _fn = function(handler) {
        var i, lastPropIndex, obj, p, parentProps, props, rebind, rebinders, targetProp, _base, _fn2, _len, _ref;
        if (props = parsePropChange(type)) {
          lastPropIndex = props.length - 1;
          targetProp = props[lastPropIndex];
          parentProps = props.slice(0, lastPropIndex);
          rebind = function(i, obj) {
            var _base, _name, _ref;
            return unshiftIfNotPresent(((_ref = (_base = obj._ls)[_name = "change:" + props[i]]) != null ? _ref : _base[_name] = []), rebinders[i]);
          };
          obj = self;
          rebinders = [];
          _fn2 = function(i) {
            rebinders[i] = function(pev) {
              var ev, j, parentObj, pobj;
              j = i;
              obj = pev.cur;
              pobj = pev.prev;
              parentObj = pev.model;
              while (j++ < lastPropIndex) {
                if (obj instanceof Model) {
                  rebind(j, obj);
                }
                parentObj = obj;
                obj = obj != null ? obj[props[j]] : void 0;
                pobj = pobj != null ? pobj[props[j]] : void 0;
              }
              ev = {
                cur: obj,
                prev: pobj,
                property: targetProp,
                type: "change:" + targetProp,
                model: parentObj,
                data: pev.data
              };
              if (i !== lastPropIndex) {
                ev.parentEvent = pev;
              }
              return handler(ev);
            };
            if (obj instanceof Model) {
              rebind(i, obj);
              return obj = obj[p];
            }
          };
          for (i = 0, _len = props.length; i < _len; i++) {
            p = props[i];
            _fn2(i);
          }
          try {
            return handler({
              cur: obj,
              property: targetProp,
              type: type,
              model: pathObj(self, parentProps)
            });
          } catch (e) {
            return console.error((e != null ? e.stack : void 0) || e);
          }
        } else {
          unshiftIfNotPresent(((_ref = (_base = self._ls)[type]) != null ? _ref : _base[type] = []), handler);
          try {
            return handler({
              type: type,
              model: self
            });
          } catch (_e) {}
        }
      };
      for (type in binds) {
        handler = binds[type];
        _fn(handler);
      }
    };
    Model.prototype.on = function(binds) {
      var bind, handler, obj, p, props, type, v, _base, _i, _len, _ref, _ref2;
      for (type in binds) {
        handler = binds[type];
        if (props = parsePropChange(type)) {
          obj = this;
          _ref = props.slice(0, -1);
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            p = _ref[_i];
            if ((v = obj[p]) instanceof Model) {
              bind = {};
              bind["change:" + p] = function(_arg) {
                var cur, prev;
                cur = _arg.cur, prev = _arg.prev;
              };
              v.bind(bind);
            }
          }
        }
        unshiftIfNotPresent(((_ref2 = (_base = this._ls)[type]) != null ? _ref2 : _base[type] = []), handler);
      }
    };
    Model.prototype.off = function(binds) {
      var handler, i, l, ls, type, _len, _results;
      _results = [];
      for (type in binds) {
        handler = binds[type];
        if (ls = this._ls[type]) {
          for (i = 0, _len = ls.length; i < _len; i++) {
            l = ls[i];
            if (l === handler) {
              delete ls[i];
              return;
            }
          }
        }
      }
      return _results;
    };
    return Model;
  })();
});