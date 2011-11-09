
define(['cell!LogView', 'cell!Header'], function(LogView, Header) {
  return {
    render: function(_) {
      return [_(Header), _(LogView)];
    }
  };
});
