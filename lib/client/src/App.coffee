define [
  'Bus'
  'cell!LogView'
  'cell!Header'
], (Bus,LogView,Header)->
  _ = cell::$R

  render: (_)-> [
    _ Header
    _ LogView
  ]
