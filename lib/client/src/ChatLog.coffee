define [
  'AppModel'
  'Bus'
], (AppModel, Bus)->
  _ = cell::$R

  renderChat: ({name,msg,date})->
    @$el.append do->
      _ ".chat#{AppModel.username is name and '.self' or ''}",
        _ 'p.datetime', new Date(date).toLocaleTimeString()
        _ 'p.from', name
        _ '.msg', msg
    $(window).scrollTop @$el.height()
    
  afterRender: ->
    AppModel.on
      login: ({chats})=>
        @renderChat msg for msg in chats if chats
      newChat: (data)=>
        @renderChat data if data
      logout: => @$el.html ''

    Bus.on 'chat', (data)=>
      @renderChat data if data