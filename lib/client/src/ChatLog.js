
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
      var _this = this;
      AppModel.on({
        login: function(_arg) {
          var chats, msg, _i, _len, _results;
          chats = _arg.chats;
          if (chats) {
            _results = [];
            for (_i = 0, _len = chats.length; _i < _len; _i++) {
              msg = chats[_i];
              _results.push(_this.renderChat(msg));
            }
            return _results;
          }
        },
        newChat: function(data) {
          if (data) return _this.renderChat(data);
        },
        logout: function() {
          return _this.$el.html('');
        }
      });
      return Bus.on('chat', function(data) {
        if (data) return _this.renderChat(data);
      });
    }
  };
});
