
define(['Bus', 'cell!LogView', 'cell!Header'], function(Bus, LogView, Header) {
  var _;
  _ = cell.prototype.$R;
  return {
    render: function(_) {
      return [_(Header), _(LogView)];
    }
  };
});
