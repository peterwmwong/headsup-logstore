var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
define(['AppModel', 'Bus'], function(AppModel, Bus) {
  var _;
  _ = cell.prototype.$R;
  return {
    renderChat: function(_arg) {
      var date, msg, name;
      name = _arg.name, msg = _arg.msg, date = _arg.date;
      this.$el.append((function() {
        return _(".chat" + (AppModel.username === name && '.self' || ''), _('p.datetime', new Date(date).toLocaleTimeString()), _('p.from', name), _('.msg', msg));
      })());
      return $(window).scrollTop(this.$el.height());
    },
    afterRender: function() {
      AppModel.on({
        login: __bind(function(_arg) {
          var chats, msg, _i, _len, _results;
          chats = _arg.chats;
          if (chats) {
            _results = [];
            for (_i = 0, _len = chats.length; _i < _len; _i++) {
              msg = chats[_i];
              _results.push(this.renderChat(msg));
            }
            return _results;
          }
        }, this),
        newChat: __bind(function(data) {
          if (data) {
            return this.renderChat(data);
          }
        }, this),
        logout: __bind(function() {
          return this.$el.html('');
        }, this)
      });
      return Bus.on('chat', __bind(function(data) {
        if (data) {
          return this.renderChat(data);
        }
      }, this));
    }
  };
});