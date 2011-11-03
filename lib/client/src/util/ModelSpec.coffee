define ['SpecHelpers'], ({spyOnAll})->
  ({loadModule})->
    Model = undefined
    model = undefined
    initObj = undefined

    beforeEach ->
      loadModule (module)->
        Model = module
        initObj =
          a: 'A'
          b: 2
          c: {}
          d: (->)
          e: new Model {f: new Model {g:3} }
        model = new Model initObj

    describe 'Model.pathObj', ->
      itPaths = (o,path,expected)->
        it "#{JSON.stringify o} #{JSON.stringify path} => #{expected}", ->
          expect(Model.pathObj o, path).toBe expected
      
      itPaths undefined, ['a','b'], undefined
      itPaths {a:0}, ['a'], 0
      itPaths {a: m = {b:2}}, ['a'], m
      itPaths {a:{b:2}}, ['a','b'], 2
      itPaths {a: m = {b:{c:3}}}, ['a'], m
      itPaths {a:{b: m = {c:3}}}, ['a','b'], m
      itPaths {a:{b:{c:3}}}, ['a','b','c'], 3

    describe "new Model(/*{object}*/)", ->
      it "copies key/values from object passed into constructor", ->
        for k,v of initObj
          expect(model[k]).toBe v
    

    describe ".on({'test': <func>})", ->
      it "calls <func> once when .trigger('test') called", ->
        mHandler = spyOn (binds = test:->), 'test'
        model.on binds
        model.trigger 'test'
        expect(mHandler.callCount).toBe 1


    describe ".onAndCall({'test': <func>})", ->
      it "calls <func> when handler is set AND once whenever .trigger('test') is called", ->
        mBinds = test: (->)
        mHandler = spyOn mBinds, 'test'

        model.onAndCall mBinds

        expect(mHandler.callCount).toBe 1
        expect(mHandler.argsForCall[0][0]).toEqual
          model: model
          type: 'test'

        model.trigger 'test'
        expect(mHandler.callCount).toBe 2
        expect(mHandler.argsForCall[1][0]).toEqual
          model: model
          type: 'test'
    

    describe ".onAndCall({'change:a': <func>})", ->
      it "calls <func> when handler is set AND once whenever .set({a:<new value>) is called", ->
        mHandler = spyOn (mBinds = 'change:a': (->)), 'change:a'

        model.onAndCall mBinds

        expect(mHandler.callCount).toBe 1
        expect(mHandler.argsForCall[0][0]).toEqual
          cur: 'A'
          property: 'a'
          model: model
          type: 'change:a'

        model.set a: 'B'
        expect(mHandler.callCount).toBe 2
        expect(mHandler.argsForCall[1][0]).toEqual
          cur: 'B'
          prev: 'A'
          property: 'a'
          model: model
          type: 'change:a'


    describe ".onAndCall({'change:a.b.c': <func>})", ->
      
      describe "handles nested properties initially undefined set to bindable values (instanceof Model)", ->
        hRoot = undefined
        hParent = undefined
        hChild = undefined
        resetSpies = ->
          hRoot?.reset()
          hParent?.reset()
          hChild?.reset()

        beforeEach ->
          model.onAndCall {'change:root':hRoot,'change:root.parent':hParent,'change:root.parent.child':hChild} =
            spyOnAll
              'change:root': ->
              'change:root.parent': ->
              'change:root.parent.child': ->

        it '@bindAndCall calls parent and child handlers', ->
          expect(hRoot.callCount).toBe 1
          expect(hParent.callCount).toBe 1
          expect(hChild.callCount).toBe 1

        it "@set({root:<NOT an Object>}) calls parent and child handlers, passing <undefined> to child handler", ->
          resetSpies()
          model.set root: 5
          expect(hRoot.callCount).toBe 1
          expect(hParent.callCount).toBe 1
          expect(hChild.callCount).toBe 1

        it "@set({root: {parent: {child:5} } }) calls parent and child handlers, passing 5 to child handler", ->
          resetSpies()
          model.set root: {parent: {child: 5}}
          expect(hRoot.callCount).toBe 1
          expect(hParent.callCount).toBe 1
          expect(hChild.callCount).toBe 1

          expect(hParent.argsForCall[0][0].cur).toEqual {child: 5}
          expect(hChild.argsForCall[0][0].cur).toBe 5

        it "@set({root: new Model({parent: new Model({child:5})}) }) calls parent and child handlers, passing 5 to child handler", ->
          resetSpies()
          model.set
            root: root = new Model
              parent: parent = new Model
                child: 5
          expect(hRoot.callCount).toBe 1
          expect(hParent.callCount).toBe 1
          expect(hChild.callCount).toBe 1

          expect(hParent.argsForCall[0][0].cur).toBe parent
          expect(hChild.argsForCall[0][0].cur).toBe 5

        it "@set({root: new Model({parent: new Model({child:5})}) }), @root.parent.set({child: 6}), calls child handler twice passing (1) 5, (2) 6", ->
          resetSpies()
          model.set
            root: root = new Model
              parent: parent = new Model
                child: 5

          expect(hParent.callCount).toBe 1
          expect(hChild.callCount).toBe 1
          expect(hChild.argsForCall[0][0].cur).toBe 5

          model.root.parent.set child: 6
          expect(hParent.callCount).toBe 1
          expect(hChild.callCount).toBe 2
          expect(hChild.argsForCall[1][0].cur).toBe 6

      it "calls <func> when handler is set AND once whenever .set({a:<new value>}) is called", ->
        model.onAndCall {'change:e':hE,'change:e.f':hEF,'change:e.f.g':hEFG} = spyOnAll
          'change:e': ->
          'change:e.f': ->
          'change:e.f.g': ->
        expect(hE.callCount).toBe 1
        expect(hEF.callCount).toBe 1
        expect(hEFG.callCount).toBe 1
        expect(hE.argsForCall[0][0]).toEqual
          cur: model.e
          property: 'e'
          model: model
          type: 'change:e'

        expect(hEF.argsForCall[0][0]).toEqual
          cur: model.e.f
          property: 'f'
          model: model.e
          type: 'change:e.f'
        
        expect(hEFG.argsForCall[0][0]).toEqual
          cur: model.e.f.g
          property: 'g'
          model: model.e.f
          type: 'change:e.f.g'


        olde = model.e
        model.set e: (newe = new Model {f: new Model {g: 4}})

        expect(hE.callCount).toBe 2
        expect(hEF.callCount).toBe 2
        expect(hEFG.callCount).toBe 2
        expect(hE.argsForCall[1][0]).toEqual parentEvent =
          cur: newe
          prev: olde
          property: 'e'
          model: model
          type: 'change:e'

        expect(hEF.argsForCall[1][0]).toEqual
          cur: newe.f
          prev: olde.f
          property: 'f'
          model: model.e
          type: 'change:f'
          parentEvent: parentEvent
          
        expect(hEFG.argsForCall[1][0]).toEqual
          cur: newe.f.g
          prev: olde.f.g
          property: 'g'
          model: model.e.f
          type: 'change:g'
          parentEvent: parentEvent
        

        oldf = model.e.f
        model.e.set f: (newf = new Model {g: 4})

        expect(hE.callCount).toBe 2
        expect(hEF.callCount).toBe 3
        expect(hEFG.callCount).toBe 3

        expect(hEF.argsForCall[2][0]).toEqual parentEvent =
          cur: newf
          prev: oldf
          property: 'f'
          model: model.e
          type: 'change:f'
        
        expect(hEFG.argsForCall[2][0]).toEqual
          cur: newf.g
          prev: oldf.g
          property: 'g'
          model: newf
          type: 'change:g'
          parentEvent: parentEvent


        model.e.f.set g: 5
        expect(hE.callCount).toBe 2
        expect(hEF.callCount).toBe 3
        expect(hEFG.callCount).toBe 4

        expect(hEFG.argsForCall[3][0]).toEqual
          cur: 5
          prev: 4
          property: 'g'
          model: model.e.f
          type: 'change:g'

    describe ".off({'test': <func>})", ->
      it "does no longer calls <func> whenever .trigger('test') called", ->
        mBinds = test: (->)
        spyOn mBinds, 'test'

        model.on mBinds
        model.trigger 'test'
        expect(mBinds.test.callCount).toBe 1
        expect(mBinds.test).toHaveBeenCalledWith
          model: model
          type: 'test'
        
        model.off 'test': mBinds.test
        model.trigger 'test'
        expect(mBinds.test.callCount).toBe 1


    describe ".set()", ->

      describe "a.b.set( { c:'B' }, { event: 'data' } )", ->
        it "triggers 'change:a.b.c' AND passes event data", ->
          model.a = new Model
            b: new Model
              c: 'A'

          binds = {}
          binds[b = "change:a.b.c"] = ->
          spyOn binds, b
          model.onAndCall binds

          model.a.b.set {c:'B'}, eventData = {event:'data'}

          expect(binds['change:a.b.c'].callCount).toBe 2
          expect(binds['change:a.b.c'].argsForCall[1][0]).toEqual
            prev: 'A'
            cur: 'B'
            property: 'c'
            model: model.a.b
            type: 'change:c'
            data: eventData

      describe ".set( { a:'B', b:3 }, { event: 'data' } )", ->
        it "triggers 'change:a', 'change:b' AND passes event data", ->
          binds = {}
          for p in ['a','b','c','d']
            binds[b = "change:#{p}"] = ->
            spyOn binds, b
          model.on binds
          
          model.set {a:'B',b:3}, eventData = {event:'data'}

          expect(binds['change:a']).toHaveBeenCalledWith
            prev: 'A'
            cur: 'B'
            property: 'a'
            model: model
            type: 'change:a'
            data: eventData

          expect(binds['change:b']).toHaveBeenCalledWith
            prev: 2
            cur: 3
            property: 'b'
            model: model
            type: 'change:b'
            data: eventData

      describe ".set( { a:'B', b:3 } )", ->
        it "triggers 'change:a' and 'change:b'", ->
          binds = {}
          for p in ['a','b','c','d']
            binds[b = "change:#{p}"] = ->
            spyOn binds, b
          model.on binds
          
          model.set a: 'B', b: 3

          expect(binds['change:a']).toHaveBeenCalledWith
            prev: 'A'
            cur: 'B'
            property: 'a'
            model: model
            type: 'change:a'

          expect(binds['change:b']).toHaveBeenCalledWith
            prev: 2
            cur: 3
            property: 'b'
            model: model
            type: 'change:b'

          expect(binds["change:c"]).not.toHaveBeenCalled()
          expect(binds["change:d"]).not.toHaveBeenCalled()
